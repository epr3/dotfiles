---
name: setup-context
description: "Configure and scaffold this repo for the engineering skills: context store, tickets/specs, triage labels, domain-doc layout, and install the machine-wide `## Agent skills (defaults)` block. Run once before the other skills, or again to switch any of those choices."
disable-model-invocation: true
---

# Setup Context

Scaffold the config the engineering skills assume. Prompt-driven: explore, present, confirm, write. Machine-wide defaults live in global config; per-repo choices (made below) are recorded as an `## Agent skills` block + convention docs in the **config home**; every skill reads them without extra wiring.

## Process

### 1. Machine-wide defaults block: once per machine

The `## Agent skills (defaults)` block (domain-docs / context+ADRs conventions) is machine-wide and repo-independent. Its home is `~/.pi/agent/AGENTS.md`; Pi layers global and project instruction files, so it applies in every repo. Harness tooling (LSP usage) is separate; it ships as `pi-config/AGENTS.md`, pasted in directly, not managed here. Read the block in [global-rules.md](./global-rules.md), then check what's installed:

- **absent** -> offer to install. On confirm: append `global-rules.md`'s block to `~/.pi/agent/AGENTS.md` (create the file if missing).
- **present and identical** -> report it installed, move on.
- **present but drifted** -> show the difference (which clauses the installed copy lacks, which it has that the seed doesn't) and offer to update it in place: replace that block's body, leave surrounding content untouched, never duplicate. Don't overwrite silently; a local edit may be deliberate, so let the user decline per clause or wholesale. This is the block's only repair path; skipping "present" is what lets a copy installed once rot indefinitely.

Optional: shared **context root**. To put every **context repo** under one fixed folder instead of `~/.pi/agent/ctx`, set `AGENT_CONTEXT_HOME` (absolute path) in the environment Pi runs under (for example, its shell profile or launcher); offer it, skip if the per-harness default is fine.

### 2. Explore

Check current state, don't assume:

- `git remote -v` + `.git/config`: GitHub? GitLab? which repo?
- the repo's own agent-instructions file: does an `## Agent skills` block from a prior run already exist? (Re-running updates it in place.)
- what the repo resolves to today: run the numbered procedure in [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) → *Resolving the context store*, which also fixes the vocabulary used from here on. Then look at what's on disk: a **context repo** at `${AGENT_CONTEXT_HOME:-<harness ctx dir>}/<slug>`? a **context worktree** for the current branch? existing `domain.md` / `CONTEXT.md` / `CONTEXT-MAP.md`?
- in-tree `CONTEXT.md` / `CONTEXT-MAP.md` / `docs/adr/` in the code repo: either a prior **in-repo context** choice or leftovers from an older setup; don't move anything yet, section A decides what it is.
- is the `triage` skill installed (a `triage` folder beside this one, or `triage` among the available skills)? Decides whether section C runs at all.
- monorepo signals: a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, a populated `packages/*` with its own `src/`. Their absence means single-context, which is almost every repo.

### 3. Present + ask

Summarise present/missing, then ask as **round**s in the `grilling` skill's question format. Lead each section with the recommended answer so the user can accept it in a word; assume they don't know the terms, so give the explainer only where the choice genuinely branches, and skip a section outright when exploration already settled it. Section B depends on A's answer and C on B's, so they land in later rounds.

**Section A: Context store.** This picks a *model*, not a location; the location follows from it.

> Domain context + ADRs are what the skills read to orient and write as decisions crystallise. Two models: a **context repo** (a bare git repo mirroring this code repo, one **context worktree** per branch; personal, branch-aware, off the code tree; `offload-context` / `merge-context` / `rebase-context` manage it) or **in-repo context** (a plain `CONTEXT.md` + `docs/adr/` committed with the code: simpler, team-shared by default, no context repo machinery, and those three skills don't apply).

- **Context repo** (default): the suite's standard model; pick this unless you want context in the code repo.
- **In-repo context**: `CONTEXT.md` / `CONTEXT-MAP.md` at the code repo root, ADRs under `docs/adr/`, committed like any code.

If explore found in-tree context and the user picks **context repo**, offer to migrate it into the **context worktree**; if they pick **in-repo context**, it stays where it is.

**Context repo follow-up: parent branch.** The branch's **context worktree** forks off its *parent's* context, so it inherits that ancestry's glossary and ADRs; forking off the wrong parent means inheriting the wrong context. Detect the code branch's base (merge-base against likely parents; `main`/`master` when nothing closer), present it, and ask: fork off the detected parent, or name another branch. Default: the detected parent.

**Section B: Tickets & specs.**

> `to-spec` writes specs and `to-tickets` breaks them into tickets; `implement` picks tickets up, `code-review` reads them as the spec, and `wayfinder` keeps its planning map there. They need to know where that lives: local markdown (`.scratch/` in the **context home** section A resolves to) or a real tracker.

- **Local files** (default): `.scratch/<feature-slug>/` in that **context home** (its `SPEC.md` + `tickets/`); no external service, and whether they're kept or discarded is the user's call (conventions in [issue-tracker-local.md](./issue-tracker-local.md)).
- **GitHub**: issues in the repo's GitHub Issues via the `gh` CLI; specs stay local files. Conventions seed: [issue-tracker-github.md](./issue-tracker-github.md).
- **GitLab**: issues in GitLab Issues via the `glab` CLI; specs stay local files. Conventions seed: [issue-tracker-gitlab.md](./issue-tracker-gitlab.md).
- **Other** (Jira, Linear, …): user describes the workflow in one paragraph; recorded as freeform prose for the skills to follow.

Propose the tracker matching the remote found in explore; local files when there's no remote or the user prefers.

The GitHub/GitLab seeds carry a **PRs (MRs) as a request surface** flag, default **off**: leave it off and don't raise it. On means `triage` pulls *external* PRs into the same queue, roles, and states as issues; a user who wants that flips the flag in `issue-tracker.md` (config home) later. Local files / other: no PRs, nothing to record.

**Section C: Triage labels.** Skip entirely when the `triage` skill isn't installed; an uninstalled skill needs no labels. Otherwise it applies if section B chose a tracker, or chose local files and the user wants a triage flow (state then lives as a `Status:` line per ticket file).

> When issues live in a tracker, a small label vocabulary lets `to-tickets` mark what it creates, `implement` know what's safe to pick up, and the `triage` skill run its state machine. Skip it if you don't triage.

- **No triage** (default): skills create/read tickets and issues with no label conventions.
- **Yes**: record the five canonical roles, each overridable to match existing labels (seed table: [triage-labels.md](./triage-labels.md)): `needs-triage` (maintainer evaluates), `needs-info` (waiting on reporter), `ready-for-agent` (fully specified, AFK-ready), `ready-for-human`, `wontfix`. `to-tickets` labels what it creates `needs-triage` (or `ready-for-agent` when fully specified); `implement` treats `ready-for-agent` as the pick-up signal.

**Section D: Domain docs layout.** No monorepo signals in explore -> **single-context**, one `CONTEXT.md` at the context-home root; write it without asking. Signals found -> confirm which:

> The skills read `CONTEXT.md` for the project's domain language. Need to know: one global context or multiple (e.g. monorepo, separate frontend/backend) -> look in the right place.

- **Single-context**: one `CONTEXT.md` at the context-home root. Most repos.
- **Multi-context**: `CONTEXT-MAP.md` at the root -> per-context `CONTEXT.md` files (mirroring the code's dirs). Typically monorepo.

### 4. Confirm + edit

Show a draft of everything step 5 writes and let the user edit it first. The `## Agent skills` block gets one line per decision from sections A–D, section A's first (e.g. "Store: context repo" or "Store: in-repo" / "Issues: GitHub via `gh`, triage labels on; see `issue-tracker.md` in the config home" / "Layout: single-context").

### 5. Write

**Record the choices** as an `## Agent skills` block (`Store: context repo` or `Store: in-repo` first, then one line per section B–D) in the **config home** the procedure resolves for the chosen store:

- **Context repo** (default) -> `agent-skills.md` there (`$proj/.agents/`, beside the **context worktree**s): one copy per context repo, read by all of its branches, never duplicated into them; do **not** import or append it into the global `AGENTS.md` or the code repo's instructions file. The code repo stays untouched.
- **In-repo context** -> the code repo's instructions file, auto-loaded by the harness, so its lines may reference the convention docs directly (e.g. "see `docs/agents/issue-tracker.md`"). `AGENTS.md` at the repo root if it exists, else `CLAUDE.md` if that exists; if neither, ask the user which to create; never pick for them, never create one when the other exists.

Either way: update an existing block in place; never duplicate, never touch surrounding content.

**Write the convention docs** into the same **config home**, per the choices: `issue-tracker.md` is **always written** (from [issue-tracker-github.md](./issue-tracker-github.md), [issue-tracker-gitlab.md](./issue-tracker-gitlab.md), or [issue-tracker-local.md](./issue-tracker-local.md) to match section B, or from the user's description for "other"). Triage on -> also `triage-labels.md` from [triage-labels.md](./triage-labels.md) with the user's mappings. Re-running updates them in place.

**Then scaffold the context home.** **In-repo context**: create `CONTEXT.md` (or `CONTEXT-MAP.md` + per-context stubs) and `docs/adr/` at the code repo root, seed `domain.md` into `docs/agents/` (the config home, beside the convention docs), commit with the code; the scripts below don't apply, plain git carries it. **Context repo** (default): continue below.

Resolve `<slug>` from the code repo's origin (formula in [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) → *Layout*) and `proj="${AGENT_CONTEXT_HOME:-<harness ctx dir>}/<slug>"`.

Run every script below **by its path with cwd in the code repo**; they read the repo + branch from the cwd and locate their siblings themselves; don't `cd` into the skill folder (rule stated once in [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) → *Running the helper scripts*). `<skill-dir>` below is this skill's folder.

1. **Ensure the context repo + worktree**: run `<skill-dir>/ctx-init.sh [team-remote]`, passing `--base <branch>` with the parent confirmed in section A whenever it differs from the auto-detected base (matching answer -> omit the flag, detection is the default). It ensures the bare context repo at `$proj/.git` (clones the team remote when given, else `git init --bare` + a seed) and a **context worktree** for the current code branch at `$proj/<branch>`, forked off the parent's context so the ancestry's glossary/ADRs carry over. Prints the worktree path: **edit context there.**
2. **Build the manifest**: `<skill-dir>/manifest.sh` on the code repo: the set of real paths. This is the allowed-path universe.
3. **Inherited context**: the worktree was forked off its base, so it already carries the ancestry's glossary / ADRs. Nothing to copy. (A legacy per-branch `domain.md` found at the worktree root is from the old layout; move it to `.agents/domain.md`.)
4. **Write `domain.md` to `$proj/.agents/domain.md`** (create `.agents/` if missing) from the seed template [domain.md](./domain.md), its **Code repo** line filled with the origin URL + `<slug>`. This is in the config home, outside the worktree; the manifest doesn't govern it. Re-run: update in place.
5. **Scaffold the worktree, from the manifest only**: (multi-context) `CONTEXT-MAP.md` at the **worktree root**; for each manifest dir you designate a context that has no `CONTEXT.md` yet, a stub `<dir>/CONTEXT.md` (glossary header only) + `<dir>/adr/`. A `CONTEXT-MAP` link or term pointing at a path **not** in the manifest is flagged dangling and **not** created; that is the grounding guarantee.
6. Run `<skill-dir>/ctx-index.sh` to refresh `INDEX.md`.

You edit this context directly in the **context worktree**; `offload-context` commits + pushes it to the team remote.

### 6. Done

Tell user: machine-wide defaults block installed, already present, or updated from a drifted copy; which choices were recorded in the `## Agent skills` block and convention docs at the config home; where `domain.md` + context now live and which skills read them. Block and docs are plain markdown; edit them directly later; re-run only to switch **context store** / tracker or restart.
