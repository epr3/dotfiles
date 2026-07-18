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

The context-store + ADR conventions the engineering skills rely on — repo-agnostic and personal, branch/worktree-independent like the store itself. This is the context side of setup: `setup-context` seeds each repo's `domain.md` into the store's `.agents/` and can install this block into your global Pi instructions (`~/.pi/agent/AGENTS.md`). The harness tooling — LSP usage + the Pi extensions — is separate: it ships as `pi-config/AGENTS.md`, which you paste into your Pi instructions directly.

---

## Agent skills

### Domain docs

Each repo's domain docs live in the **context store** — `domain.md` at the store's `.agents/domain.md` (seeded once per repo by `setup-context`, edit-in-place, branch-independent; in-repo context keeps it at `docs/agents/domain.md`, committed with the code). Glossaries + ADRs live in the branch worktrees; `offload-context` commits + pushes those to the team remote (skipped for in-repo context). Layout is self-describing: `CONTEXT-MAP.md` at the worktree root = multi-context, a lone `CONTEXT.md` = single. See CONTEXT-FORMAT.md.

### Context & ADRs (personal)

Domain context and ADRs live in a separate **context repo** by default (the recorded `## Agent skills` block — at the store's `.agents/agent-skills.md`, or the repo's instructions file when in-repo — written by `setup-context`, can override this per repo: e.g. in-repo context, or a real issue tracker): a bare git repo at `${AGENT_CONTEXT_HOME:-<your harness ctx dir>}/<org>__<repo>` with a `git worktree` paired 1:1 to each code branch. You **edit context directly in that worktree**; `offload-context` commits + pushes the branch to the team remote. You run the trunk merges (`merge-context` reconciles a branch into trunk, `rebase-context` rebases onto a moved base). Structure is grounded by the code manifest (`git ls-files`) — context only at real paths, dangling refs flagged not created. Set `AGENT_CONTEXT_HOME` in the environment Pi runs under to relocate or share the root. See CONTEXT-FORMAT.md.
