#!/usr/bin/env bash
# Contract tests for model-aware automatic compaction (ticket 0005).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
export REPO
OPENCODE_BIN=${OPENCODE_BIN:-$(command -v opencode || true)}
export OPENCODE_BIN
EXPECTED_VERSION=${OPENCODE_EXPECTED_VERSION:-v2.0.22}

if [ ! -f "$REPO/.config/opencode/plugins/model-aware-compaction.ts" ]; then
  printf >&2 'FAIL model-aware compaction plugin is missing\n'
  exit 1
fi
if ! grep -q '"auto": false' "$REPO/.config/opencode/opencode.json" || \
   ! grep -q '"tokens": 8000' "$REPO/.config/opencode/opencode.json"; then
  printf >&2 'FAIL native compaction configuration must keep only the adapter trigger and 8,000 recent tokens\n'
  exit 1
fi
printf 'ok  - server plugin is discoverable; native early auto-compaction is disabled and keep.tokens is 8000\n'

if command -v bun >/dev/null 2>&1; then
  bun test "$REPO/.config/opencode/plugins/model-aware-compaction/" || exit 1
else
  printf >&2 'FAIL bun is required for the deterministic policy contract tests\n'
  exit 1
fi

if [ -n "$OPENCODE_BIN" ] && [ -x "$OPENCODE_BIN" ] && \
   [ "$("$OPENCODE_BIN" --version 2>/dev/null | head -1)" = "opencode $EXPECTED_VERSION" ]; then
  python3 "$REPO/scripts/test-opencode-compaction-driver.py"
else
  printf 'SKIP installed-runtime checks (set OPENCODE_BIN to OpenCode %s)\n' "$EXPECTED_VERSION"
fi
