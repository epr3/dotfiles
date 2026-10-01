---
kind: substitution
upstream: skills/engineering/implement-spec/SKILL.md
local: .pi/agent/skills/implement-spec/SKILL.md
rationale: >
  Setup-entrypoint substitution only: upstream's repo-configuration entrypoint
  `setup-matt-pocock-skills` does not run here, so the single reference points
  at the retained `setup-context` (exception 0004). Everything else is
  byte-exact upstream wording; no workflow, flag, or stopping-condition change.
---

- `/setup-matt-pocock-skills`
- `/setup-context`
