---
name: grill-with-docs
description: Grill a plan against the project's CONTEXT.md and ADRs, updating both inline as decisions crystallise. Use when user wants to stress-test a plan against documented domain language. First step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context).
---

<what-to-do>

Read `CONTEXT.md` in this branch's context worktree — the dir mirroring the code it describes (or the worktree's root `CONTEXT-MAP.md` -> relevant context; see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) for the store model + path). ADRs (personal, in `docs/adr/` + `<dir>/adr/` — see [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md)): don't enumerate the dir — grep for topic terms, read matches only (enumeration is partial + racy). Then run the **grilling** loop (see the `grilling` skill — walk the tree one branch at a time, recommend each answer, one question at a time, and answer from the code instead of asking when you can), applying the **domain-modeling** moves to each question (see the `domain-modeling` skill — challenge glossary conflicts, sharpen fuzzy terms, stress-test edge-case scenarios, surface code contradictions — writing the glossary + ADRs inline as decisions crystallise).

**Stop at the modeling boundary.** This skill produces *understanding and recorded decisions* — a stress-tested plan plus a sharpened `CONTEXT.md` glossary and any ADRs in the context worktree. It does NOT implement. When the grilling settles, don't roll into writing code — that eagerness is the failure mode here. Hand the result to the pipeline as its own deliberate step: `to-spec` -> `to-tickets` -> `implement`. Implement directly only if the user explicitly asks, now, as a separate action. Close by reporting: what crystallised, where it was recorded (`CONTEXT.md`, ADRs), and the suggested next step.

</what-to-do>

<supporting-info>

**Modeling discipline:** the four moves, the inline-write rule (resolved term -> straight into the context worktree, the dir mirroring that code; `offload-context` commits + pushes at cycle end — skip it when context is in-repo), the ADR test, and glossary discipline all live in the `domain-modeling` skill.

**Multi-context:** `CONTEXT-MAP.md` at the worktree root -> per-context `CONTEXT.md` files (links relative to the map, mirroring the code's paths — see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)). Infer which applies; ask if unclear. ADRs: `docs/adr/` = system-wide; each context may carry own `<dir>/adr/` — write ADR where decision lives.

</supporting-info>
