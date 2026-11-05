## Workflow

- Explore narrowly; note reversible assumptions and ask about consequential ambiguity or required authorization. Follow repo skills and prerequisites; search ignored `.scratch/` for specs.
- Favor simple, maintainable solutions: clear interfaces and errors, actionable docs, reproducible workflows, minimal dependencies.
- Batch proportionate checks and tests after changes; run earlier when useful. Report skipped or blocked checks and unverified behavior.
- Delegate when useful, handling simple tasks directly when delegation adds little value; use read-only agents for discovery, and honor an explicitly requested specialist. Track multi-step work; use structured questions for decisions.
- Keep every subagent at or below medium effort using a supported provider-specific effort level. Report an unavailable model or an unverifiable effort ceiling, switch to a verified compatible model and effort, and ask the user when no verified fallback exists.

## Git

Before committing, obtain explicit approval of the exact repo-style message and file scope; renew if either changes. Preserve unrelated changes and staging. Other Git commands need no approval.

## Context

Repo `## Agent skills` choices override defaults. Check config-home `agent-skills.md` or repo instructions; resolve paths via the `domain-modeling` skill's `GLOSSARY-FORMAT.md`.

- Default: bare repo at `${AGENT_CONTEXT_HOME:-<harness context dir>}/<org>__<repo>`, worktree per branch; use `offload-context` to push and `merge-context` / `rebase-context` to reconcile.
- Keep unrecorded in-repo context in place; suggest `setup-context`.
- Consult config-home `domain.md`, `GLOSSARY-MAP.md` / `GLOSSARY.md` and `artifact-locations.md`. Use OS temp for reports and handoffs. Follow `git ls-files`; flag dangling references.

## Tools

- Batch with `codemode`; use direct tools for single calls.
- Use `lsp_*` for code navigation, grep/find for non-code; check references before renames or signature changes. Run diagnostics on changed code files and fix errors.
- Use `Agent` `explore` for discovery, `general` for delegated work; use `question` and `todo_write` / `todo_read` for decisions and multi-step work.
