---
kind: substitution
upstream: skills/engineering/domain-modeling/ADR-FORMAT.md
local: .pi/agent/skills/domain-modeling/ADR-FORMAT.md
rationale: >
  ADR destination/naming substitutions, downstream-reusable: the `adrs`
  destination resolves per class instead of being hardcoded to `docs/adr/`
  (the artifact-locations contract); filenames are date-prefixed instead of
  sequentially numbered (recorded user decision, issue 0002 of
  upstream-skill-parity: branch-merge collision under context-worktree ADR
  merges, plus the existing date-prefixed ADR corpus stays intact);
  `superseded by ADR-NNNN` reads `{filename}` accordingly; an added line
  points to the retained offload lifecycle. "superseded by ADR-NNNN" and the
  removed sequential-numbering lines are the upstream counterpart of the
  same naming substitution. Template, optional sections, the ADR test, and
  What-qualifies wording are byte-exact upstream.
---

- ADRs live in `docs/adr/` by default; the `adrs` destination resolves per class with `<setup-context skill dir>/resolve-location.sh adrs`, run with cwd in the code repo. Multiple contexts: system-wide ADRs at the destination, context-specific at `<dir>/adr/`, and write the ADR where the decision lives.
- Like the glossary, ADRs recorded in the **context worktree** are committed + pushed by `offload-context` at the end of a cycle; skipped when the destination is the code repo, where they commit with the code.
- **Status** frontmatter (`proposed | accepted | deprecated | superseded by {filename}`): useful when decisions are revisited
- ## Names
- Filenames are **date-prefixed**: `YYYY-MM-DD-slug.md`, not sequentially numbered: two context branches both grabbing the next number collide on merge; a date prefix is collision-free, still sorts chronologically, and needs no directory listing to pick an ID.
- Take the slug from the decision; never derive an identifier by counting existing ADRs.
- ADRs live in `docs/adr/` and use sequential numbering: `0001-slug.md`, `0002-slug.md`, etc.
- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`): useful when decisions are revisited
- ## Numbering
- Scan `docs/adr/` for the highest existing number and increment by one.
