## Code intelligence

`lsp_*` tools available -> prefer over grep/find/read for code navigation — compiler's understanding, not text matching:

- `lsp_definition` — symbol's declaration; `lsp_implementation` — concrete code behind interface/abstract member
- `lsp_references` — every usage across codebase
- `lsp_workspace_symbols` — find by name when file unknown
- `lsp_document_symbols` — file outline before reading whole
- `lsp_hover` — type/signature/docs without opening file
- `lsp_incoming_calls` / `lsp_outgoing_calls` — who calls this, what this calls

Positions: 1-based `file:line:column`.

**Before** any rename/signature change -> `lsp_references` on it (grep misses dynamic + re-exported usages, over-matches common names). **After** writing/editing -> `lsp_diagnostics` per touched file; fix type errors + missing imports immediately, before moving on.

Grep/find for what server can't see: comments, strings, config values, TODOs, log messages, non-code files.

## Sub-agents & tooling

This harness exposes extension tools — prefer them over doing everything in the main context:

- **`Agent`** — spawn an isolated sub-agent to keep the main context clean. `subagent_type: "explore"` = read-only codebase discovery, `"researcher"` = read-only web/external research (grounded against the code), `"general"` = off-context work that may write. Foreground blocks and returns the result; `run_in_background: true` returns an id you poll with `get_subagent_result`. Reach for explore/researcher before large inline reads or web digs.
- **`question`** — when a decision needs the user, ask through `question` (2–4 mutually-exclusive options, recommended one first), not free prose.
- **`todo_write` / `todo_read`** — track multi-step work as an explicit list so the plan survives context pressure; update entries as steps complete.
# Global rules — context store (install once per machine, personal, not per-repo)

The context-store + ADR conventions the engineering skills rely on — repo-agnostic and personal, branch/worktree-independent like the store itself; this is the context side of setup, what `setup-context` establishes. Pi layers global and project instruction files, and `~/.pi/agent/AGENTS.md` keeps applying when a repo has its own instruction file, so it's the right home. The harness tooling (LSP usage) is separate: it ships as `pi-config/AGENTS.md`, pasted into your instructions directly.

Install: paste the `## Agent skills (defaults)` block below into `~/.pi/agent/AGENTS.md`.

---

## Agent skills (defaults)

**Precedence.** A repo's own `## Agent skills` block wins. This block is the machine-wide default and applies only when the repo has no block of its own; it supplies the **context store** model, never a path. Resolve **context home** and **config home** per repo with the numbered procedure in CONTEXT-FORMAT.md (*Resolving the context store*), which reads the code repo first.

### Domain docs

Each repo's domain docs live at `domain.md` in its **config home** — `.agents/domain.md` at the **context repo** root, or `docs/agents/domain.md` under **in-repo context**, committed with the code. Seeded once per repo by `setup-context`, edit-in-place, branch-independent. Glossaries + ADRs live in the **context worktree**s instead; `offload-context` commits + pushes those to the team remote (skipped under **in-repo context**). Layout is self-describing: `CONTEXT-MAP.md` at the **context home** root = multi-context, a lone `CONTEXT.md` = single.

### Context & ADRs (personal)

The default **context store** is a **context repo** (the recorded `## Agent skills` block — at the **config home**'s `agent-skills.md`, or the repo's instructions file under **in-repo context** — written by `setup-context`, overrides this per repo: e.g. in-repo context, or a real issue tracker): a bare git repo at `${AGENT_CONTEXT_HOME:-<your harness ctx dir>}/<org>__<repo>` with one **context worktree** paired 1:1 to each code branch. You **edit context directly in that worktree**; `offload-context` commits + pushes the branch to the team remote. You run the trunk merges (`merge-context` reconciles a branch into trunk, `rebase-context` rebases onto a moved base). Structure is grounded by the code manifest (`git ls-files`) — context only at real paths, dangling refs flagged not created. **Unconfigured repo with in-tree docs** (a `CONTEXT.md` / `docs/adr/` in the code tree but no recorded block anywhere): treat the in-tree docs as the context and read them — don't init a **context repo** or migrate anything uninvited; suggest running `setup-context` once to record the choice. `AGENT_CONTEXT_HOME` points at the **context root**; set it in the environment Pi runs under to relocate or share that root.
