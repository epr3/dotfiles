---
kind: substitution
upstream: skills/engineering/triage/OUT-OF-SCOPE.md
local: .pi/agent/skills/triage/OUT-OF-SCOPE.md
rationale: >
  Single substitution across the supporting doc: the out-of-scope knowledge
  base lives in the **config home** (branch-independent repo-wide conventions,
  per the retained context-store mechanism) instead of upstream's repo-root
  `.out-of-scope/`. Directory name, file format, and the check/write/update
  flow are byte-exact upstream.
---

- .out-of-scope/
- <config-home>/out-of-scope/
