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
