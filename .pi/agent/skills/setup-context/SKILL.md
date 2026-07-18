---
name: setup-context
description: Configure this repo for the engineering skills — context home (store or in-repo), tickets/specs (local files or GitHub/GitLab/other), triage labels, domain-doc layout — then scaffold it. Installs the machine-wide `## Agent skills` block once. Run before first use of to-spec, to-tickets, triage, implement, code-review, wayfinder, tdd, or improve-codebase-architecture — or when those skills appear to be missing context about the issue tracker, triage labels, or where context lives. Defaults preserve current behaviour.
disable-model-invocation: true
---

# Setup Context

Scaffold the config the engineering skills assume. Prompt-driven — explore, present, confirm, write. Machine-wide conventions live in global config; per-repo choices (made below) are recorded as an `## Agent skills` block + convention docs in the **config home** (CONTEXT-FORMAT.md defines it) — every skill reads them without extra wiring. Defaults: context in the separate store, tickets as local files, no triage.

## Process

### 1. Global block — once per machine

The `## Agent skills` block (domain-docs / context+ADRs conventions) is machine-wide and repo-independent. Its home is your global Pi instructions, `~/.pi/agent/AGENTS.md`. (The harness tooling — LSP + the extension tools — is separate: it ships as `pi-config/AGENTS.md`, pasted in directly, not managed here.) Check it:

- block already present -> skip; note it's installed.
- absent -> offer to install. On confirm: append the `## Agent skills` block from [global-rules.md](./global-rules.md) to `~/.pi/agent/AGENTS.md` (create if missing). Update an existing block in place; never duplicate.

Optional — shared global context folder: set `AGENT_CONTEXT_HOME` (absolute path) in the environment Pi runs under (shell profile or launcher) to use one fixed folder instead of `~/.pi/agent/ctx`.

### 2. Explore

Check current state, don't assume:

- `git remote -v` + `.git/config` — GitHub? GitLab? which repo?
- the repo's own agent-instructions file — does an `## Agent skills` block from a prior run already exist? (Re-running updates it in place.)
- context repo (`${AGENT_CONTEXT_HOME:-<harness ctx dir>}/<slug>`, bare git repo; resolve per [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)) — does it exist already? a context worktree for the current branch? existing `domain.md` / `CONTEXT.md` / `CONTEXT-MAP.md`?
- in-tree `CONTEXT.md` / `CONTEXT-MAP.md` / `docs/adr/` in the code repo — either a prior in-repo choice or leftovers from an older setup; don't move anything yet, section A decides what it is.

### 3. Present + ask

Summarise present/missing. Walk decisions **one at a time** — present, answer, next. No dumping all at once. `question` tool if available, else prose (2–4 options, `(recommended)`, one-line reason, stop).

Assume user doesn't know terms. Each section: short explainer (what, why skills need it, what changes per choice), then choices + default.

**Section A — Context home.**

