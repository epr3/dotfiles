#!/usr/bin/env bash
# Set Node LTS via pnpm env. Requires pnpm to be available.
set -euo pipefail

if ! command -v pnpm &>/dev/null; then
  echo "pnpm not available. Skipping Node LTS setup."
  exit 0
fi

echo "Setting Node LTS via pnpm..."
pnpm env use --global lts
