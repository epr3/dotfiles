# Issue tracker: GitLab

Issues for this repo live as GitLab issues; specs stay local files under `.scratch/<feature-slug>/SPEC.md` in the context home. Use the `glab` CLI for all issue operations.

## Conventions

- **Create an issue**: `glab issue create --title "..." --description "..."`. Use a heredoc for multi-line descriptions.
- **Read an issue**: `glab issue view <number> --comments`
- **List issues**: `glab issue list --output json` with appropriate `--label` / state filters.
- **Comment on an issue**: `glab issue note <number> --message "..."` (GitLab calls comments "notes")
- **Apply / remove labels**: `glab issue update <number> --label "..."` / `--unlabel "..."`
- **Close**: `glab issue close <number>`; `glab issue close` takes no closing comment, so post any explanation as a note first, then close.
- **Merge requests**: GitLab calls PRs "merge requests". Use `glab mr create`, `glab mr view`, `glab mr note`, etc., the same shape as `gh pr ...` with `mr` in place of `pr` and `note`/`--message` in place of `comment`/`--body`.

Infer the project from `git remote -v`; `glab` does this automatically when run inside a clone (works for gitlab.com and self-hosted hosts it's authenticated against).

## When a skill says "publish to the issue tracker"

Create a GitLab issue.

## Wayfinding operations

The `wayfinder` map is a single issue titled `wayfinder: <effort>`; child tickets are issues linked from it.

- **Map**: a single issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body. `glab issue create --label wayfinder:map`. (On GitLab tiers with native epics, an epic may hold the map instead; a labelled issue works everywhere.)
- **Child ticket**: an issue carrying `Part of #<map>` at the top of its description, labelled `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`).
- **Claim before any work**: `glab issue update <n> --assignee @me`, the session's first write, then add a claim comment `claimed_by: pi:$PI_SESSION_ID` prefixed with the AI disclaimer (`_Posted by an AI triage agent on behalf of the maintainer._`). Re-read to confirm. Cooperative and best-effort, no silent steal; takeover or release is a comment on the issue; no auto-expiry; the claim is retained on resolve.
- **Blocking**: GitLab's native blocking link, the canonical, UI-visible representation. Add it with the `/blocked_by #<n>` quick action, posted as a note (`glab issue note <child> --message "/blocked_by #<blocker>"`). Native blocking links are a Premium/Ultimate feature; on the free tier (or where unavailable) fall back to a `Blocked by: #<n>, #<n>` line at the top of the description. A ticket is unblocked when every blocker is closed.
- **Frontier**: the map's open children, dropping any with an open blocker (a native `blocked_by` link to an open issue, checked with `glab api projects/:id/issues/:iid/links`, or an open issue in the `Blocked by` line) or an assignee; first in map order wins.
- **Closing a ticket**: post the decision as a note, then close, then update the map's "Decisions so far" with a one-line gist + link.

## When a skill says "fetch the relevant issue"

Run `glab issue view <number> --comments`.

## MRs as a request surface

**Off.** Flip to on to have `triage` pull *external* merge requests into the same queue, roles, and states as issues (collaborators' in-flight MRs are left alone); useful in open-source projects that receive feature requests as MRs.

When on, MRs run through the same labels and states as issues, using the `glab mr` equivalents:

- **Read an MR**: `glab mr view <number> --comments` and `glab mr diff <number>` for the diff.
- **List external MRs for triage**: `glab mr list -F json`, then keep only MRs whose author is not a project member/owner (a contributor's MR, not a maintainer's in-flight work).
- **Comment / label / close**: `glab mr note`, `glab mr update --label`/`--unlabel`, `glab mr close`.

Unlike GitHub, GitLab numbers issues and MRs separately, so `#42` is unambiguous once you know which surface the maintainer means.
