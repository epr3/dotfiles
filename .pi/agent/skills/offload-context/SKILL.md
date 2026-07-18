---
name: offload-context
description: Publish this branch's context — commit the context worktree and push the branch to the team remote. Context lives in the separate context repo by default; you edit it directly in the worktree, so offload just saves it. Skip this skill entirely when the repo keeps context in-repo — it ships with the code commits. It does not merge to trunk (you run that). Use at the end of a grill-with-docs cycle, or when the user wants to offload, commit, publish, or sync context/ADRs. Final step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context), skippable when context is in-repo.
argument-hint: "(optional) --check to preview the worktree's uncommitted context"
---

# Offload Context

**Doesn't apply when context is in-repo** (the repo's `## Agent skills` block says so): context then commits and pushes with the code — say that and stop.

Publish this branch's context: **commit the context worktree and push the branch** to the team remote. Context lives **only** in the separate context repo — you edit it directly in the worktree `ctx-init` materialises (`$AGENT_CONTEXT_HOME/<slug>/<branch>/`), so there is no in-tree copy and nothing to reconcile; offload just saves your work. It does **not** merge to trunk — you run that yourself: a deliberate `git merge` in the context repo, then `merge-context` to reconcile the glossary. See [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) for the store model.

## Process

### 1. Check

Run `./offload-context.sh --check` **by its path, with cwd inside the code repo** (the script reads the repo + branch from your cwd to resolve the worktree, and finds its siblings itself — don't `cd` into the skill folder). It prints the worktree's uncommitted context (`git status`). Clean -> report "nothing to offload", stop.

### 2. Present

Summarise what will be committed (new / changed CONTEXT.md, ADRs, map). Confirm before pushing: `question` if available, else prose (offload now / cancel).

### 3. Apply

Run `./offload-context.sh` (no flag; same cwd — the code repo): it commits the worktree (`context: <branch>`) and pushes the branch to the team remote. No merge.

### 4. Done

Report: committed + pushed on branch `<branch>` in the context repo. The context trunk stays unchanged until you reconcile it deliberately (`git merge`, then `merge-context` for glossary sharpening).

## Notes

- The closing step of the workflow (`grill-with-docs -> to-spec -> to-tickets -> implement -> offload-context`) — a separate skill you invoke; **not** auto-run by `implement`.
- Just a **commit + push** of the context worktree — no in-tree copy, no reconcile. You edit context directly in the worktree; this saves it. Bringing a context branch into trunk is your deliberate `git merge`, then `merge-context` to interview + sharpen the merged glossary; `rebase-context` rebases a branch's context onto a moved base.
- Commits in the external context repo's worktree (a real git commit there), not the code tree; the `--check` preview is the review gate.
