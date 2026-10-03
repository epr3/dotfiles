#!/usr/bin/env bash
# Safely activate the repository-managed OpenCode config, outside Dotbot's wrapper.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOME_DIR=${HOME:?HOME must be set}
CONFIG_DIR=${OPENCODE_MIGRATION_CONFIG:-${XDG_CONFIG_HOME:-$HOME_DIR/.config}/opencode}
MANAGED_CONFIG=${OPENCODE_MIGRATION_MANAGED_CONFIG:-$REPO_DIR/.config/opencode}
MIGRATOR="$SCRIPT_DIR/migrate-opencode.sh"

if [ -L "$CONFIG_DIR" ] && [ "$(readlink "$CONFIG_DIR")" = "$MANAGED_CONFIG" ]; then
  printf 'OpenCode config is already active: %s\n' "$CONFIG_DIR" >&2
  exit 0
fi

"$MIGRATOR" prepare
if ! ln -s "$MANAGED_CONFIG" "$CONFIG_DIR"; then
  "$MIGRATOR" rollback || true
  printf 'Failed to activate managed OpenCode config\n' >&2
  exit 1
fi
if ! "$MIGRATOR" commit; then
  "$MIGRATOR" rollback || true
  exit 1
fi
