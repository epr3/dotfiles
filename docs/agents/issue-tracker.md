# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files under `.scratch/` at the board's recorded artifact location (default: the context home - here, the repo itself, since context is in-repo).

## Board layout

- **New layout (write this)**: lowercase basenames - the spec is `.scratch/<feature-slug>/spec.md`, the `wayfinder` map is `.scratch/<effort-slug>/map.md`, and child files live in an `issues/` directory.
- **Legacy layout (read-only discovery)**: `SPEC.md` / `MAP.md` / `tickets/`. Boards already in the legacy form stay readable until migration completes; no indefinite fallback is promised - write only the new layout, and continue a legacy board in its legacy form rather than mixing `issues/` into its dir.
- Everything else below applies to both layouts; read either directory name when locating existing boards.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/` - a feature dir carries a `spec.md` (legacy: `SPEC.md`); a dir carrying a `map.md` (legacy: `MAP.md`) instead is a `wayfinder` effort (its issues are **decision tickets**, not implementation slices).
- The spec lives at `.scratch/<feature-slug>/spec.md` (legacy: `SPEC.md`).
- Issues are one file per issue at `.scratch/<feature-slug>/issues/<NNNN>-<slug>.md` (legacy: `tickets/`), zero-padded build order from `0001`. Never a single combined issue file; each records its parent spec path (e.g. the relative link `../spec.md`) or its parent map path (e.g. `../map.md`) and its `blocked_by` issue numbers.
- Each ticket carries frontmatter: `status: open | resolved`, `type: research | prototype | grilling | task`, `mode: HITL | AFK`, `parent: <spec.md or map.md path> (legacy boards may still record <SPEC or MAP path>)`, `blocked_by: [NNNN, ...]`, and `claimed_by:` (absent means unclaimed). Mode constraints: `research` -> AFK; `prototype` -> HITL; `grilling` -> HITL; `task` -> either.
- Triage state, when triage is on, is a `Status:` line near the top of each issue file (role strings per `triage-labels.md`, beside this file)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading.

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## Wayfinding operations

The `wayfinder` map is `.scratch/<effort-slug>/map.md` (legacy: `MAP.md`); child **decision tickets** are issue files beside it under `issues/` (legacy: `tickets/`), each with an H1 title beginning `wayfinder: ` and frontmatter `type`, `mode`, `claimed_by`, `status`, and `blocked_by`.

- **Frontier**: issues whose `status` is open, whose blockers are all resolved, and whose `claimed_by` is absent. First by number wins.
- **Claim before any work**: the first write after selection sets `claimed_by: pi:$PI_SESSION_ID`. Re-read to confirm. Cooperative and best-effort, no silent steal; explicit takeover or release is a ticket comment; no auto-expiry; the claim is retained on resolve.
- **Out of scope**: close the ticket and add one line under the map's `Out of scope` section, linked from the ticket. Out-of-scope tickets never graduate to the frontier.
- **Closing a decision ticket**: record the decision in the ticket, set `status: resolved`, then update the map's `Decisions so far` with a one-line gist + relative link.

## When a skill says "fetch the relevant issue"

Read the matching `.scratch/*/issues/*.md` (new layout) or `.scratch/*/tickets/*.md` (legacy layout) file (feature dirs plus wayfinder efforts; skip effort dirs only when the caller means feature work, `wayfinder` explicitly queries its own effort dir).
