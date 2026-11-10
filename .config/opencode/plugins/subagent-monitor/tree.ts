/** Read-only subset of the installed v2 session client. */
export type Session = {
  id: string
  parentID?: string
  title?: string
  agent?: string
  time?: { created?: number }
  outcome?: "succeeded" | "failed" | "interrupted"
  tokens?: { input: number; output: number; reasoning: number; cache: { read: number; write: number } }
}

export type SessionReader = {
  get(input: { sessionID: string }): Promise<Session>
  list(input: { parentID?: string; limit: number; cursor?: unknown }): Promise<{
    data: Session[]
    cursor: { next?: unknown }
  }>
}

export type Tree = { root: Session; rows: { session: Session; depth: number }[] }

/** Resolve ancestors, then page every parent's children (not just cached family IDs). */
export async function discoverTree(client: SessionReader, sessionID: string): Promise<Tree> {
  let root = await client.get({ sessionID })
  const ancestors = new Set([root.id])
  while (root.parentID) {
    if (ancestors.has(root.parentID)) throw new Error("Session ancestry contains a cycle")
    ancestors.add(root.parentID)
    root = await client.get({ sessionID: root.parentID })
  }

  const rows: Tree["rows"] = []
  const visited = new Set([root.id])
  async function visit(parentID: string, depth: number) {
    let cursor: unknown
    const cursors = new Set<unknown>()
    do {
      const page = await client.list({ parentID, limit: 100, ...(cursor ? { cursor } : {}) })
      for (const session of page.data) {
        // Cursor pages are opaque; enforce scope even if the server returns extra records.
        if (session.parentID !== parentID || visited.has(session.id)) continue
        visited.add(session.id)
        rows.push({ session, depth })
        await visit(session.id, depth + 1)
      }
      cursor = page.cursor.next
      if (cursor && cursors.has(cursor)) throw new Error("Session listing repeated a cursor")
      cursors.add(cursor)
    } while (cursor)
  }
  await visit(root.id, 0)
  return { root, rows }
}

export function sessionLabel(session: Session): string {
  return session.title?.trim() || session.agent?.trim() || "Unknown agent"
}
