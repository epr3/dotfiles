#!/usr/bin/env bash
# Create a Worktree container: <dest>/.git is a bare clone of <src>.
# Accepts <source> [destination]; with no destination, derive the container
# name from the source (drop trailing slashes and only a final `.git` suffix,
# keep every other dot) and create it beneath the caller's directory.
# Local sources and relative destinations resolve from the caller's original
# directory, which Git shell aliases report via GIT_PREFIX: the alias runs
# from the enclosing repository's top level, so the caller's directory is
# recovered before anything moves.
set -euo pipefail

usage() {
  echo "Usage: git clone-for-worktrees <source> [destination]" >&2
  echo "Clone <source> as a bare repository into <destination>/.git; no worktree is created." >&2
  echo "With no destination, the container name is derived from <source> (without a trailing '/.git')." >&2
}

usage_die() { usage; die "$*"; }

die() {
  echo "clone-for-worktrees: $*" >&2
  exit 1
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] \
  || usage_die "expected a source and optionally a destination; got $# argument(s)"

src="$1"
dest="${2-}"

# Empty values would hit git as surprising paths; reject up front.
[ -n "$src" ] || usage_die "source must not be empty"
if [ "$#" -eq 2 ] && [ -z "$dest" ]; then
  usage_die "destination must not be empty"
fi

# Recover the caller's original directory. Git runs `!` shell aliases from the
# enclosing repository's top level and exports GIT_PREFIX as the path from
# there back to the invocation directory; outside a repository the current
# directory already is the caller's.
caller_dir="$(pwd)"
if [ -n "${GIT_PREFIX:-}" ]; then
  caller_dir="$caller_dir/${GIT_PREFIX%/}"
fi
caller_dir="$(cd -- "$caller_dir" && pwd -P)"

# Git treats a path as local when no colon exists or a slash precedes the
# first colon; otherwise the source is a URL and is passed through untouched.
is_local_source() {
  local s="$1"
  case "$s" in
    *:*) ;;
    *) return 0 ;;
  esac
  case "${s%%:*}" in
    */*) return 0 ;;
    *) return 1 ;;
  esac
}

# Physical path of $1 as seen from the caller's directory ($1 must exist).
from_caller() {
  (cd -- "$caller_dir" && cd -- "$1" && pwd -P) 2>/dev/null
}

# Canonicalize a local source against the caller's directory so the origin
# recorded in the container stays usable after the caller changes directory.
resolve_source() {
  local s="$1"
  case "$s" in
    /*) printf '%s\n' "$s"; return 0 ;;
  esac
  from_caller "$s"
}

if is_local_source "$src"; then
  resolved="$(resolve_source "$src")" \
    || die "cannot resolve local source '$src' against '$caller_dir'"
  src="$resolved"
fi

# Remove every trailing slash so "repo/" and "repo" name the same thing.
strip_trailing_slashes() {
  local s="$1"
  while [ "${s%/}" != "$s" ]; do s="${s%/}"; done
  printf '%s\n' "$s"
}

# Derive the container name from the source's final component: drop trailing
# slashes, keep every other dot, remove only a terminal `.git` suffix, and
# for scp-style SSH forms ignore the leading host part. `$1` still holds the
# original source, unmodified by resolution.
derive_name() {
  local s="$1" name
  name="$(strip_trailing_slashes "$s")"
  name="${name##*/}"
  case "$name" in
    *:*) name="${name##*:}" ;;
  esac
  case "$name" in
    *.git) name="${name%.git}" ;;
  esac
  printf '%s\n' "$name"
}

if [ "$#" -eq 1 ]; then
  name="$(derive_name "$1")"
  [ -n "$name" ] \
    || usage_die "could not derive a destination name from '$1'; pass an explicit destination"
  dest="$caller_dir/$name"
else
  # Trailing slashes on an explicit destination behave like their absence.
  dest="$(strip_trailing_slashes "$dest")"
  [ -n "$dest" ] || usage_die "destination must not be empty"
  case "$dest" in
    /*) ;;
    *)
      # Resolve against the caller's directory, canonicalizing through the
      # (existing) parent so the recorded path stays physically clean.
      dest_parent="$(dirname -- "$dest")"
      dest_base="$(basename -- "$dest")"
      dest_resolved="$(from_caller "$dest_parent")"
      if [ -n "$dest_resolved" ]; then
        dest="$dest_resolved/$dest_base"
      else
        dest="$caller_dir/$dest"
      fi
      ;;
  esac
fi

# Refuse anything that already exists, including dangling symlinks (-L catches
# what -e misses). Never modify an existing path or its target.
if [ -e "$dest" ] || [ -L "$dest" ]; then
  die "destination already exists; refusing to touch it: $dest"
fi

parent="$(dirname -- "$dest")"
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