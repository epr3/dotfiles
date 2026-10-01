---
kind: substitution
upstream: skills/engineering/improve-codebase-architecture/SKILL.md
local: .pi/agent/skills/improve-codebase-architecture/SKILL.md
rationale: >
  Two line replacements, both context-mechanism only: the hardcoded ADR path
  `docs/adr/` becomes the recorded `adrs` destination, and the glossary/ADR
  read line resolves its `glossary` and `adrs` artifact destinations with the
  setup skill's resolve-location script (the step-3 writes land at the same
  destinations) instead of assuming both sit at the code repo root. Upstream
  wording stands byte-exact; no scope, question-format, tool, sub-agent, or
  stopping-behavior change is retained.
---

- - The domain language in `GLOSSARY.md` gives names to good seams; ADRs in `docs/adr/` record decisions this command should not re-litigate.
- - The domain language in `GLOSSARY.md` gives names to good seams; ADRs at the recorded `adrs` destination record decisions this command should not re-litigate.
- Read the project's domain glossary (`GLOSSARY.md`) and any ADRs in the area you're touching first.
- Read the project's domain glossary (`GLOSSARY.md`) and any ADRs in the area you're touching first, resolving the `glossary` and `adrs` artifact destinations with `<setup-context skill dir>/resolve-location.sh <class>` run with cwd in the code repo; the step-3 updates land there too.
