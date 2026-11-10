/** @jsxImportSource @opentui/solid */
import { Plugin } from "@opencode/plugin/tui"
import { For, Show, createSignal, onCleanup } from "solid-js"
import { sessionLabel } from "./tree.ts"
import { watchTree, type LiveTree } from "./live.ts"

const panelName = "subagent-monitor.tree"

export default Plugin.define({
  id: "subagent-monitor",
  setup(context: any) {
    const retained = new Map<string, LiveTree>()
    // The host binds each panel to one conversation. Carry the original root
    // across the remount when we rebind the panel after navigating.
    let navigationScope: { sessionID: string; rootID: string } | undefined
    function Monitor(props: { panel: any }) {
      const [tree, setTree] = createSignal<LiveTree>()
      const [error, setError] = createSignal("")
      let disposed = false
      onCleanup(() => { disposed = true })
      const scopeID = navigationScope?.sessionID === props.panel.sessionID
        ? navigationScope.rootID
        : props.panel.sessionID
      onCleanup(watchTree(context, scopeID,
        (value) => { setTree(value); setError("") },
        (cause) => {
          console.warn("[subagent-monitor] discovery failed", cause)
          setError("Tree refresh failed; displayed data may be stale. Retrying automatically.")
        },
        retained,
      ))
      async function openConversation(sessionID: string) {
        const snapshot = tree()
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
        const snapshot = tree()
        if (!snapshot) return
        const sessionID = await context.ui.dialog.select({
          title: "Open monitored conversation",
          current: props.panel.sessionID,
          options: [
            { title: sessionLabel(snapshot.root), value: snapshot.root.id, description: "Root conversation" },
            ...snapshot.rows.map(({ session, depth }) => ({
              title: `${"  ".repeat(depth)}└ ${sessionLabel(session)}`,
              value: session.id,
              description: session.outcome ?? "Status unknown",
            })),
          ],
        })
        if (sessionID && !disposed) await openConversation(sessionID)
      }
      context.keymap.layer(() => ({
        commands: [
          { bind: "escape", title: "Close subagent monitor", run: props.panel.close },
          { bind: "return", title: "Open monitored conversation", run: browse },
        ],
      }))
      return (
        <box flexDirection="column" width="100%" height="100%" minWidth={0} minHeight={0} padding={1} gap={1}>
          <text fg={context.theme.text.base}>Subagents</text>
          <text fg={context.theme.text.muted} onMouseUp={() => props.panel.close()}>
            esc close · /subagents toggle
          </text>
          <text fg={context.theme.text.muted} onMouseUp={browse}>enter browse · click a conversation to open</text>
          <Show when={error()}><text fg={context.theme.text.feedback.error.base}>{error()}</text></Show>
          <Show when={!tree() && !error()}><text fg={context.theme.text.muted}>Discovering subagents…</text></Show>
          <Show when={tree()}>{(value) => (
            <>
              <text fg={context.theme.text.muted} width="100%" flexShrink={0} wrapMode="none" truncate
                onMouseUp={() => openConversation(value().root.id)}>Root: {sessionLabel(value().root)}</text>
              <text fg={context.theme.text.muted}>Live · events + 5-second polling</text>
              <scrollbox flexGrow={1} minWidth={0} minHeight={0} focused={props.panel.focused}>
                <Show when={value().rows.length === 0}>
                  <text fg={context.theme.text.muted}>No discoverable subagents</text>
                </Show>
                <For each={value().rows}>{({ session, depth, status, activity, usage, stale }) => (
                  <box flexDirection="column" flexShrink={0} minWidth={0}
                    // Let the host resize the same mounted tree. Reserve label space even at deep nesting.
                    paddingLeft={Math.min(depth * 2, Math.max(0, props.panel.width - 24))}
                    onMouseUp={() => openConversation(session.id)}>
                    <text fg={context.theme.text.base} wrapMode="none" truncate>└ {sessionLabel(session)}</text>
                    <text fg={context.theme.text.muted} wrapMode="none" truncate>  {status} · {activity}{stale ? " · No longer discoverable; last known data" : ""}</text>
                    <text fg={context.theme.text.muted} wrapMode="none" truncate>  {usage}</text>
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
      render: (panel: any) => (
        <Show when={panel.name === panelName}><Monitor panel={panel} /></Show>
      ),
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
            context.ui.panel.close()
          } else if (!context.ui.panel.open(panelName)) {
            context.ui.toast.show({ message: "Open a session before opening the subagent monitor.", variant: "info" })
          }
        },
      }],
    }))
  },
})
