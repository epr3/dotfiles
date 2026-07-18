#!/usr/bin/env bash
# Manifest -- the set of real paths in THIS code repo (branch/worktree-accurate).
# Grounding rule: context may be created ONLY at a path the manifest contains. A
# CONTEXT-MAP link or term pointing at a path not here is dangling -> flag it, do NOT
# create it. (Whether a grounded term's symbol still exists is a separate LSP
# check. The manifest grounds paths; LSP grounds symbols.)
#   manifest.sh             tracked directories (context-attachable)
#   manifest.sh --files     tracked files
#   manifest.sh --has PATH   exit 0 if PATH is a tracked file or dir, else 1
set -euo pipefail
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo" >&2; exit 2; }
case "${1:-}" in
  --files) git ls-files ;;
  --has)   p="${2%/}"; git ls-files --error-unmatch "$p" >/dev/null 2>&1 && exit 0
           git ls-files | grep -q "^$p/" && exit 0 || exit 1 ;;
  *)       git ls-files | sed "s#/[^/]*\$##" | sort -u ;;
esac
