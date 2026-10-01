---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design, which also creates docs (ADRs and glossary) as we go. First step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context).
---

# Grill With Docs

This skill is the `grilling` skill and the `domain-modeling` skill run together: the interview sharpens the plan while docs (ADRs, glossary) are created inline as decisions crystallise.

## Process

### 1. Load the documented language

Read `GLOSSARY.md` in this branch's context worktree (the dir mirroring the code it describes), or the worktree's root `GLOSSARY-MAP.md` -> the relevant context (store model, path formula, and multi-context layout: [GLOSSARY-FORMAT.md](../domain-modeling/GLOSSARY-FORMAT.md)). Multi-context: infer which applies; ask if unclear.

ADRs (personal, see [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md)): resolve their destination with `<setup-context skill dir>/resolve-location.sh adrs` run with cwd in the code repo (contract: [artifact-locations.md](../setup-context/artifact-locations.md)), then grep `docs/adr/` + `<dir>/adr/` beneath the resolved destination for topic terms and read the matches only, since enumerating the dir is partial and racy.

### 2. Grill, modeling as you go

Load the `grilling` and `domain-modeling` skills (read their SKILL.md). Run the **grill** loop, applying the **domain-modeling** moves to each question (domain-modeling also owns the inline-write rule, the ADR test, and glossary discipline). System-wide decisions go to the resolved ADR destination's `docs/adr/`; a context's own go to its `<dir>/adr/` beneath the same destination.

### 3. Stop at the modeling boundary

The deliverable is *understanding and recorded decisions* (a stress-tested plan plus a sharpened glossary and any ADRs at the resolved ADR destination), not code. Once the grill settles and the user confirms it, close and stop. Confirmation approves the understanding, not a workflow transition. Starting `to-spec`, `to-tickets`, implementation, or any other next step requires a separate explicit user request.

Close by reporting: what crystallised, where it was recorded, and the suggested next step.
