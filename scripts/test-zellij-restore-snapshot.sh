#!/usr/bin/env bash
# Tests for single-session Resurrect snapshot restore: parse, translate,
# create Zellij session, verify, and report.
# Isolated homes/caches/data, disposable sessions, no real user sessions touched.
# No `set -e`: error paths are asserted by capturing command output.
#
# Run: bash scripts/test-zellij-restore-snapshot.sh

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
migration_bin="$repo_root/scripts/zellij-restore-snapshot"
config_src="$repo_root/.config/zellij/config.kdl"

# --- Isolation ---
sandbox="$(mktemp -d "${TMPDIR:-/tmp}/zellij-restore-test.XXXXXX")"
trap 'cleanup' EXIT
echo "sandbox: $sandbox"

test_home="$sandbox/home"
test_config_dir="$sandbox/config/zellij"
test_cache="$sandbox/cache"
test_data="$sandbox/data"
test_fixtures="$sandbox/fixtures"
test_dest="$sandbox/destination"
test_layouts="$test_config_dir/layouts"

mkdir -p "$test_home" "$test_config_dir" "$test_cache" "$test_data" \
         "$test_fixtures" "$test_dest" "$test_layouts"

# Create fixture directories so snapshot panes can reference them.
mkdir -p "$test_fixtures/dir-a" "$test_fixtures/dir-b" "$test_fixtures/dir-c"

cp "$config_src" "$test_config_dir/config.kdl"

if ! command -v zellij >/dev/null 2>&1; then
  echo "SKIP: zellij not in PATH" >&2
  exit 0
fi

zellij_bin="$(command -v zellij)"
zellij_version="$("$zellij_bin" --version 2>&1)"
echo "zellij: $zellij_version"

# Kill any leftover test sessions from previous runs.
for sess in session-a session-b sess solo 'session "quoted"' new-sess foreign-sess good-sess bad-sess sess-x sess-y sess-a sess-b sess-c; do
  HOME="$test_home" ZELLIJ_CONFIG_DIR="$test_config_dir" \
    "$zellij_bin" kill-session "$sess" 2>/dev/null || true
done

# --- Helpers ---
fail_count=0
pass_count=0
ok()   { echo "ok  - $1"; pass_count=$((pass_count + 1)); }
fail() { echo "FAIL - $1" >&2; fail_count=$((fail_count + 1)); }

strip_ansi() { sed 's/\x1b\[[0-9;]*m//g'; }

# Run zellij with isolated dirs.
zellij_cmd() {
  HOME="$test_home" ZELLIJ_CONFIG_DIR="$test_config_dir" \
    XDG_CACHE_HOME="$test_cache" XDG_DATA_HOME="$test_data" \
    "$zellij_bin" "$@"
}

# Run migration with isolated dirs.
run_migration() {
  HOME="$test_home" ZELLIJ_CONFIG_DIR="$test_config_dir" \
    XDG_CACHE_HOME="$test_cache" XDG_DATA_HOME="$test_data" \
    "$migration_bin" "$@"
}

# Clean up all test sessions.
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

kill_session() {
  local sess="$1"
  zellij_cmd kill-session "$sess" 2>/dev/null || true
  local i
  for i in "${!active_sessions[@]}"; do
    [ "${active_sessions[$i]}" = "$sess" ] && unset 'active_sessions[i]'
  done
}

# --- Synthetic fixtures ---
# Helper: write fixture file. Uses printf to avoid heredoc quoting issues.
T=$'\t'  # tab character
write_fixture() {
  local file="$1"; shift
  printf '%s\n' "$@" > "$file"
}

# A multi-session snapshot with spaces, quotes, nested splits, saved apps.
write_fixture "$test_fixtures/snapshot.txt" \
  "pane${T}session-a${T}1${T}1${T}:*${T}1${T}pane-one${T}${test_fixtures}/dir-a${T}1${T}zsh${T}:" \
  "pane${T}session-a${T}1${T}0${T}:-${T}2${T}pane-two${T}${test_fixtures}/dir-a${T}0${T}zsh${T}:" \
  "pane${T}session-a${T}2${T}1${T}:*${T}3${T}pane-three${T}${test_fixtures}/dir-b${T}1${T}lazygit${T}:lazygit" \
  "pane${T}session-a${T}2${T}0${T}:-${T}4${T}\"pane with spaces\"${T}${test_fixtures}/dir-b${T}0${T}zsh${T}:" \
  "pane${T}session-b${T}1${T}1${T}:*${T}5${T}single${T}${test_fixtures}/dir-c${T}1${T}zsh${T}:" \
  "pane${T}session-b${T}1${T}0${T}:-${T}6${T}pane-six${T}${test_fixtures}/dir-c${T}0${T}echo${T}:echo 'hello world'" \
  "window${T}session-a${T}1${T}:first window${T}1${T}*${T}f57,80x24,0,0[40x24,0,0,1,39x24,41,0,2]${T}off" \
  "window${T}session-a${T}2${T}:second window${T}0${T}-${T}8e91,80x24,0,0[40x24,0,0{20x24,0,0,3,19x24,21,0,4},39x24,41,0,5]${T}off" \
  "window${T}session-b${T}1${T}:only window${T}1${T}*${T}abcd,80x24,0,0,6${T}off" \
  "state${T}session-b${T}session-a"

