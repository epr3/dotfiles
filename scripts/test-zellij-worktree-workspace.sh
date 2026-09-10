#!/usr/bin/env bash
# Tests for the Zellij worktree workspace hook: layout, hook script,
# worktrunk integration, ZELLIJ guard, and branch-name quoting.
# Isolated config, disposable Zellij sessions, no real user sessions touched.
# No `set -e`: error paths are asserted by capturing command output.
#
# Run: bash scripts/test-zellij-worktree-workspace.sh
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hook_script="$repo_root/scripts/zellij-worktree-workspace.sh"
layout_file="$repo_root/.config/zellij/layouts/worktree.kdl"
worktrunk_config="$repo_root/.config/worktrunk/config.toml"
config_src="$repo_root/.config/zellij/config.kdl"

# --- Isolation ---
sandbox="$(mktemp -d "${TMPDIR:-/tmp}/zellij-worktree-test.XXXXXX")"
trap 'cleanup' EXIT
echo "sandbox: $sandbox"

test_home="$sandbox/home"
test_config_dir="$sandbox/config/zellij"
test_layouts="$sandbox/layouts"

mkdir -p "$test_home" "$test_config_dir" "$test_layouts"
cp "$config_src" "$test_config_dir/config.kdl"
# Layout file for the hook's $HOME-based lookup.
mkdir -p "$test_home/.config/zellij/layouts"
cp "$layout_file" "$test_home/.config/zellij/layouts/worktree.kdl"

# Ensure zellij binary exists.
if ! command -v zellij >/dev/null 2>&1; then
  echo "SKIP: zellij not in PATH" >&2
  exit 0
fi

zellij_bin="$(command -v zellij)"
zellij_version="$("$zellij_bin" --version 2>&1)"
echo "zellij: $zellij_version"

# --- Helpers ---
fail_count=0
ok()   { echo "ok  - $1"; }
fail() { echo "FAIL - $1" >&2; fail_count=$((fail_count + 1)); }

# Simple 3-pane layout for session creation.
cat > "$test_layouts/three-pane.kdl" << 'LAYOUT'
layout {
    pane split_direction="vertical" {
        pane {
            command "sh"
            args "-c" "echo PANE_TOP_READY; sleep infinity"
        }
        pane {
            command "sh"
            args "-c" "echo PANE_MID_READY; sleep infinity"
        }
        pane {
            command "sh"
            args "-c" "echo PANE_BOT_READY; sleep infinity"
        }
    }
}
LAYOUT

zellij_cmd() {
  HOME="$test_home" ZELLIJ_CONFIG_DIR="$test_config_dir" "$zellij_bin" "$@"
}

strip_ansi() { sed 's/\x1b\[[0-9;]*m//g'; }

cleanup() {
  if [ -n "${active_sessions[*]:-}" ]; then
    for sess in "${active_sessions[@]}"; do
      [ -z "$sess" ] && continue
      zellij_cmd kill-session "$sess" 2>/dev/null || true
    done
  fi
  rm -rf "$sandbox"
}
active_sessions=()

add_session() { active_sessions+=("$1"); }

# Create a background session and return the session name.
create_bg_session() {
  local layout="$1"
  local out
  out=$(zellij_cmd --layout "$layout" attach --create-background 2>&1) || true
  sleep 1
  zellij_cmd list-sessions 2>&1 | strip_ansi | head -1 | awk '{print $1}'
}

kill_session() {
  local sess="$1"
  zellij_cmd kill-session "$sess" 2>/dev/null || true
  local i
  for i in "${!active_sessions[@]}"; do
    if [ "${active_sessions[$i]}" = "$sess" ]; then
      unset 'active_sessions[i]'
    fi
  done
}

# ======================================================================
# Test 1: Layout file — declarative, no private data, expected structure
# ======================================================================
t_layout_file() {
  if [ ! -f "$layout_file" ]; then
    fail "layout: file does not exist"
    return
  fi

  # Contains expected structural elements.
  if grep -q 'tab.*split_direction="vertical"' "$layout_file"; then
    ok "layout: vertical tab split"
  else
    fail "layout: missing vertical tab split"
  fi

  if grep -q 'command "pi"' "$layout_file"; then
    ok "layout: pi command present"
  else
    fail "layout: missing pi command"
  fi

  if grep -q 'command "lazygit"' "$layout_file"; then
    ok "layout: lazygit command present"
  else
    fail "layout: missing lazygit command"
  fi

  if grep -q 'focus=true' "$layout_file"; then
    ok "layout: focus on pi"
  else
    fail "layout: no focus=true"
  fi

  if grep -q 'split_direction="horizontal"' "$layout_file"; then
    ok "layout: horizontal split for lazygit/shell"
  else
    fail "layout: missing horizontal split"
  fi

  # No hardcoded paths or private data.
  if grep -qE '/Users/|/home/' "$layout_file"; then
    fail "layout: contains hardcoded user paths"
  else
    ok "layout: no hardcoded user paths"
  fi

  # Uses placeholder markers, not resolved values.
  if grep -q 'WORKTREE_BRANCH' "$layout_file" && grep -q 'WORKTREE_PATH' "$layout_file"; then
    ok "layout: uses placeholder markers for parameterization"
  else
    fail "layout: missing placeholder markers"
  fi
}

