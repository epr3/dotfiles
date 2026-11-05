## Workflow

- Explore narrowly; note reversible assumptions and ask about consequential ambiguity or required authorization. Follow repo skills and prerequisites; search ignored `.scratch/` for specs.
- Favor simple, maintainable solutions: clear interfaces and errors, actionable docs, reproducible workflows, minimal dependencies.
- Batch proportionate checks and tests after changes; run earlier when useful. Report skipped or blocked checks and unverified behavior.
- Delegate when useful, handling simple tasks directly when delegation adds little value; use read-only agents for discovery, and honor an explicitly requested specialist. Track multi-step work; use structured questions for decisions.
- Keep every subagent at or below medium effort using a supported provider-specific effort level. Report an unavailable model or an unverifiable effort ceiling, switch to a verified compatible model and effort, and ask the user when no verified fallback exists.
- Route delegated review to a read-only reviewer that reports findings without fixes, and keep review findings separate from implementation; do not hand review to an agent that changes files.
- Route explicitly requested branch integration to a merger that integrates branches, resolves clear conflicts while reporting each resolution, escalates conflicts with multiple plausible resolutions to the requesting session instead of deciding, and runs integration checks.
- Route delegated research to a researcher that investigates against primary sources and reports findings with citations, or captures them as one cited research file when asked, without changing other repo work.

## Git

An explicit request to commit or to integrate authorizes the necessary local commits for that work: write concise repo-style messages, preserve unrelated changes and staging, and never let the request cover unrelated work; implementing a change alone does not authorize committing or integrating it. Pushing always requires separate approval. Other Git commands need no approval.

## Context

Repo `## Agent skills` choices override defaults. Check config-home `agent-skills.md` or repo instructions; resolve paths via the `domain-modeling` skill's `GLOSSARY-FORMAT.md`.

- Default: bare repo at `${AGENT_CONTEXT_HOME:-<harness context dir>}/<org>__<repo>`, worktree per branch; use `offload-context` to push and `merge-context` / `rebase-context` to reconcile.
- Keep unrecorded in-repo context in place; suggest `setup-context`.
- Consult config-home `domain.md`, `GLOSSARY-MAP.md` / `GLOSSARY.md` and `artifact-locations.md`. Use OS temp for reports and handoffs. Follow `git ls-files`; flag dangling references.

## Tools

- Batch with `codemode`; use direct tools for single calls.
- Use `lsp_*` for code navigation, grep/find for non-code; check references before renames or signature changes. Run diagnostics on changed code files and fix errors.
- Route delegated work to specialists: `explore` for read-only discovery, `implementer` to make changes and run relevant checks, `tester` to run checks, investigate failures, and report results without fixing implementation code, `reviewer` for delegated independent review, `merger` for explicitly requested branch integration, `researcher` for delegated research against primary sources, and `general` for anything else delegated. Use `question` and `todo_write` / `todo_read` for decisions and multi-step work.
