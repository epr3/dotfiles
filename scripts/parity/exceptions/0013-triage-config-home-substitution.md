---
kind: substitution
upstream: skills/engineering/triage/SKILL.md
local: .pi/agent/skills/triage/SKILL.md
rationale: >
  Two narrow substitutions: the triage-label setup reference points at the
  retained `setup-context` (exception 0004); and the out-of-scope knowledge
  base is read/written in the **config home** (branch-independent repo-wide
  conventions, per the context-policy slice and the retained context-store
  mechanism) instead of upstream's repo-root `.out-of-scope/`. Roles,
  transitions, state machine, and workflow are byte-exact upstream.
---

- `/setup-matt-pocock-skills`
- `/setup-context`
- .out-of-scope/
- <config-home>/out-of-scope/
