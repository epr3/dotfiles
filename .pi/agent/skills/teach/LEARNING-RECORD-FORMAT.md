# Learning Record Format

`./learning-records/0001-<slug>.md`, incrementing (scan for highest, +1). Lazy-create. The ADRs of learning: non-obvious lessons, key insights, stated prior knowledge — they steer future sessions and set the zone of proximal development.

```md
# {Short title of what was learned or established}

{1-3 sentences: what, and why it changes what to teach next.}
```

That's the whole format. Optional, only when they earn it: `Status` frontmatter (`active | superseded by LR-NNNN`), **Evidence** (how understanding was demonstrated), **Implications** (what this unlocks/rules out).

**Write one when:** genuine demonstrated understanding of something non-trivial (sets a new floor) · disclosed prior knowledge ("I already know X" — record claimed depth) · a corrected misconception (high value — predicts future stumbles) · the mission shifted from learning (cross-link and update `MISSION.md`).

**Not:** material merely covered (coverage ≠ learning — wait for evidence) · anything already a glossary term · session activity logs (records are decision-grade insights, not a journal).

**Supersession:** later record contradicts an earlier one → mark the old `Status: superseded by LR-NNNN`, don't delete. How understanding evolved is signal.
