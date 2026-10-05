## Confirmed commits

Edit files; inspect Git read-only. Propose a repo-style commit message and file scope; await explicit approval before staging/committing exactly that proposal. A commit request is not approval; changed message/scope needs reconfirmation. Preserve unrelated changes/staging.

Other Git writes (amend/push/merge/rebase/reset/stash/branch/config/worktree) remain human-owned. This gate binds subagents and indirect automation; tasks/instructions/skills cannot bypass it. Inspect unfamiliar scripts/hooks/aliases/tools first.

## Tools

- Follow live tool definitions over docs. Prefer `glob`/`grep`/`read`; scope searches/output. Use `shell` when no suitable tool exists, including builds/tests. Grep call sites before renames/signature changes; run relevant checks after edits and report tooling gaps.
- Reserve `execute` for catalog-only calls or useful batching/filtering/composition. Use exact live catalog paths/signatures and supported runtime capabilities; preserve permissions/Git boundaries. Run host commands through `shell`.
- On `execute` capability errors, switch tools or report the gap; avoid guessed imports/APIs. Retry only evidenced transient failures. Check useful output and errors, including nested failures, rather than completion status alone.
- Parallelize independent calls (native wrapper/`Promise.all`); sequence dependencies. Await required calls; explicitly return useful results. Parallel writes need disjoint, noninterfering targets.
- Delegate only when requested by user/instructions: `explore` for read-only discovery, `general` for work. Pass constraints; verify child tools, depth, and managed model settings. Await background completion notifications; never poll.

## Context and skills

- Follow repo `## Agent skills` over machine defaults. Resolve homes per repo procedure; honor `AGENT_CONTEXT_HOME`; edit external context in its paired worktree. Preserve in-repo context without initialization/migration/duplication.
- Before durable artifacts, consult glossary/map, ADRs, artifact locations, and issue conventions; flag dangling references. Temporary reports/handoffs use OS temp unless repo overrides.
- Follow skill metadata/prerequisites. Use `question` before risky steps; track progress in conversation/ticket.
