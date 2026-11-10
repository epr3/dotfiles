import { discoverTree, type Tree, type SessionReader } from "./tree.ts"

type Message = {
  type: string
  time?: { completed?: number }
  content?: { type: string; name?: string; state?: { status: string }; time?: { completed?: number } }[]
}
type Context = {
  client: {
    session: SessionReader & { active(): Promise<Record<string, { type: string }>> }
    message: { list(input: { sessionID: string; limit: number; order: "desc"; type: "assistant" }): Promise<{ data: Message[] }> }
  }
  data: { listen(callback: (event: { details: { type: string; data?: { sessionID?: string } } }) => void): () => void }
}
export type LiveTree = {
  root: Tree["root"]
  rows: (Tree["rows"][number] & { status: string; activity: string; usage: string[]; stale: boolean })[]
}

function usage(session: Tree["root"]): string[] {
  const tokens = session.tokens
  const categories = [tokens?.input, tokens?.output, tokens?.cache?.read, tokens?.cache?.write]
  const known = (value: number | undefined): value is number => typeof value === "number" && Number.isFinite(value) && value >= 0
  if (!categories.some(known)) return ["Tokens unknown"]
  const [input, output, read, write] = categories.map((value) => known(value) ? value : "unknown")
  return [`Tokens: in ${input} · out ${output}`, `Cache: read ${read} · write ${write}`]
}

/** Read-only live adapter at the TUI boundary. Reads are serialized and events invalidate,
 * rather than overwrite, snapshots. Polling recovers missed events/reconnections. */
export function watchTree(
  context: Context,
  sessionID: string,
  update: (tree: LiveTree, createdIDs: readonly string[]) => void,
  failure: (cause: unknown) => void,
  retained = new Map<string, LiveTree>(),
): () => void {
  let stopped = false
  let running = false
  let dirty = false
  let rootID = sessionID
  let timer: ReturnType<typeof setTimeout> | undefined
  const created = new Set<string>()

  // Routes remount the watcher, including while the server is unavailable.
  // Restore only this scope's retained view before attempting any network reads.
  const cached = retained.get(sessionID) ?? [...retained.values()].find((tree) =>
    tree.rows.some(({ session }) => session.id === sessionID))
  if (cached) { rootID = cached.root.id; update(cached, []) }

  async function refresh() {
    if (stopped) return
    if (running) { dirty = true; return }
    running = true
    try {
      const tree = await discoverTree(context.client.session, rootID)
      rootID = tree.root.id
      const active = await context.client.session.active().catch(() => undefined)
      const current = new Set(tree.rows.map(({ session }) => session.id))
      const rows = new Map(retained.get(rootID)?.rows.map((row) => [row.session.id, {
        ...row, stale: true, status: "Status unknown", activity: "Activity unknown",
      }]))
      for (const row of tree.rows) {
        const running = active?.[row.session.id]?.type === "running"
        let activity = "Activity unknown"
        if (running) {
          try {
            const messages = await context.client.message.list({ sessionID: row.session.id, limit: 1, order: "desc", type: "assistant" })
            const message = messages.data[0]
            if (message?.type === "assistant" && message.time?.completed === undefined) {
              const tool = message.content?.findLast((part) => part.type === "tool" && ["running", "streaming"].includes(part.state?.status ?? ""))
              if (tool?.name) activity = `Tool: ${tool.name}`
              else if (message.content?.at(-1)?.type === "reasoning" && message.content.at(-1)?.time?.completed === undefined) activity = "Reasoning"
              else if (message.content?.at(-1)?.type === "text") activity = "Responding"
            }
          } catch { /* Missing message access is not evidence of inactivity. */ }
        }
        rows.set(row.session.id, {
          ...row, stale: false,
          status: running ? "Running" : row.session.outcome ?? "Status unknown",
          activity, usage: usage(row.session),
        })
      }
      // Rebuild preorder after merging so retained children stay with their parent.
      const ordered: LiveTree["rows"] = []
      const seen = new Set<string>([rootID])
      function visit(parentID: string, depth: number) {
        for (const row of rows.values()) {
          if (row.session.parentID !== parentID || seen.has(row.session.id)) continue
          seen.add(row.session.id)
          ordered.push({ ...row, depth, stale: !current.has(row.session.id) })
          visit(row.session.id, depth + 1)
        }
      }
      visit(rootID, 0)
      const value = { root: tree.root, rows: ordered }
      if (!stopped) {
        // Creation events are only hints until discovery confirms membership.
        // Preserve them across failed/overlapping reads, including the first one.
        const createdIDs = [...created].filter((id) => current.has(id))
        for (const id of createdIDs) created.delete(id)
        retained.set(rootID, value)
        update(value, createdIDs)
      }
    } catch (cause) {
      if (!stopped) failure(cause)
    } finally {
      running = false
      if (dirty && !stopped) { dirty = false; schedule() }
    }
  }
  function schedule() {
    if (stopped || timer) return
    timer = setTimeout(() => { timer = undefined; void refresh() }, 250)
  }
  // Subscribe before discovery: events during a read cause another pass, never a lost update.
  const unsubscribe = context.data.listen(({ details }) => {
    if (details.type === "session.created" && details.data?.sessionID) created.add(details.data.sessionID)
    if (details.type.startsWith("session.") || details.type === "server.connected") schedule()
  })
  const poll = setInterval(schedule, 5000)
  void refresh()
  return () => { stopped = true; unsubscribe(); clearInterval(poll); clearTimeout(timer) }
}
