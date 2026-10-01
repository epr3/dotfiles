---
kind: substitution
upstream: skills/engineering/to-tickets/SKILL.md
local: .pi/agent/skills/to-tickets/SKILL.md
rationale: >
  Two narrow substitutions: the tracker-configuration setup reference points
  at the retained `setup-context` (exception 0004); and the local-files
  publishing bullet reaches the retained board destination by resolving the
  recorded `board` artifact location with the setup skill's
  resolve-location script (the artifact-locations contract), rather than
  assuming the board always sits at the code repo root. The ticket schema,
  numbering, blocking edges, templates, and workflow are byte-exact upstream.
---

- `/setup-matt-pocock-skills`
- `/setup-context`
- **Local files** → write one file per ticket under
- - **Local files** → write one file per ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md` at the board's recorded artifact location (resolve it with `<setup-context skill dir>/resolve-location.sh board` run with cwd in the code repo), numbered from `01` in dependency order (blockers first). Each file's "Blocked by" lists the numbers/titles it depends on. Use the per-ticket file template below: one ticket per file, never a single combined file.
