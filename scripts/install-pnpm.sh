#!/usr/bin/env bash
# Install pnpm via install script if not present.
set -euo pipefail

if command -v pnpm &>/dev/null; then
  echo "pnpm already installed: $(pnpm --version). Skipping installation."
  exit 0
fi

echo "Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | sh -
