# Subagent monitor

In a session, run `/subagents` or select **Toggle subagent monitor** from the
command palette. Run it again, press Escape while the panel has focus, or click
the close hint to close. The panel uses the active theme and the host's session
panel layout and scrolling.

The open panel is live: it resolves the current session's ancestors and pages
each parent's children recursively, even when they are not in the TUI cache.
Session events trigger debounced reads; five-second polling recovers missed
events and reconnections. Reads are serialized, and events during discovery
schedule another pass. The resolved root stays fixed while the panel is mounted.
Finished and archived descendants are not filtered out. Previously discovered
rows are retained across refreshes and closing/reopening for this plugin's
lifetime; no-longer-discoverable rows are marked as last known data. Reloading
the plugin loses that in-memory history but rediscovers accessible descendants.
A discovery failure keeps the last view with a stale-data warning and retries
automatically. No execution or conversation mutation APIs are called.

## Runtime contract and limits

Checked against the installed OpenCode v2.2.7 binary and read-only API calls to
the running v2.2.7 service, including its `/openapi.json`. References:
[plugins](https://opencode.ai/docs/build/plugins) and
[TUI plugins](https://opencode.ai/docs/build/plugins/cli).

- `client.session.get({ sessionID })` returns a session; `list` returns
  `{ data, cursor }`. Child queries use `parentID`; archive filtering is omitted
  to include both archived and unarchived records. Cursor pages are followed.
- The installed cache's `root` and `family` depend on records already loaded.
  Ordinary `session.sync` does not discover children; its children option loads
  only direct children. Client reads avoid claiming that cached data is complete.
- The cache's `status` defaults absent records to `idle`; idle is not proof of
  completion. `client.session.active()` reports foreground executions owned by
  the connected server. Its explicit `running` takes precedence over a reported
  `outcome`; otherwise that outcome or **Status unknown** is displayed. This
  cannot identify executions owned by another server process.
- Session `tokens` are reported cumulative provider categories, displayed
  separately (input, output, reasoning, cache read/write). Reasoning may overlap
  output, so these are not summed. Missing/invalid categories are **Tokens
  unknown**, never default zeros. Usage can lag streaming until recorded.
- For explicitly running sessions, `client.message.list` reads the latest
  assistant message (`type: "assistant", order: "desc", limit: 1`). An incomplete
  message's running/streaming tool name, reasoning, or response content kind
  supplies activity. Completed messages and failed reads yield **Activity
  unknown**. Prompts, tool arguments, and outputs are not displayed.
- `context.data.listen` supplies `{ details }`. `session.*` events (including
  creation, execution, message content, and usage changes) invalidate discovery;
  `server.connected` also refreshes. Event payloads never directly admit a row,
  so unrelated sessions cannot enter the tree. Reads are not an atomic snapshot.
- The host owns sizing and panel focus. In the installed v2.2.7 host, fewer
  than 108 available columns forces full-screen presentation; wider layouts
  show the monitor beside the conversation. Available width excludes vertical
  tabs when present. The plugin does not impose a competing breakpoint or
  remount its contents on resize. Indentation is capped to leave label space;
  long labels and the root title truncate rather than widening the panel.
- A v2.2.7 PTY check opened the monitor for an existing session with real
  subagents, resized 160 → 80 → 160 columns, and closed with Escape. The heading
  moved from column 82 to column 2 and back, with the root and agent rows still
  visible. Temporary TUI-slot checks also retained 24 nested rows and focused
  scrolling across widths 60 → 35 → 18 → 60 without remounting or refetching.
  A human terminal/theme check and deep nesting in the real TUI remain unverified.
- Navigation, automatic opening, and suppression behavior belong to later
  tickets. This slice does not implement them.
- Deleted sessions or descendants inaccessible to the connected server cannot
  be recovered if they were never discovered.

Ticket 02 verification: temporary adapter checks covered nested additions,
unrelated-session exclusion, retention, unknowns, changing status/activity/tokens,
events during discovery, polling recovery, failure retention, and disposal.
Read-only real-session polling confirmed running/completed agents, tool/reasoning
activity changes, and increasing token categories. A real new nested-agent check
could not complete: spawning was rejected by the runtime's subagent depth limit;
the probe consequently failed its new-child assertion. New-child event delivery
and interactive rendered updates remain unverified. No runtime events or fields
used here were found unsupported; unavailable values remain explicitly unknown.

Verification uses temporary ad hoc checks, not a repository test suite or
verification script (see `docs/adr/2026-10-04-no-maintained-dotfiles-test-suite.md`).
