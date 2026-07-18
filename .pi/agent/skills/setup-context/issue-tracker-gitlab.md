# Issue tracker: GitLab

Issues for this repo live as GitLab issues; specs stay local files under `.scratch/<feature-slug>/SPEC.md` in the context home. Use the `glab` CLI for all issue operations.

## Conventions

- **Create an issue**: `glab issue create --title "..." --description "..."`. Use a heredoc for multi-line descriptions.
- **Read an issue**: `glab issue view <number> --comments`
- **List issues**: `glab issue list --output json` with appropriate `--label` / state filters.
- **Comment on an issue**: `glab issue note <number> --message "..."`
- **Apply / remove labels**: `glab issue update <number> --label "..."` / `--unlabel "..."`
- **Close**: `glab issue close <number>`

Infer the project from `git remote -v` — `glab` does this automatically when run inside a clone (works for gitlab.com and self-hosted hosts it's authenticated against).

## When a skill says "publish to the issue tracker"

Create a GitLab issue.

## Wayfinding operations

The `wayfinder` map is a single issue titled `wayfinder: <effort>`; child tickets are issues linked from a task-list in the map body. Blocking: GitLab's native "blocked by" issue links (`glab` or the UI). Frontier: open children with no open blockers. Closing a ticket: post the decision as the closing comment, then update the map's "Decisions so far" with a one-line gist + link.

## When a skill says "fetch the relevant issue"

Run `glab issue view <number> --comments`.
