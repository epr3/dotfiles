---
name: grilling
description: The reusable relentless-interview loop. Reach for it whenever a plan, design, or ticket needs stress-testing before building.
---

**Grill** the user: be **relentless**. Work the design tree in **round**s until every branch is resolved or the user calls it. A branch the user settled stays settled — reopen one only when new information contradicts it, and say so when you do.

**Rounds.** Each round asks the whole **frontier** in one assistant message: every decision whose prerequisites are already settled. A question depending on one still open belongs to a later round, which is what keeps a round answerable in a single pass. Number the questions and give each your recommended answer, in this format:

```
❓ **1. Per-user cache or one global cache?**
→ **Per-user.** The data is already scoped that way; a global cache needs invalidation we'd have to build.
```

When the frontier has exactly one truly discrete question, use Pi's `question` tool. When it has multiple questions, ask the whole numbered frontier in the assistant message above — the tool would serialize the round into separate prompts. Use the tool for a single discrete confirmation gate too.

**Legwork.** A fact you can find by exploring the codebase, look up rather than ask — the decisions are the user's, so put each one to them and wait for the answer. Broad digging goes to a read-only `explore` sub-agent (`Agent` tool, `subagent_type: "explore"`).

**The user answers.** A round closes on their reply: the answers are theirs to give, not yours to supply.

**Confirmation gate.** When the frontier empties, state the understanding back — what was decided and what it commits to — and get explicit confirmation before acting on it.
