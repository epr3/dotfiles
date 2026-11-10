# Subagent monitor

In a session, run `/subagents` or select **Toggle subagent monitor** from the
command palette. Run it again, press Escape while the panel has focus, or click
the close hint to close. The panel uses the active theme and the host's session
panel layout and scrolling.

With the panel focused, press Enter to search/select a conversation with the
host's picker (arrows and Enter; Escape cancels). Click a tree row or the root
label to open it directly. Use the host's **Focus right pane** command to focus
the monitor without a mouse. Navigation opens the existing conversation and
rebinds the monitor to it, retaining the original root scope so siblings and the
root remain reachable. It does not create sessions or change their content or
execution. On a narrow terminal the host keeps the monitor full-screen; close
it with Escape to read the selected conversation, then `/subagents` to reopen.

Monitoring stays live while viewing a session, even with the panel closed. The
first successful discovery establishes a baseline for its root; subsequently
discovered descendants open the monitor automatically only when no panel is
visible. Another panel is never displaced, and blocked openings are not queued.
Closing the monitor (including via the host), or replacing it with another panel,
suppresses automatic reopening for that root tree. `/subagents` can still open it
deliberately. Suppression survives switching between roots and descendants within
this plugin instance, but not plugin reload or TUI exit. Completion never closes
the monitor.

The live watcher resolves the current session's ancestors and pages
each parent's children recursively, even when they are not in the TUI cache.
Session events trigger debounced reads; five-second polling recovers missed
events and reconnections. Reads are serialized, and events during discovery
schedule another pass. The watcher follows the current root scope, preserving
the original root during explicit monitor navigation.
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
- `panel.current()` in v2.2.7 is plugin-scoped: it cannot report another plugin's
  panel. A contribution to the shared `session.panel` slot observes the visible
  panel's reactive name/session and disposal instead. Navigation away is not
  treated as a manual closure. A replacing panel is treated as dismissal.
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

Ticket 04 verification: temporary TUI-boundary checks covered automatic opening,
host and toggle closure, deliberate reopening, competing panels (with the real
plugin-scoped `current` contract), no deferred takeover, completion retention,
root-scoped suppression across descendant navigation, and subscription disposal.
After rebasing onto the navigation/layout changes, the same checks passed again,
including sibling navigation, panel rebinding, and retained root/nested scope.
An installed v2.2.7 PTY run loaded this plugin with temporary synthetic session
data and a separate competing plugin: both panels rendered, the competitor
remained selected on a new child, a later child opened the monitor, host closure
suppressed another child, deliberate reopening worked, and completion left it
open. These were real host panel/slot lifecycle checks, not real-subagent event
verification. Real-subagent automatic opening remains unverified in this slice;
the prior nested spawning attempt hit the runtime depth limit (above). No panel
behavior exercised by this slice was found unsupported. Human visual/focus and
narrow-terminal automatic-opening checks remain outstanding.

Verification uses temporary ad hoc checks, not a repository test suite or
verification script (see `docs/adr/2026-10-04-no-maintained-dotfiles-test-suite.md`).

Navigation was checked at the TUI plugin boundary with temporary ad hoc checks
for descendant/sibling/root routes, root scope across panel remounts, cancelled
selection, inaccessible sessions, and absence of mutation calls. Installed
v2.2.7 PTY checks opened a real existing descendant by both row click and the
keyboard picker, then observed its transcript beside the original root and
sibling tree. Real deeper-than-one-level descendant navigation and narrow-screen
navigation remain unverified; nested scope is covered by the boundary check.
