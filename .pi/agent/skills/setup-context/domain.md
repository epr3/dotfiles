# Domain Docs

**Code repo:** `<origin-url>` (`<slug>`) — filled by `setup-context` on write.

How the engineering skills should consume this code repo's domain documentation. It lives in the **config home** — `.agents/domain.md` at the **context repo** root, or `docs/agents/domain.md` under **in-repo context** (committed with the code) — one copy per **context repo**, used by all its branches, edit-in-place; skills resolve it there when orienting, beside the repo-wide convention docs (see CONTEXT-FORMAT.md).

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
