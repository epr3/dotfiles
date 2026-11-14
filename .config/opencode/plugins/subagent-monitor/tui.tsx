/** @jsxImportSource @opentui/solid */
import { Plugin } from "@opencode/plugin/tui"
import { For, Show, createEffect, createMemo, createSignal, onCleanup } from "solid-js"
import { sessionLabel } from "./tree.ts"
import { watchTree, type LiveTree } from "./live.ts"

const panelName = "subagent-monitor.tree"

function isFinishedStatus(status: string) {
  return ["succeeded", "failed", "interrupted"].includes(status)
}

export default Plugin.define({
  id: "subagent-monitor",
  setup(context: any) {
    const agentEmojis: Record<string, string> = Object.create(null)
    const configuredEmojis = context.options?.agentEmojis
    if (configuredEmojis && typeof configuredEmojis === "object" && !Array.isArray(configuredEmojis)) {
      for (const [agent, emoji] of Object.entries(configuredEmojis)) {
        if (typeof emoji === "string") agentEmojis[agent.toLowerCase()] = emoji
      }
    }
    const retained = new Map<string, LiveTree>()
    // The host binds each panel to one conversation. Carry the original root
    // across the remount when we rebind the panel after navigating.
    let navigationScope: { sessionID: string; rootID: string } | undefined
    const seen = new Map<string, Set<string>>()
    const suppressed = new Set<string>()
    let activePanel: { name: string; sessionID: string } | undefined
    const [tree, setTree] = createSignal<LiveTree>()
    const [error, setError] = createSignal("")
    const finishedAt = new Map<string, number>()
    const [now, setNow] = createSignal(Date.now())
    const visibleTree = createMemo(() => {
      const snapshot = tree()
      const time = now()
      if (!snapshot) return undefined
      return {
        ...snapshot,
        rows: snapshot.rows.filter((row) => {
          const finished = finishedAt.get(row.session.id)
          return finished === undefined || time - finished < 30_000
        }),
      }
    })
    context.ui.slot({
      append: "app",
      render: () => {
        const clock = setInterval(() => setNow(Date.now()), 1000)
        onCleanup(() => clearInterval(clock))
        createEffect(() => {
          const route = context.ui.router.current()
          setTree(undefined)
          setError("")
          if (route.type !== "session") return
          const scopeID = navigationScope?.sessionID === route.sessionID
            ? navigationScope.rootID
            : route.sessionID
          const knownRoot = retained.get(scopeID)?.root.id ?? [...retained.values()]
            .find((snapshot) => snapshot.rows.some(({ session }) => session.id === scopeID))?.root.id ?? scopeID
          if (!activePanel && !suppressed.has(scopeID) && !suppressed.has(knownRoot)) {
            context.ui.panel.open(panelName)
          }
          onCleanup(watchTree(context, scopeID, (value, createdIDs) => {
            const observedAt = Date.now()
            for (const row of value.rows) {
              if (!row.stale && row.status === "Running") finishedAt.delete(row.session.id)
              else if (!row.stale && isFinishedStatus(row.status) && !finishedAt.has(row.session.id)) {
                finishedAt.set(row.session.id, observedAt)
              }
            }
            setTree(value)
            setError("")
            const previous = seen.get(value.root.id)
            const ids = new Set(value.rows.map(({ session }) => session.id))
            seen.set(value.root.id, ids)
            const closed = [value.root.id, ...ids].some((id) => suppressed.has(id))
            const added = createdIDs.length > 0 || (previous && [...ids].some((id) => !previous.has(id)))
            if (added && !closed && !activePanel) {
              context.ui.panel.open(panelName)
            }
          }, (cause) => {
            console.warn("[subagent-monitor] discovery failed", cause)
            setError("Tree refresh failed; displayed data may be stale. Retrying automatically.")
          }, retained))
        })
        return null
      },
    })
    function closeMonitor(sessionID: string) {
      suppressed.add(sessionID)
      context.ui.panel.close()
    }
    function statusCue(status: string, stale: boolean) {
      if (stale) return { symbol: "?", color: context.theme.text.muted }
      if (status === "Running") return { symbol: "●", color: context.theme.text.feedback.success.base }
      if (status === "succeeded") return { symbol: "✓", color: context.theme.text.feedback.success.base }
      if (status === "failed") return { symbol: "✕", color: context.theme.text.feedback.error.base }
      if (status === "interrupted") return { symbol: "■", color: context.theme.text.feedback.warning.base }
      return { symbol: "?", color: context.theme.text.muted }
    }
    function agentEmoji(agent?: string) {
      return agentEmojis[agent?.toLowerCase() ?? ""] ?? agentEmojis.default ?? ""
    }
    function Monitor(props: { panel: any }) {
      let disposed = false
      onCleanup(() => { disposed = true })
      async function openConversation(sessionID: string) {
        const snapshot = visibleTree()
        if (!snapshot) return
        try {
          // Fail visibly if a discoverable conversation has since disappeared.
          await context.client.session.get({ sessionID })
          if (disposed) return
          navigationScope = { sessionID, rootID: snapshot.root.id }
          context.ui.router.navigate({ type: "session", sessionID })
          context.ui.panel.open(panelName)
        } catch (cause) {
          console.warn("[subagent-monitor] navigation failed", cause)
          if (!disposed) context.ui.toast.show({
            message: "Could not open that conversation. Close and reopen the monitor to refresh.",
            variant: "error",
          })
        }
      }
      async function browse() {
        const snapshot = visibleTree()
        if (!snapshot) return
        const sessionID = await context.ui.dialog.select({
          title: "Open monitored conversation",
          current: props.panel.sessionID,
          options: [
            { title: sessionLabel(snapshot.root), value: snapshot.root.id, description: "Root conversation" },
            ...snapshot.rows.map(({ session, status }) => ({
              title: `${agentEmoji(session.agent)} ${sessionLabel(session)}`,
              value: session.id,
              description: status,
            })),
          ],
        })
        if (sessionID && !disposed) await openConversation(sessionID)
      }
      context.keymap.layer(() => ({
        commands: [
          { bind: "escape", title: "Close subagent monitor", run: () => closeMonitor(props.panel.sessionID) },
          { bind: "return", title: "Open monitored conversation", run: browse },
        ],
      }))
      return (
        <box flexDirection="column" width="100%" height="100%" minWidth={0} minHeight={0} padding={1}>
          <text fg={context.theme.text.base}>Subagents</text>
          <text fg={context.theme.text.muted} onMouseUp={() => closeMonitor(props.panel.sessionID)}>
            esc close · /subagents toggle
          </text>
          <text fg={context.theme.text.muted} onMouseUp={browse}>enter browse · click a conversation to open</text>
          <Show when={error()}><text fg={context.theme.text.feedback.error.base}>{error()}</text></Show>
          <Show when={!visibleTree() && !error()}><text fg={context.theme.text.muted}>Discovering subagents…</text></Show>
          <Show when={visibleTree()}>{(value) => (
            <>
              <box marginTop={1} flexShrink={0} minWidth={0}>
                <text fg={context.theme.text.muted} width="100%" wrapMode="none" truncate
                  onMouseUp={() => openConversation(value().root.id)}>Root: {sessionLabel(value().root)}</text>
              </box>
              <text fg={context.theme.text.muted} wrapMode="none" truncate>
                {value().rows.length} agents · {value().rows.filter((row) => row.status === "Running" && !row.stale).length} running · live
              </text>
              <scrollbox flexGrow={1} minWidth={0} minHeight={0} focused={props.panel.focused}>
                <Show when={value().rows.length === 0}>
                  <text fg={context.theme.text.muted}>No visible subagents</text>
                </Show>
                <For each={value().rows}>{({ session, status, activity, usage, stale }) => (
                  <box flexDirection="column" flexShrink={0} minWidth={0} marginBottom={1}
                    onMouseUp={() => openConversation(session.id)}>
                    <box flexDirection="row" minWidth={0}>
                      <text fg={statusCue(status, stale).color}>● </text>
                      <text fg={context.theme.text.base} flexShrink={1} wrapMode="none" truncate>{session.id === props.panel.sessionID ? "▶ " : ""}{agentEmoji(session.agent)} {sessionLabel(session)}</text>
                    </box>
                    <text fg={statusCue(status, stale).color} width="100%" wrapMode="word">  {statusCue(status, stale).symbol} {status}{stale ? " · Last known data" : ""}</text>
                    <Show when={status === "Running"}>
                      <text fg={context.theme.text.muted} width="100%" wrapMode="word">  {activity}</text>
                    </Show>
                    <For each={usage}>{(line) => <text fg={context.theme.text.muted} width="100%" wrapMode="word">  {line}</text>}</For>
                  </box>
                )}</For>
              </scrollbox>
            </>
          )}</Show>
        </box>
      )
    }

    context.ui.slot({
      append: "session.panel",
      render: (panel: any) => {
        // panel.current() is plugin-scoped in v2.2.7. The shared slot is the
        // supported boundary that also observes another plugin's visible panel.
        let observed: typeof activePanel
        const release = () => {
          if (activePanel !== observed) return
          const route = context.ui.router.current()
          if (observed?.name === panelName && route.type === "session" && route.sessionID === observed.sessionID) {
            suppressed.add(observed.sessionID)
          }
          activePanel = undefined
        }
        createEffect(() => {
          const next = { name: panel.name, sessionID: panel.sessionID }
          if (observed && (observed.name !== next.name || observed.sessionID !== next.sessionID)) release()
          activePanel = observed = next
        })
        onCleanup(release)
        return <Show when={panel.name === panelName}><Monitor panel={panel} /></Show>
      },
    })
    context.keymap.layer(() => ({
      mode: "global",
      commands: [{
        id: "subagent-monitor.toggle",
        title: "Toggle subagent monitor",
        group: "Session",
        palette: true,
        slash: { name: "subagents" },
        run() {
          context.ui.dialog.clear()
          if (context.ui.panel.current()?.name === panelName) {
            closeMonitor(context.ui.panel.current().sessionID)
          } else if (!context.ui.panel.open(panelName)) {
            context.ui.toast.show({ message: "Open a session before opening the subagent monitor.", variant: "info" })
          }
        },
      }],
    }))
  },
})
