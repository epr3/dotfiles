# Issue tracker: Local Markdown

Tickets and specs for this repo live as markdown files under `.scratch/` at the context home (the store worktree, or the repo itself if context is in-repo).

## Conventions

- One feature per directory: `.scratch/<feature-slug>/` — a feature dir carries a `SPEC.md`; a dir carrying a `MAP.md` instead is a `wayfinder` effort (its `tickets/` are investigation tickets, not implementation slices)
- The spec is `.scratch/<feature-slug>/SPEC.md`
- Implementation tickets are `.scratch/<feature-slug>/tickets/<NNNN>-<slug>.md`, zero-padded build order from `0001`; each records its parent spec path/slug and its `blocked_by` ticket numbers
- Triage state, when triage is on, is a `Status:` line near the top of each issue file (role strings per `triage-labels.md`, beside this file)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## Wayfinding operations

The `wayfinder` map is `.scratch/<effort-slug>/MAP.md`; child tickets are ticket files beside it under `tickets/`, each with a `blocked_by:` list. Frontier: tickets whose `Status:` is open and whose blockers are all resolved. Closing a ticket: record the decision in the ticket, then update the map's "Decisions so far" with a one-line gist + relative link.

## When a skill says "fetch the relevant issue"

Read the matching `.scratch/*/tickets/*.md` file (feature dirs — skip effort dirs, i.e. those with a `MAP.md`).
