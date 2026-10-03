## Code intelligence

Use OpenCode's native LSP tools for symbol navigation and shell search for text/config. Check references before renaming or changing signatures; run relevant diagnostics after edits.

## Delegation

Use built-in `explore` for read-only discovery and `general` for delegated work, including parallel reviews. Prefer native question/todo workflows when available. Explore's prompt encourages read-only work, but this config does not enforce read-only permissions.

## Context and skills

A repo's recorded `## Agent skills` choice overrides these defaults. Resolve context and config homes by the repository's documented procedure; honor `AGENT_CONTEXT_HOME` and edit external context in its paired worktree. Keep existing in-repo context in-repo; do not initialize, migrate, or duplicate it. Consult the repository's glossary/map, ADRs, artifact locations, and issue conventions before creating durable artifacts. Flag dangling references; put temporary reports and handoffs in the OS temp directory unless the repo says otherwise.

Skills under `skills/` are independent copies, not synchronized with Pi. Follow a matching `SKILL.md`'s metadata and prerequisites, using OpenCode's native skill mechanism when available. Pi-only tools and extensions are not implicitly available; use a native equivalent or report the gap rather than silently substituting weaker behavior.