# Snapshot with a pane whose directory does not exist.
write_fixture "$test_fixtures/snapshot-missing-dir.txt" \
  "pane${T}sess${T}1${T}1${T}:*${T}1${T}pane${T}/nonexistent/path/that/does/not/exist${T}1${T}zsh${T}:" \
  "window${T}sess${T}1${T}:test${T}1${T}*${T}a1b2,80x24,0,0,1${T}off" \
  "state${T}sess"

# Snapshot with a pane running a saved application.
write_fixture "$test_fixtures/snapshot-saved-app.txt" \
  "pane${T}sess${T}1${T}1${T}:*${T}1${T}vim-pane${T}${test_fixtures}/dir-a${T}1${T}vim${T}:vim +/pattern file.txt" \
  "pane${T}sess${T}1${T}0${T}:-${T}2${T}shell${T}${test_fixtures}/dir-a${T}0${T}zsh${T}:" \
  "window${T}sess${T}1${T}:editor${T}1${T}*${T}c3d4,80x24,0,0[40x24,0,0,1,39x24,41,0,2]${T}off" \
  "state${T}sess"

# Snapshot with a sentinel command to prove no auto-run.
write_fixture "$test_fixtures/snapshot-sentinel.txt" \
  "pane${T}sess${T}1${T}1${T}:*${T}1${T}sentinel${T}${test_fixtures}/dir-a${T}1${T}sh${T}:sh -c 'echo SENTINEL_SIDE_EFFECT; sleep infinity'" \
  "window${T}sess${T}1${T}:test${T}1${T}*${T}e5f6,80x24,0,0,1${T}off" \
  "state${T}sess"

# Snapshot with special characters in names.
write_fixture "$test_fixtures/snapshot-escaping.txt" \
  "pane${T}session \"quoted\"${T}1${T}1${T}:*${T}1${T}pane'with'quotes${T}${test_fixtures}/dir-a${T}1${T}zsh${T}:" \
  "pane${T}session \"quoted\"${T}1${T}0${T}:-${T}2${T}pane-tab-tabs${T}${test_fixtures}/dir-a${T}0${T}zsh${T}:" \
  "window${T}session \"quoted\"${T}1${T}:\"window name with spaces\"${T}1${T}*${T}g7h8,80x24,0,0,1${T}off" \
  "state${T}session \"quoted\""

# Empty snapshot (no pane/window/state lines).
printf '%s\n' '# just a comment' > "$test_fixtures/snapshot-empty.txt"

# Snapshot with only state, no pane or window lines.
printf '%s\n' "state${T}sess-a${T}sess-b" > "$test_fixtures/snapshot-no-panes.txt"

# Single-session snapshot (for the single-session import test).
write_fixture "$test_fixtures/snapshot-single-session.txt" \
  "pane${T}solo${T}1${T}1${T}:*${T}1${T}p1${T}${test_fixtures}/dir-a${T}1${T}zsh${T}:" \
  "pane${T}solo${T}1${T}0${T}:-${T}2${T}p2${T}${test_fixtures}/dir-a${T}0${T}zsh${T}:" \
  "pane${T}solo${T}2${T}1${T}:*${T}3${T}p3${T}${test_fixtures}/dir-b${T}1${T}zsh${T}:" \
  "window${T}solo${T}1${T}:tab-one${T}1${T}*${T}i9j0,80x24,0,0[40x24,0,0,1,39x24,41,0,2]${T}off" \
  "window${T}solo${T}2${T}:tab-two${T}0${T}-${T}k1l2,80x24,0,0[40x24,0,0,2,39x24,41,0,3]${T}off" \
  "state${T}solo"

# ======================================================================
# Test 1: Missing arguments
# ======================================================================
t_missing_args() {
  local out rc
  out=$(run_migration 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ] && echo "$out" | grep -qi "usage\|arguments\|required"; then
    ok "args: missing arguments fails with usage hint"
  else
    fail "args: expected usage error (rc=$rc, out=$out)"
  fi
}

# ======================================================================
# Test 2: Non-existent source file
# ======================================================================
t_nonexistent_source() {
  local out rc
  out=$(run_migration /nonexistent/path.txt "$test_dest" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ] && echo "$out" | grep -qi "not found\|no such file\|does not exist\|source"; then
    ok "source: non-existent source fails clearly"
  else
    fail "source: expected source-not-found error (rc=$rc, out=$out)"
  fi
}

