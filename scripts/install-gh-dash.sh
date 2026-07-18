#!/usr/bin/env bash
# Install gh-dash via GitHub CLI extension (no Homebrew formula available).
# Idempotent: skips silently when already installed.
set -euo pipefail

if gh extension list 2>/dev/null | grep -qF "dlvhdr/gh-dash"; then
  echo "gh-dash extension already installed."
  exit 0
fi

echo "Installing gh-dash via GitHub CLI extension..."
gh extension install dlvhdr/gh-dash
