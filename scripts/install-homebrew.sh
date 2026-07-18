#!/usr/bin/env bash
# Install Homebrew if not present. Skip if already available.
set -euo pipefail

if command -v brew &>/dev/null; then
  echo "Homebrew already installed at $(command -v brew). Skipping installation."
  exit 0
fi

echo "Installing Homebrew..."
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Make brew available in current shell for subsequent bootstrap stages
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
