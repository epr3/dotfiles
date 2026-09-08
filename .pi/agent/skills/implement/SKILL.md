---
name: implement
description: Pick up a ticket, build the vertical slice it describes, verify it, and set its status to resolved. Use when the user wants a ticket implemented, resolved, or closed. Fourth step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context).
argument-hint: "issue number or path under .scratch/*/tickets/"
---

# Implement

Implement one ticket end-to-end, mark it resolved.

## Process

### 1. Load the ticket

**Tracker configured** (the recorded `## Agent skills` block / `issue-tracker.md` in the config home) -> fetch the issue there per its conventions; a bare `#42` resolves in the tracker. With triage on, `ready-for-agent` is the pick-up signal, and an attached Agent Brief (`triage`'s output, see [AGENT-BRIEF.md](../triage/AGENT-BRIEF.md)) *is* the spec: its acceptance criteria are the definition of done and its out-of-scope line is binding. Claim the issue as the first write after selection: self-assign plus a claim comment carrying the baseline snapshot described below (prefixed with the AI disclaimer on GitHub / GitLab), then re-read to confirm. Everything below is unchanged.

**Default: local files.** Resolve the arg (slug, numbered filename, or full path) by slug match against `.scratch/*/tickets/*.md` **at the context home**, skipping effort dirs (those with a `MAP.md`), since wayfinder tickets are decisions to make, not slices to build. Ambiguous -> list candidates, ask.

Arg names a spec, or is omitted with a single spec in play -> don't pick arbitrarily: take the open ticket with the lowest `<NNNN>` for that `parent` whose blockers are all resolved. That's what the filename number is for; implement a spec's tickets in sequence. That set is the **frontier**: open, blockers resolved, and *unclaimed*; a claimed ticket is off the frontier for every other session. Claim before any work: the first write after selection sets `claimed_by: pi:$PI_SESSION_ID` in the ticket's frontmatter, then re-read to confirm it landed. **Capture the baseline before that first write**: the start commit (`git rev-parse HEAD`, full SHA) and the pre-existing dirty-work snapshot, one `<status> <hash> <path>` line per dirty path: the `git status --porcelain` status, the path's content marker (`git hash-object -- <path>`), and the path. Expand directory collapses so every untracked file has its own line (use `git ls-files --others --exclude-standard` for the recursive list). Record both in the claim (a `## Comments` section for local files); review later uses this record to exclude unrelated pre-existing work and to detect overlapping changes. Cooperative and best-effort: no silent steal; explicit takeover or release is a comment on the ticket; no auto-expiry; the claim is retained on resolve.

`status: resolved` already -> stop and tell the user. No `status` field -> treat as `open`.

Read the full body: what to build, acceptance criteria, blocked-by.

Read the frontmatter with legacy compatibility: `type: HITL | AFK` is the older schema that conflated kind and mode, so read that `type` as `mode` with `type` defaulting to `task`. Unified tickets carry `type` (research | prototype | grilling | task) beside `mode` (HITL | AFK); old tickets keep loading either way.

### 2. Check unblocked

Read each "Blocked by" issue. Any not `status: resolved` -> stop, report the open blocker, and offer to resolve it first.

### 3. Build the slice

Explore as needed: broad digging goes to a read-only `explore` sub-agent (`Agent` tool, `subagent_type: "explore"`). Use the domain glossary (`CONTEXT.md` in the context worktree, see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)); respect ADRs. Build the thin **vertical slice**: every layer, demoable alone. Acceptance criteria = definition of done. Where the ticket names seams, drive the build with the `tdd` skill's red-green-refactor loop at those seams. Code comments stay *caveman*-terse (see the `caveman` skill): non-obvious WHY only, never narrating WHAT.

Track with `todo_write`/`todo_read`: one entry per step, exactly one `in_progress`, mark completed as each criterion is met; `todo_read` re-reads the set, so a long implementation stays legible.

**Delegate outsized steps.** A step too big to hold alongside the rest (and separable, meaning it has its own acceptance criterion and no dependence on the conversation's working state) goes to a sub-agent: one `Agent` call, `subagent_type: "general"`, brief = the ticket, that step's criterion, the relevant files (and the red-green-refactor loop when `tdd` is driving). Prefer delegating **repetitive** steps (the same change across many sites, where you write the brief once and fan out in parallel when the chunks are independent) and **context-heavy** ones, whose reads would fill the main context with material only that step needs. Verify each result against its criterion yourself before marking the todo item `completed`: delegation moves the work, not the responsibility. One level only; sub-agents don't re-delegate, and you stay the integrator.

**HITL** -> surface the decision or review point before committing, as one **round** in the `grilling` skill's question format. **AFK** -> proceed unattended.

### 4. Verify

Run the project's tests/build for the touched area: typecheck and focused tests as you go, the full suite once at the end. Confirm every acceptance box is genuinely checkable. No resolve on red.

### 5. Review

Hand the work to the `code-review` skill as a WIP-scope review of the whole slice: committed changes since the recorded start commit, plus any uncommitted staged, unstaged, and relevant untracked additions (with a clean working tree this is a committed-range review). Pass the recorded baseline so pre-existing user work is excluded, and name the slice's files plus the workflow-record paths (the ticket, its spec, and the claim record) explicitly in the handoff. Never stage or commit to make review possible; offer-not-auto-commit stands. Fix every finding before resolving; no resolve on open findings.

### 6. Set status

Frontmatter `status: open` -> `status: resolved`. Tick the acceptance checkboxes. Rest of the file intact.

Report: what was built, what was verified, the resolved ticket's path, and which follow-up tickets are now unblocked. Offer a commit as a closing line; never perform it.