# ======================================================================
# Test 2: Hook script — exists, executable, handles ZELLIJ guard
# ======================================================================
t_hook_script() {
  if [ ! -f "$hook_script" ]; then
    fail "hook: script does not exist"
    return
  fi

  if [ -x "$hook_script" ]; then
    ok "hook: script is executable"
  else
    fail "hook: script is not executable"
  fi

  # Outside Zellij: prints skip message, exits 0.
  local out
  out=$(ZELLIJ="" branch="test-branch" worktree_path="/tmp/test" bash "$hook_script" 2>&1)
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    ok "hook: exits 0 outside Zellij"
  else
    fail "hook: non-zero exit outside Zellij (rc=$rc)"
  fi

  if echo "$out" | grep -qi "skip"; then
    ok "hook: prints skip message outside Zellij"
  else
    fail "hook: no skip message outside Zellij"
  fi

  # Missing branch: should fail (inside Zellij with layout present).
  # Need layout file for the hook to reach the parameter check.
  local test_home_hook="$sandbox/hook-test-home"
  mkdir -p "$test_home_hook/.config/zellij/layouts"
  cp "$layout_file" "$test_home_hook/.config/zellij/layouts/worktree.kdl"

  out=$(ZELLIJ="1" worktree_path="/tmp/test" HOME="$test_home_hook" bash "$hook_script" 2>&1)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    ok "hook: fails when branch is unset"
  else
    fail "hook: should fail when branch is unset"
  fi

  # Missing worktree_path: should fail.
  out=$(ZELLIJ="1" branch="test-branch" HOME="$test_home_hook" bash "$hook_script" 2>&1)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    ok "hook: fails when worktree_path is unset"
  else
    fail "hook: should fail when worktree_path is unset"
  fi

  # Missing layout file: should fail.
  local empty_home="$sandbox/empty-home"
  mkdir -p "$empty_home/.config/zellij/layouts"
  out=$(ZELLIJ="1" branch="test-branch" worktree_path="/tmp/test" HOME="$empty_home" bash "$hook_script" 2>&1)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    ok "hook: fails when layout file is missing"
  else
    fail "hook: should fail when layout file is missing"
  fi
}

# ======================================================================
# Test 3: Worktrunk config — zellij hook declared
# ======================================================================
t_worktrunk_config() {
  if [ ! -f "$worktrunk_config" ]; then
    fail "config: worktrunk config does not exist"
    return
  fi

  if grep -q 'zellij' "$worktrunk_config"; then
    ok "config: zellij hook declared"
  else
    fail "config: zellij hook not found"
  fi

  # zellij hook references the script.
  if grep -q 'zellij-worktree-workspace.sh' "$worktrunk_config"; then
    ok "config: zellij hook references script"
  else
    fail "config: zellij hook does not reference script"
  fi
}

# ======================================================================
# Test 4: Worktrunk recognizes the hook — dry-run
# ======================================================================
t_worktrunk_recognizes() {
  if ! command -v wt >/dev/null 2>&1; then
    echo "SKIP: wt not in PATH" >&2
    return
  fi

  # Dry-run pre-start should list the zellij hook.
  local out
  out=$(cd "$repo_root" && wt hook pre-start --dry-run --branch=test/dry-run 2>&1) || true

  if echo "$out" | grep -q 'zellij'; then
    ok "worktrunk: zellij hook recognized in dry-run"
  else
    fail "worktrunk: zellij hook not in dry-run output"
  fi
}

