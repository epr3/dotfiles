---
name: code-review
description: Review the changes since a fixed point along two axes — Standards (does the code follow this repo's documented coding standards?) and Spec (does it match what the originating issue, spec, or PR asked for?). Use when the user wants to review a branch, a PR, or work-in-progress changes.
argument-hint: "PR or fixed point to review (commit, branch, tag, PR; default: main)"
---

# Code Review

Two-axis review of the diff between `HEAD` and a fixed point the user supplies:

- **Standards** — does the code conform to this repo's documented coding standards?
- **Spec** — does the code faithfully implement the originating issue, ticket, or spec?

A change can follow every standard and implement the wrong thing, or do exactly what the issue asked and break every convention. So each axis runs as its own sub-agent, and the two reports stay separate — reporting them apart stops one from masking the other.

## Process

### 1. Pin the fixed point

Whatever the user said is the fixed point — a commit SHA, branch name, tag, `main`, `HEAD~5`. Reviewing a PR or branch? The fixed point is the base it targets (or its merge-base with `main`). If they didn't specify one, ask for it.

Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Also note the list of commits via `git log <fixed-point>..HEAD --oneline`.

Confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty — a bad ref or empty diff should fail here, not inside two parallel sub-agents.

### 2. Identify the spec source

The spec is whatever says what this change was *supposed* to do — it doesn't have to come from the workflow. Look for it in this order, stopping at the first that fits:

1. A path, PR, or issue reference the user passed in — treat it as authoritative.
2. A pull request: its description plus any issues it closes. Pull the PR body and linked issues (`gh pr view`, the GitLab MR page, etc.); issue references in the commit messages (`#123`, `Closes #45`, `!67`) point the way.
3. The repo's configured tracker (`issue-tracker.md` in the config home, if present): the issue this branch implements, fetched per its conventions.
4. A spec/ticket file — common homes are `docs/` or `specs/`; and if this repo runs the workflow, a `.scratch/<feature>/tickets/*.md` plus its `SPEC.md` beside it in the context home (see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)).
5. Nothing found -> ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent skips and reports "no spec available".

### 3. Identify the standards sources

Anything in the repo that documents how code should be written, such as `CODING_STANDARDS.md` or `CONTRIBUTING.md`. If the repo keeps ADRs or a domain glossary (e.g. `CONTEXT.md`), those count too — naming and structure should match them.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** — [SMELLS.md](./SMELLS.md), a fixed set of Fowler code smells that applies even when a repo documents nothing. Don't read it yourself; the Standards sub-agent reads it in step 4.

### 4. Spawn both sub-agents in parallel

Send a single message with two `Agent` tool calls — `subagent_type: "general"` for both — so they run in parallel with isolated context.

**Exactly two top-level sub-agents — one per axis**, whatever the diff's size. Each may spawn read-only `explore` sub-agents within its own work to navigate the code.

**Standards sub-agent prompt** — include:

- The full diff command and commit list.
- The standards-source files you found in step 3, and the **absolute path** to `SMELLS.md` in this skill folder, with the instruction to read it first.
- The brief: "Report — per file/hunk where relevant — (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls — documented-standard breaches can be hard, baseline smells never are. Under 400 words."

**Spec sub-agent prompt** — include:

- The diff command and commit list.
- The path or fetched contents of the spec.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned, findings neither merged nor reranked.

End with a one-line summary: total findings per axis, and the worst issue *within each axis* (if any) — no single winner across axes.