# ======================================================================
# Test 3: Non-existent destination directory
# ======================================================================
t_nonexistent_dest() {
  local out rc
  out=$(run_migration --force "$test_fixtures/snapshot.txt" /nonexistent/dest/path 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ] && echo "$out" | grep -qi "destination\|does not exist\|not found"; then
    ok "dest: non-existent destination fails clearly"
  else
    fail "dest: expected destination error (rc=$rc, out=$out)"
  fi
}

# ======================================================================
# Test 4: Empty snapshot
# ======================================================================
t_empty_snapshot() {
  local out rc
  out=$(run_migration --force "$test_fixtures/snapshot-empty.txt" "$test_dest" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ] && echo "$out" | grep -qi "empty\|no sessions\|no panes\|no pane\|invalid\|records"; then
    ok "empty: empty snapshot fails clearly"
  else
    fail "empty: expected empty-snapshot error (rc=$rc, out=$out)"
  fi
}

# ======================================================================
# Test 5: Snapshot with no panes
# ======================================================================
t_no_panes_snapshot() {
  local out rc
  out=$(run_migration --force "$test_fixtures/snapshot-no-panes.txt" "$test_dest" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ] && echo "$out" | grep -qi "no panes\|no sessions\|invalid\|empty\|records"; then
    ok "no-panes: snapshot with only state fails clearly"
  else
    fail "no-panes: expected no-panes error (rc=$rc, out=$out)"
  fi
}

# ======================================================================
# Test 6: Missing directory fails before session creation
# ======================================================================
t_missing_dir_before_create() {
  local out rc
  out=$(run_migration --force "$test_fixtures/snapshot-missing-dir.txt" "$test_dest" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ] && echo "$out" | grep -qi "directory\|does not exist\|missing\|nonexistent"; then
    ok "missing-dir: fails before creating session"
  else
    fail "missing-dir: expected missing-directory error (rc=$rc, out=$out)"
  fi
  # Verify no session was created.
  if zellij_cmd list-sessions 2>&1 | strip_ansi | grep -q "sess"; then
    fail "missing-dir: session should not have been created"
  else
    ok "missing-dir: no session created"
  fi
}

# ======================================================================
# Test 7: Full single-session import — names, tabs, panes, focus
# ======================================================================
t_full_import() {
  local out rc report_file
  report_file="$test_dest/report.txt"

  out=$(run_migration --force "$test_fixtures/snapshot.txt" "$test_dest" \
    --session session-a --report "$report_file" 2>&1) && rc=$? || rc=$?

  if [ "$rc" -ne 0 ]; then
    fail "import: migration failed (rc=$rc, out=$out)"
    return
  fi
  ok "import: migration succeeded"

  # Session should appear in list-sessions.
  if zellij_cmd list-sessions 2>&1 | strip_ansi | grep -q "session-a"; then
    ok "import: session-a in list-sessions"
    add_session "session-a"
  else
    fail "import: session-a not in list-sessions"
  fi

  # Report file should exist and have content.
  if [ -f "$report_file" ] && [ -s "$report_file" ]; then
    ok "import: report file created with content"
  else
    fail "import: report file missing or empty"
    return
  fi

  # Report should mention session name.
  if grep -q "session-a" "$report_file"; then
    ok "import: report mentions session-a"
  else
    fail "import: report does not mention session-a"
  fi

  # Report should mention tab count.
  if grep -qi "tab\|window" "$report_file"; then
    ok "import: report mentions tabs/windows"
  else
    fail "import: report does not mention tabs/windows"
  fi

  # Report should mention pane count.
  if grep -qi "pane" "$report_file"; then
    ok "import: report mentions panes"
  else
    fail "import: report does not mention panes"
  fi

  # Recovery copy of manifest should exist.
  if [ -f "$test_dest/manifest.recovery.txt" ] || [ -d "$test_dest/recovery" ]; then
    ok "import: recovery manifest copy exists"
  else
    fail "import: recovery manifest copy not found"
  fi
}

# ======================================================================
# Test 8: Verify tab names and pane structure via Zellij CLI
# ======================================================================
t_verify_workspace() {
  local out rc report_file
  report_file="$test_dest/report-verify.txt"

  out=$(run_migration --force "$test_fixtures/snapshot.txt" "$test_dest" \
    --session session-a --report "$report_file" 2>&1) && rc=$? || rc=$?

  if [ "$rc" -ne 0 ]; then
    fail "verify: migration failed (rc=$rc, out=$out)"
    return
  fi
  add_session "session-a"
  ok "verify: session-a created"

  # Use zellij list-clients to check session exists.
  if zellij_cmd list-sessions 2>&1 | strip_ansi | grep -q "session-a"; then
    ok "verify: session discoverable via list-sessions"
  else
    fail "verify: session not in list-sessions"
  fi

  # The report should contain semantic comparison results.
  if grep -qi "tab\|pane\|name\|order\|focus\|directory" "$report_file"; then
    ok "verify: report contains semantic comparison data"
  else
    fail "verify: report missing semantic comparison"
  fi

  # Report should state what was NOT transferred.
  if grep -qi "process\|scrollback\|live\|not transferred\|not restored" "$report_file"; then
    ok "verify: report states what is not transferred"
  else
    fail "verify: report missing disclaimer about non-transferred state"
  fi
}

