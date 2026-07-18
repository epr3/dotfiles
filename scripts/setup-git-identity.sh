#!/usr/bin/env bash
# Set git user name and email only when global config values are missing.
set -euo pipefail

if git config --global user.email &>/dev/null; then
  echo "Git email already configured: $(git config --global user.email)"
else
  read -p "Enter git email: " email
  git config --global user.email "$email"
fi

if git config --global user.name &>/dev/null; then
  echo "Git name already configured: $(git config --global user.name)"
else
  read -p "Enter git name: " name
  git config --global user.name "$name"
fi
