---
name: code-review
description: "Review the changes since a fixed point along two axes: Standards (does the code follow this repo's documented coding standards?) and Spec (does it match what the originating issue, spec, or PR asked for?). Runs both reviews in parallel sub-agents and reports them side by side. Use when the user wants to review a branch, a PR, work-in-progress changes, or asks to \"review since X\"."
argument-hint: "PR or fixed point to review (commit, branch, tag, PR; default: main), or the working tree for uncommitted work"
---

Two-axis review of the change set since a fixed point the user supplies, covering committed changes and, for WIP reviews, the staged, unstaged, and relevant untracked work on top of it:

- **Standards**: does the code conform to this repo's documented coding standards?
- **Spec**: does the code faithfully implement the originating issue, ticket, or spec?

Both axes run as **parallel sub-agents** so they don't pollute each other's context, then this skill aggregates their findings.

The issue tracker should have been provided to you. If `docs/agents/issue-tracker.md` is missing, tell the user to run `setup-context`.

## Process

### 1. Pin the review scope

Clarify what to review: **committed-only** (the default: everything between a fixed point and `HEAD`) or **WIP** (committed changes plus working-tree work: staged, unstaged, and relevant untracked additions). "Review my work", "review the current changes", or a review-before-commit handoff means WIP; "review the branch/PR" or a named range means committed-only. Preserve committed-only when that is the requested scope.

Whatever the user said is the fixed point: a commit SHA, branch name, tag, `main`, `HEAD~5`, or (for a PR/branch) the base it targets, resolved to its merge-base with `main`. Ask for the fixed point when none is given; for WIP with no fixed point, the base is current `HEAD` and the review covers the uncommitted work on top of it. Resolve the base once to a full SHA (`git rev-parse`) and record it in the final report; a bad ref fails here, not inside two parallel sub-agents.

Capture the change evidence once, in this order, and hand the same evidence to both axes:

- Committed: `git diff <base>...HEAD` (three-dot, so the comparison is against the merge-base) plus `git log <base>..HEAD --oneline`.
- Staged against `HEAD`: `git diff --cached`.
- Unstaged against the index: `git diff`.
- Relevant untracked: `git ls-files --others --exclude-standard` (ignored files are irrelevant). Their contents are in no diff; list the paths and read each file.

The non-empty check applies to the whole change set, not the committed diff alone: fail here only on a bad ref or a genuinely empty scope (no commits in range, clean index, clean tree, and no relevant untracked). A WIP review must show staged, unstaged, and untracked additions even when the committed diff is empty.

**Baseline exclusion.** A review-before-commit handoff carries a recorded baseline: a start commit plus a pre-existing dirty-work snapshot, one `<status> <hash> <path>` line per dirty path (status from `git status --porcelain`, the hash the path's `git hash-object` at claim time; see implement's claim). Without a baseline, every path in the change evidence is the requested review by default. With one, classify every path in the change evidence, and check every recorded baseline path against the current state too: a recorded path that has vanished since (deleted, or reverted to the base) is not silently dropped.

- **Slice**: the paths the handoff names as the work under review. Include.
- **Workflow record**: ticket, spec, and claim-record paths. Exclude without asking; they are the workflow's trace, not code under review.
- **Pre-existing, unchanged**: in the baseline, with a content marker equal to the current content (same `git hash-object`), still outside the index and the committed range, or untracked and still exactly as recorded. Exclude, and report the excluded paths; never drop them silently.
- **Ambiguous**: in the baseline but with different content now, or touched by the slice's own git actions (staged, or present in the committed range), or changed with no baseline entry and not named as slice. Stop and ask the user, one round in the `grilling` skill's question format: is the difference the slice, continued user work, or both? Never guess, include silently, drop silently, stage, or commit. Proceed only on the decision.

### 2. Identify the spec source

The spec is whatever says what this change was *supposed* to do; it doesn't have to come from the workflow. Look for it in this order, stopping at the first that fits:

1. A path, PR, or issue reference the user passed in: treat it as authoritative.
2. A pull request: its description plus any issues it closes. Pull the PR body and linked issues (`gh pr view`, the GitLab MR page, etc.); issue references in the commit messages (`#123`, `Closes #45`, `!67`) point the way.
3. The repo's configured tracker (`issue-tracker.md` in the config home, if present): the issue this branch implements, fetched per its conventions. If `issue-tracker.md` is absent, tell the user to run `setup-context` to configure the tracker.
4. A spec/issue file: common homes are `docs/`, `specs/`, or `.scratch/` matching the branch name or feature; and if this repo runs the workflow, a `.scratch/<feature>/issues/*.md` (legacy: `tickets/`) plus its `spec.md` (legacy: `SPEC.md`) beside it at the board's recorded artifact location - default the context home (see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)).
5. Nothing found -> ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent skips and reports "no spec available".

### 3. Identify the standards sources

Anything in the repo that documents how code should be written, such as `CODING_STANDARDS.md` or `CONTRIBUTING.md`. If the repo keeps ADRs or a domain glossary (e.g. `GLOSSARY.md`), those count too; naming and structure should match them.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below: a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation. Like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name**: a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Spawn both sub-agents in parallel

Send a single message with two `Agent` tool calls (`subagent_type: "general"` for both) so they run in parallel with isolated context.

**Exactly two top-level sub-agents, one per axis**, whatever the change set's size. Each may spawn read-only `explore` sub-agents within its own work to navigate the code.

**Standards sub-agent prompt** should include:

- The full change evidence: the committed diff command and commit list, plus the staged, unstaged, and relevant untracked path lists (read each untracked path's content; it is in no diff).
- The standards-source files you found in step 3, **plus the smell baseline from step 3** pasted in full (the sub-agent has no other access to it).
- The brief: "Report, per file/hunk where relevant, (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls: documented-standard breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt** should include:

- The full change evidence (the committed diff command and commit list, plus the staged, unstaged, and relevant untracked paths).
- The path or fetched contents of the spec.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings, because the two axes are deliberately separate (see _Why two axes_).

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any). Don't pick a single winner across axes: that's the reranking the separation exists to prevent.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
