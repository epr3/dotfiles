---
kind: substitution
upstream: skills/engineering/code-review/SKILL.md
local: .pi/agent/skills/code-review/SKILL.md
rationale: >
  Two narrow substitutions only: the tracker-configuration setup reference
  points at the retained `setup-context` (exception 0004) instead of upstream's
  `setup-matt-pocock-skills`; and the hardcoded repo-root tracker path resolves
  to the **config home** (`.agents/` at the context repo root, or `docs/agents/`
  in-repo) so the skill reaches the retained config destination. Review scope,
  spec-source ordering, smell baseline, delegation wording, aggregation, and
  the two-axis rationale are byte-exact upstream; no WIP/baseline-exclusion or
  sub-agent-tool policy is retained.
---

- The issue tracker should have been provided to you. If `docs/agents/issue-tracker.md` is missing, tell the user to run `/setup-matt-pocock-skills`.
- The issue tracker should have been provided to you. If the config home's `issue-tracker.md` is missing, tell the user to run `/setup-context`.
- 1. Issue references in the commit messages (`#123`, `Closes #45`, GitLab `!67`, etc.), fetched via the workflow in `docs/agents/issue-tracker.md`.
- 1. Issue references in the commit messages (`#123`, `Closes #45`, GitLab `!67`, etc.), fetched via the workflow in the config home's `issue-tracker.md`.
