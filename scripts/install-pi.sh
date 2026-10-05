#!/usr/bin/env bash
# Install the pi coding agent if it is not present.
set -euo pipefail

PACKAGE="@earendil-works/pi-coding-agent"

# Explicit mise execution: dependent Bootstrap stages run with the locked Node
# from the tracked global configuration, even without a previously activated
# shell (docs/mise-node-migration.md). Re-exec resolves from $HOME — outside
# this repository — so project configuration cannot participate, matching
# scripts/install-mise-tools.sh.
source "$(cd "$(dirname "$0")" && pwd)/mise-stage-helpers.sh"
mise_stage_resolve
if [[ "${MISE_PI_STAGE:-}" != "1" ]]; then
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  export MISE_PI_STAGE=1
  mise_stage_cd_home
  exec mise x -- bash "$script_dir/$(basename "$0")"
fi

# pnpm's standalone install location may not be on PATH in a fresh shell.
if ! command -v pnpm &>/dev/null; then
  PNPM_HOME="$HOME/Library/pnpm"
  if [ -x "$PNPM_HOME/pnpm" ]; then
    export PNPM_HOME
    export PATH="$PNPM_HOME:$PATH"
  fi
fi

if command -v pi &>/dev/null; then
  echo "pi already installed: $(pi --version 2>/dev/null || echo unknown). Skipping installation."
  exit 0
fi

if ! command -v pnpm &>/dev/null; then
  echo "pnpm is required to install pi coding agent." >&2
  exit 1
fi

echo "Installing pi coding agent with pnpm..."
pnpm add --global --ignore-scripts "$PACKAGE"
