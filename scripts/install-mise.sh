#!/usr/bin/env bash
# Install mise via Homebrew if not present. Skip if already available.
# mise is also listed in the Brewfile: this stage exists because mise must be
# present before the locked tool install stage, which runs before `brew bundle`.
set -euo pipefail

if command -v mise &>/dev/null; then
  echo "mise already installed: $(mise --version | head -n1). Skipping installation."
  exit 0
fi

if ! command -v brew &>/dev/null; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

if ! command -v brew &>/dev/null; then
  echo "Homebrew is required to install mise. Run the Homebrew stage first." >&2
  exit 1
fi

echo "Installing mise..."
brew install mise
