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
    function Monitor(props: { panel: any }) {
      const [tree, setTree] = createSignal<LiveTree>()
      const [error, setError] = createSignal("")
      onCleanup(watchTree(context, props.panel.sessionID,
        (value) => { setTree(value); setError("") },
        (cause) => {
          console.warn("[subagent-monitor] discovery failed", cause)
          setError("Tree refresh failed; displayed data may be stale. Retrying automatically.")
        },
        retained,
      ))
      context.keymap.layer(() => ({
        commands: [{ bind: "escape", title: "Close subagent monitor", run: props.panel.close }],
      }))
      return (
        <box flexDirection="column" width="100%" height="100%" minWidth={0} minHeight={0} padding={1} gap={1}>
          <text fg={context.theme.text.base}>Subagents</text>
          <text fg={context.theme.text.muted} onMouseUp={() => props.panel.close()}>
            esc close · /subagents toggle
          </text>
          <Show when={error()}><text fg={context.theme.text.feedback.error.base}>{error()}</text></Show>
          <Show when={!tree() && !error()}><text fg={context.theme.text.muted}>Discovering subagents…</text></Show>
          <Show when={tree()}>{(value) => (
            <>
              <text fg={context.theme.text.muted} width="100%" flexShrink={0} wrapMode="none" truncate>Root: {sessionLabel(value().root)}</text>
              <text fg={context.theme.text.muted}>Live · events + 5-second polling</text>
              <scrollbox flexGrow={1} minWidth={0} minHeight={0} focused={props.panel.focused}>
                <Show when={value().rows.length === 0}>
                  <text fg={context.theme.text.muted}>No discoverable subagents</text>
                </Show>
                <For each={value().rows}>{({ session, depth, status, activity, usage, stale }) => (
                  <box flexDirection="column" flexShrink={0} minWidth={0}
                    // Let the host resize the same mounted tree. Reserve label space even at deep nesting.
                    paddingLeft={Math.min(depth * 2, Math.max(0, props.panel.width - 24))}>
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
