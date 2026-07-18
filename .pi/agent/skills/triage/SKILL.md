---
name: triage
description: Move issues on the project issue tracker through a small state machine of triage roles — categorise, verify, grill if needed, and write agent-ready briefs. Use when the user wants to triage issues, review incoming bugs or feature requests, prepare issues for an AFK agent, or manage the issue queue. Requires a tracker + triage labels configured by setup-context.
disable-model-invocation: true
argument-hint: "what to triage (e.g. 'what needs attention', '#42', 'move #42 to ready-for-agent')"
---

# Triage

Move issues through a small state machine of triage roles. Requires the repo to be configured: tracker operations come from `issue-tracker.md`, label strings from `triage-labels.md` — both in the **config home** (CONTEXT-FORMAT.md defines it). Missing either -> stop, point the user at `setup-context` (tracker + triage on). If the issue-tracker config says external PRs are a request surface, triage covers them too — a PR is an issue with attached code: same roles, same states, with the deltas marked "for a PR" below.

Every comment posted to the tracker during triage starts with this disclaimer:

> _Posted by an AI triage agent on behalf of the maintainer._

## Roles

Two **category** roles: `bug`, `enhancement`. Five **state** roles: `needs-triage` (maintainer evaluates), `needs-info` (waiting on reporter), `ready-for-agent` (fully specified, AFK-ready), `ready-for-human` (needs human implementation), `wontfix`. These are canonical names — apply the actual strings from `triage-labels.md` (config home). Every triaged issue carries exactly one category role and one state role; conflicting state roles -> flag and ask before doing anything else.

For a PR the states read against the attached code: `ready-for-agent` means a brief is attached and an agent takes the next step on the diff; `ready-for-human` means it's ready for a human to merge.

**Transitions:** unlabeled -> `needs-triage` first; from there -> `needs-info`, `ready-for-agent`, `ready-for-human`, or `wontfix`. `needs-info` -> back to `needs-triage` once the reporter replies. The maintainer can override any transition — flag unusual ones and ask (`question` tool if available, else prose) before proceeding.

## Process

The maintainer invokes triage and describes what they want in natural language. Interpret and act.

**"What needs attention"** -> query the tracker and present three buckets, oldest first, counts + a one-line summary per item: **Unlabeled** (never triaged), **needs-triage** (evaluation in progress), **needs-info with reporter activity** (replied since the last triage notes). PRs in scope -> external PRs join the buckets, lines tagged `[PR]`/`[issue]`. Discovery surfaces *external* PRs only (tracker config defines external) — a collaborator's in-flight PR isn't triage work; but the filter is discovery-only, an explicitly named PR is always triaged. Let the maintainer pick.

**A specific issue** -> per-issue flow:

1. **Gather.** Read the full issue — body, comments, labels, reporter, dates (for a PR, the diff too). Parse prior triage notes; check whether the reporter answered outstanding questions and present the updated picture — never re-ask resolved questions. Explore the codebase using the project's glossary, respecting ADRs in the area: does the requested behaviour already exist? Read `out-of-scope/*.md` in the config home and surface any prior rejection resembling this issue.
2. **Recommend.** Category + state recommendation with reasoning, plus a brief codebase summary relevant to the issue. Wait for direction (`question` tool if available, else prose).
3. **Reproduce** (bugs only, before any grilling). Follow the reporter's steps, trace the relevant code, run tests or commands. Report: confirmed repro with code path, failed repro, or insufficient detail (a strong `needs-info` signal). For a PR: check out the code and run the tests to confirm the diff does what it claims. A confirmed repro makes a much stronger brief.
4. **Grill** (if the issue needs fleshing out). Run the [`grilling`](../grilling/SKILL.md) loop with [`domain-modeling`](../domain-modeling/SKILL.md) — sharpen the terms, record what crystallises.
5. **Apply the state:**
   - `ready-for-agent` — attach an agent brief ([AGENT-BRIEF.md](./AGENT-BRIEF.md)); moving here without a grilling session -> ask whether to write the brief anyway.
   - `ready-for-human` — same structure as a brief, plus why it can't be delegated (judgment calls, external access, design decisions, manual testing).
   - `needs-info` — post triage notes (template below).
   - `wontfix` (enhancement) — record the rejection as `out-of-scope/<slug>.md` in the config home (what was asked, why it's out of scope), link it from a closing comment, close.
   - `needs-triage` — apply the role; optional comment if there's partial progress.

**A direct order** ("move #42 to ready-for-agent") -> trust it: confirm what's about to happen (role changes, comment, close), apply directly, skip grilling. Offer the brief if moving to `ready-for-agent` without one.

## Triage notes template

```
## Triage Notes

**What we've established so far:**
- point

**What we still need from you (@reporter):**
- question
```

Capture everything resolved during grilling under "established so far" so the work isn't lost. Questions must be specific and actionable, never "please provide more info".
