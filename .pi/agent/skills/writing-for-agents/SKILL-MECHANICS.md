# Skill Mechanics

The skill-specific branch of [writing-for-agents](./SKILL.md) — everything that only applies when the document is a skill under Pi's skill directories (`~/.pi/agent/skills/`, `.pi/skills/`, or `.agents/skills/`). The universal levers live there; these are the mechanics that dress them.

## Frontmatter

```yaml
---
name: <matches the directory name>
description: <see below>
disable-model-invocation: true   # user-invoked only
---
```

`name` must match its directory. The `description` field is the whole invocation axis: its mere presence decides which of the two kinds the skill is.

## The invocation choice

Two kinds, trading the **two loads** against each other:

- A **model-invoked** skill keeps a `description`, so the agent can fire it autonomously *and* other skills can reach it (you can still type its name too — model-invocation *includes* user reach; there is no model-only state). It pays a permanent **context load**: the description sits in the window every turn. Mechanics: omit `disable-model-invocation`, and write a model-facing description with rich trigger phrasing ("Use when the user wants…, mentions…").
- A **user-invoked** skill strips the description from the agent's reach: only the human, typing its name, can invoke it — and no other skill can. Zero context load, but it spends **cognitive load**: the human is the index that must remember it exists. Mechanics: set `disable-model-invocation: true`; the `description` becomes human-facing — a one-line summary, trigger lists stripped.

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. If it only ever fires by hand, make it user-invoked and pay no context load. Most of this suite is model-invoked, because the skills reach each other; the user-invoked ones are those a human always starts deliberately (`setup-context`, `teach`, `triage`, `wayfinder`, `to-questionnaire`, `wait-what`, `zoom-out`). [writing-for-agents](./SKILL.md) is model-invoked so the discipline is reachable when a document is being edited without anyone asking for it.

A model-invoked skill whose content is all **reference** doubles as a home for shared reference: another skill can invoke it, so reference several skills need lives in one place. Two user-invoked skills can't share that way — neither has a description, so neither can fire the other; they share through **external reference** instead.

## Writing the description

A model-invoked description does two jobs — state what the skill is, and list the **branches** that should trigger it. Every word is context load, so it earns harder pruning than the body:

- **Front-load the skill's leading word** — the description is where it does its invocation work.
- **One trigger per branch.** Synonyms renaming a single branch are **duplication** — "build features using TDD … asks for test-first development" is one branch written twice. Keep only genuinely distinct branches.
- **Cut identity that's already in the body.** Keep it to triggers — a description carries the branches that should fire it, while cross-skill reach belongs in the referring skill's body, where it names the dependency.

## Splitting by invocation

**Granularity** — how finely you divide skills — spends one of the two loads with every cut, so split only when the cut earns it. Beside the **sequence** cut in `SKILL.md`, skills have one of their own: split off a model-invoked skill when you have a distinct **leading word** that should trigger it on its own, or another skill must reach it. You pay context load for the new always-loaded description, so that independent reach has to be worth it.

## Composition (this suite's rule)

Orchestrators compose disciplines, not other orchestrators: a flow skill invokes reference/discipline skills, never another flow. The invocation mechanics enforce half of this for free — a user-invoked skill has no description, so nothing can fire it — the rest is design intent. One sanctioned exception: a *methodology* skill may run on top of a base flow and change how one of its steps is done (`tdd` layering red-green-refactor onto `implement`'s build-the-slice step) — a layer, not an orchestrator calling an orchestrator. Keep shared discipline model-invoked, or as external reference, so several flows can reach it.

## Router skills

When user-invoked skills multiply past what the human can remember, that piled-up **cognitive load** is cured by a **router skill**: one user-invoked skill that names the others and when to reach for each. It can only hint, never fire them — user-invoked skills have no description, so nothing but the human reaches them.
