---
kind: inventory
upstream: skills/engineering/ask-matt/SKILL.md
local: absent
rationale: >
  Separate user-requested retirement re-recorded here (head commit 335543a
  "drop ask-matt from the suite"): ask-matt is a This-is-a-router skill over
  the upstream set whose pi environment routes differently. Recorded as an
  explicit inventory decision, not a wording or behavior exception: the
  parity suite must treat its absence as an accounting item so its content
  cannot reappear from a future sync unnoticed.
---

Recorded retirement: ask-matt is present at the pinned snapshot and absent
from the curated suite. Its SKILL.md and agents/ metadata are not compared;
no other skill may retire under this entry (whole-skill exclusions beyond
this exact counterpart are rejected).
