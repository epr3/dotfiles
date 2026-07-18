---
name: explain-diff
description: Create a rich, self-contained interactive HTML explanation of a code change, diff, branch, or pull request — background, intuition, literate walk-through, diagrams, and a quiz — saved as a dated HTML file in the context home. Use when the user wants to understand a change, not review it (reviewing against standards/spec is code-review).
argument-hint: "the change to explain (diff, branch, PR, commit range; default: working tree vs main)"
---

# Explain Diff

Produce a single long-form HTML page that teaches a reader how a specified code change works. Investigate the surrounding system before explaining the diff: the page should make sense to a beginner while still giving an experienced engineer a concise path to the changed behaviour.

**Identify the change first.** The source of truth is whatever the user pointed at — a diff, branch, PR (fetch body + linked issues per the tracker conventions in `issue-tracker.md` when configured), commit range, or the working tree against `main`. Ambiguous -> infer the most likely change from context and state the assumption on the page.

**Build the page** — five sections in order: Background · Intuition · Literate diff · Data flow & diagrams · Quiz. Per-section craft and the container conventions: [PAGE-FORMAT.md](./PAGE-FORMAT.md); quiz options and feedback: [QUIZ-FORMAT.md](./QUIZ-FORMAT.md).

**Save it** in the context home as `explainers/<YYYY-MM-DD>-<change-slug>.html` — date-prefixed for time-sorting, out of the code repo's version control (in-repo context: somewhere outside the repo instead, say where). Report the path.
