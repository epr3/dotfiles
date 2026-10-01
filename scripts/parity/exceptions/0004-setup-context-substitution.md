---
kind: inventory
upstream: skills/engineering/setup-matt-pocock-skills/
local: .pi/agent/skills/setup-context/
rationale: >
  The context-repo mechanism replaces upstream's repo configuration
  entrypoint for the curated suite: setup-context substitutes every upstream
  reference to setup-matt-pocock-skills and serves the retained Agent context
  store (context home, config home, context worktrees, artifact locations,
  merge/rebase/offload lifecycle). Do not install both competing setup
  workflows. This records the entrypoint substitution only: individual file
  edits inside upstream-derived skills that change a setup reference use
  their own narrow substitution entries with the exact change and location.
---

Recorded substitution: upstream setup-matt-pocock-skills is replaced by the
local-only setup-context. References inside upstream-derived skills must be
documented with per-file substitution entries, never by this entry.
