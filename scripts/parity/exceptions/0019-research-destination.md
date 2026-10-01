---
kind: substitution
upstream: skills/engineering/research/SKILL.md
local: .pi/agent/skills/research/SKILL.md
rationale: >
  Single line replacement, context-mechanism only: the final save step reaches
  the recorded `research` artifact location with the setup skill's
  resolve-location script instead of upstream's "where the repo already keeps
  such notes". The description, background-agent framing, primary-source
  requirement, and citation step are byte-exact upstream; no surrounding
  workflow is changed.
---

- 3. Save it where the repo already keeps such notes; match the existing convention, and if there is none, put it somewhere sensible and say where.
- 3. Save it at the recorded `research` artifact location (resolve it with `<setup-context skill dir>/resolve-location.sh research` run with cwd in the code repo); match the existing convention there, and if there is none, put it somewhere sensible and say where.
