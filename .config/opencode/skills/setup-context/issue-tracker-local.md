# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files under `.scratch/` at the board's recorded artifact location (default: the context home - the store worktree, or the repo itself if context is in-repo; resolve overrides with `resolve-location.sh board`).

## Board layout

- **New layout (write this)**: lowercase basenames - the spec is `.scratch/<feature-slug>/spec.md`, the `wayfinder` map is `.scratch/<effort-slug>/map.md`, and child files live in an `issues/` directory.
- This is the only supported layout: no other directory names are discovered. A board not in this form must be migrated before it is read.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`. A feature dir carries a `spec.md`; a dir carrying a `map.md` instead is a `wayfinder` effort (its issues are **decision tickets**, not implementation slices).
- The spec lives at `.scratch/<feature-slug>/spec.md`.
- Issues are one file per issue at `.scratch/<feature-slug>/issues/<NNNN>-<slug>.md`, zero-padded build order from `0001`. Never a single combined issue file; each records its parent spec path (e.g. the relative link `../spec.md`) or its parent map path (e.g. `../map.md`) and its `blocked_by` issue numbers.
- Each ticket carries frontmatter: `status: open | resolved`, `type: research | prototype | grilling | task`, `mode: HITL | AFK`, `parent: <spec.md or map.md path>`, `blocked_by: [NNNN, ...]`, and `claimed_by:` (absent means unclaimed). Mode constraints: `research` -> AFK; `prototype` -> HITL; `grilling` -> HITL; `task` -> either.
- Triage state, when triage is on, is a `Status:` line near the top of each issue file (role strings per `triage-labels.md`, beside this file)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading.

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## Wayfinding operations

The `wayfinder` map is `.scratch/<effort-slug>/map.md`; child **decision tickets** are issue files beside it under `issues/`, each with an H1 title beginning `wayfinder: ` and frontmatter `type`, `mode`, `claimed_by`, `status`, and `blocked_by`.

- **Frontier**: issues whose `status` is open, whose blockers are all resolved, and whose `claimed_by` is absent. First by number wins.
- **Claim before any work**: the first write after selection sets `claimed_by` to `opencode:<session-id>` (use a unique `opencode:<timestamp>-<short-random>` token if the session ID is not exposed). Re-read to confirm. Cooperative and best-effort, no silent steal; explicit takeover or release is a ticket comment; no auto-expiry; the claim is retained on resolve.
- **Out of scope**: close the ticket and add one line under the map's `Out of scope` section, linked from the ticket. Out-of-scope tickets never graduate to the frontier.
- **Closing a decision ticket**: record the decision in the ticket, set `status: resolved`, then update the map's `Decisions so far` with a one-line gist + relative link.

## When a skill says "fetch the relevant issue"

Read the matching `.scratch/*/issues/*.md` file (feature dirs plus wayfinder efforts; skip effort dirs only when the caller means feature work, `wayfinder` explicitly queries its own effort dir).
