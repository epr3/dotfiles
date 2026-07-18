---
name: grilling
description: The reusable relentless-interview loop — walk the decision tree one branch at a time resolving dependencies, recommend an answer to each question, ask one at a time. Invoked by grill-me and grill-with-docs; reach for it whenever a plan or design needs stress-testing before building.
---

Walk the design tree one branch at a time, resolving dependencies between decisions. For each question, give your recommended answer. One question at a time, waiting for the answer before continuing — asking multiple questions at once is bewildering. The loop ends when every branch is resolved or the user calls it — don't reopen a branch the user already settled unless new information contradicts it, and say so when you do.

**Asking:** use the `question` tool if available — 2–4 short mutually-exclusive options, recommended one marked, no "Other" (the picker adds free-text). If it's not available, ask in prose: the question, 2–4 options with `(recommended)`, your reason in one sentence, then stop and wait.

**If a fact can be found by exploring the codebase, look it up rather than asking — but the decisions are the user's: put each one to them and wait for the answer.** Prefer LSP tools (`lsp_definition`, `lsp_references`, `lsp_document_symbols`) for precise navigation when available; else `read`/`grep`/`find`/`ls`, or a read-only `explore` sub-agent via the `Agent` tool if that extension is installed.
