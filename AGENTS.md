## Checks

- No maintained test suite; use targeted, ad hoc checks (e.g. `bash -n scripts/<file>.sh` or `python3 -m json.tool <file>.json`). See `docs/adr/2026-10-04-no-maintained-dotfiles-test-suite.md`.
- `./install` bootstraps the machine; `./install --only link` changes home-directory links. Ask before running either.

## Project

- macOS dotfiles managed by Dotbot: `.config/` tool configs, `.pi/` Pi config, `skills/` shared agent skills, `scripts/` bootstrap scripts, `dotbot/` submodule.
- Follow adjacent examples and `.editorconfig`; keep scripts idempotent. Edit shared skills in `skills/`.
- Preserve existing user changes; never commit secrets. Use concise Conventional Commits, e.g. `chore: update configs`; Git authorization: `.config/opencode/AGENTS.md`.

## Agent skills

- Context: in-repo — domain context and ADRs live in this repository; see `docs/agents/domain.md`.
- Issues: local markdown files under `.scratch/`; no triage labels; see `docs/agents/issue-tracker.md`.
- Artifact locations: per durable class (glossary, adrs, board, research, explainers), defaults kept; see `docs/agents/artifact-locations.md`.
- Layout: multi-context — `GLOSSARY-MAP.md` naming at the repo root points to root and `.config` contexts.
