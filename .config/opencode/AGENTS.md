## Code intelligence

Use the native search tools for everything related to code navigation: `glob` for file-pattern discovery, `grep` for text, config, and non-code searches, and `read` for source inspection. OpenCode v2 exposes no agent-facing LSP tools (no `lsp_*` equivalents): to check references before renaming or changing signatures, grep for call sites; to surface type or build errors after edits, run the relevant build, compiler, or test commands with `shell` and fix what they report. Report any decided-upon LSP dependency as an explicit gap rather than assuming tooling exists.

## Subagents and delegation

Use native `subagent` with the built-in `explore` and `general` subagents: `explore` for read-only discovery, `general` for delegated work. `explore`'s read-only behavior is enforced by its runtime toolset (read/search/web only — no edit, write, shell, question, or subagent tools in v2); do not treat it as a prompt promise. `background: true` runs children asynchronously; nested subagent launching is limited to the configured depth (default 1). Subagent model and reasoning preferences come from the managed `agents` configuration.

## Context, skills, and tools

OpenCode's native toolset includes Code Mode (`execute` tool: call and combine catalog tools in JS), `question` for discrete user decisions, webfetch/websearch, and the `skill` tool for loading skills. A repo's recorded `## Agent skills` choice overrides machine defaults. Resolve context and config homes by the repository's documented procedure; honor `AGENT_CONTEXT_HOME` and edit external context in its paired worktree. Keep existing in-repo context in-repo; do not initialize, migrate, or duplicate it. Consult the repository's glossary/map, ADRs, artifact locations, and issue conventions before creating durable artifacts. Flag dangling references; put temporary reports and handoffs in the OS temp directory unless the repo says otherwise.

Skills under `skills/` are independent copies, not synchronized with Pi. Follow a matching `SKILL.md`'s metadata and prerequisites. There is no native todo tool in OpenCode v2: track multi-step work in the conversation (restating the plan and crossing items off) or via the issuing ticket, and surface a question before risky steps. Pi-only tools and extensions (codemode-as-namespace, `tool_search`, `lsp_*`, `todo_*`, model presets) are not implicitly available; use the native equivalent where one exists and report the gap rather than silently substituting weaker behavior.
