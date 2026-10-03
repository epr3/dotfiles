#!/usr/bin/env bash
# List the context repos (bare context repos) under the context root, into INDEX.md.
# Each <slug>/ is a separate bare context repo for one code repo -- readable by name.
set -euo pipefail
root="${AGENT_CONTEXT_HOME:-$HOME/.pi/agent/ctx}"
[ -d "$root" ] || { echo "no context root at $root"; exit 0; }
idx="$root/INDEX.md"
{ echo "# Context repos"; echo
  echo "| repo (slug) | remote |"
  echo "|-------------|--------|"; } > "$idx"
shopt -s nullglob
n=0
for d in "$root"/*/; do
  slug="$(basename "$d")"; gd=""
  [ -e "${d}.git" ] && gd="${d}.git"
  [ -n "$gd" ] || continue
  remote="$(git --git-dir="$gd" config --get remote.origin.url 2>/dev/null || echo -)"
  echo "| \`$slug\` | $remote |" >> "$idx"
  n=$((n+1))
done
echo "indexed $n context repo(s) -> $idx"
exit 0
