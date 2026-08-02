---
name: grilling
description: The reusable relentless-interview loop. Reach for it whenever a plan, design, or ticket needs stress-testing before building.
---

Be **relentless**. Walk the design tree one branch at a time, resolving dependencies between decisions. For each question, give your recommended answer. One question at a time, waiting for the answer before continuing — asking multiple questions at once is bewildering. The loop ends when every branch is resolved or the user calls it — don't reopen a branch the user already settled unless new information contradicts it, and say so when you do.

**Asking:** use the `question` tool if available — options short and mutually exclusive, recommended one marked, no "Other" (the picker adds free-text); your reason in one sentence. Not available -> ask in prose: the question, the options, `(recommended)`, your reason, then stop and wait.

**If a fact can be found by exploring the codebase, look it up rather than asking — but the decisions are the user's: put each one to them and wait for the answer.** Broad digging goes to a read-only `explore` sub-agent (`Agent` tool, `subagent_type: "explore"`).
