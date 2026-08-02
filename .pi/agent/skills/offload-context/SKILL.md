---
name: offload-context
description: Offload context — commit this branch's context worktree and push the branch to the team remote. Use when the user wants to offload, publish, or sync context/ADRs. Not a merge into trunk (that is merge-context), and skipped entirely when the repo keeps context in-repo. Final step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context).
argument-hint: "(optional) --check to preview the worktree's uncommitted context"
---

# Offload Context

**Doesn't apply when context is in-repo** (the repo's `## Agent skills` block says so): context then commits and pushes with the code — say that and stop.

Context lives **only** in the separate context repo, and you edit it directly in the worktree `ctx-init` materialises (`$AGENT_CONTEXT_HOME/<slug>/<branch>/`) — so there is no in-tree copy and nothing to reconcile. This skill just **commits that worktree and pushes the branch**. It does **not** merge to trunk: that stays your deliberate `git merge` in the context repo, followed by `merge-context` to reconcile the glossary (`rebase-context` when a branch's base has moved). See [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) for the store model.

## Process

### 1. Check

Run `./offload-context.sh --check` **by its path, with cwd inside the code repo** (the script reads the repo + branch from your cwd to resolve the worktree, and finds its siblings itself — don't `cd` into the skill folder). It prints the worktree's uncommitted context (`git status`). Clean -> report "nothing to offload", stop.

### 2. Present

Summarise what will be committed (new / changed CONTEXT.md, ADRs, map). Confirm before pushing: `question` if available, else prose (offload now / cancel).

### 3. Apply

Run `./offload-context.sh` (no flag; same cwd — the code repo): it commits the worktree (`context: <branch>`) and pushes the branch to the team remote.

### 4. Done

Report: committed + pushed on branch `<branch>` in the context repo, and that the context trunk stays unchanged until you reconcile it deliberately.

## Notes

- A separate skill you invoke; **not** auto-run by `implement`.
- Commits in the external context repo's worktree, not the code tree; the `--check` preview is the review gate.
