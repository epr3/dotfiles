#!/usr/bin/env bash
# Guarded alias-registration stage: install the clone-for-worktrees alias.
# Independent of Git identity setup; a preserved conflict never fails setup.
set -euo pipefail

alias_name="clone-for-worktrees"
# Literal $HOME: expanded by the shell at invocation time, so a home directory
# with spaces keeps working and remains portable across machines.
alias_value='!bash "$HOME/git-clone-bare-for-worktrees.sh"'

existing="$(git config --global --get "alias.$alias_name" || true)"

if [ -z "$existing" ]; then
  git config --global "alias.$alias_name" "$alias_value"
  echo "Registered git alias '$alias_name'."
elif [ "$existing" = "$alias_value" ]; then
  echo "Git alias '$alias_name' already configured; leaving it unchanged."
else
  echo "Warning: git alias '$alias_name' already set to a different value; preserving it." >&2
fi

exit 0