---
name: merge-context
description: Reconcile divergent glossaries + ADRs term-by-term by interview — fold one branch's context into trunk, one context into another, or one repo's whole store into another; union ADRs, update the CONTEXT-MAP, flag genuine conflicts. Use to reconcile a context branch into trunk after a git merge (the glossary-sharpening half), when two bounded contexts turn out to be one, when a repo's origin moved (transfer / rename) and its old store is stranded, or when consolidating a fork's or sibling repo's context. Distinct from offload-context (commit + push, no reconcile).
argument-hint: "<source> into <target> — contexts (folders) or stores (repo name / hash from the index)"
---

# Merge Context

**Doesn't apply when context is in-repo** (the repo's `## Agent skills` block says so): plain git on the code repo carries the context — say that and stop.

Reconcile a **source** glossary + ADRs into a **target** by interview, rather than blindly copying. Three modes:

- **branch -> trunk (reconcile)**: bring this branch's context into the context trunk. Plain `git merge` combines the files mechanically; this skill then interviews the diverging glossary terms so the merged glossary stays *semantically* coherent — a line merge can leave a crept-back alias or two surviving definitions for one concept, which git cannot catch. This is the glossary-sharpening half of reconciliation; run it on the merged trunk worktree after the `git merge`.
- **context -> context** (within one store): two bounded contexts that turned out to be one — fold `src/orders/` into `src/ordering/`, repoint the map.
- **store -> store** (across repos): bring another origin-slug store's context in — a moved origin (new slug, old store stranded), a fork, or a sibling. Identify the source from the readable dir names or `INDEX.md` (see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)).

## Process

### 1. Resolve source + target

Resolve both sides. For **branch -> trunk**: source = this branch's context worktree, target = the trunk worktree — run the `git merge` first, then reconcile the merged result here. For **context/store** modes: resolve the store paths (key formula in [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md); dir names and `INDEX.md` identify them). Confirm direction with the user — the reconcile writes into the **target**; the source is read, never silently destroyed.

### 2. Inventory + classify

Read both glossaries (`CONTEXT.md` / per-context) and ADRs. Classify every term:

- **New** — in source, absent in target -> add.
- **Identical** — same term, same definition -> dedupe.
- **Divergent** — same term, different definition -> conflict; don't pick silently.
- **Alias clash** — source's primary term sits on target's `_Avoid_` list (or vice versa) -> a real domain disagreement; surface it.

ADRs: union by `YYYY-MM-DD-slug`; identical dedupe; same slug, different body -> conflict; decisions that contradict across the two -> flag (supersede per [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md), never delete). Map relationships: union; repoint any link that pointed at a context being folded away.

### 3. Present

Group: N new, N identical, N divergent, alias clashes, ADR conflicts. Lead with conflicts — they need a decision. Ask per conflict — `question` tool if available, else prose (2–4 options, `(recommended)`, one-line reason, stop) — keep target / take source / merge both into one sharper line. **AFK** -> apply the unambiguous adds + dedupes; hold every divergence, alias clash, and ADR conflict for review (never auto-resolve meaning).

### 4. Merge

Write the reconciled glossary + ADRs into the **target** store; update its `CONTEXT-MAP.md` (add the folded context's entries, repoint relationships, drop the merged-away entry). Glossary discipline holds: one sentence per term, opinionated, aliases under `_Avoid_` ([CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)). A losing definition that's a genuine alias folds into the winner's `_Avoid_` list; one that's simply dead is deleted. Leave the source intact.

### 5. Finish

Run `../setup-context/ctx-index.sh` (it scans the whole store, so cwd doesn't matter) to refresh the readable index. Report what merged, what conflicted, where the target store is. Offer to remove the source (the context folder, or the source store dir) now that it's folded in — only on explicit confirm.

## Notes

- Reconciles **meaning**, not just files — a divergent term or contradictory ADR is never auto-resolved; it's surfaced.
- Writes into the target context worktree, outside the code repo.
- Not offload-context (commit + push, no reconcile).
