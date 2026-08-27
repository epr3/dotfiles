# Issue tracker: Local Markdown

Tickets and specs for this repo live as markdown files under `.scratch/` at the context home (the store worktree, or the repo itself if context is in-repo).

## Conventions

- One feature per directory: `.scratch/<feature-slug>/` — a feature dir carries a `SPEC.md`; a dir carrying a `MAP.md` instead is a `wayfinder` effort (its `tickets/` are **decision tickets**, not implementation slices).
- The spec lives at `.scratch/<feature-slug>/SPEC.md`.
- Tickets are one file per ticket at `.scratch/<feature-slug>/tickets/<NNNN>-<slug>.md`, zero-padded build order from `0001`. Never a single combined tickets file; each records its parent spec path or map path and its `blocked_by` ticket numbers.
- Each ticket carries frontmatter: `status: open | resolved`, `type: research | prototype | grilling | task`, `mode: HITL | AFK`, `parent: <SPEC or MAP path>`, `blocked_by: [NNNN, ...]`, and `claimed_by:` (absent means unclaimed). Mode constraints: `research` -> AFK; `prototype` -> HITL; `grilling` -> HITL; `task` -> either.
- Triage state, when triage is on, is a `Status:` line near the top of each issue file (role strings per `triage-labels.md`, beside this file)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading.

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## Wayfinding operations

The `wayfinder` map is `.scratch/<effort-slug>/MAP.md`; child **decision tickets** are ticket files beside it under `tickets/`, each with frontmatter `type`, `mode`, `claimed_by`, `status`, and `blocked_by`.

- **Frontier**: tickets whose `status` is open, whose blockers are all resolved, and whose `claimed_by` is absent. First by number wins.
- **Claim before any work**: the first write after selection sets `claimed_by: pi:$PI_SESSION_ID`. Re-read to confirm. Cooperative and best-effort, no silent steal; explicit takeover or release is a ticket comment; no auto-expiry; the claim is retained on resolve.
- **Out of scope**: close the ticket and add one line under the map's `Out of scope` section, linked from the ticket. Out-of-scope tickets never graduate to the frontier.
- **Closing a decision ticket**: record the decision in the ticket, set `status: resolved`, then update the map's `Decisions so far` with a one-line gist + relative link.

## When a skill says "fetch the relevant issue"

Read the matching `.scratch/*/tickets/*.md` file (feature dirs plus wayfinder efforts; skip effort dirs only when the caller means feature work, `wayfinder` explicitly queries its own effort dir).
