# Domain Docs

**Code repo:** `<origin-url>` (`<slug>`) — filled by `setup-context` on write.

How the engineering skills should consume this code repo's domain documentation. This doc lives as `domain.md` — globally at `.agents/domain.md` — written once per context repo, used by all of its branches, edit-in-place, or at `docs/agents/domain.md` when context is in-repo (committed with the code). Either way it lives in the config home; skills resolve it there when orienting. Repo-wide choices live separately at the config home (`.agents/` at the store root — see CONTEXT-FORMAT.md).

## Before exploring, read

Context is personal, living **in the context worktree** by default — you edit it there directly; `offload-context` commits + pushes it to the team remote (in-repo context: skip offload, it commits with the code). See `CONTEXT-FORMAT.md` (ships with the `domain-modeling` skill):

- `CONTEXT.md` at the worktree root, **or**
- `CONTEXT-MAP.md` at the worktree root if it exists — points at per-context `CONTEXT.md` files (mirroring the code's dirs). Read each one relevant to the topic.

If neither exists, **proceed silently**. Don't flag the absence; don't suggest creating files upfront. `grill-with-docs` creates them lazily when terms or decisions actually resolve.

## File structure

**Single-context** (most repos):

```
CONTEXT.md
```

**Multi-context** (`CONTEXT-MAP.md` at the worktree root):

```
CONTEXT-MAP.md
src/ordering/CONTEXT.md
src/billing/CONTEXT.md
```

## Use the glossary's vocabulary

When naming a domain concept (issue title, refactor proposal, hypothesis, test name), use the term as defined in the project's `CONTEXT.md` (in the context worktree). Don't drift to synonyms the glossary explicitly avoids.

If the concept isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider), or there's a real gap (note it for `grill-with-docs`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR `2026-01-12-event-sourced-orders` — but worth reopening because…_
