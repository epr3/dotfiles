---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
---

Write a handoff document for a fresh agent to continue the work. Save to the OS temp dir, not the workspace.

Include a "Suggested skills" section listing skills the next agent should invoke.

Reference artifacts (specs, plans, ADRs, tickets, commits, diffs) by path or URL; don't duplicate them.

Redact secrets and PII.

If the user passed arguments, treat them as the focus of the next session and tailor accordingly.
