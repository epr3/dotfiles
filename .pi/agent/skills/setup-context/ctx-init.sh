#!/usr/bin/env bash
# Ensure the context repo (bare) + a worktree for the current CODE branch exist, using
# plain git -- no extra tooling. The context branch graph MIRRORS the code branch graph:
# a new context branch is forked off the context branch matching its base in the code repo
# (the branch it was created from -- e.g. feature-3 off feature-2), falling back to the
# designated master (the context branch mirroring the code repo's default branch).
#   ctx-init.sh [--base <branch>] [team-remote]
#     --base   override the detected base branch (the start point to fork off)
# Prints the worktree path on stdout (and nothing else).
set -euo pipefail
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo" >&2; exit 1; }

base_override=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base_override="${2:-}"; shift 2 || true;;
    *) break;;
  esac
done
remote="${1:-}"

# --- slug from the code repo origin --------------------------------------------------
url="$(git config --get remote.origin.url 2>/dev/null || true)"; slug=""
if [ -n "$url" ]; then
  s="${url%.git}"; s="${s##*://}"; s="${s##*@}"; s="$(printf '%s' "$s" | tr ':' '/')"
  repo="${s##*/}"; rest="${s%/*}"; org="${rest##*/}"; [ "$rest" = "$s" ] && org=""
  if [ -n "$org" ]; then slug="${org}__${repo}"; else slug="$repo"; fi
  slug="$(printf '%s' "$slug" | tr -c 'A-Za-z0-9._-' '_')"
fi
[ -n "$slug" ] || { slug="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"; slug="$(printf '%s' "$slug" | tr -c 'A-Za-z0-9._-' '_')"; }
[ -n "$slug" ] || { echo "could not determine a repo name for the context repo" >&2; exit 1; }

root="${AGENT_CONTEXT_HOME:-$HOME/.pi/agent/ctx}"; proj="$root/$slug"; bare="$proj/.git"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"; [ "$branch" = HEAD ] && branch="main"

# --- designated master = the code repo's default branch ------------------------------
trunk=""
ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"   # e.g. origin/main
[ -n "$ref" ] && trunk="${ref#origin/}"
if [ -z "$trunk" ]; then
  for c in main master; do git show-ref --verify --quiet "refs/heads/$c" && { trunk="$c"; break; }; done
fi
[ -n "$trunk" ] || trunk="$branch"

# --- detect the branch this one was forked from, in the CODE repo --------------------
# Nearest merge-base first (a moved base's tip may no longer be an ancestor, so distance to
# the cut point decides); ties -> the designated master, else ref-name order stays.
detect_base() {
  local B="$1" T="$2" c mb d
  local best="" bestd=""
  while IFS= read -r c; do
    [ -z "$c" ] && continue; [ "$c" = "$B" ] && continue
    git merge-base --is-ancestor "$B" "$c" 2>/dev/null && continue   # skip branches that contain B (children)
    mb="$(git merge-base "$B" "$c" 2>/dev/null)" || continue; [ -n "$mb" ] || continue
    d="$(git rev-list --count "$mb..$B" 2>/dev/null)" || continue
    if [ -z "$bestd" ] || [ "$d" -lt "$bestd" ] \
       || { [ "$d" -eq "$bestd" ] && [ "$c" = "$T" ] && [ "$best" != "$T" ]; }; then
      best="$c"; bestd="$d"
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null)
  printf '%s' "$best"
}

# --- ensure the bare context repo ----------------------------------------------------
if [ ! -d "$bare" ]; then
  mkdir -p "$proj"
  if [ -n "$remote" ]; then git clone --bare -q "$remote" "$bare"; else git init --bare -q "$bare"; fi
fi
if git -C "$bare" rev-parse --verify -q HEAD >/dev/null 2>&1; then
  d="$(git -C "$bare" symbolic-ref --short HEAD 2>/dev/null || true)"; [ -n "$d" ] && trunk="$d"
fi
if ! git -C "$bare" rev-parse --verify -q HEAD >/dev/null 2>&1 && ! git -C "$bare" show-ref --verify -q "refs/heads/$trunk"; then
  et="$(git -C "$bare" hash-object -w -t tree /dev/null)"
  rc="$(printf 'init context\n' | GIT_AUTHOR_NAME=context GIT_AUTHOR_EMAIL=context@local GIT_COMMITTER_NAME=context GIT_COMMITTER_EMAIL=context@local git -C "$bare" commit-tree "$et")"
  git -C "$bare" update-ref "refs/heads/$trunk" "$rc"
  git -C "$bare" symbolic-ref HEAD "refs/heads/$trunk"
fi

# --- worktree for the current branch, forked to MIRROR the code branch graph ---------
wt="$proj/$branch"
if [ ! -d "$wt" ]; then
  if git -C "$bare" show-ref --verify -q "refs/heads/$branch"; then
    git -C "$bare" worktree add "$wt" "$branch" >/dev/null 2>&1 || true               # existing context branch
  else
    if [ -n "$base_override" ]; then base="$base_override"; else base="$(detect_base "$branch" "$trunk")"; fi
    [ -n "$base" ] || base="$trunk"     # no candidate -> the designated master
    start="$trunk"; git -C "$bare" show-ref --verify -q "refs/heads/$base" && start="$base"   # fork off base's context if it exists
    git -C "$bare" worktree add -b "$branch" "$wt" "$start" >/dev/null 2>&1 \
      || git -C "$bare" worktree add -b "$branch" "$wt" >/dev/null 2>&1 || true
    if [ -d "$wt" ]; then
      # persist the resolved fork parent, branch-scoped, read by rebase-context for this
      # branch. A fork-time fact: written once (also when start fell back to base/trunk),
      # never rewritten or duplicated by later runs.
      rec="$bare/info/fork-parent/$branch"
      if [ ! -f "$rec" ]; then mkdir -p "$(dirname "$rec")"; printf '%s\n' "$base" > "$rec"; fi
    fi
  fi
fi
[ -d "$wt" ] || { echo "failed to create worktree $wt" >&2; exit 1; }

echo "$wt"
