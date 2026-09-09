#!/usr/bin/env bash
# Create a Worktree container: <dest>/.git is a bare clone of <src>.
# This slice: exactly one absolute source and one explicit absolute destination.
set -euo pipefail

usage() {
  echo "Usage: git clone-for-worktrees <source> <destination>" >&2
  echo "Clone <source> as a bare repository into <destination>/.git; no worktree is created." >&2
}

usage_die() { usage; die "$*"; }

die() {
  echo "clone-for-worktrees: $*" >&2
  exit 1
}

[ "$#" -eq 2 ] || usage_die "expected exactly a source and a destination; got $# argument(s)"

src="$1"
dest="$2"

# Empty values would hit git as surprising destinations; reject up front.
[ -n "$src" ] || usage_die "source must not be empty"
[ -n "$dest" ] || usage_die "destination must not be empty"

# Refuse anything that already exists, including dangling symlinks (-L catches
# what -e misses). Never modify an existing path or its target.
if [ -e "$dest" ] || [ -L "$dest" ]; then
  die "destination already exists; refusing to touch it: $dest"
fi

parent="$(dirname "$dest")"
[ -d "$parent" ] || die "destination parent does not exist: $parent"

mkdir "$dest" || die "could not create destination: $dest"

if ! git clone --bare "$src" "$dest/.git"; then
  die "clone failed; new container retained at '$dest' (inspect, then clean up if you want)"
fi

# Force-update all origin remote-tracking branches, not just the default head.
git -C "$dest/.git" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' \
  || die "failed to configure origin fetch mapping; new container retained at '$dest'"

if ! git -C "$dest/.git" fetch origin; then
  die "initial fetch failed; new container retained at '$dest' (inspect, then clean up if you want)"
fi

echo "Created Worktree container at '$dest' (bare repository at '$dest/.git'). No worktree created."