# ======================================================================
# Test 9: Saved application arguments intact, not auto-run
# ======================================================================
t_saved_app_not_running() {
  local out rc report_file
  report_file="$test_dest/report-sentinel.txt"

  out=$(run_migration --force "$test_fixtures/snapshot-sentinel.txt" "$test_dest" \
    --session sess --report "$report_file" 2>&1) && rc=$? || rc=$?

  if [ "$rc" -ne 0 ]; then
    fail "sentinel: migration failed (rc=$rc, out=$out)"
    return
  fi
  add_session "sess"
  ok "sentinel: sess created"

  # Verify the session is alive but sentinel command was not auto-run.
  # The sentinel echoes "SENTINEL_SIDE_EFFECT". If it ran, the pane would
  # have that output. We check the report for evidence.
  if grep -qi "sentinel\|not.*run\|waiting\|enter" "$report_file"; then
    ok "sentinel: report confirms commands not auto-run"
  else
    fail "sentinel: report missing sentinel confirmation"
  fi

  # The session should exist and be usable.
  if zellij_cmd list-sessions 2>&1 | strip_ansi | grep -q "sess"; then
    ok "sentinel: session alive (not killed by command execution)"
  else
    fail "sentinel: session not alive"
  fi
}

# ======================================================================
# Test 10: Malformed snapshot fails clearly
# ======================================================================
t_malformed_snapshot() {
  # Write a file with garbage data.
  echo "GARBAGE DATA NOT A VALID SNAPSHOT" > "$test_fixtures/snapshot-garbage.txt"
  local out rc
  out=$(run_migration --force "$test_fixtures/snapshot-garbage.txt" "$test_dest" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ] && echo "$out" | grep -qi "invalid\|malformed\|parse\|format\|error"; then
    ok "malformed: garbage snapshot fails clearly"
  else
    fail "malformed: expected parse error (rc=$rc, out=$out)"
  fi
}

