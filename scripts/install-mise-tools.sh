#!/usr/bin/env bash
# Install the locked tool versions from the tracked global mise configuration.
# The committed mise.lock is authoritative (tool_config.locked = true), so
# ordinary Bootstrap never re-resolves newer versions or rewrites the lock.
# Upgrades are deliberate reviewed changes — see docs/mise-node-migration.md
# and docs/mise-runtime-migration.md.
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/mise-stage-helpers.sh"

mise_stage_resolve

if ! command -v jq &>/dev/null; then
  echo "jq is required to verify the locked tools (installed by the Brewfile)." >&2
  exit 1
fi

mise_stage_cd_home

global_config="$HOME/.config/mise/config.toml"
global_lock="$HOME/.config/mise/mise.lock"

if [ ! -f "$global_lock" ]; then
  echo "Missing ~/.config/mise/mise.lock. Generate it deliberately with 'mise lock --global' and commit it to the dotfiles repository." >&2
  exit 1
fi

# Every [tools] entry: tool name plus all declared versions (the first is the
# default). Comments inside the section are ignored.
tool_lines="$(awk '/^\[tools\]/{f=1;next} /^\[/{f=0} f && /^[a-z][a-z0-9_-]* *=/{print}' "$global_config")"
if [ -z "$tool_lines" ]; then
  echo "No tools declared in $global_config." >&2
  exit 1
fi

# MISE_YES keeps the stage noninteractive; locked resolution leaves nothing to
# confirm.
export MISE_YES=1
echo "Installing locked tools from the global mise configuration..."
mise install --locked
mise reshim

# Verify each declared tool: every declared version is installed, the active
# resolution equals the first declared version, and the install lives in
# mise's data directory — i.e. the tracked global config and lockfile actually
# own what runs. `mise current` lists a tool's active versions in PATH-priority
# order (mise ls --json sorts them by version instead, so its first entry is
# not necessarily the default).
fail() {
  echo "$1" >&2
  exit 1
}

while IFS= read -r line; do
  tool="$(awk -F= '{gsub(/ +/,"",$1); print $1}' <<<"$line")"
  versions=()
  while IFS= read -r version; do
    versions+=("$version")
  done < <(grep -o '"[^"]*"' <<<"$line" | tr -d '"')
  if [ "${#versions[@]}" -eq 0 ]; then
    fail "Could not read any version for '$tool' in $global_config."
  fi

  json="$(mise ls "$tool" --json 2>/dev/null)" || fail "mise ls failed for '$tool'."

  for version in "${versions[@]}"; do
    echo "$json" | jq -e --arg v "$version" 'any(.[]; .version == $v and .installed)' >/dev/null \
      || fail "'$tool@$version' (declared by the global config) is not installed."
  done

  active="$(mise current "$tool" 2>/dev/null | awk '{print $1}')"
  if [ "$active" != "${versions[0]}" ]; then
    fail "'$tool' resolves to ${active:-nothing} but the global config declares ${versions[0]} as the default."
  fi

  install_path="$(mise where "${tool}@${versions[0]}")"
  mise_stage_check_path "$install_path" "'$tool'"

  echo "$tool ${versions[*]} at $install_path (locked by the global config)"
done <<<"$tool_lines"

mise ls
