# Subagent monitor

In a session, run `/subagents` or select **Toggle subagent monitor** from the
command palette. Run it again, press Escape while the panel has focus, or click
the close hint to close. The panel uses the active theme and the host's session
panel layout and scrolling.

This initial slice is a read-only snapshot taken on opening: it resolves the
current session's ancestors and pages each parent's children recursively, even
when they are not in the TUI cache. Finished and archived descendants are not
filtered out. Reopen to refresh. A discovery failure is displayed rather than
being presented as an empty tree. No execution or conversation APIs are called.

## Runtime contract and limits

Checked against the installed OpenCode v2.2.7 binary and read-only API calls to
the running v2.2.6 service. References:
[plugins](https://opencode.ai/docs/build/plugins) and
[TUI plugins](https://opencode.ai/docs/build/plugins/cli).

- `client.session.get({ sessionID })` returns a session; `list` returns
  `{ data, cursor }`. Child queries use `parentID`; archive filtering is omitted
  to include both archived and unarchived records. Cursor pages are followed.
- The installed cache's `root` and `family` depend on records already loaded.
  Ordinary `session.sync` does not discover children; its children option loads
  only direct children. Client reads avoid claiming that cached data is complete.
- The cache's `status` defaults absent records to `idle`; idle is not proof of
  completion. Only the session's reported `outcome` is displayed, otherwise
  **Status unknown**. Activity and usage are explicitly unknown in this slice.
- The host owns sizing and panel focus. Interactive layout, theme appearance,
  and focused scrolling still require a human TUI check; the attempted PTY
  check was interrupted by a service restart before a result was captured.
- New-agent reconciliation, navigation, automatic opening, and suppression
  behavior belong to later tickets. This slice does not implement them.
- Deleted sessions or descendants inaccessible to the connected server cannot
  be recovered. A snapshot is not an atomic view of concurrently changing data.

Verification uses temporary ad hoc checks, not a repository test suite or
verification script (see `docs/adr/2026-10-04-no-maintained-dotfiles-test-suite.md`).
