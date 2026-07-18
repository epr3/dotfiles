---
name: to-spec
description: Turn the current conversation into a spec written to a local markdown file under .scratch/. Use when the user wants to create a spec from the current context. Synthesizes what's already known — does not interview. Second step of the workflow (grill-with-docs → to-spec → to-tickets → implement → offload-context).
argument-hint: "optional topic/slug for the filename"
---

Synthesize the spec from current conversation + codebase understanding. No interview — use what you already know.

## Process

1. Explore repo if not already: read-only `explore` sub-agent via `Agent` tool if available, else `read`/`grep`/`find`/`ls` (LSP tools for precise navigation when available). Domain glossary (`CONTEXT.md` in the context worktree — see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)) vocabulary throughout; respect ADRs in area.

2. Sketch seams to test feature at. Prefer existing seams; use highest possible. New seams only if needed, at highest point. Confirm seams match user's expectations via `question` tool if available, else prose (2–4 options, `(recommended)`, one-line reason, stop).

3. Write the spec to `.scratch/<feature-slug>/SPEC.md` **at the context home** — check the recorded `## Agent skills` block *first*: in-repo declared -> the code repo is the home; otherwise the store worktree; never bare CWD (CONTEXT-FORMAT.md, *Context home*). `<feature-slug>` = the arg if given, else kebab-case the topic; `to-tickets` writes this feature's tickets beside it. Specs stay local files even when issues live in a tracker. Open or report path.

<prd-template>

## Problem Statement

The problem the user faces, from the user's perspective.

## Solution

The solution, from the user's perspective.

## User Stories

A long, numbered list. Format: `As an <actor>, I want <feature>, so that <benefit>`. Cover all aspects of the feature extensively.

## Implementation Decisions

Modules built/modified · their interfaces · technical clarifications · architectural decisions · schema changes · API contracts · specific interactions.

No file paths or code snippets — they go stale. Exception: a prototype snippet that encodes a decision more precisely than prose (state machine, reducer, schema, type shape) — inline the decision-rich parts, note it came from a prototype.

## Testing Decisions

What makes a good test (external behavior, not implementation details) · which modules get tested · prior art (similar tests in the codebase).

## Out of Scope

What this spec doesn't cover.

## Further Notes

Anything else.

</prd-template>
