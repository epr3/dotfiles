## Workflow efficiency

- Prefer `codemode` for batching, chaining, and filtering; use direct tools for single calls.
- Make and note reversible assumptions for routine choices. Ask when ambiguity affects the outcome, a decision is consequential, or authorization is required.
- Explore narrowly; expand as needed.
- Verify proportionately: lightweight checks for low-risk config and docs, targeted checks for code. Report skipped or blocked checks; never claim unverified behavior passes.

## Git and commits

Before committing, propose the exact repo-style message and file scope; get explicit approval, renewed if either changes. Preserve unrelated changes and staging. Other Git commands need no approval.

## Code intelligence

Use `lsp_*` for code navigation; grep/find for non-code. Check `lsp_references` before renaming a symbol or changing its signature. Run `lsp_diagnostics` on each changed code file and fix errors.

## Subagents

Delegate only when a workflow or skill requires it, or for clear benefit. Use `Agent` `explore` for read-only discovery and `general` for delegated work, including code review. Use `question` for discrete decisions and `todo_write` / `todo_read` for multi-step work.

## Context and ADRs

A repo's recorded `## Agent skills` choice overrides these defaults: check the config home's `agent-skills.md` for a context repo or repo instructions for in-repo context. Resolve paths using *Resolving the context store* in the `domain-modeling` skill's `GLOSSARY-FORMAT.md`.

- Default to a bare context repo at `${AGENT_CONTEXT_HOME:-<harness context dir>}/<org>__<repo>`, with a paired worktree per code branch. Edit in that worktree; push with `offload-context` and reconcile with `merge-context` / `rebase-context`.
- Existing in-repo context without recorded setup stays in-repo. Use it and suggest `setup-context`; do not migrate or initialize a context repo.
- Domain docs live at `domain.md` in the config home. Consult `GLOSSARY-MAP.md` / `GLOSSARY.md` and `artifact-locations.md` for layout and destinations. Put temporary reports and handoffs in the OS temp directory.
- Follow `git ls-files` for context structure; flag dangling references rather than creating paths. `AGENT_CONTEXT_HOME` relocates the context root when set in Pi's environment.