> Domain context + ADRs are what the skills read to orient and write as decisions crystallise. They can live in a **separate context store** (a bare git repo per code repo, one worktree per branch — personal, branch-aware, off the code tree; `offload-context` / `merge-context` / `rebase-context` manage it) or **in-repo** (a plain `CONTEXT.md` + `docs/adr/` committed with the code — simpler, team-shared by default, no store machinery, and the context skills above don't apply).

- **Context store** (default) — the suite's standard model; pick this unless you want context in the code repo.
- **In-repo** — `CONTEXT.md` / `CONTEXT-MAP.md` at the repo root, ADRs under `docs/adr/`, committed like any code.

If explore found in-tree context and the user picks **store**, offer to migrate it into the worktree; if they pick **in-repo**, it stays where it is.

**Store follow-up — parent branch.** The branch's context worktree forks off its *parent's* context, so it inherits that ancestry's glossary and ADRs — forking off the wrong parent means inheriting the wrong context. Detect the code branch's base (merge-base against likely parents; `main`/`master` when nothing closer), present it, and ask: fork off the detected parent, or name another branch. Default: the detected parent.

**Section B — Tickets & specs.**

> `to-spec` writes specs and `to-tickets` breaks them into tickets; `implement` picks tickets up, `code-review` reads them as the spec, and `wayfinder` keeps its planning map there. They need to know where that lives: local markdown (`.scratch/` in the context home from section A) or a real tracker.

- **Local files** (default) — `.scratch/<feature-slug>/` in the context home chosen above (its `SPEC.md` + `tickets/`); no external service, and whether they're kept or discarded is the user's call (conventions in [issue-tracker-local.md](./issue-tracker-local.md)).
- **GitHub** — issues in the repo's GitHub Issues via the `gh` CLI; specs stay local files. Conventions seed: [issue-tracker-github.md](./issue-tracker-github.md).
- **GitLab** — issues in GitLab Issues via the `glab` CLI; specs stay local files. Conventions seed: [issue-tracker-gitlab.md](./issue-tracker-gitlab.md).
- **Other** (Jira, Linear, …) — user describes the workflow in one paragraph; recorded as freeform prose for the skills to follow.

Propose the tracker matching the remote found in explore; local files when there's no remote or the user prefers.

If — and only if — a tracker (GitHub/GitLab) was picked, one follow-up: **PRs as a request surface** — yes / no (default no). Open-source repos often receive feature requests as pull requests; yes means `triage` pulls *external* PRs into the same queue, roles, and states as issues (collaborators' in-flight PRs are left alone). Record the answer in `issue-tracker.md` (config home). Local files / other: skip, there are no PRs.

**Section C — Triage labels** (only if section B chose a tracker, or local files and the user wants a triage flow — state then lives as a `Status:` line per ticket file).

> When issues live in a tracker, a small label vocabulary lets `to-tickets` mark what it creates, `implement` know what's safe to pick up, and the `triage` skill run its state machine. Skip it if you don't triage.

- **No triage** (default) — skills create/read tickets and issues with no label conventions.
- **Yes** — record the five canonical roles, each overridable to match existing labels (seed table: [triage-labels.md](./triage-labels.md)): `needs-triage` (maintainer evaluates), `needs-info` (waiting on reporter), `ready-for-agent` (fully specified, AFK-ready), `ready-for-human`, `wontfix`. `to-tickets` labels what it creates `needs-triage` (or `ready-for-agent` when fully specified); `implement` treats `ready-for-agent` as the pick-up signal.

**Section D — Domain docs layout.**

> The skills read `CONTEXT.md` for the project's domain language. Need to know: one global context or multiple (e.g. monorepo, separate frontend/backend) -> look in the right place.

- **Single-context** — one `CONTEXT.md` at the context-home root. Most repos.
- **Multi-context** — `CONTEXT-MAP.md` at the root -> per-context `CONTEXT.md` files (mirroring the code's dirs). Typically monorepo.

### 4. Confirm + edit

Show drafts, let the user edit before writing:

- the per-repo `## Agent skills` block (one line per decision from sections A–D, e.g. "Context: store" / "Issues: GitHub via `gh`, triage labels on — see `issue-tracker.md` in the config home" / "Layout: single-context")
- `issue-tracker.md` (always — from the seed matching section B) and, when triage is on, `triage-labels.md` — both at the config home (step 5)
- `domain.md` contents (from seed template [domain.md](./domain.md), filled for the chosen layout)

### 5. Write

**Record the choices** as an `## Agent skills` block, placed per the context home:

- **Store** (default) -> `.agents/agent-skills.md` at the **store root** (`$proj/.agents/`, beside the worktrees) — written once per context repo, used by all of its branch worktrees, never duplicated into them; skills read it when they orient — do **not** import or append it into the global CLAUDE.md/AGENTS.md or the repo's instructions file, it lives only in the store. The code repo stays untouched.
- **In-repo** -> the repo's instructions file, auto-loaded by the harness; its lines may reference the convention docs directly (e.g. "see `docs/agents/issue-tracker.md`") since both live in the repo. `AGENTS.md` at the repo root (Pi's per-project instructions); create it if missing, after confirming.

Either way: update an existing block in place — never duplicate, never touch surrounding content.

**Write the convention docs** into the **config home** — `$proj/.agents/` at the store root (default), or `docs/agents/` in the repo when context is in-repo — per the choices: `issue-tracker.md` is **always written** — from [issue-tracker-github.md](./issue-tracker-github.md), [issue-tracker-gitlab.md](./issue-tracker-gitlab.md), or [issue-tracker-local.md](./issue-tracker-local.md) to match section B, or from the user's description for "other". Triage on -> also `triage-labels.md` from [triage-labels.md](./triage-labels.md) with the user's mappings. Re-running updates them in place.

**Then scaffold the chosen context home.** In-repo choice: create `CONTEXT.md` (or `CONTEXT-MAP.md` + per-context stubs) and `docs/adr/` in the code repo, seed `domain.md` into `docs/agents/` (the config home, beside the convention docs), commit with the code — the store scripts below don't apply. Context-store choice (default): continue below.

Resolve `<slug>` from the code repo's origin (formula in [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)) and `proj="${AGENT_CONTEXT_HOME:-<harness ctx dir>}/<slug>"`.

Run every script below **by its path with cwd in the code repo** — they read the repo + branch from the cwd and locate their siblings themselves; don't `cd` into the skill folder (see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md) → *Where to run the scripts*).

1. **Ensure the store + worktree** — run `../setup-context/ctx-init.sh [team-remote]`, passing `--base <branch>` with the parent confirmed in section A whenever it differs from the auto-detected base (matching answer -> omit the flag, detection is the default). It ensures the bare context repo at `$proj/.git` (clones the team remote when given, else `git init --bare` + a seed) and a worktree for the current code branch at `$proj/<branch>`, forked off the parent's context so the ancestry's glossary/ADRs carry over. Prints the worktree path — **edit context there.**
2. **Build the manifest** — `../setup-context/manifest.sh` on the code repo: the set of real paths. This is the allowed-path universe.
3. **Inherited context** — the worktree was forked off its base, so it already carries the ancestry's glossary / ADRs. Nothing to copy. (A legacy per-branch `domain.md` found at the worktree root is from the old layout — move it to `.agents/domain.md`.)
4. **Write `domain.md` to `$proj/.agents/domain.md`** (create `.agents/` if missing) from the seed template [domain.md](./domain.md), its **Code repo** line filled with the origin URL + `<slug>`. This is at the store root, outside the worktree — the manifest doesn't govern it. Re-run: update in place.
5. **Scaffold the worktree, from the manifest only**: (multi-context) `CONTEXT-MAP.md` at the **worktree root**; for each manifest dir you designate a context that has no `CONTEXT.md` yet, a stub `<dir>/CONTEXT.md` (glossary header only) + `<dir>/adr/`. A `CONTEXT-MAP` link or term pointing at a path **not** in the manifest is flagged dangling and **not** created — that is the grounding guarantee.
6. Run `../setup-context/ctx-index.sh` to refresh `INDEX.md`.

You edit this context directly in the worktree; `offload-context` commits + pushes it to the team remote.

### 6. Done

Tell user: global block installed (or already present); which choices were recorded in the `## Agent skills` block and convention docs at the config home; where `domain.md` + context now live and which skills read them. Block and docs are plain markdown — edit them directly later; re-run only to switch context home / tracker or restart.
