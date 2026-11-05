## Agent skills

- Context: in-repo — domain context and ADRs live in this repository; see `docs/agents/domain.md`.
- Issues: local markdown files under `.scratch/`; no triage labels; see `docs/agents/issue-tracker.md`.
- Artifact locations: per durable class (glossary, adrs, board, research, explainers), defaults kept; see `docs/agents/artifact-locations.md`.
- Layout: multi-context — `GLOSSARY-MAP.md` naming at the repo root points to root and `.config` contexts.
- Commit proposals: concise Conventional Commit-style subjects (for example, `chore: update configs`); an explicit commit or integration request authorizes the necessary local commits under the Git rules in `.config/opencode/AGENTS.md`, while pushing keeps separate approval. An implementation request alone authorizes neither.
