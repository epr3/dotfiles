# Global rules: context store (install once per machine, personal, not per-repo)

The context-store + ADR conventions the engineering skills rely on (repo-agnostic and personal, branch/worktree-independent like the store itself); this is the context side of setup, what `setup-context` establishes. OpenCode layers global and project instruction files, and `~/.config/opencode/AGENTS.md` keeps applying when a repo has its own instruction file, so it's the right home. Harness-specific tooling instructions are separate and should use the native capabilities available in the current harness.

Install: paste the `## Agent skills (defaults)` block below into `~/.config/opencode/AGENTS.md`.

---

## Agent skills (defaults)

**Precedence.** A repo's own `## Agent skills` block wins. This block is the machine-wide default and applies only when the repo has no block of its own; it supplies the **context store** model, never a path. Resolve **context home** and **config home** per repo with the numbered procedure in GLOSSARY-FORMAT.md (*Resolving the context store*), which reads the code repo first.

### Domain docs

Each repo's domain docs live at `domain.md` in its **config home** (`.agents/domain.md` at the **context repo** root, or `docs/agents/domain.md` under **in-repo context**), committed with the code. Seeded once per repo by `setup-context`, edit-in-place, branch-independent. Glossaries + ADRs live in the **context worktree**s by default; `offload-context` commits + pushes those to the team remote (skipped under **in-repo context**). Each durable artifact class (glossary, adrs, board, research, explainers) records its own destination in `artifact-locations.md` at the **config home**, resolved per class with `setup-context/resolve-location.sh`; defaults equal the pre-existing effective destinations. Temporary reports and handoffs use the OS temp directory. Layout is self-describing: `GLOSSARY-MAP.md` at the **context home** root = multi-context, a lone `GLOSSARY.md` = single.

### Context & ADRs (personal)

The default **context store** is a **context repo** (the recorded `## Agent skills` block, at the **config home**'s `agent-skills.md`, or the repo's instructions file under **in-repo context**, written by `setup-context`, overrides this per repo: e.g. in-repo context, or a real issue tracker): a bare git repo at `${AGENT_CONTEXT_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/agent/ctx}/<org>__<repo>` with one **context worktree** paired 1:1 to each code branch. You **edit context directly in that worktree**; `offload-context` commits + pushes the branch to the team remote. You run the trunk merges (`merge-context` reconciles a branch into trunk, `rebase-context` rebases onto a moved base). Structure is grounded by the code manifest (`git ls-files`): context only at real paths, dangling refs flagged not created. **Unconfigured repo with in-tree docs** (a `GLOSSARY.md` / `GLOSSARY-MAP.md` / `docs/adr/` in the code tree but no recorded block anywhere): treat the in-tree docs as the context and read them. Don't init a **context repo** or migrate anything uninvited; suggest running `setup-context` once to record the choice. `AGENT_CONTEXT_HOME` points at the **context root**; set it in the environment OpenCode runs under to relocate or share that root.
