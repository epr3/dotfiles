#!/usr/bin/env bash
# Contract tests for the independently copied OpenCode v2 assets (ticket 0002).
#
# Part 1 is static and always runs: inventory shape, independence from Pi, and
# no runtime state. Parts 2-3 need the target v2 CLI and an isolated
# HOME/XDG/TMP environment; they make no model calls (a local mock provider is
# used to capture the assembled prompt) and never touch live config or Pi.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
ASSET_DIR="$REPO/.config/opencode"
OPENCODE_BIN=${OPENCODE_BIN:-$(command -v opencode || true)}
EXPECTED_VERSION=${OPENCODE_EXPECTED_VERSION:-v2.0.22}

failures=0
ok() { printf 'ok  - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1" >&2; failures=$((failures + 1)); }

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/opencode-assets.XXXXXX") || exit 1
MOCK_PID=""
SERVER_PID=""
cleanup() {
  [ -n "$MOCK_PID" ]   && kill "$MOCK_PID"   2>/dev/null || true
  [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null || true
  rm -rf "$SANDBOX"
}
trap cleanup EXIT

# --------------------------------------------------------------------------
# Part 1: static inventory, independence, and exclusions
# --------------------------------------------------------------------------

EXPECTED_SKILLS=(
  code-review codebase-design diagnosing-bugs domain-modeling explain-diff
  grill-me grill-with-docs grilling handoff implement improve-codebase-architecture
  merge-context offload-context pr prototype rebase-context research retro
  setup-context tdd teach to-questionnaire to-spec to-tickets triage wait-what
  wayfinder wizard writing-for-agents
)

EXPECTED_SUPPORT=(
  codebase-design/DEEPENING.md
  codebase-design/DESIGN-IT-TWICE.md
  diagnosing-bugs/scripts/hitl-loop.template.sh
  domain-modeling/ADR-FORMAT.md
  domain-modeling/GLOSSARY-FORMAT.md
  explain-diff/PAGE-FORMAT.md
  explain-diff/QUIZ-FORMAT.md
  improve-codebase-architecture/HTML-REPORT.md
  offload-context/offload-context.sh
  pr/CREDITS.md
  prototype/LOGIC.md
  prototype/UI.md
  setup-context/artifact-locations.md
  setup-context/ctx-index.sh
  setup-context/ctx-init.sh
  setup-context/domain.md
  setup-context/global-rules.md
  setup-context/issue-tracker-github.md
  setup-context/issue-tracker-gitlab.md
  setup-context/issue-tracker-local.md
  setup-context/manifest.sh
  setup-context/resolve-location.sh
  setup-context/triage-labels.md
  tdd/mocking.md
  tdd/tests.md
  teach/GLOSSARY-FORMAT.md
  teach/LEARNING-RECORD-FORMAT.md
  teach/MISSION-FORMAT.md
  teach/RESOURCES-FORMAT.md
  triage/AGENT-BRIEF.md
  triage/OUT-OF-SCOPE.md
  wizard/template.sh
  writing-for-agents/SKILL-MECHANICS.md
)

missing_skills=0
for skill in "${EXPECTED_SKILLS[@]}"; do
  [ -f "$ASSET_DIR/skills/$skill/SKILL.md" ] || { fail "missing skill: $skill"; missing_skills=1; }
done
[ "$missing_skills" -eq 0 ] && ok 'all 29 curated skills are present with SKILL.md'

actual_skills=$(find "$ASSET_DIR/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | tr '\n' ' ')
expected_sorted=$(printf '%s\n' "${EXPECTED_SKILLS[@]}" | sort | tr '\n' ' ')
[ "$actual_skills" = "$expected_sorted" ] && ok 'skill inventory has no extras beyond the expected set' || fail "unexpected skill inventory: $actual_skills"

missing_support=0
for f in "${EXPECTED_SUPPORT[@]}"; do
  [ -f "$ASSET_DIR/skills/$f" ] || { fail "missing support file: $f"; missing_support=1; }
done
[ "$missing_support" -eq 0 ] && ok 'all 33 supporting files were copied with their skill trees'

if find "$ASSET_DIR/skills" -type l -print -quit | grep -q .; then
  fail 'skill tree contains a runtime symlink'
else
  ok 'skill tree contains no symlinks back to Pi or anywhere else'
fi

if grep -rInE 'pi/agent|pi-extensions|pi-mono|\$PI_SESSION_ID|/skill:' "$ASSET_DIR/skills" >/dev/null 2>&1; then
  fail 'copied skills still reference Pi-specific paths or vocabulary'
else
  ok 'copied skills contain no Pi-specific path or invocation references'
fi

if [ -f "$ASSET_DIR/AGENTS.md" ]; then
  ok 'global instructions file AGENTS.md is present'
else
  fail 'global instructions file AGENTS.md is missing'
fi

if find "$ASSET_DIR" \( -name auth.json -o -name '*.db' -o -name node_modules -o -name sessions -o -name ctx \) -print -quit | grep -q .; then
  fail 'managed assets contain credential, session, cache, dependency, or context state'
else
  ok 'managed assets exclude credentials, sessions, caches, dependencies, and context worktrees'
fi

# Relative support references inside copied skills must resolve within the copy.
if python3 - "$ASSET_DIR/skills" <<'PY'
import os, re, sys, glob
root = sys.argv[1]
link = re.compile(r'\]\(([^)]+)\)')
dangling = []
for path in glob.glob(root + '/**/*.md', recursive=True):
    base = os.path.dirname(path)
    for match in link.finditer(open(path, encoding='utf-8').read()):
        target = match.group(1).strip().split('#')[0]
        if not target or target.startswith(('http://', 'https://', 'mailto:')):
            continue
        if '.' not in os.path.basename(target):  # prose placeholder, not a file
            continue
        if '/src/' in target:  # illustrative context-path examples
            continue
        if not os.path.exists(os.path.normpath(os.path.join(base, target))):
            dangling.append((path, target))
for path, target in dangling:
    print(f'{path}: {target}', file=sys.stderr)
sys.exit(1 if dangling else 0)
PY
then
  ok 'every referenced supporting file resolves relative to its SKILL.md'
else
  fail 'a copied skill references a missing supporting file'
fi

# --------------------------------------------------------------------------
# Part 3 prerequisites: mock provider used to capture the assembled prompt
# --------------------------------------------------------------------------

cat > "$SANDBOX/mock_provider.py" <<'PY'
import json, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

capture, port = sys.argv[1], int(sys.argv[2])

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get('Content-Length', 0)))
        with open(capture, 'ab') as out:
            out.write(body + b'\n')
        try:
            model = json.loads(body).get('model', 'mock-model')
        except Exception:
            model = 'mock-model'
        chunks = [
            {"id": "chatcmpl-mock", "object": "chat.completion.chunk", "created": 0,
             "model": model, "choices": [{"index": 0, "delta": {"role": "assistant", "content": "ok"}, "finish_reason": None}]},
            {"id": "chatcmpl-mock", "object": "chat.completion.chunk", "created": 0,
             "model": model, "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
             "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2}},
        ]
        payload = ''.join('data: ' + json.dumps(c) + '\n\n' for c in chunks) + 'data: [DONE]\n\n'
        self.send_response(200)
        self.send_header('Content-Type', 'text/event-stream')
        self.end_headers()
        self.wfile.write(payload.encode())

    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"object":"list","data":[]}')

HTTPServer(('127.0.0.1', port), Handler).serve_forever()
PY

if [ -z "$OPENCODE_BIN" ] || [ ! -x "$OPENCODE_BIN" ]; then
  echo "SKIP isolated OpenCode asset runtime checks (set OPENCODE_BIN to the target v2 CLI)"
elif [ "$("$OPENCODE_BIN" --version 2>/dev/null | head -1)" != "opencode $EXPECTED_VERSION" ]; then
  echo "SKIP isolated OpenCode asset runtime checks (expected opencode $EXPECTED_VERSION)"
else
  HOME="$SANDBOX/home"
  export HOME
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_DATA_HOME="$SANDBOX/data"
  export XDG_STATE_HOME="$SANDBOX/state"
  export XDG_CACHE_HOME="$SANDBOX/cache"
  export TMPDIR="$SANDBOX/tmp"
  mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$TMPDIR" "$HOME/project"

  # The isolated runtime sees only the copied assets: no Pi source, no credentials.
  cp -R "$ASSET_DIR" "$XDG_CONFIG_HOME/opencode"
  if find "$XDG_CONFIG_HOME/opencode" \( -name auth.json -o -name node_modules -o -name '*.db' \) -print | grep -q .; then
    fail 'credentials, dependencies, or databases leaked into the isolated config fixture'
  fi
  if [ -e "$HOME/.pi" ]; then
    fail 'isolated fixture unexpectedly exposes a Pi source tree'
  else
    ok 'isolated fixture exposes no Pi source tree to the runtime'
  fi

  # ---- Part 2: discovery and invocation at the installed-runtime boundary ----
  PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')
  ( cd "$HOME/project" && exec env -i PATH="$PATH" HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
      XDG_DATA_HOME="$XDG_DATA_HOME" XDG_STATE_HOME="$XDG_STATE_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" \
      TMPDIR="$TMPDIR" OPENCODE_DISABLE_MODELS_FETCH=1 \
      "$OPENCODE_BIN" serve --hostname 127.0.0.1 --port "$PORT" ) >"$SANDBOX/server.log" 2>&1 &
  SERVER_PID=$!
  ready=0
  for _ in $(seq 1 20); do
    grep -q "server listening on http://127.0.0.1:$PORT" "$SANDBOX/server.log" 2>/dev/null && { ready=1; break; }
    kill -0 "$SERVER_PID" 2>/dev/null || break
    sleep 1
  done

  if [ "$ready" -ne 1 ]; then
    fail "isolated OpenCode server did not start"
    grep -E 'error|Error|invalid|failed' "$SANDBOX/server.log" | sed -E 's/server password .*/server password [redacted]/' >&2 || true
  else
    PASSWORD=$(grep -o 'server password .*' "$SANDBOX/server.log" | awk '{print $3}')
    api() { OPENCODE_PASSWORD="$PASSWORD" "$OPENCODE_BIN" api --server "http://127.0.0.1:$PORT" "$@"; }

    discovered=0
    for _ in $(seq 1 8); do
      if api --param "directory=$HOME/project" skill.list 2>/dev/null > "$SANDBOX/skills.json" \
         && python3 - "$SANDBOX/skills.json" "${EXPECTED_SKILLS[@]}" 2>/dev/null <<'PY'
import json, sys
found = {s.get('id') for s in json.load(open(sys.argv[1])).get('data', [])}
missing = [s for s in sys.argv[2:] if s not in found]
if missing:
    print('missing: ' + ', '.join(missing), file=sys.stderr)
    sys.exit(1)
PY
      then
        discovered=1
        break
      fi
      sleep 1
    done
    if [ "$discovered" -eq 1 ]; then
      ok 'isolated runtime discovers all 29 managed skills'
    else
      fail 'isolated runtime is missing managed skills'
    fi

    api session.create --data '{"title":"asset-probe"}' > "$SANDBOX/session.json" 2>/dev/null
    SESSION=$(python3 -c "import json;print(json.load(open('$SANDBOX/session.json'))['data']['id'])" 2>/dev/null)
    if [ -n "$SESSION" ] && api --param sessionID="$SESSION" experimental.session.skill --data '{"id":"diagnosing-bugs"}' >/dev/null 2>&1 \
       && api --param sessionID="$SESSION" session.message.list > "$SANDBOX/messages.json" 2>/dev/null; then
      if python3 - "$SANDBOX/messages.json" "$ASSET_DIR/skills/diagnosing-bugs/SKILL.md" <<'PY'
import json, sys
messages = json.load(open(sys.argv[1])).get('data', [])
skills = [m for m in messages if m.get('type') == 'skill' and m.get('skill') == 'diagnosing-bugs']
if not skills:
    print('no skill message returned', file=sys.stderr)
    sys.exit(1)
body = open(sys.argv[2], encoding='utf-8').read()
if body.startswith('---'):
    body = body.split('---', 2)[2]
text = skills[-1].get('text', '')
if body.strip()[:40] not in text:
    print('skill body did not match the managed copy', file=sys.stderr)
    sys.exit(1)
if text.lstrip().startswith('---'):
    print('skill injection leaked frontmatter', file=sys.stderr)
    sys.exit(1)
PY
      then
        ok 'isolated runtime loads a representative skill body from the managed copy'
      else
        fail 'representative skill could not be invoked from the isolated runtime'
      fi
    else
      fail 'skill invocation or message inspection failed'
    fi
  fi

  # ---- Part 3: global AGENTS.md is loaded through the supported v2 mechanism ----
  MOCK_PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')
  CAPTURE="$SANDBOX/capture.jsonl"
  python3 "$SANDBOX/mock_provider.py" "$CAPTURE" "$MOCK_PORT" >/dev/null 2>&1 &
  MOCK_PID=$!
  sleep 1

  cat > "$HOME/project/opencode.json" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "mock/mock-model",
  "providers": {
    "mock": {
      "name": "Mock",
      "env": [],
      "package": "@opencode/ai/providers/openai-compatible",
      "settings": { "baseURL": "http://127.0.0.1:$MOCK_PORT/v1" },
      "models": { "mock-model": { "name": "Mock Model", "limit": { "context": 100000, "output": 4096 } } }
    }
  }
}
EOF

  MARKER=$(grep -F 'Skills under `skills/` are independent copies' "$ASSET_DIR/AGENTS.md" | head -1)
  ( cd "$HOME/project" && env -i PATH="$PATH" HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
      XDG_DATA_HOME="$XDG_DATA_HOME" XDG_STATE_HOME="$XDG_STATE_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" \
      TMPDIR="$TMPDIR" OPENCODE_DISABLE_MODELS_FETCH=1 \
      "$OPENCODE_BIN" run --standalone --model mock/mock-model "hello" >"$SANDBOX/run.out" 2>"$SANDBOX/run.err" )
  run_status=$?

  if [ "$run_status" -ne 0 ]; then
    fail "mock-provider prompt run failed (exit $run_status)"
    tail -20 "$SANDBOX/run.err" >&2 || true
  elif [ ! -s "$CAPTURE" ]; then
    fail 'mock provider captured no request'
  elif python3 - "$CAPTURE" <<'PY'
import json, sys
needle = 'Skills under `skills/` are independent copies'
for line in open(sys.argv[1], encoding='utf-8'):
    if not line.strip():
        continue
    for message in json.loads(line).get('messages', []):
        content = message.get('content')
        if isinstance(content, str) and needle in content:
            sys.exit(0)
print('global AGENTS.md text not present in any captured prompt', file=sys.stderr)
sys.exit(1)
PY
  then
    ok 'global AGENTS.md content is loaded into the assembled v2 prompt'
  else
    fail 'global AGENTS.md did not load through the v2 instruction mechanism'
  fi
fi

[ "$failures" -eq 0 ] || exit 1
printf 'PASS OpenCode independent asset contract tests\n'
