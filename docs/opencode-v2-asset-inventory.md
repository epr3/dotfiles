# OpenCode v2 asset inventory and disposition

Historical inventory of **Curated Pi assets** initially copied into the Dotfile-managed OpenCode configuration at `.config/opencode/`, recorded per the `0002` ticket. "Copied" means byte-identical to the Pi source at inventory time; "adapted" means the copy changed harness vocabulary or machine-specific references while preserving triggers, prerequisites, and invocation intent. Counts and correspondence checks below describe those checkpoints, not a maintained parity contract. Since 2026-10-08, Pi and OpenCode assets are maintained independently; neither tree is the other's source of truth.

## Method

- Initial copy source: `.pi/agent/skills/` (29 directories, 62 files).
- Initial destination: `.config/opencode/skills/` (same 29 directories, 62 files, no symlinks).
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
| `implement` | adapted | Upstream refresh retained; OpenCode skill-loader wording for `tdd` and `code-review`. |
| `improve-codebase-architecture` | adapted | Skill-invocation wording. |
| `merge-context` | copied | |
| `offload-context` | copied | Includes `offload-context.sh`. |
| `pr` | copied | Includes `CREDITS.md` (Dex Horthy `show-me` attribution). |
| `prototype` | copied | |
| `rebase-context` | adapted | Harness-neutral context-root default. |
| `research` | copied | |
| `retro` | adapted | Skill-invocation wording. |
| `setup-context` | adapted | Global-instruction home → `~/.config/opencode/AGENTS.md`; context-root default; session claim `pi:$PI_SESSION_ID` → `opencode:<session-id>`; `ctx-init.sh`, `ctx-index.sh`, and `resolve-location.sh` defaults aligned to `${AGENT_CONTEXT_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/agent/ctx}`; `issue-tracker-local.md` seed documents the local ticket format and no-label mapping. |
| `tdd` | adapted | Skill-invocation wording. |
| `teach` | copied | |
| `to-questionnaire` | copied | |
| `to-spec` | copied | |
| `to-tickets` | copied | |
| `triage` | adapted | Skill-invocation wording. |
| `wait-what` | copied | |
| `wayfinder` | adapted | OpenCode skill-loader wording; the refreshed research-branch workflow pauses for human-owned branch creation and push. |
| `wizard` | copied | |
| `writing-for-agents` | copied | |

17 skills are byte-identical copies; 12 carry narrow, recorded adaptations. No prerequisite, trigger, or activation condition was removed.

Correspondence re-check (2026-10-04, after the pinned-parity restoration closed): all 18 differing files between the two trees were diffed line-by-line and every changed line is one of the recorded adaptations above (skill-invocation wording, AGENTS.md home, context-root default, session-claim ID, LSP generalization) — no other drift; the restored upstream content (tickets 0003–0005 of upstream-skill-parity, all committed before the copy was made) is present in both trees.

Refresh correspondence re-check (2026-10-08): the OpenCode copies of the refreshed retained skills were compared against Pi after updating the changed packages. Every skill directory remains present in both inventories; OpenCode-only adaptations are limited to skill-loader wording, the previously recorded harness/context substitutions, and the explicit human handoff for the refreshed wayfinder research-branch operation. The `implement` copy includes the refreshed ticket-reference instruction and OpenCode skill-loader wording. `retro` remains unchanged and present in both trees.

## Instructions

`.config/opencode/AGENTS.md` is independently maintained, not a counterpart to `.pi/agent/AGENTS.md`. Its four bullets cover commit approval, batching independent calls, native tools versus `execute` (Code Mode), and repo/skill context resolution. Global `AGENTS.md` loading was verified at the time by the since-retired `scripts/test-opencode-assets.sh`.

## Theme material

| Pi asset | Disposition | Notes |
| --- | --- | --- |
| `.pi/agent/themes/catppuccin-*.json` | native | Not copied. OpenCode ships the Catppuccin variants and exposes theme tokens to CLI plugins; `cli.json` selects the built-in `catppuccin`, and the footer adapter (ticket `0004`) consumes `context.theme` rather than a copied Pi palette. |

## Extensions

| Pi asset | Disposition | Notes |
| --- | --- | --- |
| `.pi/agent/extensions/rtk.ts` | rebuilt for v2 | Pi command-rewrite extension was **not** copied or loaded unchanged; ticket `0003` built a v2-approved equivalent at `.config/opencode/plugins/rtk.ts` (thin delegation to `rtk rewrite`; version floor, `RTK_DISABLED` env guard, advisory exit-3 accepted, timeout and fail-open preserved). Pi's file is byte-unchanged. |
| `.pi/agent/extensions/session-name/index.ts` | native | OpenCode generates session titles natively through its hidden `title` agent; the manual `/session-name` command has no v2 counterpart, and the hidden agent is now pinned to `opencode-go/qwen3.8-flash` variant `low` (see `docs/opencode-v2-workflows.md`). |
| `.pi/agent/extensions/usage.ts` | native | OpenCode tracks usage natively; footer usage display is ticket `0004`. |
| `pi-extensions` `subagents` | native | OpenCode `explore` / `general` subagents; model/reasoning preferences and hard read-only semantics verified (ticket `0003`). |
| `pi-extensions` `question` | native | OpenCode native question workflow present in the primary tool catalog (ticket `0003`). |
| `pi-extensions` `todo` | unsupported | **No native todo tool existed in v2.0.22** (the release migrated `todowrite` away as a removed v1 tool). Reported as a gap at that checkpoint. |
| `pi-extensions` `lsp` | unsupported | v2.0.22 exposed no agent-facing LSP tools (a config `lsp` key existed but yielded nothing tool-level). Reported as a gap at that checkpoint. |
| `pi-extensions` `web-fetch` | native | OpenCode `webfetch` tool; Pi's extraction-model selection has no v2 config surface (ticket `0003` gap report). |
| `pi-extensions` `web-search` | native | OpenCode `websearch` tool (ticket `0003`). |
| `pi-extensions` `statusline` | unsupported in Pi form | Rebuilt as an OpenCode CLI footer slot adapter, delivered at `.config/opencode/plugins/dumb-zone/` (ticket `0004`; zone contract per the 200k ADR, host-API patterns credited in `.config/opencode/CREDITS.md`). |
| `pi-extensions` `model-compaction` | unsupported in Pi form | OpenCode native compaction configuration (ticket `0005`). |
| `pi-extensions` `model-presets` | unsupported | No native preset/cycle mechanism verified on v2.0.22 (ticket `0003` gap report; per-session `--model provider/model#variant` is the manual mitigation). |

No Pi runtime extension or external Pi extension package is imported as an OpenCode plugin.

## Exclusions

Credentials, session databases, caches, installed packages/dependencies, and context worktrees are excluded by `.gitignore` and by the migration/backup scripts. `.config/opencode/skills/` contains no symlinks back to Pi; independence was asserted at the time by the since-retired `scripts/test-opencode-assets.sh`. Under the standing no-maintained-test-suite policy (`adr/2026-10-04-no-maintained-dotfiles-test-suite.md`), no automated assertion of this independence remains.

## Related

- `docs/opencode-v2-status.md` — verified vs unresolved migration status.
- `.config/opencode/CREDITS.md` — upstream and palette attribution.
