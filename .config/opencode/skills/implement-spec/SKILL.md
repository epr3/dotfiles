---
name: implement-spec
description: "Implement the result of /to-spec and /to-tickets in code."
disable-model-invocation: true
---

You have been provided a spec. This spec should have tickets associated with it, describing how to implement the spec.

The issue tracker should have been provided to you. If not, tell the user to run `/setup-context`.

The goal is the entire spec implemented on a single **integration branch**, with every ticket resolved the way the issue tracker closes work.

The tickets are not a list of steps. They are a **task graph** with blocking relationships between them. This means there is always a **frontier** of tickets which are ready to be grabbed.

Communication to and from subagents should be sparse. Communicate primarily through **context pointers**: to the spec, tickets, research notes, and previous commits. Don't duplicate information already available via pointers.

**Implementer subagents** should be run in the background where possible for maximum concurrency.

## Git ownership and approval

The human owns all Git writes. Never create, remove, or change branches or worktrees; merge; push; rebase; reset; stash; change Git configuration; or perform any other Git write through a command, script, alias, tool, or delegated agent. At each required operation, name the exact operation and target, hand it to the human, and pause until the human confirms completion. Do not begin dependent work on the assumption that the operation happened.

Staging and committing are also gated. First propose a repository-style commit message and the exact file scope, then wait for explicit approval before staging or committing. A request to commit is not approval. Any change to the message or file scope requires renewed approval. The gate applies to every delegated implementer. Preserve unrelated changes and existing staging; never include unrelated staged or unstaged work. If the approved scope overlaps existing staging or cannot be isolated safely, pause and ask the human how to proceed.

## Steps

1. Read the spec and tickets to understand the task graph. Select the first ticket on the frontier (all blockers resolved), unless the user named a ticket. If no ticket is ready, report the blocker rather than starting dependent work.

2. (optional) Use an **exploration subagent** to conduct any exploration required by the tickets - relevant codebase files or external documentation. Ensure the exploration subagent can save files - it should save its markdown notes in a directory outside the repo, accessible by all future subagents. This lets **implementer subagents** focus on implementation rather than exploration.

3. Create the integration branch. Branch creation is human-owned: name the branch, ask the human to create it, and pause until they confirm it exists. If the issue tracker closes work through PRs, or the user asks for one, hand off pushing the integration branch and opening a draft PR after the first merge in step 5 (a branch with no commits ahead of main can't open one), marked as closing the spec and tickets. Pause until the human confirms.

4. Use **implementer subagents** to implement each ticket, each in its own worktree on its own branch. For each ticket, name the branch and worktree path, ask the human to create them from the integration branch, and pause until the human supplies the worktree path and confirms its base. Each implementer subagent:
   - confirms its worktree is based on the integration branch before starting; if not, stops and asks the human to correct it (never reset or rebase);
   - reads the OpenCode skill named "tdd" to build the ticket;
   - before staging or committing, proposes a repository-style commit message and exact file scope, then waits for explicit approval. A commit request alone is not approval; changed proposals need renewed approval. Preserve unrelated changes and existing staging;
   - asks the human to merge the integration branch tip into its own branch before reporting done, and pauses until the human confirms the merge;
   - reports completion and any integration concerns without performing Git writes. These rules apply to every implementer.

5. Once an **implementer subagent** completes, have a **merger subagent** review its work for integration readiness. Then hand off merging the named ticket branch into the integration branch to the human. Pause until the human confirms the merge.

6. If this changes the **frontier** of available tickets, kick off more **implementer subagents** to work on the new tickets. This allows for maximum concurrency. Follow the same isolation and human Git handoffs for each.

7. Once all tickets are complete, read the OpenCode skill named "code-review" to review the work on the integration branch. Fix all issues raised by the code review in a single **implementer subagent**, using the same isolated-worktree, Git-handoff, and commit-approval rules.

8. If a draft PR exists, hand off pushing any final integration changes and marking the PR ready for review to the human; pause until they confirm. Otherwise, resolve each ticket the way the issue tracker closes work, and report the integration branch.

9. Clean up all **implementer subagent** worktrees. Worktree and branch removal is human-owned: list the exact worktrees and branches to remove, ask the human to perform cleanup, and pause until they confirm completion. Never clean them up yourself or via a script or delegate.
