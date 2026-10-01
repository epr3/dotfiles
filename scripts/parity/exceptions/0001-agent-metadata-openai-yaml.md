---
kind: metadata
upstream: skills/*/*/agents/
local: .pi/agent/skills/*/agents/
rationale: >
  Upstream keeps per-skill `agents/openai.yaml` harness-specific metadata for
  OpenAI packaging. Prior review during the pinned sync (issue 0010 of the
  upstream-pi-skills-sync board) recorded these files as explicitly removed
  from the curated suite: they configure a different runtime harness and no
  pi equivalent exists. Recorded as an explicit decision so agent metadata
  still participates in comparison and the absence is reviewable, not silent.
  If a future restoration decides otherwise, replace this entry, never a
  blanket exemption.
---

Recorded removal: `agents/openai.yaml` under every upstream-derived skill is
not retained in the curated suite. Main SKILL.md frontmatter and invocation
metadata still participate in parity comparison; only the OpenAI-specific
packaging directory is excluded.
