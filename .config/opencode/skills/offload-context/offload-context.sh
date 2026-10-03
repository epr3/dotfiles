#!/usr/bin/env bash
# Publish this branch's context: commit + push the context worktree to the team remote.
#
# Context lives ONLY in the separate context repo -- you edit it directly in the worktree that
# ctx-init materialises at $AGENT_CONTEXT_HOME/<slug>/<branch>/ (slug = <org>__<repo> from origin).
# There is no in-tree copy and no reconcile: offload simply saves your context work.
# Run from inside the CODE repo (it reads the repo + branch from your cwd to resolve the worktree).
#   --check   show the worktree's uncommitted context; commit/push nothing.
set -euo pipefail
mode=publish
for a in "$@"; do case "$a" in
  --check) mode=check;;
  *) echo "usage: offload-context.sh [--check]" >&2; exit 2;;
esac; done
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo -- nothing to offload"; exit 0; }
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"; [ "$branch" = HEAD ] && branch="main"

# the context worktree for this branch (ctx-init ensures the bare repo + worktree, forked off base)
wt="$("$(dirname "$0")/../setup-context/ctx-init.sh")" || { echo "could not resolve context worktree" >&2; exit 1; }
echo "context worktree: $wt   (branch $branch)"

if [ "$mode" = check ]; then
  st="$( cd "$wt" && git status --porcelain )" || true
  if [ -n "$st" ]; then printf '%s\n' "$st" | sed 's/^/  /'; else echo "  (worktree clean -- nothing to offload)"; fi
  echo "--check: offload commits the above and pushes branch $branch to the team remote"
  exit 0
fi

( cd "$wt"
  git add -A
  if git diff --cached --quiet; then echo "offload: nothing to commit"
  else git commit -q -m "context: $branch"; echo "offload: committed context for $branch"; fi
  if git push -u origin "$branch" >/dev/null 2>&1; then echo "offload: pushed $branch"
  else echo "offload: push skipped (no remote / offline)"; fi
)
"$(dirname "$0")/../setup-context/ctx-index.sh" >/dev/null 2>&1 || true
exit 0