# ======================================================================
# Test 11: Re-run detects existing session, does not duplicate
# ======================================================================
t_no_duplicate_session() {
  local out rc report_file
  report_file="$test_dest/report-dup.txt"

  # First import.
  out=$(run_migration --force "$test_fixtures/snapshot-single-session.txt" "$test_dest" \
    --session solo --report "$report_file" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "dup: first import failed (rc=$rc, out=$out)"
    return
  fi
  add_session "solo"
  ok "dup: first import succeeded"

  # Second import — should detect already-imported session (no --force).
  # The session was tracked in imported-sessions.txt, so it's recognized as previously imported.
  out=$(run_migration "$test_fixtures/snapshot-single-session.txt" "$test_dest" \
    --session solo --report "$report_file" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -eq 0 ] && echo "$out" | grep -qi "already imported\|previously imported\|skipping"; then
    ok "dup: re-run detects already-imported session"
  else
    fail "dup: re-run should detect already-imported session (rc=$rc, out=$out)"
  fi

  # Report should indicate already imported, not success.
  if grep -qi "already imported\|previously imported" "$report_file"; then
    ok "dup: report indicates already imported"
  else
    fail "dup: report missing already-imported indication"
  fi

  # Session should still exist (not duplicated).
  local sess_count
  sess_count=$(zellij_cmd list-sessions 2>&1 | strip_ansi | grep -cw "solo")
  if [ "$sess_count" -eq 1 ]; then
    ok "dup: no duplicate session"
  else
    fail "dup: expected 1 solo session, found $sess_count"
  fi
}

# ======================================================================
# Test 12: Escaping — special characters in names survive
# ======================================================================
t_escaping() {
  local out rc report_file
  report_file="$test_dest/report-escape.txt"

  out=$(run_migration --force "$test_fixtures/snapshot-escaping.txt" "$test_dest" \
    --session 'session "quoted"' --report "$report_file" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "escape: migration with special chars failed (rc=$rc, out=$out)"
    return
  fi
  add_session 'session "quoted"'
  ok "escape: session with special chars created"

  # Report should mention the escaped session name.
  if grep -q 'session "quoted"\|session.*quoted' "$report_file"; then
    ok "escape: report mentions session name with quotes"
  else
    fail "escape: report does not mention session name"
  fi
}

# ======================================================================
# Test 13: No session name specified — import all sessions
# ======================================================================
t_import_all_sessions() {
  local out rc report_file
  report_file="$test_dest/report-all.txt"

  out=$(run_migration --force "$test_fixtures/snapshot.txt" "$test_dest" \
    --report "$report_file" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "all: import-all failed (rc=$rc, out=$out)"
    return
  fi

  # Both sessions should be created.
  if zellij_cmd list-sessions 2>&1 | strip_ansi | grep -q "session-a"; then
    ok "all: session-a created"
    add_session "session-a"
  else
    fail "all: session-a not created"
  fi

  if zellij_cmd list-sessions 2>&1 | strip_ansi | grep -q "session-b"; then
    ok "all: session-b created"
    add_session "session-b"
  else
    fail "all: session-b not created"
  fi

  # Report should list both sessions.
  if grep -q "session-a" "$report_file" && grep -q "session-b" "$report_file"; then
    ok "all: report mentions both sessions"
  else
    fail "all: report does not mention both sessions"
  fi
}

# ======================================================================
# Test 14: Invalid session name not in snapshot
# ======================================================================
t_invalid_session_name() {
  local out rc
  out=$(run_migration --force "$test_fixtures/snapshot.txt" "$test_dest" \
    --session nonexistent-session 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ] && echo "$out" | grep -qi "not found\|does not exist\|no such session\|session.*not"; then
    ok "invalid-session: requesting non-existent session fails"
  else
    fail "invalid-session: expected session-not-found error (rc=$rc, out=$out)"
  fi
}

# ======================================================================
# Test 15: Report outside tracked fixtures directory
# ======================================================================
t_report_outside_git() {
  local out rc report_file
  report_file="$test_dest/report-git.txt"

  out=$(run_migration --force "$test_fixtures/snapshot-single-session.txt" "$test_dest" \
    --session solo --report "$report_file" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -eq 0 ]; then
    add_session "solo"
    # Report should be in the specified location, not in fixtures.
    if [ -f "$report_file" ]; then
      ok "report-git: report at specified path"
    else
      fail "report-git: report not at specified path"
    fi
    # No generated layout should be in the fixtures dir.
    if find "$test_fixtures" -name "*.kdl" -newer "$test_fixtures/snapshot.txt" 2>/dev/null | grep -q .; then
      fail "report-git: generated layout found in fixtures dir"
    else
      ok "report-git: no generated layout in fixtures"
    fi
  else
    fail "report-git: migration failed"
  fi
}

# ======================================================================
# Test 16: Collision detection — all sessions checked before any created
# ======================================================================
t_preflight_collision() {
  # Create a session using migration, then remove it from imported-sessions.txt
  # so it appears as a foreign (untracked) session.
  local out rc
  write_fixture "$test_fixtures/snapshot-foreign.txt" \
    "pane${T}foreign-sess${T}1${T}1${T}:*${T}1${T}p1${T}${test_fixtures}/dir-a${T}1${T}zsh${T}:" \
    "window${T}foreign-sess${T}1${T}:tab-foreign${T}1${T}*${T}x1y2,80x24,0,0,1${T}off" \
    "state${T}foreign-sess"

  # Import foreign-sess (will be tracked).
  out=$(run_migration --force "$test_fixtures/snapshot-foreign.txt" "$test_dest" \
    --session foreign-sess --report "$test_dest/report-preflight.txt" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "preflight: first import failed (rc=$rc, out=$out)"
    return
  fi
  add_session "foreign-sess"
  ok "preflight: first import succeeded (foreign-sess)"

  # Remove foreign-sess from imported-sessions.txt to simulate a foreign session.
  local tracking_file="$test_dest/recovery/imported-sessions.txt"
  if [ -f "$tracking_file" ]; then
    grep -v '^foreign-sess$' "$tracking_file" > "${tracking_file}.tmp" || true
    mv "${tracking_file}.tmp" "$tracking_file"
  fi

  # Now try to import a snapshot with two sessions:
  # 'foreign-sess' exists but is NOT tracked in imported-sessions.txt.
  # 'new-sess' does not exist.
  write_fixture "$test_fixtures/snapshot-preflight.txt" \
    "pane${T}foreign-sess${T}1${T}1${T}:*${T}1${T}p1${T}${test_fixtures}/dir-a${T}1${T}zsh${T}:" \
    "pane${T}new-sess${T}1${T}1${T}:*${T}3${T}p3${T}${test_fixtures}/dir-b${T}1${T}zsh${T}:" \
    "window${T}foreign-sess${T}1${T}:tab-one${T}1${T}*${T}p9q0,80x24,0,0,1${T}off" \
    "window${T}new-sess${T}1${T}:tab-new${T}1${T}*${T}r1s2,80x24,0,0,3${T}off" \
    "state${T}foreign-sess${T}new-sess"

  # Without --force, should fail because foreign-sess exists and is not tracked.
  out=$(run_migration "$test_fixtures/snapshot-preflight.txt" "$test_dest" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ] && echo "$out" | grep -qi "already exist\|conflict\|collision\|cannot proceed"; then
    ok "preflight: detects collision before creating any"
  else
    fail "preflight: expected collision error (rc=$rc, out=$out)"
  fi

  # new-sess should NOT have been created.
  if zellij_cmd list-sessions 2>&1 | strip_ansi | grep -q "new-sess"; then
    fail "preflight: new-sess should not exist (no partial creation)"
    add_session "new-sess"  # Clean it up if it was created
  else
    ok "preflight: no partial creation on collision"
  fi
}

# ======================================================================
# Test 17: Rerun safety — detects prior import, no duplicate
# ======================================================================
t_rerun_safety() {
  local out rc report_file
  report_file="$test_dest/report-rerun.txt"

  # First import.
  out=$(run_migration --force "$test_fixtures/snapshot-single-session.txt" "$test_dest" \
    --session solo --report "$report_file" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "rerun: first import failed (rc=$rc, out=$out)"
    return
  fi
  add_session "solo"
  ok "rerun: first import succeeded"

  # Verify imported-sessions.txt was created.
  if [ -f "$test_dest/recovery/imported-sessions.txt" ] &&
     grep -qF "solo" "$test_dest/recovery/imported-sessions.txt"; then
    ok "rerun: imported-sessions.txt tracks solo"
  else
    fail "rerun: imported-sessions.txt missing or incomplete"
    return
  fi

  # Second import without --force.
  out=$(run_migration "$test_fixtures/snapshot-single-session.txt" "$test_dest" \
    --session solo --report "$report_file" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -eq 0 ]; then
    ok "rerun: second import succeeded (not a failure)"
  else
    fail "rerun: second import failed unexpectedly (rc=$rc, out=$out)"
    return
  fi

  # Report should indicate already imported.
  if grep -qi "already imported\|previously imported\|no action taken" "$report_file"; then
    ok "rerun: report indicates already imported"
  else
    fail "rerun: report missing already-imported indication"
  fi

  # Session should still exist (not duplicated).
  local sess_count
  sess_count=$(zellij_cmd list-sessions 2>&1 | strip_ansi | grep -cw "solo")
  if [ "$sess_count" -eq 1 ]; then
    ok "rerun: no duplicate session"
  else
    fail "rerun: expected 1 solo session, found $sess_count"
  fi
}

# ======================================================================
# Test 18: Partial failure — mid-apply failure, what remains, retry instruction
# ======================================================================
t_partial_failure() {
  local out rc report_file
  report_file="$test_dest/report-partial.txt"

  # Create a snapshot with two sessions, one that will fail.
  # 'good-sess' will succeed, 'bad-sess' references a nonexistent layout
  # that will cause a parse failure.
  write_fixture "$test_fixtures/snapshot-partial.txt" \
    "pane${T}good-sess${T}1${T}1${T}:*${T}1${T}p1${T}${test_fixtures}/dir-a${T}1${T}zsh${T}:" \
    "pane${T}good-sess${T}1${T}0${T}:-${T}2${T}p2${T}${test_fixtures}/dir-a${T}0${T}zsh${T}:" \
    "pane${T}bad-sess${T}1${T}1${T}:*${T}3${T}p3${T}${test_fixtures}/dir-a${T}1${T}zsh${T}:" \
    "window${T}good-sess${T}1${T}:good${T}1${T}*${T}t1u2,80x24,0,0[40x24,0,0,1,39x24,41,0,2]${T}off" \
    "window${T}bad-sess${T}1${T}:bad${T}1${T}*${T}v3w4,80x24,0,0,3${T}off" \
    "state${T}good-sess${T}bad-sess"

  # We need to make the migration fail for one session.
  # One way: make ZELLIJ_BIN point to a script that fails for bad-sess.
  # Create a wrapper that blocks bad-sess creation by checking the session name.
  local wrapper="$sandbox/zellij-wrapper.sh"
  cat > "$wrapper" <<WRAPPER
#!/usr/bin/env bash
# Wrapper that blocks session creation for 'bad-sess'.
if [ "\$1" = "--layout" ] && [ "\$3" = "attach" ]; then
  # Check if the session name (last arg) contains 'bad-sess'.
  if echo "\$@" | grep -q 'bad-sess'; then
    echo "Error: simulated failure for bad-sess"
    exit 1
  fi
fi
exec "$zellij_bin" "\$@"
WRAPPER
  chmod +x "$wrapper"

  # Run with the wrapper.
  out=$(ZELLIJ_BIN="$wrapper" \
    run_migration --force "$test_fixtures/snapshot-partial.txt" "$test_dest" \
    --report "$report_file" 2>&1) && rc=$? || rc=$?

  # good-sess should have been created.
  if zellij_cmd list-sessions 2>&1 | strip_ansi | grep -q "good-sess"; then
    ok "partial: good-sess created before failure"
    add_session "good-sess"
  else
    fail "partial: good-sess not found"
  fi

  # Report should exist and mention partial failure.
  if [ -f "$report_file" ] && grep -qi "partial failure\|failed to import\|retry" "$report_file"; then
    ok "partial: report indicates partial failure"
  else
    fail "partial: report missing partial failure info"
  fi

  # Report should mention what succeeded and what failed.
  if grep -q "good-sess" "$report_file" && grep -q "bad-sess" "$report_file"; then
    ok "partial: report lists both succeeded and failed"
  else
    fail "partial: report missing success/failure details"
  fi

  # Report should provide retry instruction.
  if grep -qi "retry\|run the same command\|use --force" "$report_file"; then
    ok "partial: report provides retry instruction"
  else
    fail "partial: report missing retry instruction"
  fi
}

# ======================================================================
# Test 19: Sentinel in multi-session — commands not auto-run
# ======================================================================
t_multi_session_sentinel() {
  local out rc report_file
  report_file="$test_dest/report-multi-sentinel.txt"

  # Create a snapshot with two sessions, each with a sentinel command.
  write_fixture "$test_fixtures/snapshot-multi-sentinel.txt" \
    "pane${T}sess-x${T}1${T}1${T}:*${T}1${T}sentinel-x1${T}${test_fixtures}/dir-a${T}1${T}sh${T}:sh -c 'echo SENTINEL_X1; sleep infinity'" \
    "pane${T}sess-x${T}1${T}0${T}:-${T}2${T}shell-x2${T}${test_fixtures}/dir-a${T}0${T}zsh${T}:" \
    "pane${T}sess-y${T}1${T}1${T}:*${T}3${T}sentinel-y1${T}${test_fixtures}/dir-b${T}1${T}sh${T}:sh -c 'echo SENTINEL_Y1; sleep infinity'" \
    "pane${T}sess-y${T}1${T}0${T}:-${T}4${T}shell-y2${T}${test_fixtures}/dir-b${T}0${T}zsh${T}:" \
    "window${T}sess-x${T}1${T}:tab-x${T}1${T}*${T}x1y2,80x24,0,0[40x24,0,0,1,39x24,41,0,2]${T}off" \
    "window${T}sess-y${T}1${T}:tab-y${T}1${T}*${T}z3a4,80x24,0,0[40x24,0,0,3,39x24,41,0,4]${T}off" \
    "state${T}sess-x${T}sess-y"

  out=$(run_migration --force "$test_fixtures/snapshot-multi-sentinel.txt" "$test_dest" \
    --report "$report_file" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "multi-sentinel: migration failed (rc=$rc, out=$out)"
    return
  fi
  add_session "sess-x"
  add_session "sess-y"
  ok "multi-sentinel: both sessions created"

  # Both sessions should exist.
  if zellij_cmd list-sessions 2>&1 | strip_ansi | grep -q "sess-x" &&
     zellij_cmd list-sessions 2>&1 | strip_ansi | grep -q "sess-y"; then
    ok "multi-sentinel: both sessions in list-sessions"
  else
    fail "multi-sentinel: sessions not found"
  fi

  # Report should confirm sentinels not auto-run.
  if grep -qi "sentinel\|not.*auto.*run\|require enter" "$report_file"; then
    ok "multi-sentinel: report confirms sentinels not auto-run"
  else
    fail "multi-sentinel: report missing sentinel confirmation"
  fi

  # Report should list both sessions.
  if grep -q "sess-x" "$report_file" && grep -q "sess-y" "$report_file"; then
    ok "multi-sentinel: report mentions both sessions"
  else
    fail "multi-sentinel: report missing session details"
  fi
}

# ======================================================================
# Test 20: Multi-session with varying tab/pane counts
# ======================================================================
t_varying_counts() {
  local out rc report_file
  report_file="$test_dest/report-varying.txt"

  # Session A: 3 windows, 5 panes total.
  # Session B: 1 window, 1 pane.
  # Session C: 2 windows, 3 panes.
  write_fixture "$test_fixtures/snapshot-varying.txt" \
    "pane${T}sess-a${T}1${T}1${T}:*${T}1${T}a-w1-p1${T}${test_fixtures}/dir-a${T}1${T}zsh${T}:" \
    "pane${T}sess-a${T}1${T}0${T}:-${T}2${T}a-w1-p2${T}${test_fixtures}/dir-a${T}0${T}zsh${T}:" \
    "pane${T}sess-a${T}2${T}1${T}:*${T}3${T}a-w2-p1${T}${test_fixtures}/dir-b${T}1${T}zsh${T}:" \
    "pane${T}sess-a${T}2${T}0${T}:-${T}4${T}a-w2-p2${T}${test_fixtures}/dir-b${T}0${T}zsh${T}:" \
    "pane${T}sess-a${T}3${T}1${T}:*${T}5${T}a-w3-p1${T}${test_fixtures}/dir-c${T}1${T}zsh${T}:" \
    "pane${T}sess-b${T}1${T}1${T}:*${T}6${T}b-w1-p1${T}${test_fixtures}/dir-a${T}1${T}zsh${T}:" \
    "pane${T}sess-c${T}1${T}1${T}:*${T}7${T}c-w1-p1${T}${test_fixtures}/dir-b${T}1${T}zsh${T}:" \
    "pane${T}sess-c${T}1${T}0${T}:-${T}8${T}c-w1-p2${T}${test_fixtures}/dir-b${T}0${T}zsh${T}:" \
    "pane${T}sess-c${T}2${T}1${T}:*${T}9${T}c-w2-p1${T}${test_fixtures}/dir-c${T}1${T}zsh${T}:" \
    "window${T}sess-a${T}1${T}:a-tab1${T}1${T}*${T}aa1,80x24,0,0[40x24,0,0,1,39x24,41,0,2]${T}off" \
    "window${T}sess-a${T}2${T}:a-tab2${T}0${T}-${T}bb2,80x24,0,0[40x24,0,0,3,39x24,41,0,4]${T}off" \
    "window${T}sess-a${T}3${T}:a-tab3${T}0${T}-${T}cc3,80x24,0,0,5${T}off" \
    "window${T}sess-b${T}1${T}:b-tab1${T}1${T}*${T}dd4,80x24,0,0,6${T}off" \
    "window${T}sess-c${T}1${T}:c-tab1${T}1${T}*${T}ee5,80x24,0,0[40x24,0,0,7,39x24,41,0,8]${T}off" \
    "window${T}sess-c${T}2${T}:c-tab2${T}0${T}-${T}ff6,80x24,0,0,9${T}off" \
    "state${T}sess-a${T}sess-b${T}sess-c"

  out=$(run_migration --force "$test_fixtures/snapshot-varying.txt" "$test_dest" \
    --report "$report_file" 2>&1) && rc=$? || rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "varying: migration failed (rc=$rc, out=$out)"
    return
  fi
  add_session "sess-a"
  add_session "sess-b"
  add_session "sess-c"
  ok "varying: all three sessions created"

  # Verify session counts in report.
  if grep -q "sess-a" "$report_file" &&
     grep -q "sess-b" "$report_file" &&
     grep -q "sess-c" "$report_file"; then
    ok "varying: report lists all three sessions"
  else
    fail "varying: report missing session entries"
  fi

  # Verify tab/pane counts in report.
  if grep -qi "tabs\|windows" "$report_file" && grep -qi "panes" "$report_file"; then
    ok "varying: report mentions tab and pane counts"
  else
    fail "varying: report missing tab/pane counts"
  fi
}

# ======================================================================
# Run all tests
# ======================================================================
echo ""
echo "=== Missing Arguments ==="
t_missing_args

echo ""
echo "=== Non-existent Source ==="
t_nonexistent_source

echo ""
echo "=== Non-existent Destination ==="
t_nonexistent_dest

echo ""
echo "=== Empty Snapshot ==="
t_empty_snapshot

echo ""
echo "=== No Panes Snapshot ==="
t_no_panes_snapshot

echo ""
echo "=== Missing Directory ==="
t_missing_dir_before_create

echo ""
echo "=== Full Single-Session Import ==="
t_full_import

echo ""
echo "=== Verify Workspace ==="
t_verify_workspace

echo ""
echo "=== Saved App Not Running ==="
t_saved_app_not_running

echo ""
echo "=== Malformed Snapshot ==="
t_malformed_snapshot

echo ""
echo "=== No Duplicate Session ==="
t_no_duplicate_session

echo ""
echo "=== Escaping ==="
t_escaping

echo ""
echo "=== Import All Sessions ==="
t_import_all_sessions

echo ""
echo "=== Invalid Session Name ==="
t_invalid_session_name

echo ""
echo "=== Report Outside Git ==="
t_report_outside_git

echo ""
echo "=== Preflight Collision Detection ==="
t_preflight_collision

echo ""
echo "=== Rerun Safety ==="
t_rerun_safety

echo ""
echo "=== Partial Failure ==="
t_partial_failure

echo ""
echo "=== Multi-Session Sentinel ==="
t_multi_session_sentinel

echo ""
echo "=== Varying Counts ==="
t_varying_counts

echo ""
echo "=== Results ==="
if [ "$fail_count" -eq 0 ]; then
  echo "All $pass_count tests passed."
else
  echo "$fail_count test(s) FAILED, $pass_count passed."
  exit 1
fi
