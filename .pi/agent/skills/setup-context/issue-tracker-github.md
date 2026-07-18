# Issue tracker: GitHub

Issues for this repo live as GitHub issues; specs stay local files under `.scratch/<feature-slug>/SPEC.md` in the context home. Use the `gh` CLI for all issue operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments by `jq` and also fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v` — `gh` does this automatically when run inside a clone.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## Wayfinding operations

The `wayfinder` map is a single issue titled `wayfinder: <effort>`; child tickets are issues linked from a task-list in the map body (`- [ ] #N`). Blocking: a `Blocked by #N` line at the top of a child's body. Frontier: open children whose `Blocked by` issues are all closed. Closing a ticket: post the decision as the closing comment, then update the map's "Decisions so far" with a one-line gist + link.

## When a skill says "fetch the relevant issue"

Run `gh issue view <number> --comments`.
