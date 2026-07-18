---
name: domain-modeling
description: Build and sharpen the project's domain model — challenge terms against the glossary, sharpen fuzzy language, stress-test with edge-case scenarios, surface code contradictions, and write the glossary + ADRs the moment they crystallise. The reusable modeling discipline behind grill-with-docs; reach for it when actively pinning down domain terms or recording a decision outside a grill.
---

# Domain Modeling

The *active* discipline of building + sharpening the domain model: challenge terms, invent edge-case scenarios, write the glossary + decisions the moment they crystallise. (Merely *reading* `CONTEXT.md` for vocabulary is not this skill — that's a one-line habit any skill does. This is for when you're *changing* the model.)

## Four moves

Layer these onto a grilling pass, or apply directly when modeling:

- **Glossary conflict** -> `Keep glossary definition (recommended)` / `Update glossary` / `Two distinct terms`
- **Fuzzy term** -> candidate canonical terms (`Customer` / `User` / `Both — needs splitting`)
- **Scenario edge case** -> concrete branches (`Cancel whole order` / `Cancel line item` / `Not allowed`). Invent scenarios — probe edges forcing precision about concept boundaries; don't wait for the user to supply.
- **Code contradiction** -> `Code is right, update plan` / `Plan is right, code is wrong` / `Both partially right`

## Writing it down

**Inline updates:** term resolved -> write immediately into the context worktree (the dir mirroring that code; [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md)) — your WIP for the whole cycle, so new terms and corrections alike go there. Decision passes the ADR test -> offer write ([ADR-FORMAT.md](./ADR-FORMAT.md)) into `docs/adr/` (or `<dir>/adr/`) in the worktree. The `offload-context` skill commits + pushes it at cycle end.

**ADR test (all three or skip):** hard to reverse · surprising without context · real trade-off.

**Glossary discipline:** glossary only — no implementation details, specs, or decisions. One sentence per term, opinionated, aliases under `_Avoid_`. Lazy-create `CONTEXT.md` on first term; same for `docs/adr/`. Growing or retiring terms follows CONTEXT-FORMAT's *Growth & retention*: split when big, delete when obsolete, summarize verbose prose.
