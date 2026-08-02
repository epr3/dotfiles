---
name: grill-with-docs
description: Grill a plan against the project's CONTEXT.md and ADRs, sharpening both inline as decisions crystallise. Use when the user wants a plan stress-tested against documented domain language. First step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context).
---

# Grill With Docs

## Process

### 1. Load the documented language

Read `CONTEXT.md` in this branch's context worktree — the dir mirroring the code it describes, or the worktree's root `CONTEXT-MAP.md` -> the relevant context (store model, path formula, and multi-context layout: [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)). Multi-context: infer which applies; ask if unclear.

ADRs (personal, in `docs/adr/` + `<dir>/adr/` — see [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md)): don't enumerate the dir — grep for topic terms and read the matches only, since enumeration is partial and racy.

### 2. Grill, modeling as you go

Run the **grilling** loop (see the `grilling` skill), applying the **domain-modeling** moves to each question (see the `domain-modeling` skill — which also owns the inline-write rule, the ADR test, and glossary discipline). System-wide decisions go to `docs/adr/`; a context's own go to its `<dir>/adr/`.

### 3. Stop at the modeling boundary

This skill produces *understanding and recorded decisions* — a stress-tested plan plus a sharpened glossary and any ADRs in the context worktree. It does NOT implement. When the grilling settles, don't roll into writing code; that eagerness is the failure mode here. Hand the result onward as its own deliberate step: `to-spec` -> `to-tickets` -> `implement`. Implement directly only if the user explicitly asks, now, as a separate action.

Close by reporting: what crystallised, where it was recorded, and the suggested next step.
