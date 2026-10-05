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

export MISE_YES=1
echo "Installing locked tools from the global mise configuration..."
mise install --locked
mise reshim

# Verify that Node resolves to a mise-managed installation via the global config.
resolved="$(mise which node)"
case "$resolved" in
  "$HOME"/.local/share/mise/*) ;;
  *) echo "node does not resolve to a mise-managed install: $resolved" >&2; exit 1 ;;
esac
echo "node $(mise x -- node --version) at $resolved"
mise ls node
