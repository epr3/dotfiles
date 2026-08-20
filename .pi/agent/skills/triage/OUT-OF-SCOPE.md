# Out-of-Scope Knowledge Base

The `out-of-scope/` directory in a repository's **config home** stores persistent records of rejected feature requests. It serves two purposes:

1. **Institutional memory**: why a feature was rejected, so the reasoning is not lost when the issue is closed.
2. **Deduplication**: when a new issue matches a prior rejection, triage can surface the earlier decision instead of re-litigating it.

## Directory structure

```text
<config-home>/out-of-scope/
├── dark-mode.md
├── plugin-system.md
└── graphql-api.md
```

One file per **concept**, not per issue. Multiple issues requesting the same thing are grouped under one file.

## File format

Write a relaxed, readable document, more like a short design note than a database entry. Use paragraphs, code samples, and examples to make the reasoning clear to someone encountering it for the first time.

```markdown
# Dark Mode

This project does not support dark mode or user-facing theming.

## Why this is out of scope

The rendering pipeline assumes a single color palette defined in
`ThemeConfig`. Supporting multiple themes would require:

- A theme context provider wrapping the entire component tree
- Per-component theme-aware style resolution
- A persistence layer for user theme preferences

This is a significant architectural change that does not align with the
project's focus on content authoring. Theming is a concern for downstream
consumers who embed or redistribute the output.

## Prior requests

- #42: "Add dark mode support"
- #87: "Night theme for accessibility"
- #134: "Dark theme option"
```

### Naming the file

Use a short, descriptive kebab-case name for the concept: `dark-mode.md`, `plugin-system.md`, `graphql-api.md`. The name should let someone browsing the directory understand what was rejected without opening the file.

### Writing the reason

The reason should be substantive: not "we do not want this," but why. Good reasons reference:

- Project scope or philosophy
- Technical constraints
- Strategic decisions

The reason must be durable. Avoid temporary circumstances such as being too busy; those are deferrals, not rejections.

## When to check `out-of-scope/`

During triage's Gather step, read the knowledge-base records. When evaluating a new issue:

- Match by concept similarity, not keywords: "night theme" matches `dark-mode.md`.
- Surface a match to the maintainer with its prior reason.

The maintainer may:

- **Confirm**: add the new issue to the existing record's **Prior requests**, then close it.
- **Reconsider**: delete or update the record, then continue normal triage.
- **Disagree**: treat the issues as distinct and continue normal triage.

## When to write to `out-of-scope/`

Write a record only when an **enhancement** is rejected as `wontfix`. A rejected enhancement PR is recorded the same way as an issue, so the same request does not return as fresh code.

Do not write a record when an issue is `wontfix` because it is **already implemented**. Point the closing comment to the existing feature instead.

The flow:

1. The maintainer decides an enhancement is out of scope.
2. Check for a matching record.
3. Append the request to **Prior requests** if one exists; otherwise create a record with the concept, decision, reason, and first request.
4. Post a closing comment that explains the decision and links the record.
5. Close the request with the configured `wontfix` state.

## Updating or removing records

When a maintainer changes their mind about a rejected concept, delete or update its record. The new issue that triggered reconsideration continues through normal triage; old issues remain historical.