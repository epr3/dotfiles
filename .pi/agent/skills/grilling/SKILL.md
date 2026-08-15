---
name: grilling
description: The reusable relentless-interview loop. Reach for it whenever a plan, design, or ticket needs stress-testing before building.
---

**Grill** the user: be **relentless**. Work the design tree in **round**s until every branch is resolved or the user calls it. A branch the user settled stays settled — reopen one only when new information contradicts it, and say so when you do.

**Frontier.** The **frontier** is every decision whose prerequisites are already settled — the questions you can ask _now_, without guessing at answers you haven't heard yet. A question depending on one still open belongs to a _later_ round, not this one, which is what keeps a round answerable in a single pass. Ask the whole frontier in one round: number each question and give your recommended answer, in this format:

```
❓ **Q1** — **Per-user cache or one global cache?** The data is already scoped per-user; a global cache would need invalidation we'd have to build.

➡️ **Per-user.** Same shape as the data; nothing new to invalidate.
```

Wait for the user's answers before the next round.

When the frontier has exactly one truly discrete question, use Pi's `question` tool. When it has multiple questions, ask the whole numbered frontier in the assistant message above — the tool would serialize the round into separate prompts. Use the tool for a single discrete confirmation gate too.

**Legwork.** A fact you can find by exploring the codebase, look up rather than ask — the decisions are the user's, so put each one to them and wait for the answer. Broad digging goes to a read-only `explore` sub-agent (`Agent` tool, `subagent_type: "explore"`). A running exploration is an unsettled prerequisite: only the questions downstream of it wait for the sub-agent to report — ask the rest of the frontier now.

**The user answers.** A round closes on their reply: the answers are theirs to give, not yours to supply.

**Confirmation gate.** When the frontier empties, state the understanding back — what was decided and what it commits to — and get explicit confirmation before acting on it.
