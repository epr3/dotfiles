# OpenCode v2 asset inventory and disposition

Inventory of **Curated Pi assets** copied into the Dotfile-managed OpenCode configuration at `.config/opencode/`, recorded per the `0002` ticket. "Copied" means byte-identical to the Pi source at inventory time; "adapted" means the copy changes harness vocabulary or machine-specific references while preserving triggers, prerequisites, and invocation intent. Pi remains unchanged and there is no ongoing synchronization between the two trees (`GLOSSARY.md` → **Curated Pi assets**; spec `Further Notes`).

## Method

- Source of truth for skills: `.pi/agent/skills/` (29 directories, 62 files).
- Destination: `.config/opencode/skills/` (same 29 directories, 62 files, no symlinks).
- Disposition computed by directory-level `diff -rq` at inventory time. Referenced support files resolve relative to `SKILL.md`; the tree structure is preserved.
- Runtime state, credentials, sessions, caches, installed packages, and context worktrees are excluded (see `.gitignore` and the "Exclusions" section).

## Skills

| Skill | Disposition | Notes |
| --- | --- | --- |
| `code-review` | copied | |
| `codebase-design` | copied | |
| `diagnosing-bugs` | copied | Includes `scripts/hitl-loop.template.sh`. |
| `domain-modeling` | adapted | `GLOSSARY-FORMAT.md`: Pi LSP tool names generalized to "native references / workspace-symbol lookup". |
| `explain-diff` | copied | |
| `grill-me` | adapted | "Call the Skill tool" → "Read the OpenCode skill named …". |
| `grill-with-docs` | adapted | Skill-invocation wording. |
| `grilling` | copied | |
| `handoff` | adapted | Skill-invocation wording. |
| `implement` | copied | |
| `improve-codebase-architecture` | adapted | Skill-invocation wording. |
| `merge-context` | copied | |
| `offload-context` | copied | Includes `offload-context.sh`. |
| `pr` | copied | Includes `CREDITS.md` (Dex Horthy `show-me` attribution). |
| `prototype` | copied | |
| `rebase-context` | adapted | Harness-neutral context-root default. |
| `research` | copied | |
| `retro` | adapted | Skill-invocation wording. |
| `setup-context` | adapted | Global-instruction home → `~/.config/opencode/AGENTS.md`; context-root default; session claim `pi:$PI_SESSION_ID` → `opencode:<session-id>`; `ctx-init.sh`, `ctx-index.sh`, and `resolve-location.sh` defaults aligned to `${AGENT_CONTEXT_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/agent/ctx}`. |
| `tdd` | adapted | Skill-invocation wording. |
| `teach` | copied | |
| `to-questionnaire` | copied | |
| `to-spec` | copied | |
| `to-tickets` | copied | |
| `triage` | adapted | Skill-invocation wording. |
| `wait-what` | copied | |
| `wayfinder` | adapted | Skill-invocation wording. |
| `wizard` | copied | |
| `writing-for-agents` | copied | |

18 skills are byte-identical copies; 11 carry narrow, recorded adaptations. No prerequisite, trigger, or activation condition was removed.

## Instructions

| Pi asset | Disposition | OpenCode mechanism |
| --- | --- | --- |
| `.pi/agent/AGENTS.md` | adapted | `.config/opencode/AGENTS.md`, loaded as the v2 **global** `AGENTS.md`. Pi tool names were rewritten to what v2.0.22 actually exposes (grep/read navigation — no agent-facing LSP tools; `explore`/`general` subagents; `question`; conversation-tracked plans — no native todo tool), per the ticket `0003` runtime verification. The v2 `instructions` config array is accepted but **not resolved** by V2, so it is not used; `AGENTS.md` is the supported mechanism and is verified by `scripts/test-opencode-assets.sh`. |

## Theme material

| Pi asset | Disposition | Notes |
| --- | --- | --- |
| `.pi/agent/themes/catppuccin-*.json` | native | Not copied. OpenCode ships the Catppuccin variants and exposes theme tokens to CLI plugins; `cli.json` selects the built-in `catppuccin`, and the footer adapter (ticket `0004`) consumes `context.theme` rather than a copied Pi palette. |

## Extensions

| Pi asset | Disposition | Notes |
| --- | --- | --- |
| `.pi/agent/extensions/rtk.ts` | rebuilt for v2 | Pi command-rewrite extension was **not** copied or loaded unchanged; ticket `0003` built a v2-approved equivalent at `.config/opencode/plugins/rtk.ts` (thin delegation to `rtk rewrite`; version floor, `RTK_DISABLED` env guard, advisory exit-3 accepted, timeout and fail-open preserved). Pi's file is byte-unchanged. |
| `.pi/agent/extensions/session-name/index.ts` | native | OpenCode generates session titles natively. |
| `.pi/agent/extensions/usage.ts` | native | OpenCode tracks usage natively; footer usage display is ticket `0004`. |
| `pi-extensions` `subagents` | native | OpenCode `explore` / `general` subagents; model/reasoning preferences and hard read-only semantics verified (ticket `0003`). |
| `pi-extensions` `question` | native | OpenCode native question workflow present in the primary tool catalog (ticket `0003`). |
| `pi-extensions` `todo` | unsupported | **No native todo tool exists in v2.0.22** (the release migrates `todowrite` away as a removed v1 tool). Reported as a gap; `AGENTS.md` tells agents to track multi-step work in conversation. |
| `pi-extensions` `lsp` | unsupported | v2.0.22 exposes no agent-facing LSP tools (a config `lsp` key exists but yields nothing tool-level). Reported as a gap; grep + build/test commands replace them per the adapted instructions (ticket `0003`). |
| `pi-extensions` `web-fetch` | native | OpenCode `webfetch` tool; Pi's extraction-model selection has no v2 config surface (ticket `0003` gap report). |
| `pi-extensions` `web-search` | native | OpenCode `websearch` tool (ticket `0003`). |
| `pi-extensions` `statusline` | unsupported in Pi form | Rebuilt as an OpenCode CLI footer slot adapter (ticket `0004`). |
| `pi-extensions` `model-compaction` | unsupported in Pi form | OpenCode native compaction configuration (ticket `0005`). |
| `pi-extensions` `model-presets` | unsupported | No native preset/cycle mechanism verified on v2.0.22 (ticket `0003` gap report; per-session `--model provider/model#variant` is the manual mitigation). |

No Pi runtime extension or external Pi extension package is imported as an OpenCode plugin.

## Exclusions

Credentials, session databases, caches, installed packages/dependencies, and context worktrees are excluded by `.gitignore` and by the migration/backup scripts. `.config/opencode/skills/` contains no symlinks back to Pi; independence is asserted by `scripts/test-opencode-assets.sh`.

## Related

- `docs/opencode-v2-status.md` — verified vs unresolved migration status.
- `.config/opencode/CREDITS.md` — upstream and palette attribution.
- `.scratch/opencode-v2-pi-parity/spec.md` — parent scope.
