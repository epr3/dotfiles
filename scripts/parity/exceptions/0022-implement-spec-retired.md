---
kind: inventory
upstream: skills/engineering/implement-spec/SKILL.md
local: absent
rationale: >
  User-requested retirement, recorded 2026-10-04 on issue 0008 of
  upstream-skill-parity. implement-spec was restored byte-exact from the
  pinned snapshot by issue 0003, then deleted in commit e572e8f ("chore:
  streamline agent instructions") during the OpenCode v2 streamlining; that
  deletion carried no recorded retirement on this board. Asked whether to
  restore it or record the retirement, the user chose retirement. Recorded
  as an explicit inventory decision, not a wording or behavior exception,
  so its content cannot reappear from a future sync unnoticed. Like ask-matt
  (exception 0003), this is an accounting item over the pinned snapshot:
  the suite retains 24 upstream counterparts plus this recorded retirement,
  the setup substitution, and the five local-only skills.
---

Recorded retirement: implement-spec is present at the pinned snapshot
(`skills/engineering/implement-spec/SKILL.md`) and absent from the curated
suite by explicit user request. The 0003 restoration's substitution entry
0009 (its setup-entrypoint substitution) is retired with the skill and
removed from the active registry — a substitution entry with no local file
cannot load — and remains in git history as the record of that restoration.
