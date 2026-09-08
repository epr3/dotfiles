---
name: grilling
description: The reusable relentless-interview loop. Reach for it whenever a plan, decision, or idea needs stress-testing - building or not - or the user asks to be grilled.
---

**Grill** the user: be **relentless**. Map what's being grilled as a **design tree**: every decision branches into the decisions that hang off it. Work the tree in **round**s until every branch is resolved or the user calls it. A branch the user settled stays settled; reopen one only when new information contradicts it, and say so when you do.

**Frontier.** The **frontier** is every decision whose prerequisites are already settled (the questions you can ask _now_, without guessing at answers you haven't heard yet). A question depending on one still open belongs to a _later_ round, not this one, which is what keeps a round answerable in a single pass. Ask the whole frontier in one round: number each question and give your recommended answer, a horizontal rule between questions, in this format:

```
❓ **Q1**: **Per-user cache or one global cache?** The data is already scoped per-user; a global cache would need invalidation we'd have to build.

➡️ **Per-user.** Same shape as the data; nothing new to invalidate.

---

❓ **Q2**: **Evict eagerly or lazily?** Eager eviction needs a background sweep we don't otherwise run.

➡️ **Lazily.** Stale entries are harmless; the sweep is not.
```

Wait for the user's answers before the next round. Each answered round reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and put the newly eligible questions in the next round; a question still waits until its own prerequisites are answered.

When the frontier has exactly one truly discrete question, use Pi's `question` tool. When it has multiple questions, ask the whole numbered frontier in the assistant message above; the tool would serialize the round into separate prompts. Use the tool for a single discrete confirmation gate too. This affordance stays subject to higher-priority harness instructions governing actual tool use.

**Legwork.** A fact you can discover from the environment, filesystem, or tools, look up rather than ask; the decisions are the user's, so put each one to them and wait for the answer. Look a fact up in-process when a quick check settles it; delegate only broad digging, to a sub-agent (`Agent` tool) with the capabilities the fact needs: read-only `explore` for codebase and filesystem reading, `general` when the lookup needs tools an explore worker cannot run. Never offload a fact to the user just because the default worker lacks a tool. A running lookup is an unsettled prerequisite: only the questions downstream of it wait for the worker to report. Dispatch broad digging in the background (`run_in_background: true`), ask the rest of the frontier now, and collect the result (`get_subagent_result`) before asking any dependent question. A foreground dispatch blocks the parent in this turn either way, and same-turn parallelism among workers is not evidence that the parent stayed unblocked.

**The user answers.** A round closes on their reply: the answers are theirs to give, not yours to supply. Your recommendation is your view, never a substitute for their answer.

**Confirmation gate.** When the frontier empties (every branch visited, nothing left silently assumed), state the understanding back: what was decided and what it commits to. Get explicit confirmation. An empty currently-askable frontier is not completion while a lookup still governs an open branch: collect it, settle the dependent questions, then confirm. Confirmation completes the design work: specifications and tickets may then follow as the workflow requires, without another request. Implementation and code changes stay a separate boundary; never start them without an explicit implementation request from the user.
