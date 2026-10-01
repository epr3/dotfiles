---
kind: substitution
upstream: skills/engineering/diagnosing-bugs/SKILL.md
local: .pi/agent/skills/diagnosing-bugs/SKILL.md
rationale: >
  Single line replacement, context-mechanism only: when exploring the codebase
  the skill resolves the recorded `glossary` and `adrs` artifact locations with
  the setup skill's resolve-location script instead of assuming both sit at the
  code repo root. All six diagnosis phases, the redaction rule, the HITL
  template reference, and completion criteria are byte-exact upstream.
---

- When exploring the codebase, read `GLOSSARY.md` (if it exists) to get a clear mental model of the relevant modules, and check ADRs in the area you're touching.
- When exploring the codebase, read `GLOSSARY.md` (if it exists) to get a clear mental model of the relevant modules, and check ADRs in the area you're touching, resolving the `glossary` and `adrs` artifact locations with `<setup-context skill dir>/resolve-location.sh <class>` run with cwd in the code repo.
