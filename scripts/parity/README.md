# scripts/parity — pinned upstream parity seam

`check-parity.sh` compares the curated suite (`.pi/agent/skills/`) against
mattpocock/skills at the pinned commit, over complete retained skill
directories: main `SKILL.md`, frontmatter and invocation metadata, supporting
references, templates, formats, and credits. It does **not** verify the
context mechanism's runtime behavior — parity only.

- `map.sh` — shared constants (pinned commit, family/skill mapping, inventory
  rules) and the snapshot helper. `PARITY_UPSTREAM_DIR` +
  `PARITY_EXPECTED_COMMIT` (+ `PARITY_EXPECTED_DIRS` +
  `PARITY_UPSTREAM_SKILLS_SPEC`) are test escape hatches; production runs
  fetch and verify the pinned commit from `PARITY_UPSTREAM_URL`.
- `exceptions/` — every permitted departure, one entry file each, naming its
  upstream counterpart, the exact change, and the rationale. Substitution
  entries additionally carry line-level markers enforced against the real
  diff, so an unrecorded edit beside an approved substitution fails.
  Whole-skill exclusions and pre-existing-fork exemptions are rejected.

Usage:

```sh
scripts/check-parity.sh                      # whole suite; any drift fails
scripts/check-parity.sh retro wizard         # scoped: a scoped pass does NOT imply a suite pass
scripts/check-prose.sh                       # prose/policy seam; skips files parity owns
```
