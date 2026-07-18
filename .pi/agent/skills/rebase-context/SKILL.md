---
name: rebase-context
description: Rebase one context branch onto another in the context repo — replay the source branch's context commits on top of a target/base, resolving glossary + ADR conflicts as you go, so a feature's context stays current with its moved base (or moves onto a different one). Use when the base a branch forked from has advanced and you want your branch's context rebased onto it, or to re-parent a context branch. Conflict resolution runs merge-context's glossary interview. Distinct from merge-context (reconcile a branch into trunk via merge), offload-context (commit + push, no cross-branch).
argument-hint: "<source> onto <onto> — branch whose context to rebase, and the branch to rebase it onto (source defaults to the current branch; onto defaults to its base)"
---

# Rebase Context

**Doesn't apply when context is in-repo** (the repo's `## Agent skills` block says so): plain git on the code repo carries the context — say that and stop.

Rebase a context branch **onto another** in the context repo: replay the source branch's context commits on top of the target so its history sits linearly on top of where it's now based. This is `git rebase` between two context branches plus conflict resolution with the same glossary discipline as `merge-context` — a textual rebase can leave two definitions for one term, a crept-back alias, or contradictory ADRs that git can't see. See [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) for the worktree / slug model.

Typical use: a branch's context was forked off its base (e.g. `feature-3` off `feature-2`); the base has since advanced, so you rebase the branch's context onto the updated base to stay current and linear. Bringing a branch **into** the context trunk is reconciliation (a merge), not a rebase — use `merge-context` (`branch -> trunk`).

## Process

### 1. Resolve source + onto

Parse the argument as `[<source>] onto <onto>`. Source context branch — the named branch, else the current code branch's context. Onto — the named target, else the source's **base** (the branch it was forked from; `ctx-init` records it, falling back to the designated master). Both are branches in this repo's context bare repo (origin-slug keyed; path formula in [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)), their worktrees pairing 1:1 with the code branches. Resolve the source worktree; ensure `onto` exists (materialise its worktree if needed). Confirm direction: the rebase **rewrites the source branch** on top of `onto`; `onto` is read, never changed.

### 2. Rebase

In the source worktree, replay onto the target: `git rebase <onto>`. Git applies the source's context commits one at a time on top of `<onto>`; clean ones apply untouched, the first conflicting commit stops the rebase for resolution. `git rebase --abort` at any point restores the branch exactly — nothing is lost.

### 3. Resolve each conflict by meaning

At each stop git marks the conflicted files. Resolve by **meaning**, not just markers, per `merge-context`'s discipline:

- **Glossary** (`CONTEXT.md` / per-context, `domain.md`): classify each clashing term new / identical / divergent / alias-clash; lead with the real conflicts. Ask per conflict — `question` tool if available, else prose (2–4 options, `(recommended)`, one-line reason, stop) — keep onto / take source / merge both into one sharper line. One opinionated sentence per term, aliases under `_Avoid_` ([CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)).
- **ADRs** (`docs/adr/`, `<dir>/adr/`): union by `YYYY-MM-DD-slug`; same slug, different body -> supersede per [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md), never delete.
- **CONTEXT-MAP.md**: union the links; repoint anything stale.

Stage the resolved files (`git add`) and `git rebase --continue`; repeat until the rebase finishes. **AFK** -> resolve the unambiguous (adds, dedupes, ADR unions); pause the rebase on any divergence, alias clash, or ADR contradiction for review — never auto-pick meaning.

### 4. Ground against onto's code

The rebased context now sits on `onto`, so it has to hold in **onto**'s code. Take onto's path universe (`../setup-context/manifest.sh`, run with cwd in onto's worktree, over its `git ls-files`); a `<dir>/CONTEXT.md`, a term keyed to a missing module, or an ADR about absent code that `onto` lacks is **dangling** — flag it, don't silently keep it.

### 5. Finish

Refresh the index (`../setup-context/ctx-index.sh` — scans the whole store, cwd-independent). Report: rebased `<source>` onto `<onto>`, conflicts resolved, anything held or flagged dangling. The branch's history is now rewritten on top of `<onto>` — republishing it to the team remote needs `git push --force-with-lease` (a deliberate act; never force a shared trunk). A checkout on `<source>` finds the rebased context in its worktree.

## Notes

- Rebases one branch's context **onto another** (replay + conflict-fix), rewriting the source's history linearly. Into **trunk** is reconciliation (`merge-context`, a merge); commit + push of a branch's own context is `offload-context`.
- Resolves **meaning**, not just files — the same glossary interview as `merge-context`, so a divergent term or contradictory ADR is never auto-resolved.
- History rewrite: rebasing rewrites the source branch's context commits; if already pushed, republishing needs `--force-with-lease`. `onto` is never modified, and `git rebase --abort` is always a clean way out.
- ADRs are annotated, never deleted — supersede by date-slug, keep the trail.
