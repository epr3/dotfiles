---
name: domain-modeling
description: The reusable discipline for building and sharpening the project's domain model, and writing the glossary + ADRs the moment decisions crystallise. Use while actively pinning down codebase terminology, writing or editing a CONTEXT.md, or recording or editing an ADR — inside a grill or outside one.
---

# Domain Modeling

The *active* discipline of building + sharpening the domain model — for when you're *changing* it. (Merely *reading* `CONTEXT.md` for vocabulary is a one-line habit any skill does, not this skill.)

## During the session

Layer these moves onto a grilling pass, or apply them directly when modeling:

- **Challenge glossary conflicts.** When a term conflicts with the glossary, call it out immediately: `Keep glossary definition (recommended)` / `Update glossary` / `Two distinct terms`.
- **Sharpen fuzzy language.** Propose candidate canonical terms for vague or overloaded words: `Customer` / `User` / `Both — needs splitting`.
- **Discuss concrete scenarios.** Invent edge cases that force precision about concept boundaries: `Cancel whole order` / `Cancel line item` / `Not allowed`. Do not wait for the user to supply them.
- **Cross-reference the code.** When the user's account conflicts with the code, surface the contradiction: `Code is right, update plan` / `Plan is right, code is wrong` / `Both partially right`.

## Writing it down

**Inline updates:** term resolved -> write immediately into the context worktree (the dir mirroring that code; [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md)) — your WIP for the whole cycle, so new terms and corrections alike go there. Decision passes the ADR test -> offer write ([ADR-FORMAT.md](./ADR-FORMAT.md)) into `docs/adr/` (or `<dir>/adr/`) in the worktree. The `offload-context` skill commits + pushes it at cycle end.

**ADR test (all three or skip):** hard to reverse · surprising without context · real trade-off.

**Glossary discipline:** glossary only — no implementation details, specs, or decisions. One sentence per term, opinionated, aliases under `_Avoid_`. Lazy-create `CONTEXT.md` on first term; same for `docs/adr/`. Growing or retiring terms follows CONTEXT-FORMAT's *Growth & retention*: split when big, delete when obsolete, summarize verbose prose.
