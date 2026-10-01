---
kind: packaging
upstream: skills/*/README.md
local: .pi/agent/skills/
rationale: >
  Upstream packages skills nested under category families (engineering,
  productivity, plus in-progress/misc/deprecated) with a per-family category
  index README.md. The curated suite is flat (one directory per skill under
  .pi/agent/skills/) because the pi harness discovers skills by direct
  directory scan. Family indexes serve upstream's documentation tree, not
  invocation; upstream SKILL.md descriptions and the parity inventory stand
  in. Recorded as a packaging difference so it is explicit rather than a
  silent exclusion; index content itself is not exempted from review.
---

Recorded packaging decision: skill content is compared per skill directory
under flat packaging; upstream category index files (`skills/<family>/README.md`)
are intentionally absent and so are their summaries.
