# Global rules — context store (install once per machine, personal, not per-repo)

The context-store + ADR conventions the engineering skills rely on — repo-agnostic and personal, branch/worktree-independent like the store itself. This is the context side of setup: `setup-context` seeds each repo's `domain.md` into the store's `.agents/` and can install this block into your global Pi instructions (`~/.pi/agent/AGENTS.md`). The harness tooling — LSP usage + the Pi extensions — is separate: it ships as `pi-config/AGENTS.md`, which you paste into your Pi instructions directly.

---

## Agent skills

### Domain docs

Each repo's domain docs live in the **context store** — `domain.md` at the store's `.agents/domain.md` (seeded once per repo by `setup-context`, edit-in-place, branch-independent; in-repo context keeps it at `docs/agents/domain.md`, committed with the code). Glossaries + ADRs live in the branch worktrees; `offload-context` commits + pushes those to the team remote (skipped for in-repo context). Layout is self-describing: `CONTEXT-MAP.md` at the worktree root = multi-context, a lone `CONTEXT.md` = single. See CONTEXT-FORMAT.md.

### Context & ADRs (personal)

Domain context and ADRs live in a separate **context repo** by default (the recorded `## Agent skills` block — at the store's `.agents/agent-skills.md`, or the repo's instructions file when in-repo — written by `setup-context`, can override this per repo: e.g. in-repo context, or a real issue tracker): a bare git repo at `${AGENT_CONTEXT_HOME:-<your harness ctx dir>}/<org>__<repo>` with a `git worktree` paired 1:1 to each code branch. You **edit context directly in that worktree**; `offload-context` commits + pushes the branch to the team remote. You run the trunk merges (`merge-context` reconciles a branch into trunk, `rebase-context` rebases onto a moved base). Structure is grounded by the code manifest (`git ls-files`) — context only at real paths, dangling refs flagged not created. **Unconfigured repo with in-tree docs** (a `CONTEXT.md` / `docs/adr/` in the code tree but no recorded block anywhere): treat the in-tree docs as the context and read them — don't init a store or migrate anything uninvited; suggest running `setup-context` once to record the choice. Set `AGENT_CONTEXT_HOME` in the environment Pi runs under to relocate or share the root. See CONTEXT-FORMAT.md.
