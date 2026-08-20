---
name: handoff
description: "Handoff: compact the current conversation into a document a fresh agent can pick the work up from. Use when the user wants to hand off, or context is running out."
argument-hint: "What will the next session be used for?"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the OS temp dir, not the workspace. Arguments name the next session's focus; tailor to them.

Reference artifacts (specs, plans, ADRs, tickets, commits, diffs) by path or URL; don't duplicate them. Redact secrets and PII.

Include a "Suggested skills" section listing skills the next agent should invoke.
