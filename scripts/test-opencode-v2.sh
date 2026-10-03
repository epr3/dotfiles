#!/usr/bin/env bash
# Starts the target CLI in a disposable HOME/XDG environment; no auth or model calls.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
OPENCODE_BIN=${OPENCODE_BIN:-$(command -v opencode || true)}
EXPECTED_VERSION=${OPENCODE_EXPECTED_VERSION:-v2.0.22}

if [ -z "$OPENCODE_BIN" ] || [ ! -x "$OPENCODE_BIN" ]; then
  echo "SKIP OpenCode runtime test (set OPENCODE_BIN to the target v2 CLI)"
  exit 0
fi
version=$("$OPENCODE_BIN" --version 2>/dev/null | head -1)
if [ "$version" != "opencode $EXPECTED_VERSION" ]; then
  echo "FAIL expected 'opencode $EXPECTED_VERSION'; got '$version'" >&2
  exit 1
fi

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/opencode-v2.XXXXXX") || exit 1
PID=""
cleanup() {
  if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
  rm -rf "$SANDBOX"
}
trap cleanup EXIT

export HOME="$SANDBOX/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$SANDBOX/data"
export XDG_STATE_HOME="$SANDBOX/state"
export XDG_CACHE_HOME="$SANDBOX/cache"
export TMPDIR="$SANDBOX/tmp"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$TMPDIR"
cp -R "$REPO/.config/opencode" "$XDG_CONFIG_HOME/opencode"

python3 - "$XDG_CONFIG_HOME/opencode/opencode.json" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as config:
    json.load(config)
PY

if find "$XDG_CONFIG_HOME/opencode" \( -name auth.json -o -name sessions -o -name node_modules -o -name opencode.db \) -print | grep -q .; then
  echo 'FAIL runtime state or credentials leaked into the managed config fixture' >&2
  exit 1
fi
if find "$XDG_CONFIG_HOME/opencode" -type l -print -quit | grep -q .; then
  echo 'FAIL managed assets depend on a runtime symlink' >&2
  exit 1
fi

PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()') || exit 1
env -i PATH="$PATH" HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" XDG_DATA_HOME="$XDG_DATA_HOME" XDG_STATE_HOME="$XDG_STATE_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" TMPDIR="$TMPDIR" "$OPENCODE_BIN" serve --hostname 127.0.0.1 --port "$PORT" >"$SANDBOX/server.log" 2>&1 &
PID=$!
ready=0
for _ in $(seq 1 15); do
  if grep -q "server listening on http://127.0.0.1:$PORT" "$SANDBOX/server.log" 2>/dev/null; then
    ready=1
    break
  fi
  if ! kill -0 "$PID" 2>/dev/null; then break; fi
  sleep 1
done
if [ "$ready" -ne 1 ]; then
  echo 'FAIL isolated OpenCode server did not start' >&2
  grep -E 'error|Error|invalid|failed|server listening' "$SANDBOX/server.log" | sed -E 's/server password .*/server password [redacted]/' >&2 || true
  exit 1
fi
printf 'ok  - %s starts with an isolated managed config and no credentials\n' "$version"
printf 'ok  - runtime state and installed dependencies remain outside the managed fixture\n'
printf 'PASS OpenCode v2 runtime smoke test\n'
