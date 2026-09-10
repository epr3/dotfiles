#!/usr/bin/env bash
# Worktrunk pre-start hook: create a Zellij workspace tab for the worktree.
# Inside Zellij: new tab with pi (top) | lazygit / shell (bottom), focused on pi.
# Outside Zellij: skip workspace creation, preserve the worktree operation.
#
# Called by worktrunk with these variables in scope:
#   branch          — raw branch name (e.g. "feature/auth")
#   worktree_path   — absolute path to the worktree directory
#
# Expects the caller to have sanitized variables already; this script uses
# them as-is for the tab name and working directory.
#
# Uses the declarative layout at ~/.config/zellij/layouts/worktree.kdl
# as the single source of truth for the workspace structure.

set -uo pipefail

# --- Guard: only run inside Zellij ---
if [ -z "${ZELLIJ:-}" ]; then
  echo "zellij-workspace: not inside Zellij — skipping workspace creation"
  exit 0
fi

if ! command -v zellij >/dev/null 2>&1; then
  echo "zellij-workspace: zellij not in PATH — skipping" >&2
  exit 0
fi

# --- Parameters from worktrunk ---
TAB_NAME="${branch:?zellij-workspace: branch not set}"
WORK_DIR="${worktree_path:?zellij-workspace: worktree_path not set}"

# Sanitize branch name for KDL tab name (replace chars unsafe in KDL strings).
TAB_NAME="${TAB_NAME//\//-}"
TAB_NAME="${TAB_NAME//\"/_}"

# Sanitize worktree path for KDL cwd (replace chars unsafe in KDL quoted strings).
WORK_DIR="${WORK_DIR//\"/_}"

# --- Load and parameterize the declarative layout ---
LAYOUT_FILE="${HOME}/.config/zellij/layouts/worktree.kdl"
if [ ! -f "$LAYOUT_FILE" ]; then
  echo "zellij-workspace: layout not found at $LAYOUT_FILE" >&2
  exit 1
fi

# Substitute placeholder markers with actual values.
# awk handles all special chars in replacement strings safely.
LAYOUT_KDL=$(awk -v name="$TAB_NAME" -v path="$WORK_DIR" \
  '{ gsub(/WORKTREE_BRANCH/, name); gsub(/WORKTREE_PATH/, path); print }' \
  "$LAYOUT_FILE")

# --- Create the workspace tab ---
TAB_ID=$(zellij action new-tab \
  --name "$TAB_NAME" \
  --cwd "$WORK_DIR" \
  --layout-string "$LAYOUT_KDL" 2>&1) || {
  echo "zellij-workspace: failed to create tab — $TAB_ID" >&2
  exit 1
}

echo "zellij-workspace: created tab '$TAB_NAME' (id=$TAB_ID) in $WORK_DIR"
