#!/usr/bin/env bash
# Install the pi coding agent if it is not present.
set -euo pipefail

PACKAGE="@earendil-works/pi-coding-agent"

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
