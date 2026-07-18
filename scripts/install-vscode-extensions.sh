#!/usr/bin/env bash
# Install VS Code extensions from tracked list when `code` CLI is available.
set -euo pipefail

if ! command -v code &>/dev/null; then
  echo "VS Code CLI (code) not found. Skipping extension installation."
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSIONS_FILE="${SCRIPT_DIR}/../vscode/extensions.list"

if [ ! -f "$EXTENSIONS_FILE" ]; then
  echo "Extensions list not found at ${EXTENSIONS_FILE}. Skipping."
  exit 0
fi

echo "Installing VS Code extensions from $(basename "$EXTENSIONS_FILE")..."
xargs -I {} code --install-extension {} --force < "$EXTENSIONS_FILE"