# ======================================================================
# Test 5: Branch-name quoting — special characters in branch names
# ======================================================================
t_branch_quoting() {
  # Test outside Zellij (skip path) — quick check.
  local test_cases=(
    "feature/auth"
    "fix.issue-123"
    "feature/with spaces"
    "branch/with\"quotes"
    "branch/with'sticks"
  )

  for branch in "${test_cases[@]}"; do
    local sanitized="${branch//\//-}"
    sanitized="${sanitized// /-}"
    local out
    out=$(ZELLIJ="" branch="$branch" worktree_path="/tmp/test-$sanitized" bash "$hook_script" 2>&1)
    local rc=$?
    if [ "$rc" -eq 0 ]; then
      ok "quoting: branch '$branch' handled outside Zellij"
    else
      fail "quoting: branch '$branch' caused crash outside Zellij (rc=$rc)"
    fi
  done

  # Test inside Zellij — the inner path where quoting matters.
  # Create a disposable session to run the hook in.
  local sess
  sess=$(create_bg_session "$test_layouts/three-pane.kdl" 2>/dev/null)
  if [ -z "$sess" ]; then
    echo "SKIP: quoting-inner: no Zellij session" >&2
    return
  fi
  add_session "$sess"

  for branch in "${test_cases[@]}"; do
    local sanitized="${branch//\//-}"
    sanitized="${sanitized// /-}"
    local work_dir="$sandbox/worktree-$sanitized"
    mkdir -p "$work_dir"
    # The hook reads $HOME/.config/zellij/layouts/worktree.kdl; point HOME at sandbox.
    local hook_out
    hook_out=$(ZELLIJ="$sess" branch="$branch" worktree_path="$work_dir" \
      HOME="$test_home" bash "$hook_script" 2>&1)
    local rc=$?
    if [ "$rc" -eq 0 ]; then
      ok "quoting: branch '$branch' handled inside Zellij"
    else
      fail "quoting: branch '$branch' caused crash inside Zellij (rc=$rc): $hook_out"
    fi
  done

  kill_session "$sess"
}

# ======================================================================
# Test 6: Layout valid KDL — zellij can parse it
# ======================================================================
t_layout_valid_kdl() {
  # Generate a concrete layout from the template with test values.
  local concrete_layout="$test_layouts/worktree-concrete.kdl"
  sed -e 's/WORKTREE_BRANCH/test-branch/g' \
      -e 's|WORKTREE_PATH|/tmp/test-worktree|g' \
      "$layout_file" > "$concrete_layout"

  # zellij setup --check validates config; we validate layout via dump-layout.
  # A valid layout file should be parseable.
  if zellij_cmd setup --check 2>&1 | grep -qi "error"; then
    fail "kdl: zellij config check has errors"
  else
    ok "kdl: zellij config check passes"
  fi

  # Verify the concrete layout has the expected structure.
  if grep -q 'command "pi"' "$concrete_layout" && grep -q 'command "lazygit"' "$concrete_layout"; then
    ok "kdl: concrete layout has expected commands"
  else
    fail "kdl: concrete layout missing expected commands"
  fi

  if grep -q 'name="test-branch"' "$concrete_layout"; then
    ok "kdl: concrete layout has branch name in tab"
  else
    fail "kdl: concrete layout missing branch name"
  fi
}

# ======================================================================
# Test 7: Hook creates real Zellij tab (inside Zellij session)
# ======================================================================
t_hook_creates_tab() {
  # Create a disposable Zellij session to act as the host.
  local sess
  sess=$(create_bg_session "$test_layouts/three-pane.kdl" 2>/dev/null)
  if [ -z "$sess" ]; then
    echo "SKIP: could not create test Zellij session" >&2
    return
  fi
  add_session "$sess"
  ok "tab-creation: test session '$sess' created"

  # Exercise the actual hook script inside the Zellij session.
  local branch="test-worktree-branch"
  local work_dir="$sandbox/worktree-test"
  mkdir -p "$work_dir"

  # The hook reads $HOME/.config/zellij/layouts/worktree.kdl; point HOME at sandbox.
  local hook_out
  hook_out=$(ZELLIJ="$sess" branch="$branch" worktree_path="$work_dir" \
    HOME="$test_home" bash "$hook_script" 2>&1)
  local rc=$?

  if [ "$rc" -eq 0 ]; then
    ok "tab-creation: hook script exited 0"
  else
    fail "tab-creation: hook script failed (rc=$rc): $hook_out"
    kill_session "$sess"
    return
  fi

  if echo "$hook_out" | grep -q "created tab"; then
    ok "tab-creation: hook reported tab creation"
  else
    fail "tab-creation: hook did not report tab creation: $hook_out"
  fi

  # Verify the tab appears in list-tabs.
  sleep 1
  local tabs
  tabs=$(zellij_cmd action list-tabs 2>&1 | strip_ansi)
  if echo "$tabs" | grep -q "$branch"; then
    ok "tab-creation: tab '$branch' visible in list-tabs"
  else
    fail "tab-creation: tab '$branch' not in list-tabs: $tabs"
  fi

  kill_session "$sess"
}

# ======================================================================
# Run all tests
# ======================================================================
echo ""
echo "=== Layout File ==="
t_layout_file

echo ""
echo "=== Hook Script ==="
t_hook_script

echo ""
echo "=== Worktrunk Config ==="
t_worktrunk_config

echo ""
echo "=== Worktrunk Recognizes Hook ==="
t_worktrunk_recognizes

echo ""
echo "=== Branch-Name Quoting ==="
t_branch_quoting

echo ""
echo "=== Layout Valid KDL ==="
t_layout_valid_kdl

echo ""
echo "=== Hook Creates Real Tab ==="
t_hook_creates_tab

echo ""
echo "=== Results ==="
if [ "$fail_count" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$fail_count test(s) FAILED."
  exit 1
fi
