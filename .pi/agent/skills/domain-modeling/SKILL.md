---
name: domain-modeling
description: The reusable discipline for building and sharpening the project's domain model, and writing the glossary + ADRs the moment decisions crystallise. Use while actively pinning down codebase terminology, writing or editing a GLOSSARY.md (legacy name CONTEXT.md still discovered), or recording or editing an ADR; inside a grill or outside one.
---

# Domain Modeling

The *active* discipline of building + sharpening the domain model: for when you're *changing* it. (Merely *reading* the glossary for vocabulary is a one-line habit any skill does, not this skill.)

## During the session

Layer these moves onto a grilling pass, or apply them directly when modeling:

- **Challenge glossary conflicts.** When a term conflicts with the glossary, call it out immediately: `Keep glossary definition (recommended)` / `Update glossary` / `Two distinct terms`.
- **Sharpen fuzzy language.** Propose candidate canonical terms for vague or overloaded words: `Customer` / `User` / `Both: needs splitting`.
- **Discuss concrete scenarios.** Invent edge cases that force precision about concept boundaries: `Cancel whole order` / `Cancel line item` / `Not allowed`. Do not wait for the user to supply them.
- **Cross-reference the code.** When the user states how something works, check whether the code agrees. If you find a contradiction, surface it using the existing choices: `Code is right, update plan` / `Plan is right, code is wrong` / `Both partially right`.

## Writing it down

**Inline updates:** term resolved -> write immediately into the context worktree (the dir mirroring that code; [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md)): your WIP for the whole cycle, so new terms and corrections alike go there. Decision passes the ADR test -> offer write ([ADR-FORMAT.md](./ADR-FORMAT.md)) into `docs/adr/` (or `<dir>/adr/`) of the ADR destination: resolve it with `<setup-context skill dir>/resolve-location.sh adrs` run with cwd in the code repo (contract: [artifact-locations.md](../setup-context/artifact-locations.md)), keeping the default branch worktree when unset. The `offload-context` skill commits + pushes ADRs recorded in the context worktree at cycle end; other destinations commit where they live.

**ADR test (all three or skip):** hard to reverse · surprising without context · real trade-off.

**Glossary discipline:** glossary only (no implementation details, specs, or decisions). One sentence per term, opinionated, aliases under `_Avoid_`. Lazy-create `GLOSSARY.md` on first term (existing glossaries under the legacy `CONTEXT.md` name are found and edited in place, never duplicated); lazy-create the ADR dir in the same way at the same resolved `adrs` destination. Growing or retiring terms follows CONTEXT-FORMAT's *Growth & retention*: split when big, delete when obsolete, summarize verbose prose.
