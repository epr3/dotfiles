---
name: grill-with-docs
description: Grill a plan against the project's CONTEXT.md and ADRs, sharpening both inline as decisions crystallise. Use when the user wants a plan stress-tested against documented domain language. First step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context).
---

# Grill With Docs

## Process

### 1. Load the documented language

Read `CONTEXT.md` in this branch's context worktree — the dir mirroring the code it describes, or the worktree's root `CONTEXT-MAP.md` -> the relevant context (store model, path formula, and multi-context layout: [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)). Multi-context: infer which applies; ask if unclear.

ADRs (personal, in `docs/adr/` + `<dir>/adr/` — see [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md)): grep for topic terms and read the matches only, since enumerating the dir is partial and racy.

### 2. Grill, modeling as you go

Run the **grill** loop (see the `grilling` skill), applying the **domain-modeling** moves to each question (see the `domain-modeling` skill — which also owns the inline-write rule, the ADR test, and glossary discipline). System-wide decisions go to `docs/adr/`; a context's own go to its `<dir>/adr/`.

### 3. Stop at the modeling boundary

The deliverable is *understanding and recorded decisions* — a stress-tested plan plus a sharpened glossary and any ADRs in the context worktree — not code. Once the grill settles and the user confirms it, planning may flow onward as the workflow requires: `to-spec` -> `to-tickets`, with no second request. Implementation and code changes stay a separate boundary — never roll into writing code without an explicit implementation request, as its own distinct action.

Close by reporting: what crystallised, where it was recorded, and the suggested next step.
