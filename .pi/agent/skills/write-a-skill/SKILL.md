---
name: write-a-skill
description: Create new agent skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, or build a new skill.
---

# Writing Skills

## Skill types

Two kinds, split on who can invoke them:

- **User-invoked** — reachable only when the user types them (e.g. `/grill-with-docs`); they *orchestrate*.
- **Model-invoked** — invoked by the user *or* reached for automatically when the task fits (e.g. `tdd`, `codebase-design`); they hold the reusable *discipline*.

A user-invoked skill may invoke model-invoked skills, but **never another user-invoked one** — orchestrators compose disciplines, not other orchestrators. One sanctioned exception: a *methodology* skill may run on top of a base flow and change how one of its steps is done (`tdd` layering red-green-refactor onto `implement`'s build-the-slice step) — that's a layer, not an orchestrator calling an orchestrator. Keep shared discipline in a model-invoked skill so several orchestrators can reach it.

## Process

1. **Gather requirements**: what task/domain, what use cases, scripts vs instructions only, reference materials.
2. **Draft** SKILL.md (+ reference files if >100 lines, + scripts if deterministic ops).
3. **Review with user**: covers your cases? anything missing? more/less detail anywhere?

## Structure

```
skill-name/
  SKILL.md           # required
  REFERENCE.md       # if needed
  EXAMPLES.md        # if needed
  scripts/
    helper.js
```

## SKILL.md template

```md
---
name: skill-name
description: Brief capability. Use when [specific triggers].
---

# Skill Name

## Quick start

[Minimal working example]

## Workflows

[Step-by-step with checklists for complex tasks]

## Advanced

See [REFERENCE.md](REFERENCE.md)
```

## Description requirements

The description is **the only thing your agent sees** when deciding which skill to load. Must answer:

1. What capability
2. When/why to trigger (keywords, contexts, file types)

**Format:** max 1024 chars · third person · first sentence = what it does · second sentence = "Use when [triggers]"

**Good:** *"Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when user mentions PDFs, forms, or document extraction."*

**Bad:** *"Helps with documents."*

## Pi-specific frontmatter

Pi honours one extra frontmatter field worth knowing: `disable-model-invocation: true` hides the skill from the system prompt so it only loads when the user explicitly types `/skill:<name>`. Use it for skills you only ever want invoked deliberately (e.g. `zoom-out`, `caveman`), not auto-applied.

## When to add scripts

- Operation is deterministic (validation, formatting)
- Same code would be generated repeatedly
- Errors need explicit handling

Scripts save tokens and improve reliability.

## When to split files

- SKILL.md > 100 lines
- Distinct domains (finance vs sales schemas)
- Advanced features rarely needed

## Review checklist

- [ ] Description includes "Use when..."
- [ ] SKILL.md < 100 lines
- [ ] No time-sensitive info
- [ ] Consistent terminology
- [ ] Concrete examples
- [ ] References one level deep
