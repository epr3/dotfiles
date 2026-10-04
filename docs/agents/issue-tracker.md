# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files under `.scratch/` at the board's recorded artifact location (default: the context home - here, the repo itself, since context is in-repo).

## Board shapes

Two shapes exist; both are read as found, and neither is migrated into the other:

- **Historical boards** (all current boards): authored by the pre-parity skill suite and preserved as found - one file per issue at `.scratch/<feature-slug>/issues/<NNNN>-<slug>.md`, zero-padded build order from `0001` (never a single combined issue file), with frontmatter `status: open | resolved`, `type: research | prototype | grilling | task`, `mode: HITL | AFK`, `parent: <spec.md or map.md path>`, `blocked_by: [NNNN, ...]`, and optional `claimed_by:` (absent means unclaimed; the first write after selection sets it, re-read to confirm - cooperative and best-effort, no silent steal). A feature dir carries a `spec.md`; a dir carrying a `map.md` instead is a `wayfinder` effort. Each issue records its parent spec path (e.g. the relative link `../spec.md`) or its parent map path (e.g. `../map.md`). Mode constraints: `research` -> AFK; `prototype` -> HITL; `grilling` -> HITL; `task` -> either. Comments and conversation history append under a `## Comments` heading.
- **Boards published by the restored skills**: authoritative for new work. `/to-tickets` writes one file per ticket under `.scratch/<feature-slug>/issues/` following that skill's per-ticket template verbatim: `<NN>-<slug>.md` numbered from `01` in dependency order (blockers first), H1 `# <NN>: <title>`, **What to build**, **Blocked by**, `**Status:** ready-for-agent`, and acceptance-criteria checkboxes.

This tracker has no label mechanism: triage's role vocabulary (see the `triage` skill) has no direct representation on files, so readiness is an open issue whose blockers are all resolved and which is unclaimed. On a real tracker, the triage skills' label strings and mappings apply as the `triage` skill describes.

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## Wayfinding operations

The `wayfinder` skill owns the semantics (map, child tickets, claiming, blocking, frontier); this section records only how they physically live in this local tracker, per that skill's tracker-config contract.

The `wayfinder` map is `.scratch/<effort-slug>/map.md`; child **decision tickets** are issue files beside it under `issues/`, each with an H1 title beginning `wayfinder: ` and frontmatter `type`, `mode`, `claimed_by`, `status`, and `blocked_by` (the local expression of upstream's `wayfinder:<type>` label, assignee claim, and blocking edges; native blocking does not exist on files, so "Blocked by"-style numbers are the body convention).

- **Frontier**: issues whose `status` is open, whose blockers are all resolved, and whose `claimed_by` is absent. First by number wins.
- **Claim before any work**: the first write after selection sets `claimed_by: pi:$PI_SESSION_ID`. Re-read to confirm. Cooperative and best-effort, no silent steal; explicit takeover or release is a ticket comment; no auto-expiry; the claim is retained on resolve.
- **Out of scope**: close the ticket and add one line under the map's `Out of scope` section, linked from the ticket. Out-of-scope tickets never graduate to the frontier.
- **Closing a decision ticket**: record the decision in the ticket, set `status: resolved`, then update the map's `Decisions so far` with a one-line gist + relative link.

## When a skill says "fetch the relevant issue"

Read the matching `.scratch/*/issues/*.md` file (feature dirs plus wayfinder efforts; skip effort dirs only when the caller means feature work, `wayfinder` explicitly queries its own effort dir).
