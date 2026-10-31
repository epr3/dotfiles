## Workflow efficiency

- Make reasonable, reversible assumptions instead of asking; do not ask for routine choices. Note the assumption so it can be reversed if it proves wrong.
- Start exploration narrowly and expand only when warranted: read the specific files or sections the task needs first, and widen deliberately rather than loading context "in case".
- Verify proportionate to risk: lightweight checks (syntax or JSON parse, a reference check, a quick smoke run) for low-risk config and doc edits, targeted checks for code changes. Report skipped or blocked checks as such; do not present unverified behavior as passing.
- Ask when ambiguity affects the outcome, a decision is consequential, or authorization is required. Routine choices do not justify a question.
- Do not delegate routinely; see Subagents for what justifies a subagent.

## Git and commits

Before committing, propose the exact repo-style message and file scope; commit only after explicit approval. Renew approval if either changes. Preserve unrelated changes and existing staging. Staging and other Git commands need no approval.

## Code intelligence

Use `lsp_*` tools for code navigation; use grep/find for text, config, and other non-code searches. Before renaming a symbol or changing its signature, check `lsp_references`. After edits, run `lsp_diagnostics` on each changed code file and fix reported errors.

## Subagents

Do not delegate routinely: every subagent costs tokens and context. Use `Agent` (`explore` for read-only discovery; `general` for delegated work, including code-review axes) only when an explicit workflow or skill requires delegation or there is clear benefit. Use `question` for the discrete decisions that must be surfaced, and `todo_write` / `todo_read` for multi-step work.

## Context and ADRs

A repo's recorded `## Agent skills` choice overrides these machine-wide defaults. Resolve it in the config home's `agent-skills.md` for a context repo, or the repo's instructions file for in-repo context. If no choice is recorded, use the context-repo default below—except that existing in-tree context stays in-repo. For path resolution, follow *Resolving the context store* in `GLOSSARY-FORMAT.md` in the `domain-modeling` skill.

- Resolve the context home and config home per that procedure; do not assume paths.
- The default context store is a bare repo at `${AGENT_CONTEXT_HOME:-<harness context dir>}/<org>__<repo>`, with one worktree per code branch. Edit context in its paired worktree. `offload-context` pushes it; use `merge-context` and `rebase-context` to reconcile branches.
- Existing in-repo context without recorded setup remains in-repo: read and use it; do not migrate or initialize a context repo. Suggest `setup-context` to record the choice.
- Domain docs live at `domain.md` in the config home. Context layout and artifact destinations are declared by `GLOSSARY-MAP.md` / `GLOSSARY.md` and `artifact-locations.md`; consult them rather than assuming destinations. Temporary reports and handoffs go in the OS temp directory.
- Context structure follows `git ls-files`; flag dangling references instead of creating paths. `AGENT_CONTEXT_HOME` relocates the context root when set in Pi's environment.
