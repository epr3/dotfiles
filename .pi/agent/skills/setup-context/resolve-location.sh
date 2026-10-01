#!/usr/bin/env bash
# Resolve one durable artifact class's destination. Run with cwd in the CODE repo,
# by its path; reads the config home's artifact-locations.md (written by setup-context).
#   resolve-location.sh <class>    class: glossary | adrs | board | research | explainers
# Prints the absolute destination directory on stdout, nothing else.
# Value forms: `code`, `context`, `custom:<path>` with optional {branch}.
# Missing class line -> default (the context home); missing doc -> same defaults,
# which equal the pre-existing effective destinations, so unconfigured setups are
# unchanged by this script's existence.
set -euo pipefail
[ "$#" -eq 1 ] || { echo "usage: resolve-location.sh <class>" >&2; exit 1; }
class="$1"
case "$class" in glossary|adrs|board|research|explainers) ;; *) echo "unknown class: $class" >&2; exit 1;; esac

# --- code repo + branch ---------------------------------------------------------------
root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repo" >&2; exit 1; }
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"; [ "$branch" = HEAD ] && branch="main"

# --- store + config home, per GLOSSARY-FORMAT.md *Resolving the context store* ---------
store="context"   # recorded block's Store line, or the context-repo default
instruct=""
for cand in "$root/AGENTS.md" "$root/CLAUDE.md"; do
  if [ -f "$cand" ] && grep -q '^## Agent skills' "$cand"; then instruct="$cand"; break; fi
done
if [ -n "$instruct" ]; then
  if grep -qi '^Store:[[:space:]]*in-repo' "$instruct"; then store="in-repo"
  elif grep -qi '^Store:[[:space:]]*context repo' "$instruct"; then store="context"
  elif [ -f "$root/GLOSSARY.md" ] || [ -f "$root/GLOSSARY-MAP.md" ] || [ -d "$root/docs/adr" ]; then
    store="in-repo"   # no Store line recorded -> in-tree docs decide (in-repo context)
  fi
elif [ -f "$root/GLOSSARY.md" ] || [ -f "$root/GLOSSARY-MAP.md" ] || [ -d "$root/docs/adr" ]; then
  store="in-repo"   # in-tree docs, no recorded block: in-repo context
fi
if [ "$store" = "in-repo" ]; then cf="$root/docs/agents"; else
  # slug, same formula as ctx-init.sh
  url="$(git -C "$root" config --get remote.origin.url 2>/dev/null || true)"; slug=""
  if [ -n "$url" ]; then s="${url%.git}"; s="${s##*://}"; s="${s##*@}"; s="$(printf '%s' "$s" | tr ':' '/')"
    repo="${s##*/}"; rest="${s%/*}"; org="${rest##*/}"; [ "$rest" = "$s" ] && org=""
    [ -n "$org" ] && slug="${org}__${repo}" || slug="$repo"
    slug="$(printf '%s' "$slug" | tr -c 'A-Za-z0-9._-' '_')"
  fi
  [ -n "$slug" ] || slug="$(printf '%s' "$(basename "$root")" | tr -c 'A-Za-z0-9._-' '_')"
  proj="${AGENT_CONTEXT_HOME:-$HOME/.pi/agent/ctx}/$slug"
  cf="$proj/.agents"
fi

# --- recorded value, else default -----------------------------------------------------
val=""
if [ -f "$cf/artifact-locations.md" ]; then
  val="$(grep -E "^${class}:[[:space:]]*[^[:space:]]" "$cf/artifact-locations.md" | head -1 | sed -E "s/^${class}:[[:space:]]*//" || true)"
fi
case "${val:-context}" in
  code)   printf '%s\n' "$root"; exit 0 ;;
  context) if [ "$store" = "in-repo" ]; then printf '%s\n' "$root"; else printf '%s\n' "$proj/$branch"; fi; exit 0 ;;
  custom:*) ;;
  *) echo "invalid value '${val}' for class ${class} in $cf/artifact-locations.md" >&2; exit 1 ;;
esac
dest="${val#custom:}"
if [[ "$dest" != *'{branch}'* ]]; then
  dest="$dest/$branch"   # no {branch} token -> scoped per code branch, never mixed
fi
printf '%s\n' "${dest//\{branch\}/$branch}"
