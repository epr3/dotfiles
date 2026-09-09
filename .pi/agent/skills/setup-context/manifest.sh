#!/usr/bin/env bash
# Manifest -- the set of real paths in THIS code repo (branch/worktree-accurate).
# Grounding rule: context may be created ONLY at a path the manifest contains. A
# CONTEXT-MAP link or term pointing at a path not here is dangling -> flag it, do NOT
# create it. (Whether a grounded term's symbol still exists is a separate LSP
# check. The manifest grounds paths; LSP grounds symbols.)
# Answers are repo-root-relative and cwd-independent: run from any directory
# inside the code repo. PATH args are taken literally (spaces and pattern
# metacharacters are plain path characters, never globs).
#   manifest.sh             tracked directories (context-attachable): the root and
#                           every ancestor dir of a tracked path, exactly once;
#                           never root files, never untracked-only dirs
#   manifest.sh --files     tracked files, repo-root-relative
#   manifest.sh --has PATH  exit 0 if PATH is a tracked file, a tracked dir, or
#                           the root (when anything is tracked); else exit 1
set -euo pipefail
git rev-parse --git-dir >/dev/null 2>&1 || { echo "manifest: not a git repo" >&2; exit 2; }
top="$(git rev-parse --show-toplevel)"
usage() { echo "usage: manifest.sh [--files | --has PATH]  (PATH is repo-root-relative; no args = tracked directories)" >&2; exit 2; }

case "${1:-}" in
  --files)
    [ "$#" -eq 1 ] || usage
    git -C "$top" ls-files --full-name
    ;;
  --has)
    [ "$#" -eq 2 ] || usage
    p="${2%/}"
    case "$p" in
      "")  usage;;
      .)    p="";;
      ./*)  p="${p#./}";;
    esac
    if [ -z "$p" ]; then
      # root: present iff at least one tracked path exists
      git -C "$top" ls-files -z | grep -qz . && exit 0 || exit 1
    fi
    found=0
    while IFS= read -r -d '' f; do
      case "$f" in
        "$p"|"$p/"*) found=1 ;;
      esac
      [ "$found" = 1 ] && break
    done < <(git -C "$top" ls-files -z)
    [ "$found" = 1 ] && exit 0 || exit 1
    ;;
  "")
    # directory mode: root + every ancestor dir of a tracked path
    root=0
    seen=()
    while IFS= read -r -d '' f; do
      case "$f" in
        */*)
          d="${f%/*}"
          while :; do
            seen+=("$d")
            case "$d" in */*) d="${d%/*}";; *) break;; esac
          done
          root=1
          ;;
        *) root=1 ;;
      esac
    done < <(git -C "$top" ls-files -z)
    if [ "$root" = 1 ]; then printf '.\n'; fi
    if [ "${#seen[@]}" -gt 0 ]; then printf '%s\n' "${seen[@]}" | sort -u; fi
    exit 0
    ;;
  *)
    usage
    ;;
esac