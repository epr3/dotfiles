---
kind: inventory
upstream: absent
local: .pi/agent/skills/{setup-context,merge-context,offload-context,rebase-context,explain-diff}/
rationale: >
  These five skills implement or document the retained context mechanism ("
  lifecycle: setup, merge, rebase, offload) or the separately retained diff
  explainer. They have no upstream counterpart; retention is explicit here so
  they are counted against the inventory diff and remain subject to the
  prose-voice alignment captured elsewhere on this board (issues 0006 and
  0007). Retention is not permission to fork any upstream-derived skill.
---

Recorded local-only skill retention: no upstream counterpart exists, so
content comparison does not apply; invocation metadata, frontmatter validity,
cross-references, and the prose-voice review govern them. No other local-only
skill may be registered beyond this exact list.
