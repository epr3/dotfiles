/** @jsxImportSource @opentui/solid */
// Dumb Zone footer — an OpenCode v2 CLI plugin that shows where the session
// sits on the context-degradation cliff, in the prompt footer's status row.
//
// The visible contract (docs/adr/2026-08-20-dumb-zone-contract-200k.md) lives
// in zone.ts (pure: classification, meter, labels) and segments.ts (pure: the
// footer runs and the host-shape readers); this file only reads OpenCode state
// and themes the parts.
//
//   dotfiles │ ⎇ main │ ◑ RISKY ██████░░░░ 65% eff · 130k/200k · 33% nom
//
// Host-boundary notes (verified against the installed v2.0.22 release):
// - Slot contributions are removed through normal slot cleanup when the
//   plugin deactivates; this setup still returns a cleanup that stops every
//   subscription this file owns.
// - A session record's token totals are cumulative across turns; the current
//   context occupancy is the newest assistant message's own token record
//   (input + output + reasoning + both cache sides — the same sum OpenCode's
//   own display uses).
// - The nominal window is the active model's advertised `limit.context` from
//   the location's model catalog; a model without one, or a session without
//   usage, leaves the line at the awaiting-context placeholder rather than a
//   fabricated zero.
// - Zone classification is display-only: nothing here triggers compaction or
//   rewrites responses.
import { Plugin } from "@opencode/plugin/tui"
import { For, Show, createMemo, createSignal } from "solid-js"
import { configFromEnv, configFromOptions } from "./zone.ts"
import {
  catalogWindow,
  footerRuns,
  newestAssistantUsage,
  type ModelRef,
  type Run,
} from "./segments.ts"

export default Plugin.define({
  id: "dumb-zone",
  setup(context: any) {
    const directory =
      context.location?.directory ?? context.data.location.default()?.directory ?? process.cwd()
    const config = configFromEnv(process.env, configFromOptions(context.options))

    const [version, setVersion] = createSignal(0, { equals: false })
    const bump = () => setVersion((value) => value + 1)

    /**
     * A 1s heartbeat covers the idle case: a resumed or route-opened session
     * must repaint without waiting for a subscribed event, or the row stays
     * blank until the next turn.
     */
    const heartbeat = setInterval(bump, 1_000)

    /** The host location this CLI serves; the session record may refine it. */
    const location = () => context.location ?? context.data.location.default()

    /** The branch may change during a turn; refresh the host's VCS cache on turn edges. */
    const refreshVcs = () => {
      const loc = location()
      if (!loc) return
      try {
        void Promise.resolve(context.data.location.vcs.sync(loc)).catch(() => {})
      } catch {
        /* no VCS surface at this location: the branch segment stays absent */
      }
    }

    const branchOf = (loc: any): string => {
      try {
        const vcs = context.data.location.vcs.info(loc)
        return String(vcs?.branch?.current ?? "").trim()
      } catch {
        return ""
      }
    }

    /** The active model: the prompt's selection, else the last request's model. */
    const modelRef = (sessionID: string): ModelRef | undefined => {
      try {
        const selection = context.ui.model.current()
        if (selection) return selection
      } catch {
        /* no reactive selection at this host: fall through to the message */
      }
      const usage = newestAssistantUsage(context.data.session.message.list(sessionID))
      return usage?.model
    }

    /** The footer runs for one paint; an empty list leaves the row unclaimed. */
    const buildRuns = (sessionID?: string): Run[] => {
      if (!sessionID) return []
      const found = newestAssistantUsage(context.data.session.message.list(sessionID))
      const usage =
        found && found.usedTokens > 0
          ? (() => {
              const windowTokens = catalogWindow(
                context.data.location.model.list(location()) ?? [],
                modelRef(sessionID),
              )
              return windowTokens !== undefined
                ? { usedTokens: found.usedTokens, windowTokens }
                : undefined
            })()
          : undefined
      return footerRuns(
        { directory, branch: branchOf(location()) },
        usage,
        config,
      )
    }

    /** One run's color: the resolved theme token for its role. */
    const tokenFor = (run: Run): string | undefined => {
      try {
        const theme = context.theme
        if (run.tone === "muted") return theme?.text?.muted
        if (run.tone === "success") return theme?.text?.feedback?.success?.base
        if (run.tone === "warning") return theme?.text?.feedback?.warning?.base
        if (run.tone === "error") return theme?.text?.feedback?.error?.base
      } catch {
        /* a theme without these tokens draws the default foreground */
      }
      return undefined
    }

    const currentSession = (): string | undefined => {
      const route = context.ui.router.current()
      return route.type === "session" ? route.sessionID : undefined
    }

    const lines = createMemo<Run[]>(() => {
      version()
      try {
        return buildRuns(currentSession())
      } catch (error) {
        console.warn("[dumb-zone] could not build the footer; drawing nothing this paint", error)
        return []
      }
    })

    context.ui.slot({
      append: "prompt.footer.status",
      render: () => (
        <Show when={lines().length > 0}>
          <text wrapMode="none">
            <For each={lines()}>
              {(run: Run) => <span style={{ fg: tokenFor(run) }}>{run.text}</span>}
            </For>
          </text>
        </Show>
      ),
    })

    const stops = [
      context.data.on("session.step.ended", bump),
      context.data.on("session.execution.started", bump),
      context.data.on("session.execution.succeeded", () => {
        refreshVcs()
        bump()
      }),
      context.data.on("session.execution.failed", () => {
        refreshVcs()
        bump()
      }),
      context.data.on("session.execution.interrupted", () => {
        refreshVcs()
        bump()
      }),
      context.data.on("session.idle", bump),
      context.data.on("session.model.selected", bump),
      context.data.on("session.compaction.ended", bump),
    ]

    return () => {
      clearInterval(heartbeat)
      for (const stop of stops) stop()
    }
  },
})
