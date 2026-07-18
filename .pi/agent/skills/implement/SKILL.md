---
name: implement
description: Pick up a local ticket file (`.scratch/<feature>/tickets/`), implement the vertical slice it describes, verify it, and set its status to resolved. Use when the user wants to work, resolve, close, or implement an issue from issues/. Fourth step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context).
argument-hint: "issue number or path under .scratch/*/tickets/"
---

# Resolve Issue

Implement one issue end-to-end, mark resolved.

## Process

### 1. Load issue

If the recorded `## Agent skills` block / `issue-tracker.md` (config home) designates a tracker, fetch the issue there per its conventions (a bare `#42` resolves in the tracker; when triage is on, `ready-for-agent` is the pick-up signal, and an attached Agent Brief — `triage`'s output, see [AGENT-BRIEF.md](../triage/AGENT-BRIEF.md) — is the spec: its acceptance criteria are the definition of done, its out-of-scope line is binding) — everything else below is unchanged. Default: Arg = slug, numbered filename, or full path -> resolve under `.scratch/*/tickets/` **at the context home** by slug match against `.scratch/*/tickets/*.md` — skipping effort dirs (those with a `MAP.md`): wayfinder tickets are decisions to make, not slices to build (named `<NNNN>-<slug>.md`, `<NNNN>` = build position in parent spec). Ambiguous -> list candidates, ask. Read full body: what to build, acceptance criteria, blocked-by.

Arg names spec (or omitted, single spec in play) -> don't pick arbitrarily: open ticket with lowest `<NNNN>` for that `parent`, all blockers resolved. That's what the filename number is for — implement the spec's tickets in sequence.

`status: resolved` already -> stop, tell user, don't redo. No `status` field -> treat as `open`.

### 2. Check unblocked

Read each "Blocked by" issue. Any not `status: resolved` -> stop: report open blocker, don't start. Offer to resolve blocker first.

### 3. Implement slice

Explore as needed: read-only `explore` sub-agent via `Agent` tool if available, else `read`/`grep`/`find`/`ls` — prefer LSP (`lsp_definition`, `lsp_references`) over grep when available. Domain glossary (`CONTEXT.md` in the context worktree — see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)); respect ADRs. Build the thin vertical slice — every layer, demoable alone. Acceptance criteria = definition of done. Code comments caveman-terse: minimal words, explain non-obvious WHY only, never narrate WHAT — an obvious comment is worse than none (cf. `caveman` skill register, applied to code).

`todo_write`/`todo_read` available -> break slice into steps, exactly one `in_progress`, mark `completed` as each criterion met -> long implementation stays legible.

**HITL** -> surface decision/review point before committing — `question` tool if available, else prose (2–4 options, `(recommended)`, one-line reason, stop). **AFK** -> proceed unattended.

### 4. Verify

Run project tests/build for touched area. `lsp_diagnostics` on touched files = fast first check if available. Confirm every acceptance box checkable. No resolve on red.

### 5. Set status

Frontmatter `status: open` -> `status: resolved`. Tick acceptance checkboxes. Rest of file intact.

Report: what built, what verified, resolved issue path, follow-up issues now unblocked.
