/** @jsxImportSource @opentui/solid */
import { Plugin } from "@opencode/plugin/tui"
import { For, Show, createSignal, onCleanup } from "solid-js"
import { discoverTree, sessionLabel, type Tree } from "./tree.ts"

const panelName = "subagent-monitor.tree"

export default Plugin.define({
  id: "subagent-monitor",
  setup(context: any) {
    function Monitor(props: { panel: any }) {
      const [tree, setTree] = createSignal<Tree>()
      const [error, setError] = createSignal("")
      let disposed = false
      onCleanup(() => { disposed = true })
      // Keep this snapshot mounted until explicitly closed. No execution or message mutations.
      void discoverTree(context.client.session, props.panel.sessionID).then(
        (value) => { if (!disposed) setTree(value) },
        (cause) => {
          console.warn("[subagent-monitor] discovery failed", cause)
          if (!disposed) setError("Could not discover the session tree. Close and reopen to retry.")
        },
      )
      context.keymap.layer(() => ({
        commands: [{ bind: "escape", title: "Close subagent monitor", run: props.panel.close }],
      }))
      return (
        <box flexDirection="column" height="100%" padding={1} gap={1}>
          <text fg={context.theme.text.base}>Subagents</text>
          <text fg={context.theme.text.muted} onMouseUp={() => props.panel.close()}>
            esc close · /subagents toggle
          </text>
          <Show when={error()}><text fg={context.theme.text.feedback.error.base}>{error()}</text></Show>
          <Show when={!tree() && !error()}><text fg={context.theme.text.muted}>Discovering subagents…</text></Show>
          <Show when={tree()}>{(value) => (
            <>
              <text fg={context.theme.text.muted}>Root: {sessionLabel(value().root)}</text>
              <text fg={context.theme.text.muted}>Snapshot · activity and usage unknown</text>
              <scrollbox flexGrow={1} minHeight={0} focused={props.panel.focused}>
                <Show when={value().rows.length === 0}>
                  <text fg={context.theme.text.muted}>No discoverable subagents</text>
                </Show>
                <For each={value().rows}>{({ session, depth }) => (
                  <box flexShrink={0} paddingLeft={depth * 2}>
                    <text fg={context.theme.text.base}>└ {sessionLabel(session)}</text>
                    <text fg={context.theme.text.muted}>  {session.outcome ?? "Status unknown"}</text>
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
