---
name: merge-context
description: Reconcile divergent glossaries + ADRs term-by-term by interview. Use to fold a context branch into trunk after a git merge, when two bounded contexts turn out to be one, when a repo's origin moved and its old context repo is stranded, or when consolidating a fork's or sibling's context. Distinct from offload-context (commit + push, no reconcile) and rebase-context (replays a branch onto a moved base, no trunk merge).
argument-hint: "<source> into <target> — contexts (folders) or context repos (repo name / hash from the index)"
disable-model-invocation: true
---

# Merge Context

Resolve the **context store** first: [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) → *Resolving the context store*.

Reconcile a **source** glossary + ADRs into a **target** by interview, rather than blindly copying. A line merge can leave a crept-back alias or two surviving definitions for one concept — this skill resolves **meaning**, which git cannot see. Three modes:

- **branch -> trunk (reconcile)**: plain `git merge` combines the files mechanically; run this skill on the merged trunk worktree afterwards to interview the diverging terms. **Context repo only** — under **in-repo context** there are no context branches to fold, plain git on the code repo carries it: say so and stop.
- **context -> context** (within one **context home**): two bounded contexts that turned out to be one — fold `src/orders/` into `src/ordering/`, repoint the map. Runs under either **context store** — two glossary files side by side, no store machinery involved.
- **context repo -> context repo** (across repos): bring another slug's context in — a moved origin (new slug, old context repo stranded), a fork, or a sibling. Identify the source from the readable dir names or `INDEX.md` under the **context root**. **Context repo only** — under **in-repo context** there is no second **context repo** to pull from: say so and stop.

## Process

### 1. Resolve source + target

Resolve both sides. For **branch -> trunk**: source = this branch's **context worktree**, target = the trunk worktree — run the `git merge` first, then reconcile the merged result here. For **context -> context**: both sides are dirs under the same **context home**. For **context repo -> context repo**: resolve both repos under the **context root** (slug formula in [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) → *Layout*; dir names and `INDEX.md` identify them). Confirm direction with the user — the reconcile writes into the **target**; the source is read, never silently destroyed.

### 2. Inventory + classify

Read both glossaries (`CONTEXT.md` / per-context) and ADRs. Classify every term:

- **New** — in source, absent in target -> add.
- **Identical** — same term, same definition -> dedupe.
- **Divergent** — same term, different definition -> conflict; don't pick silently.
- **Alias clash** — source's primary term sits on target's `_Avoid_` list (or vice versa) -> a real domain disagreement; surface it.

ADRs: union by `YYYY-MM-DD-slug`; identical dedupe; same slug, different body -> conflict; decisions that contradict across the two -> flag (supersede per [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md), never delete). Map relationships: union; repoint any link that pointed at a context being folded away.

### 3. Present

Group: N new, N identical, N divergent, alias clashes, ADR conflicts. Lead with conflicts — they need a decision. Ask them as **round**s in the `grilling` skill's question format, one question per conflict: keep target / take source / merge both into one sharper line. **AFK** -> apply the unambiguous adds + dedupes; hold every divergence, alias clash, and ADR conflict for review. Never auto-resolve meaning.

### 4. Merge

Write the reconciled glossary + ADRs into the **target**; update its `CONTEXT-MAP.md` (add the folded context's entries, repoint relationships, drop the merged-away entry). Glossary discipline holds: one sentence per term, opinionated, aliases under `_Avoid_` ([CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) → *Rules*). A losing definition that's a genuine alias folds into the winner's `_Avoid_` list; one that's simply dead is deleted. Leave the source intact.

### 5. Finish

Under a **context repo**, run `<skill-dir>/ctx-index.sh` (`<skill-dir>` = the `setup-context` skill's folder; it scans the whole **context root**, so cwd doesn't matter) to refresh the readable index. Report what merged, what conflicted, where the target is. Offer to remove the source (the context folder, or the source **context repo** dir) now that it's folded in — only on explicit confirm.
