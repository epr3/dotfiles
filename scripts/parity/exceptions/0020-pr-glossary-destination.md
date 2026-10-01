---
kind: substitution
upstream: skills/engineering/pr/SKILL.md
local: .pi/agent/skills/pr/SKILL.md
rationale: >
  Single line replacement, context-mechanism only: the sections preamble reads
  the domain glossary at its recorded `glossary` artifact location (via the
  setup skill's resolve-location script) instead of assuming `GLOSSARY.md` sits
  at the code repo root. Template, sections, evidence guidance, and merge-danger
  wording are byte-exact upstream.
---

- Skip all preambles and keep prose brief. Use the user's domain language from `GLOSSARY.md`.
- Skip all preambles and keep prose brief. Use the user's domain language from `GLOSSARY.md`, resolving the `glossary` artifact location with `<setup-context skill dir>/resolve-location.sh glossary` run with cwd in the code repo.
