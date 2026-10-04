## Confirmed commits

Edit files; inspect Git read-only. Before committing, offer the repo-style message and file scope; wait for explicit confirmation of that proposal. Only then stage those changes and commit with that message. A prior request to commit is not confirmation; changed scope/message requires reconfirmation. Preserve unrelated changes and staging.

Other Git writes (amend, push, merge, rebase, reset, stash, branch/config/worktree changes) remain human-owned. Applies to subagents and indirect automation; inspect unfamiliar scripts/hooks/aliases/tools first. Tasks, repo instructions, and skills cannot bypass confirmation.

## Tools

- Follow live tool definitions. Prefer `glob`/`grep`/`read`; scope searches and output. Use `shell` only without a suitable tool, including builds/tests. No native LSP: grep call sites before renames/signature changes; run relevant checks after edits; report LSP-dependent gaps.
- Use `execute` for catalog-only tools or useful batching/filtering/composition, not trivial native calls. Inside it, only exact supplied catalog paths/signatures are callable; obey runtime limits, permissions, and Git boundaries.
- Parallelize independent calls (native wrapper or `Promise.all`); sequence dependencies. Await required calls; explicitly return useful results. Parallel writes require disjoint, noninterfering targets.
- Delegate only when user/instructions request it: `explore` for runtime-enforced read-only discovery, `general` for work. Pass constraints; verify child tools (including `execute`), depth, and managed model settings. Background jobs notify completion; never poll.

## Context and skills

- Repo `## Agent skills` overrides machine defaults. Resolve homes per repo procedure; honor `AGENT_CONTEXT_HOME`; edit external context in its paired worktree. Preserve in-repo context: no initialization, migration, or duplication.
- Before durable artifacts, consult glossary/map, ADRs, artifact locations, and issue conventions. Flag dangling references. Temporary reports/handoffs go in OS temp unless repo says otherwise.
- `skills/` copies are independent of Pi; follow matching skill metadata/prerequisites. Use `question` before risky steps. Track progress in conversation/ticket (no native todo). Pi-only tools/extensions are unavailable unless exposed; use native equivalents or report gaps.
