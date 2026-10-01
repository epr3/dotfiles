---
kind: substitution
upstream: skills/engineering/domain-modeling/SKILL.md
local: .pi/agent/skills/domain-modeling/SKILL.md
rationale: >
  Two narrow line additions, downstream-reusable: where glossary/ADR writes
  land under the retained context store (context worktree vs code repo root,
  resolved by GLOSSARY-FORMAT's *Resolving the context store*), and how the
  ADR destination resolves per class with the local setup skill's
  resolve-location script. Everything else in the file is byte-exact
  upstream wording; no workflow, flag, or stopping-condition change.
---

- Resolve where these live before writing: under the retained context store the glossary + ADR home is the **context worktree** for the current code branch, or the code repo root under **in-repo context**; resolve it with the procedure in [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md) → *Resolving the context store*.
- The ADR destination resolves per class with `<setup-context skill dir>/resolve-location.sh adrs`, run with cwd in the code repo.
