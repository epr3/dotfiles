---
name: grill-me
description: Interview the user about a plan or design until reaching shared understanding. Use when user wants to stress-test a plan, get grilled, or says "grill me".
---

Run the **grilling** loop — see the `grilling` skill: walk the design tree one branch at a time, recommend an answer to each question, ask one question at a time, and answer from the code instead of asking whenever you can. grill-me is the bare interview — the grilling loop with nothing layered on.

**Stop at understanding.** The deliverable is the shared understanding the interview reaches — not code. When the grilling settles, don't roll into implementing the plan; that eagerness is the failure mode. If the user wants to act on it, that's a separate, explicit step (e.g. hand the settled plan to `to-spec` -> `to-tickets` -> `implement`).
