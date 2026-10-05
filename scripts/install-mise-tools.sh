#!/usr/bin/env bash
# Install the locked tool versions from the tracked global mise configuration.
# The committed mise.lock is authoritative (tool_config.locked = true), so
# ordinary Bootstrap never re-resolves newer versions or rewrites the lock.
# Upgrades are deliberate reviewed changes — see docs/mise-node-migration.md.
set -euo pipefail

if ! command -v mise &>/dev/null && [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! command -v mise &>/dev/null; then
  echo "mise is required. Run the Homebrew and mise Bootstrap stages first." >&2
  exit 1
fi

# Resolve outside the dotfiles repository so project configuration cannot
# participate; the tracked global configuration and lockfile own this install.
cd "$HOME"

if [ ! -f "$HOME/.config/mise/mise.lock" ]; then
  echo "Missing ~/.config/mise/mise.lock. Generate it deliberately with 'mise lock --global' and commit it to the dotfiles repository." >&2
  exit 1
fi

# MISE_YES keeps the stage noninteractive; locked resolution leaves nothing to
# confirm.
export MISE_YES=1
echo "Installing locked tools from the global mise configuration..."
mise install --locked
mise reshim

# Verify that Node resolves to a mise-managed installation at the version the
# tracked global configuration declares.
expected="$(sed -n 's/^node = "\(.*\)"$/\1/p' "$HOME/.config/mise/config.toml")"
if [ -z "$expected" ]; then
  echo "Could not read the node version request from ~/.config/mise/config.toml." >&2
  exit 1
fi
resolved="$(mise which node)"
case "$resolved" in
  "$HOME"/.local/share/mise/*) ;;
  *) echo "node does not resolve to a mise-managed install: $resolved" >&2; exit 1 ;;
esac
resolved_version="$(mise x -- node --version)"
if [ "$resolved_version" != "v$expected" ]; then
  echo "node resolves to $resolved_version but the global config declares $expected." >&2
  exit 1
fi
echo "node $resolved_version at $resolved (locked by the global config)"
mise ls node
