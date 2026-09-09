---
name: rebase-context
description: Rebase one context branch onto another in the context repo, resolving glossary + ADR conflicts as you go. Use when the base a branch forked from has advanced, or to re-parent a context branch. Distinct from merge-context (reconcile into trunk via merge) and offload-context (commit + push, no cross-branch).
argument-hint: "<source> onto <onto>: branch whose context to rebase, and the branch to rebase it onto (source defaults to the current branch; onto defaults to its base)"
disable-model-invocation: true
---

# Rebase Context

Resolve the **context store** first: [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) → *Resolving the context store*. **In-repo context** → this skill is a no-op; say so and stop.

Under a **context repo**, replay a source context branch's commits on top of a target so its history sits linearly on top of where it's now based. This is `git rebase` between two context branches plus conflict resolution with the same glossary discipline as `merge-context`: a textual rebase can leave two definitions for one term, a crept-back alias, or contradictory ADRs that git can't see.

Typical use: a branch's context was forked off its base (e.g. `feature-3` off `feature-2`); the base has since advanced, so you rebase the branch's context onto the updated base to stay current and linear. Bringing a branch **into** the context trunk is reconciliation (a merge), not a rebase; use `merge-context`.

## Process

### 1. Resolve source + onto

Parse the argument as `[<source>] onto <onto>`. Source context branch: the named branch, else the current code branch's context. Onto: the named target, else the source's recorded **base**: the fork parent `ctx-init.sh` persisted for that context branch at fork time; read it at `$AGENT_CONTEXT_HOME/<slug>/.git/info/fork-parent/<branch>` (slug formula in [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) → *Layout*), with cwd inside the code repo. An absent record falls back to the designated master. An explicit named `onto` always wins. Both are branches in this repo's **context repo**, their **context worktree**s pairing 1:1 with the code branches. Resolve the source **context worktree**; ensure `onto` exists (materialise its **context worktree** if needed). Confirm direction before any rewrite: the rebase **rewrites the source branch** on top of `onto`; `onto` is read, never changed.

### 2. Rebase

In the source **context worktree**, replay onto the target: `git rebase <onto>`. Clean commits apply untouched; the first conflicting commit stops the rebase for resolution. `git rebase --abort` at any point restores the branch exactly; nothing is lost.

### 3. Resolve each conflict by meaning

At each stop git marks the conflicted files. Resolve by **meaning**, not just markers, running `merge-context`'s classify-and-interview discipline over the conflicted glossary and unioning ADRs by date-slug (superseding, never deleting). Ask them as **round**s in the `grilling` skill's question format, one question per conflict. **AFK** -> resolve the unambiguous (adds, dedupes, ADR unions); pause the rebase on any divergence, alias clash, or ADR contradiction for review; never auto-pick meaning.

Stage the resolved files (`git add`) and `git rebase --continue`; repeat until the rebase finishes.

### 4. Ground against the source's code

The authoritative universe after a rebase is the **source code worktree**, not onto's. Take its path universe via `<skill-dir>/manifest.sh` (`<skill-dir>` = the `setup-context` skill's folder, invoked by path with **cwd anywhere inside the source code worktree** — answers are repo-root-relative for that worktree). A `<dir>/CONTEXT.md`, a term keyed to a missing module, or an ADR about absent code that the source's manifest lacks is **dangling**: surface it as a report + question and keep all context content until the user decides — never silently keep or drop anything. A dangling base-inherited path (present on onto, absent from the source) says "context rebased before code".

Source-only feature paths stay valid — they exist on the source, just not on the base. This step completes once every dangling reference is surfaced and decided; grounding alone drops nothing.

### 5. Finish

Refresh the index (`<skill-dir>/ctx-index.sh`, same folder; it scans the whole **context root**, so cwd doesn't matter). Report: rebased `<source>` onto `<onto>`, conflicts resolved, anything held or flagged dangling. Because the history is rewritten, republishing an already-pushed branch needs `git push --force-with-lease`; a deliberate act. Never force a shared trunk.
