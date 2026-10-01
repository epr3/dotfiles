## Code intelligence

Use `lsp_*` tools for code navigation; use grep/find for text, config, and other non-code searches. Before renaming a symbol or changing its signature, check `lsp_references`. After edits, run `lsp_diagnostics` on each changed code file and fix reported errors.

## Subagents

Use `Agent` (`explore` for read-only discovery; `general` for delegated work, including code-review axes). Use `question` for discrete decisions and `todo_write` / `todo_read` for multi-step work.

## Context and ADRs

A repo's recorded `## Agent skills` choice overrides these machine-wide defaults. Resolve it in the config home's `agent-skills.md` for a context repo, or the repo's instructions file for in-repo context. If no choice is recorded, use the context-repo default below—except that existing in-tree context stays in-repo. For path resolution, follow *Resolving the context store* in `GLOSSARY-FORMAT.md` in the `domain-modeling` skill.

- Resolve the context home and config home per that procedure; do not assume paths.
- The default context store is a bare repo at `${AGENT_CONTEXT_HOME:-<harness context dir>}/<org>__<repo>`, with one worktree per code branch. Edit context in its paired worktree. `offload-context` pushes it; use `merge-context` and `rebase-context` to reconcile branches.
- Existing in-repo context without recorded setup remains in-repo: read and use it; do not migrate or initialize a context repo. Suggest `setup-context` to record the choice.
- Domain docs live at `domain.md` in the config home. Context layout and artifact destinations are declared by `GLOSSARY-MAP.md` / `GLOSSARY.md` and `artifact-locations.md`; consult them rather than assuming destinations. Temporary reports and handoffs go in the OS temp directory.
- Context structure follows `git ls-files`; flag dangling references instead of creating paths. `AGENT_CONTEXT_HOME` relocates the context root when set in Pi's environment.
