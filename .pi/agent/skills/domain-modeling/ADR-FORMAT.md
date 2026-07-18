# ADR Format

Personal, in the context worktree alongside `CONTEXT.md` (see [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md)): `docs/adr/YYYY-MM-DD-slug.md` — date-prefixed, **not** sequentially numbered. Multi-context: system-wide ADRs at `docs/adr/`, context-specific at `<dir>/adr/` (the code dir the decision belongs to) — write the ADR where the decision lives.
Create dir lazily. Like context, ADRs live in the context worktree; `offload-context` commits + pushes them at the end of a cycle — skipped when context is in-repo, where they commit with the code (see [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md)).

> **Why not `NNNN-` sequence numbers.** In a multi-developer repo, two branches
> both grab the next number and collide on merge, or renumber each other in
> review. A date prefix is collision-free across branches, still sorts
> chronologically, and never needs you to read the rest of the directory to pick
> an ID. Pick the slug from the decision; never derive an identifier by counting
> existing ADRs.

## Template

```md
# {Short title}

{1–3 sentences: context, decision, why.}
```

A single paragraph is fine. Value is recording *that* a decision was made and *why* — not filling sections.

## Optional (only if they add value)

- **Status** frontmatter (`proposed | accepted | deprecated | superseded`) — when decisions are revisited. To point at the superseding decision, reference it by its `YYYY-MM-DD-slug` filename, not by number.
- **Considered Options** — when rejected alternatives are worth remembering
- **Consequences** — when non-obvious downstream effects need calling out

## Finding related ADRs

Don't enumerate the directory and treat the listing as the authoritative set —
on a shared repo it's partial (ADRs live on unmerged branches) and racy. Instead
**search by topic**: grep `docs/adr/` (plus any `<dir>/adr/`) for the terms of the decision at hand
(module names, the seam, the technology) and read only the matches. Treat the
result as "the ADRs I could find on this topic," never "all ADRs." If none match,
proceed — absence of a matching ADR is not proof none exists elsewhere.

## ADR test — all three or skip

1. **Hard to reverse** — cost of changing your mind is meaningful
2. **Surprising without context** — future reader wonders "why?"
3. **Real trade-off** — genuine alternatives, specific reasons

Easy to reverse → skip. Not surprising → nobody wonders. No alternative → nothing to record.

## What qualifies

- Architectural shape (monorepo, event-sourced, CQRS)
- Cross-context integration patterns (events vs sync HTTP)
- Lock-in tech (DB, message bus, auth, deploy target — quarter-to-swap level)
- Boundary/scope decisions (ownership, ID-only references — the explicit no-s are as valuable as the yes-s)
- Deliberate deviations from the obvious path (manual SQL over ORM — stops the next engineer "fixing" something deliberate)
- Invisible constraints (compliance, partner SLAs)
- Rejected alternatives when rejection is non-obvious (REST over GraphQL for subtle reasons)
