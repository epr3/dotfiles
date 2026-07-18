---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a cited Markdown note in the context home. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

# Research

Spin up a **background agent** to do the research, so you keep working while it reads.

Use `Agent` with `subagent_type: "general"` and `run_in_background: true` — general carries the web tools (`web_search` / `web_fetch`) and can write, so it investigates and writes the note itself. Poll with `get_subagent_result` while you keep working.

Its job:

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown note, citing each claim's source.
3. Save it into the context home alongside your other notes — this branch's context worktree by default, or the repo's context location if the repo's `## Agent skills` block puts context in-repo (see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)). Match the existing convention there; if there's none, put it somewhere sensible and say where.

**Already running inside a sub-agent** (sub-agents can't spawn further)? Do the research yourself, directly, to the same brief — primary sources, cited note, same destination.
