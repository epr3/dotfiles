## Workflow

- Be concise. Explore narrowly; state reversible assumptions and ask about consequential ambiguity or authorization. Follow repo skills and prerequisites; search ignored `.scratch/` for specs.
- Favor simple, maintainable solutions with clear errors, actionable docs, reproducible workflows, and minimal dependencies.
- Run proportionate checks; report skipped or blocked checks and unverified behavior.
- Delegate when useful; handle simple tasks directly, use read-only discovery, and honor explicitly requested specialists. Track multi-step work and use structured questions for decisions.
- Use each subagent's configured provider-specific effort. If its model or effort is unavailable, report it and use a verified fallback; ask if none exists.
- Route delegated review to a read-only reviewer, separate from implementation; integration explicitly requested by the user to a merger (report clear conflict resolutions, escalate ambiguous ones, run integration checks); and research to a researcher (primary sources, citations, no unrelated changes).

## Git

Explicit commit or integration requests and subagent workflows authorize necessary local commits. Use concise repo-style messages; preserve unrelated changes and staging. Other implementation requests authorize neither commits nor integration. Pushing requires separate approval; other Git commands do not.

## Context

Repo `## Agent skills` choices override defaults. Check config-home `agent-skills.md` or repo instructions; resolve paths via `domain-modeling`'s `GLOSSARY-FORMAT.md`.

- Default: bare repo at `${AGENT_CONTEXT_HOME:-<harness context dir>}/<org>__<repo>`, worktree per branch; use `offload-context` to push and `merge-context` / `rebase-context` to reconcile.
- Keep unrecorded in-repo context in place; suggest `setup-context`.
- Consult config-home `domain.md`, `GLOSSARY-MAP.md` / `GLOSSARY.md`, and `artifact-locations.md`. Use OS temp for reports and handoffs. Follow `git ls-files`; flag dangling references.

## Tools

- Prefer `execute` for catalog calls; batch independent calls with `Promise.allSettled` and chain dependent calls. Use native tools or the native parallel wrapper for non-catalog tools; await required calls.
- Use code intelligence for navigation; check references before renames or signature changes and run available diagnostics on changed code.
- Route delegated work to `explore` (read-only discovery), `implementer` (changes and checks), `tester` (checks and failure investigation without fixes), `reviewer`, `merger`, `researcher`, or `general` (other work).
- Search `.scratch/` explicitly or with `glob` using `hidden: true`.
