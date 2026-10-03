#!/usr/bin/env bash
# Contract tests for native OpenCode v2 agent workflows and model preferences (ticket 0003).
#
# Part 1 is static and always runs: managed preference shape, RTK plugin dispositions,
# and honest global-instruction wording.
# Part 2 validates preferred provider/model/reasoning combinations against the live
# installed-release catalog and authentication support (read-only; no model calls).
# Part 3 drives the isolated runtime (private HOME/XDG/TMP, local mock provider, mock
# rtk binary) to demonstrate native subagents, hard read-only exploration, the
# runtime tool catalog, and the RTK plugin's rewrite semantics. No production
# credentials and no paid model calls are used.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
export REPO
ASSET_DIR="$REPO/.config/opencode"
OPENCODE_BIN=${OPENCODE_BIN:-$(command -v opencode || true)}
export OPENCODE_BIN
EXPECTED_VERSION=${OPENCODE_EXPECTED_VERSION:-v2.0.22}

failures=0
ok() { printf 'ok  - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1" >&2; failures=$((failures + 1)); }
skip() { printf 'SKIP - %s\n' "$1"; }

runtime_ok() {
  [ -n "$OPENCODE_BIN" ] && [ -x "$OPENCODE_BIN" ] && \
    [ "$("$OPENCODE_BIN" --version 2>/dev/null | head -1)" = "opencode $EXPECTED_VERSION" ]
}

# --------------------------------------------------------------------------
# Part 1: static checks on the managed configuration
# --------------------------------------------------------------------------

if [ ! -f "$ASSET_DIR/opencode.json" ]; then
  fail 'managed opencode.json is missing'
elif ! python3 -c "import json;json.load(open('$ASSET_DIR/opencode.json'))" 2>/dev/null; then
  fail 'managed opencode.json does not parse'
else
  ok 'managed opencode.json parses'
fi

python3 - "$ASSET_DIR/opencode.json" <<'PY' && ok 'managed model preferences match the validated combinations' || failures=$((failures + 1))
import json, sys
cfg = json.load(open(sys.argv[1]))
agents = cfg.get("agents", {})
explore = agents.get("explore", {}).get("model", {})
general = agents.get("general", {}).get("model", {})
default_model = cfg.get("model")
errors = []
if (explore.get("providerID"), explore.get("model"), explore.get("variant")) != ("opencode-go", "qwen3.8-flash", "low"):
    errors.append(f"explore model pref wrong: {explore}")
if (general.get("providerID"), general.get("model"), general.get("variant")) != ("opencode-go", "glm-5.3-flash", "high"):
    errors.append(f"general model pref wrong: {general}")
if default_model != "openai/gpt-6.1-sol":
    errors.append(f"default model wrong: {default_model}")
deny_actions = [r.get("action") for r in agents.get("explore", {}).get("permissions", []) if r.get("effect") == "deny"]
if "edit" not in deny_actions or "shell" not in deny_actions:
    errors.append(f"explore lacks hard read-only deny rules: {deny_actions}")
if errors:
    print("FAIL - " + "; ".join(errors), file=sys.stderr)
    sys.exit(1)
PY

python3 - "$ASSET_DIR/plugins/rtk.ts" <<'PY' && ok 'RTK plugin keeps the Pi rewrite contract' || failures=$((failures + 1))
import sys
src = open(sys.argv[1], encoding="utf-8").read()
checks = {
    "version floor >= 0.23.0": "MIN_SUPPORTED_RTK_MINOR = 23",
    "exit code 3 (advisory) rewrites accepted": "code !== 0 && code !== 3",
    "rewrite timeout is bounded": "REWRITE_TIMEOUT_MS",
    "RTK_DISABLED respected": "RTK_DISABLED",
    "self-rewrites skipped": 'command.startsWith("rtk ")',
    "fail-open hook error handling": "passing through command",
}
problems = [name for name, needle in checks.items() if needle not in src]
if problems:
    print("FAIL - RTK plugin is missing: " + "; ".join(problems), file=sys.stderr)
    sys.exit(1)
PY

if grep -qE '(lsp_[a-z_]+|todo_(write|read))' "$ASSET_DIR/AGENTS.md"; then
  fail 'global instructions still reference Pi-only tool names (lsp_*, todo_*)'
else
  ok 'global instructions reference no Pi-only tool names'
fi

# --------------------------------------------------------------------------
# Part 2: preferences against the actual installed catalog + authentication
# --------------------------------------------------------------------------

if ! runtime_ok; then
  skip 'catalog/auth checks (target v2 CLI unavailable); static checks only'
else
  MODELS_FILE=$(mktemp "${TMPDIR:-/tmp}/oc-models.XXXXXX")
  VARIANTS_FILE=""
  AUTHIDS_FILE=""
  trap 'rm -f "$MODELS_FILE" "$VARIANTS_FILE" "$AUTHIDS_FILE"' EXIT
  "$OPENCODE_BIN" models >"$MODELS_FILE" 2>/dev/null || true
  missing_ids=0
  for mid in openai/gpt-6.1-sol opencode-go/qwen3.8-flash opencode-go/glm-5.3-flash \
             opencode-go/kimi-k2.7-code opencode-go/mimo-v2.6-flash opencode-go/deepseek-v4.1-flash; do
    if grep -qx "$mid" "$MODELS_FILE"; then :; else
      fail "installed catalog does not list preferred model $mid"
      missing_ids=1
    fi
  done
  if [ "$missing_ids" -eq 0 ]; then
    ok 'all preferred model IDs exist in the installed catalog'
  fi

  VARIANTS_FILE=$(mktemp)
  if "$OPENCODE_BIN" api model.list >"$VARIANTS_FILE" 2>/dev/null; then
    python3 - "$VARIANTS_FILE" <<'PY' && ok 'configured variants exist in the installed catalog' || failures=$((failures + 1))
import json, sys
data = json.load(open(sys.argv[1])).get("data", [])
variants = {}
for m in data:
    if m.get("modelID"):
        variants.setdefault((m.get("providerID"), m["modelID"]), set()).update(
            v.get("id") for v in m.get("variants", []) if v.get("id"))
errors = []
for p, mid, v in [("opencode-go", "qwen3.8-flash", "low"),
                  ("opencode-go", "glm-5.3-flash", "high"),
                  ("openai", "gpt-6.1-sol", "medium")]:
    if v not in variants.get((p, mid), set()):
        errors.append(f"{p}/{mid} lacks variant {v} (has {sorted(variants.get((p, mid), []))})")
if "low" in variants.get(("opencode-go", "mimo-v2.6-flash"), set()):
    errors.append("mimo-v2.6-flash unexpectedly gained a low variant; update the compatibility report")
if errors:
    print("FAIL - " + "; ".join(errors), file=sys.stderr)
    sys.exit(1)
PY
  else
    skip 'model variant validation (opencode api model.list unavailable)'
  fi

  AUTHIDS_FILE=$(mktemp "${TMPDIR:-/tmp}/oc-authids.XXXXXX")
  AUTH_JSON="${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json"
  if [ -f "$AUTH_JSON" ]; then
    python3 -c "import json,sys; print('\n'.join(sorted(json.load(open(sys.argv[1])))))" "$AUTH_JSON" >"$AUTHIDS_FILE" 2>/dev/null
    auth_ok=0
    grep -qx 'opencode-go' "$AUTHIDS_FILE" && auth_ok=$((auth_ok + 1))
    grep -qx 'openai' "$AUTHIDS_FILE" && auth_ok=$((auth_ok + 1))
    if [ "$auth_ok" -eq 2 ]; then
      ok 'stored credentials cover the two providers backing the validated preferences (provider IDs only; no secrets read)'
    else
      fail 'missing stored credentials for a provider backing a validated preference'
    fi
  else
    skip 'authentication support check (no local auth.json)'
  fi
fi

# --------------------------------------------------------------------------
# Part 3: isolated runtime boundary
# --------------------------------------------------------------------------

if ! runtime_ok; then
  skip 'isolated runtime workflow checks (target v2 CLI unavailable)'
  if [ "$failures" -eq 0 ]; then
    printf 'PASS OpenCode workflow contract tests (static only)\n'
    exit 0
  fi
  exit 1
fi

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/opencode-workflows.XXXXXX") || exit 1

python3 "$HERE/test-opencode-workflows-driver.py" "$SANDBOX" || failures=$((failures + 1))

rm -rf "$SANDBOX"

if [ "$failures" -eq 0 ]; then
  printf 'PASS OpenCode native workflow and model-preference contract tests\n'
  exit 0
fi
exit 1
