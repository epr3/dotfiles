#!/usr/bin/env bash
# Contract tests for the themed dumb-zone statusline plugin (ticket 0004).
#
# Part 1 is static and always runs: plugin registration in the managed CLI
# settings, independence from Pi (no Pi themes, no Pi runtime imports), and
# display-only behavior (no compaction trigger, no response rewriting, no tool
# hooks).
# Part 2 runs the pure contract suites with bun: every dumb-zone boundary value
# (immediately around each third, exactly 200,000 tokens, above the limit),
# small-model clamping, override precedence, and honest-unavailable rendering,
# all delivered as controlled usage/model metadata at the plugin's host-boundary
# seam. No credentials and no model calls.
# Part 3 needs the target v2 CLI and an isolated HOME/XDG/TMP environment: it
# boots the real CLI into a fixture session and asserts the registered plugin
# renders the honest unavailable footer. Model calls would fail in this
# sandbox; none are attempted.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
ASSET_DIR="$REPO/.config/opencode"
PLUGIN_DIR="$ASSET_DIR/plugins/dumb-zone"
OPENCODE_BIN=${OPENCODE_BIN:-$(command -v opencode || true)}
export OPENCODE_BIN
export REPO
EXPECTED_VERSION=${OPENCODE_EXPECTED_VERSION:-v2.0.22}

failures=0
ok() { printf 'ok  - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1" >&2; failures=$((failures + 1)); }
skip() { printf 'SKIP - %s\n' "$1"; }

TMPWORK=$(mktemp -d "${TMPDIR:-/tmp}/opencode-zone-tests.XXXXXX") || exit 1
cleanup() { rm -rf "$TMPWORK"; }
trap cleanup EXIT
BUN_LOG="$TMPWORK/bun.log"
RUNTIME_LOG="$TMPWORK/runtime.log"

runtime_ok() {
  [ -n "$OPENCODE_BIN" ] && [ -x "$OPENCODE_BIN" ] && \
    [ "$("$OPENCODE_BIN" --version 2>/dev/null | head -1)" = "opencode $EXPECTED_VERSION" ]
}

# --------------------------------------------------------------------------
# Part 1: static registration, independence, and display-only behavior
# --------------------------------------------------------------------------

if [ ! -f "$PLUGIN_DIR/zone.ts" ] || [ ! -f "$PLUGIN_DIR/tui.tsx" ] || [ ! -f "$PLUGIN_DIR/segments.ts" ]; then
  fail 'dumb-zone plugin sources exist in the managed config'
else
  ok 'dumb-zone plugin sources exist in the managed config'
fi

if grep -rn "earendil\|@earendil\|\.pi/\|pi-extensions\|/\.pi\b" "$PLUGIN_DIR" --include="*.ts" --include="*.tsx" | grep -q .; then
  fail 'dumb-zone imports no Pi runtime code or references the Pi source tree'
else
  ok 'dumb-zone imports no Pi runtime code or references the Pi source tree'
fi

if ! grep -q '"plugins": \["./plugins/dumb-zone"\]' "$ASSET_DIR/cli.json"; then
  fail 'cli.json registers the dumb-zone CLI plugin'
else
  ok 'cli.json registers the dumb-zone CLI plugin'
fi

# Display-only: no tool hooks, no compaction triggering, no response rewriting.
if grep -n "tool\.hook\|execute\.before\|chat\.message\|experimental\.session\.\|session\.compact(" "$PLUGIN_DIR/tui.tsx" | grep -q .; then
  fail 'dumb-zone stays display-only (no tool hooks, no compaction triggers)'
else
  ok 'dumb-zone stays display-only (no tool hooks, no compaction triggers)'
fi

# The fixed contract must not scale with the advertised window: classify clamps
# the effective limit to the window but nothing scales the limit upward.
if ! grep -n "Math\.max.*effectiveLimit\|effectiveLimit.*Math\.max" "$PLUGIN_DIR/zone.ts" | grep -q .; then
  ok 'the effective limit never scales upward with the model window'
else
  fail 'the effective limit never scales upward with the model window'
fi

# Host boundary registration and teardown shape: the setup claims a footer slot
# and returns a cleanup that stops every subscription.
if head -1 "$PLUGIN_DIR/tui.tsx" | grep -q '@opentui/solid'; then
  ok 'the CLI plugin entry opens with the OpenTUI Solid import source'
else
  fail 'the CLI plugin entry opens with the OpenTUI Solid import source'
fi
if grep -q 'prompt\.footer\.status' "$PLUGIN_DIR/tui.tsx" && grep -q 'return () =>' "$PLUGIN_DIR/tui.tsx"; then
  ok 'the plugin contributes to the prompt footer status row and returns cleanup'
else
  fail 'the plugin contributes to the prompt footer status row and returns cleanup'
fi

if find "$PLUGIN_DIR" -type l -print -quit | grep -q .; then
  fail 'dumb-zone assets contain no symlinks (independence)'
else
  ok 'dumb-zone assets contain no symlinks (independence)'
fi
if find "$ASSET_DIR" \( -name node_modules -o -name auth.json -o -name "*.log" \) -print -quit | grep -q .; then
  fail 'managed config still excludes runtime state and installed dependencies'
else
  ok 'managed config still excludes runtime state and installed dependencies'
fi

# --------------------------------------------------------------------------
# Part 2: pure contract suites (bun)
# --------------------------------------------------------------------------

if command -v bun >/dev/null 2>&1; then
  if (cd "$REPO" && bun test ./.config/opencode/plugins/dumb-zone/) > "$BUN_LOG" 2>&1; then
    ok "zone and footer contracts pass: $(grep -o '[0-9]* pass' "$BUN_LOG" | head -1)"
  else
    tail -30 "$BUN_LOG" >&2
    fail 'zone and footer contract suites (bun)'
  fi
else
  skip 'bun is not available; pure contract suites not run'
fi

# --------------------------------------------------------------------------
# Part 3: installed-runtime registration and render (isolated sandbox)
# --------------------------------------------------------------------------

if runtime_ok; then
  if python3 "$REPO/scripts/test-opencode-statusline-driver.py" > "$RUNTIME_LOG" 2>&1; then
    ok 'the installed CLI reconciles the dumb-zone plugin and renders the honest unavailable line'
  else
    cat "$RUNTIME_LOG" >&2
    fail 'dumb-zone installed-runtime probe'
  fi
else
  skip 'dumb-zone installed-runtime probe (set OPENCODE_BIN to the target v2 CLI)'
fi

if [ "$failures" -gt 0 ]; then
  printf >&2 'FAIL dumb-zone statusline contract tests (%s failure[s])\n' "$failures"
  exit 1
fi
printf 'PASS dumb-zone statusline contract tests\n'
