---
name: offload-context
description: "Offload context: commit this branch's context worktree and push the branch to the team remote. Use when the user wants to offload, publish, or sync context/ADRs. Not a merge into trunk (that is merge-context), and skipped entirely when the repo keeps context in-repo. Final step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context)."
argument-hint: "(optional) --check to preview the worktree's uncommitted context"
disable-model-invocation: true
---

# Offload Context

Resolve the **context store** first: [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) → *Resolving the context store*. **In-repo context** → this skill is a no-op; say so and stop.

Under a **context repo** it **commits this branch's context worktree and pushes the branch** to the team remote. It does **not** merge into trunk: that stays your deliberate `git merge` in the context repo, followed by `merge-context` to reconcile the glossary (`rebase-context` when a branch's base has moved).

## Process

### 1. Check

Run `<skill-dir>/offload-context.sh --check` with **cwd inside the code repo** (`<skill-dir>` = this skill's folder). It prints the **context worktree**'s uncommitted context (`git status`). Clean -> report "nothing to offload", stop.

### 2. Present

Summarise what will be committed (new / changed CONTEXT.md, ADRs, map), then get explicit confirmation before pushing; offload now, or cancel.

### 3. Apply

Run `<skill-dir>/offload-context.sh` (no flag; same cwd: the code repo): it commits the **context worktree** (`context: <branch>`) and pushes the branch to the team remote.

### 4. Done

Report: committed + pushed on branch `<branch>` in the **context repo**, and that the context trunk stays unchanged until you reconcile it deliberately.

## Notes

- A separate skill you invoke; **not** auto-run by `implement`.
