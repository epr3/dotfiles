---
name: to-tickets
description: Break a plan, spec, or conversation into independently-grabbable tracer-bullet tickets written as local markdown files under tickets/, using tracer-bullet vertical slices, each named with its zero-padded build position within its parent spec. Use when the user wants to convert a plan into issues, create implementation tickets, or break work into issues. Third step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context).
argument-hint: "optional path to a spec/plan .md file"
---

# To Tickets

If the recorded `## Agent skills` block / `issue-tracker.md` (config home) designates a tracker, publish each issue there per its conventions (labels included when triage is on) instead of local files — everything else below is unchanged. Default:

Break plan into independently-grabbable tickets = vertical slices (tracer bullets) -> local files under `.scratch/<feature-slug>/tickets/` **at the context home** — check the recorded `## Agent skills` block *first*: in-repo declared -> the code repo is the home; otherwise the store worktree; never bare CWD (CONTEXT-FORMAT.md, *Context home*). Filename carries per-spec build order (`<NNNN>-<slug>.md`) -> `ls tickets/` = build sequence, nothing re-derived later.

## Process

### 1. Gather context

Work from conversation. Path arg (spec/plan `.md`) -> read fully. Default source: newest `.scratch/*/SPEC.md` in the context home. Note parent spec path/slug — every issue records it; step-5 ordering scoped to it.

### 2. Explore (optional)

Not explored yet -> read-only `explore` sub-agent via `Agent` tool if available, else `read`/`grep`/`find`/`ls` (LSP tools when available). Issue titles use domain glossary (`CONTEXT.md` in the context worktree — see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)); respect ADRs in area.

### 3. Draft vertical slices

Each issue = thin vertical slice through ALL layers end-to-end (schema, API, UI, tests) — NOT horizontal slice of one layer.

Type: **HITL** (needs human — architectural decision, design review) or **AFK** (implementable + mergeable unattended). Prefer AFK.

While drafting, capture each slice's **blocked-by** deps — they determine step-5 build order.

No todo list here — a todo list breaks down ONE issue into steps (that's `implement`), not track a set of issues. Keep the working breakdown in the conversation; step 4 presents it as the numbered list.

<vertical-slice-rules>
- Each slice = narrow but COMPLETE path through every layer
- Completed slice demoable/verifiable alone
- Many thin slices > few thick ones
</vertical-slice-rules>

### 4. Quiz user

Present breakdown as numbered list **in proposed build order**. Per slice: order · title · type (HITL/AFK) · blocked-by · user stories covered.

Review via `question` tool if available, else prose (2–4 options, `(recommended)`, one-line reason, stop), one question at a time. Cover: granularity (coarse/fine/right) · dependency correctness · **build order itself** (anything sequenced before its dependency?) · merge/split · HITL/AFK assignment. Iterate until approved.

### 5. Order and write issue files

Each ticket **declares its blocking edges**: a `blocked_by:` frontmatter list of ticket numbers (empty when unblocked). The linear `<NNNN>` order is the flattened default; the edges are the truth. On a real tracker, express edges as native blocking links where the tracker supports them — then the **frontier** (tickets whose blockers are all done) is queryable and multiple agents can work it in parallel; in local files, work top-to-bottom by `<NNNN>`.

Compute **build order per spec** from dependency graph: topological sort, every blocker ahead of what it blocks. Ties: foundational first (schema/contracts before features built on them), then delivered value.

Write each slice to `.scratch/<feature-slug>/tickets/<NNNN>-<slug>.md`, where `<feature-slug>` is **the parent spec's directory** — tickets live beside their SPEC.md, one dir per feature. No spec (conversation-sourced) -> mint a fresh `<feature-slug>` at the same context home (location rule at the top; never bare CWD). `<NNNN>` = zero-padded build position in this spec (`0001`, `0002`, …); **order lives in the filename** — `ls tickets/` reads as build sequence. Order is per-spec: a different spec starts again at `0001`, the slug keeps filenames unique. Create blockers-first so `blocked_by` references real ticket numbers. New ticket starts `status: open`; `implement` flips it to `resolved` and uses `<NNNN>` to pick next.

**Incremental runs:** tickets with this `parent` exist -> continuation, not fresh sequence. Read them; continue after highest `<NNNN>`. New slice must precede still-open work -> renumber (`git mv`) only open tail — never resolved issues; their number = history. Read numbering from own parent's tickets only: avoided race = *global* sequential numbering across specs/branches (same reason ADRs not numbered); one spec's ticket set normally lives on one branch.

<issue-template>
---
status: open
type: HITL | AFK
parent: <path or slug of the source spec/plan, or "none">
blocked_by: [<NNNN>, ...]   # ticket numbers; [] when unblocked
---

## What to build

Concise description of this vertical slice. End-to-end behavior, not layer-by-layer.

No file paths or code snippets — they go stale. Exception: a prototype snippet encoding a decision more precisely than prose (state machine, reducer, schema, type shape) — inline the decision-rich parts, note it came from a prototype (see the `prototype` skill).

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

</issue-template>

Filename `<NNNN>` + `blocked_by` = two views of one dependency graph: linear sequence + hard constraint. Keep them in agreement — a numbering that violates `blocked_by` is a bug.

Don't modify parent spec/plan file.
