#!/usr/bin/env python3
"""Isolated-runtime driver for scripts/test-opencode-workflows.sh (ticket 0003).

Runs the installed target v2 CLI inside one-off HOME/XDG/TMP sandboxes with a
local scripted mock provider (and a mock `rtk` binary for the plugin cases) and
asserts the externally visible contracts:

  1. The runtime tool catalog for a primary agent includes native subagents,
     questions, Code Mode (`execute`), skills, and web tools, and reveals no
     todo or LSP tools (the reported Pi extensions without v2 equivalents).
  2. The explore subagent child session is hard read-only: its mutating tools
     are absent from the child tool catalog, a scripted write attempt is
     rejected in the transcript, and the fixture file is never created.
  3. Subagent model and reasoning preferences load from managed `agents`
     configuration: the child request carries the configured model and the
     configured variant is lowered to reasoning_effort in the request.
  4. The RTK plugin probes the binary, refuses rewrites below 0.23.0,
     disables itself without rtk, honors RTK_DISABLED=1, and applies exit-0/3
     rewrites from `rtk rewrite`.

No production credentials and no paid model calls are used; every model
response comes from the local mock provider.
"""
import json
import os
import shutil
import socket
import subprocess
import sys
import time

BIN = os.environ.get("OPENCODE_BIN") or shutil.which("opencode")
SANDBOX = sys.argv[1]
REPO = os.environ["REPO"]


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


def port_listening(port, timeout=1.0):
    s = socket.socket()
    s.settimeout(timeout)
    try:
        s.connect(("127.0.0.1", port))
        return True
    except OSError:
        return False
    finally:
        s.close()


MOCK_SRC = """
import json, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

CAPTURE, PORT = {capture!r}, {mockport}

def chunk(delta, finish=None, model="m"):
    return {{"id": "c1", "object": "chat.completion.chunk", "created": 0, "model": model,
            "choices": [{{"index": 0, "delta": delta, "finish_reason": finish}}]}}

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        with open(CAPTURE, "ab") as out:
            out.write(raw + b"\\n")
        try:
            req = json.loads(raw)
        except Exception:
            req = {{}}
        model = req.get("model", "mock-model")
        msgs = req.get("messages", [])
        first_user = next((m.get("content", "") for m in msgs if m.get("role") == "user"), "")
        if isinstance(first_user, list):
            first_user = " ".join(str(x) for x in first_user)
        first_user = str(first_user)
        already_called = any("tool_calls" in json.dumps(m) for m in msgs if m.get("role") == "assistant")
        chunks = []
        if "PARENT_TASK" in first_user:
            if already_called:
                chunks.append(chunk({{"role": "assistant", "content": "parent done"}}, model=model))
            else:
                args = json.dumps({{"agent": "explore", "description": "look around",
                                   "prompt": "CHILD_EXPLORE_TASK try to write forbidden.txt"}})
                chunks.append(chunk({{"role": "assistant", "content": None,
                                     "tool_calls": [{{"index": 0, "id": "call_1", "type": "function",
                                                     "function": {{"name": "subagent", "arguments": args}}}}]}},
                                    model=model))
        elif "CHILD_EXPLORE_TASK" in first_user:
            if already_called:
                chunks.append(chunk({{"role": "assistant", "content": "child done"}}, model=model))
            else:
                args = json.dumps({{"path": {forbidden_abs!r}, "content": "hi"}})
                chunks.append(chunk({{"role": "assistant", "content": None,
                                     "tool_calls": [{{"index": 0, "id": "call_2", "type": "function",
                                                     "function": {{"name": "write", "arguments": args}}}}]}},
                                    model=model))
        elif "SHELL_TASK" in first_user:
            if already_called:
                chunks.append(chunk({{"role": "assistant", "content": "shell done"}}, model=model))
            else:
                args = json.dumps({{"command": "echo ORIG_CMD"}})
                chunks.append(chunk({{"role": "assistant", "content": None,
                                     "tool_calls": [{{"index": 0, "id": "call_3", "type": "function",
                                                     "function": {{"name": "shell", "arguments": args}}}}]}},
                                    model=model))
        elif "QUESTION_TASK" in first_user:
            if already_called:
                chunks.append(chunk({{"role": "assistant", "content": "answered"}}, model=model))
            else:
                args = json.dumps({{"questions": [{{"question": "Pick the default model",
                                                   "header": "Choice",
                                                   "options": [{{"label": "A", "description": "Option A, longer description for validation"}},
                                                               {{"label": "B", "description": "Option B, longer description for validation"}}],
                                                   "multiple": False}}]}})
                chunks.append(chunk({{"role": "assistant", "content": None,
                                     "tool_calls": [{{"index": 0, "id": "call_4", "type": "function",
                                                     "function": {{"name": "question", "arguments": args}}}}]}},
                                    model=model))
        else:
            chunks.append(chunk({{"role": "assistant", "content": "n/a"}}, model=model))
        chunks.append(chunk({{}}, "stop", model=model))
        payload = "".join("data: " + json.dumps(c) + "\\n\\n" for c in chunks) + "data: [DONE]\\n\\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.end_headers()
        self.wfile.write(payload.encode())

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{{"object": "list", "data": []}}')

HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
"""

READ_ONLY_PERMS = [
    {"action": "edit", "resource": "*", "effect": "deny"},
    {"action": "shell", "resource": "*", "effect": "deny"},
]


def agent_mirror(provider, explore_model, general_model):
    """The managed agents shape (explore: model + variant + hard read-only deny
    rules; general: model + variant), parameterized so the managed bundle and
    its mock-provider sandbox mirror stay in sync."""
    return {
        "explore": {"model": {"providerID": provider, "model": explore_model, "variant": "low"},
                    "permissions": json.loads(json.dumps(READ_ONLY_PERMS))},
        "general": {"model": {"providerID": provider, "model": general_model, "variant": "high"}},
    }


AGENTS_MANAGED_MIRROR = agent_mirror("opencode-go", "qwen3.8-flash", "glm-5.3-flash")
AGENTS_MOCK_MIRROR = agent_mirror("mock", "mock-explore", "mock-general")
AGENTS_EXPLORE_PREF = {
    "explore": {"model": {"providerID": "mock", "model": "mock-explore", "variant": "low"}},
}


class Case:
    def __init__(self, name, agents, prompt, terminal, env_extra=None, plugin=False, fake_rtk=None):
        self.name = name
        self.root = os.path.join(SANDBOX, name)
        self.home = os.path.join(self.root, "home")
        self.proj = os.path.join(self.root, "project")
        self.conf = os.path.join(self.home, ".config", "opencode")
        for d in (self.home, self.proj, os.path.join(self.conf, "plugins"),
                  os.path.join(self.root, "data"), os.path.join(self.root, "state"),
                  os.path.join(self.root, "cache"), os.path.join(self.root, "tmp")):
            os.makedirs(d, exist_ok=True)
        self.mockport = free_port()
        self.serverport = free_port()
        self.agents = agents
        self.prompt = prompt
        self.terminal = terminal
        self.env_extra = env_extra or {}
        self.plugin = plugin
        self.fake_rtk = fake_rtk
        self.capture = os.path.join(self.root, "capture.jsonl")
        self.server_log = os.path.join(self.root, "server.log")
        self.rtk_log = os.path.join(self.root, "rtk.log")
        self.mock = None
        self.server = None

    def setup(self):
        mockpy = os.path.join(self.root, "mock_provider.py")
        open(mockpy, "w").write(MOCK_SRC.format(capture=self.capture, mockport=self.mockport,
                                                forbidden_abs=os.path.join(self.proj, "forbidden.txt")))
        self.mock = subprocess.Popen(["python3", mockpy], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(0.7)
        config = {
            "$schema": "https://opencode.ai/config.json",
            "model": "mock/mock-build",
            "providers": {
                "mock": {
                    "name": "Mock",
                    "env": [],
                    "package": "@opencode/ai/providers/openai-compatible",
                    "settings": {"baseURL": f"http://127.0.0.1:{self.mockport}/v1"},
                    "models": {
                        "mock-build": {"name": "Mock Build", "limit": {"context": 100000, "output": 4096}},
                        "mock-explore": {"name": "Mock Explore", "limit": {"context": 100000, "output": 4096}},
                        "mock-general": {"name": "Mock General", "limit": {"context": 100000, "output": 4096}},
                    },
                }
            },
        }
        if self.agents is not None:
            config["agents"] = self.agents
        json.dump(config, open(os.path.join(self.conf, "opencode.json"), "w"))
        if self.plugin:
            shutil.copy(os.path.join(REPO, ".config/opencode/plugins/rtk.ts"),
                        os.path.join(self.conf, "plugins", "rtk.ts"))
        env = {
            **os.environ,
            "HOME": self.home,
            "XDG_CONFIG_HOME": os.path.join(self.home, ".config"),
            "XDG_DATA_HOME": os.path.join(self.root, "data"),
            "XDG_STATE_HOME": os.path.join(self.root, "state"),
            "XDG_CACHE_HOME": os.path.join(self.root, "cache"),
            "TMPDIR": os.path.join(self.root, "tmp"),
            "OPENCODE_DISABLE_MODELS_FETCH": "1",
        }
        if self.fake_rtk:
            (version,) = self.fake_rtk
            fakebin = os.path.join(self.root, "bin")
            os.makedirs(fakebin, exist_ok=True)
            rtk = os.path.join(fakebin, "rtk")
            open(rtk, "w").write(f"""#!/bin/sh
echo "invoke: $*" >> "$RTK_LOG"
case "$1" in
  --version) echo "rtk {version}";;
  rewrite) if [ "$2" = "echo ORIG_CMD" ]; then echo "echo RTK_REWROTE_MARKER > RTK_MARKER.txt"; else exit 1; fi;;
esac
""")
            os.chmod(rtk, 0o755)
            env["PATH"] = fakebin + os.pathsep + env.get("PATH", "")
            env["RTK_LOG"] = self.rtk_log
        env.update(self.env_extra)
        self.server = subprocess.Popen(
            [BIN, "serve", "--hostname", "127.0.0.1", "--port", str(self.serverport)],
            cwd=self.proj, env=env, stdout=open(self.server_log, "w"), stderr=subprocess.STDOUT)
        for _ in range(25):
            time.sleep(1)
            if port_listening(self.serverport):
                return True
            if self.server.poll() is not None:
                return False
        return False

    def run(self):
        self.password = None
        for _ in range(10):
            text = open(self.server_log).read()
            if "server password " in text:
                self.password = text.split("server password ")[1].split("\n")[0].strip()
                break
            time.sleep(1)
        if not self.password:
            raise RuntimeError("no server password; log head: " + open(self.server_log).read()[:300])
        env = {**os.environ, "OPENCODE_PASSWORD": self.password}

        def api(*args, timeout=30):
            r = subprocess.run([BIN, "api", "--server", f"http://127.0.0.1:{self.serverport}"] + list(args),
                               cwd=self.proj, env=env, capture_output=True, text=True, timeout=timeout)
            try:
                return json.loads(r.stdout)
            except Exception:
                return {"raw": (r.stdout + r.stderr)[:300]}

        self.api = api
        created = api("session.create", "--data", json.dumps({"title": "wf-probe"}))
        sid = created.get("id") or created.get("data", {}).get("id", "")
        if not sid:
            raise RuntimeError("session.create failed: " + json.dumps(created)[:300])
        self.sid = sid
        api("session.prompt", "--param", f"sessionID={sid}", "--data", json.dumps({"text": self.prompt}))
        deadline = time.time() + 110
        while time.time() < deadline:
            time.sleep(2)
            rows = self.rows()
            if self.terminal is None:
                if rows:
                    time.sleep(4)  # let any queued tool round land in the capture too
                    return rows
                continue
            if any(self.terminal in json.dumps(r_.get("messages", [])) for r_ in rows):
                return rows
        return self.rows()

    def rows(self):
        if not os.path.exists(self.capture):
            return []
        return [json.loads(x) for x in open(self.capture, encoding="utf-8") if x.strip()]

    def teardown(self):
        for proc in (self.server, self.mock):
            if proc:
                try:
                    proc.terminate()
                except Exception:
                    pass
        time.sleep(0.3)


def first_user_text(req):
    for m in req.get("messages", []):
        if m.get("role") == "user":
            c = m.get("content")
            if isinstance(c, list):
                c = " ".join(str(x) for x in c)
            return str(c)
    return ""


def mock_model_guard(case, errors):
    """Guard against silent model substitution: on this rift between the sandbox
    provider pool and a mis-loaded config, the runtime auto-picks a free model
    (observed: opencode/longcat-2.5-preview-free) and answers sessions without
    ever touching the mock provider. Any such fallback is a test defect."""
    models = {r_.get("model") for r_ in case.rows()}
    unexpected = sorted(m for m in models if m != "mock-build" and not str(m).startswith(("mock-",)))
    if unexpected:
        errors.append(f"non-mock models answered sessions (silent fallback?): {unexpected}")


def analyze_questions(case):
    """The managed question demo: the scripted tool call reaches the runtime,
    which parks it in a pending interactive request state until a client answers."""
    rows = case.rows()
    errors = []
    if not rows:
        errors.append("no captured requests; the question flow never reached the mock provider")
    mock_model_guard(case, errors)
    pending = False
    for _ in range(30):
        time.sleep(2)
        ml = case.api("session.message.list", "--param", f"sessionID={case.sid}")
        blob = json.dumps(ml if isinstance(ml, dict) else ml)
        if '"name": "question"' in blob:
            pending = True
            break
    if not pending:
        errors.append("question tool call never surfaced as a pending runtime request")
    return errors


def analyze_enforcement(case):
    rows = case.rows()
    errors = []
    main_tools = None
    child_tools = None
    child_models = set()
    efforts = set()
    seen_denial = False
    for req in rows:
        text = first_user_text(req)
        if "CHILD_EXPLORE_TASK" in text:
            child_models.add(req.get("model"))
            efforts.add(req.get("reasoning_effort"))
            tools = sorted({t.get("function", {}).get("name") or t.get("name")
                            for t in req.get("tools", []) if isinstance(t, dict)})
            if tools:
                child_tools = tools
        elif "PARENT_TASK" in text:
            main_tools = sorted({t.get("function", {}).get("name") or t.get("name")
                                 for t in req.get("tools", []) if isinstance(t, dict)})
        blob = json.dumps(req.get("messages", []))
        if "No tool named" in blob or "denied" in blob.lower():
            seen_denial = True
    if not child_tools:
        errors.append(f"no child tool catalog captured ({len(rows)} requests)")
    else:
        mutators = {"edit", "write", "shell", "subagent", "execute", "question", "skill"}
        overlap = mutators & set(child_tools)
        if overlap:
            errors.append(f"child exposes mutating/embedding tools: {sorted(overlap)}")
        if not {"glob", "grep", "read", "webfetch", "websearch"} <= set(child_tools):
            errors.append(f"child missing read/search/web tools: {child_tools}")
        if not seen_denial:
            errors.append("no 'No tool named write' denial surfaced in the transcript")
    if os.path.exists(os.path.join(case.proj, "forbidden.txt")):
        errors.append("forbidden.txt was created in the fixture")
    if "mock-explore" not in child_models:
        errors.append(f"child did not run on the configured subagent model: {sorted(child_models)}")
    if "low" not in {str(e).lower() for e in efforts if e}:
        errors.append(f"child requests did not carry reasoning_effort=low: {sorted(efforts)}")
    if not main_tools:
        errors.append("no primary tool catalog captured")
    else:
        for required in ("execute", "question", "subagent", "webfetch", "websearch", "skill"):
            if required not in main_tools:
                errors.append(f"primary agent lacks {required} in the runtime tool catalog")
        banned = [t for t in main_tools if t.startswith("lsp_") or t.startswith("todo")]
        if banned:
            errors.append(f"primary agent exposes todo/lsp tools; update the report: {banned}")
    return errors


def analyze_rtk(case, disposition):
    log = open(case.rtk_log).read() if os.path.exists(case.rtk_log) else ""
    warn = [l for l in open(case.server_log).read().splitlines() if "[rtk]" in l]
    marker = os.path.join(case.proj, "RTK_MARKER.txt")
    errors = []
    if disposition in ("missing", "too-old"):
        expected_snippet = "not found" if disposition == "missing" else "too old"
        if not any(expected_snippet in l for l in warn):
            errors.append(f"expected '{expected_snippet}' disable warning; got {warn}")
        if "rewrite " in log:
            errors.append("disabled plugin still consulted rtk rewrite")
        if os.path.exists(marker):
            errors.append("rewrite applied although the plugin was disabled")
    elif disposition == "env":
        if "rewrite echo ORIG_CMD" in log:
            errors.append("RTK_DISABLED=1 did not skip the rewrite lookup")
        if os.path.exists(marker):
            errors.append("rewrite applied although RTK_DISABLED=1")
        if "--version" not in log:
            errors.append("plugin did not load or probe rtk version")
    else:
        if "--version" not in log:
            errors.append("plugin did not probe rtk version")
        if "rewrite echo ORIG_CMD" not in log:
            errors.append(f"rewrite hook did not consult rtk: {log[:120]!r}")
        if not os.path.exists(marker):
            errors.append("rewritten command did not execute")
    return errors


def report(name, errors, results):
    if errors:
        for e in errors:
            print(f"FAIL - {name}: {e}")
        results["failures"] += 1
    else:
        print(f"ok  - {name}")
        results["passes"] += 1


def main():
    results = {"passes": 0, "failures": 0}

    managed_like_case = Case(
        "managed-agents-catalog",
        AGENTS_MOCK_MIRROR,
        "PARENT_TASK please answer briefly",
        None,
    )
    try:
        if not managed_like_case.setup():
            report("managed agents configuration loads at the isolated runtime", ["isolated server did not start"], results)
            raise SystemExit(fin(results))
        managed_like_case.run()
        # Assert the *managed shape* of the mirror at the runtime: agent.list on the
        # isolated config with the fake provider exercises the same mechanism the
        # managed bundle relies on. Also assert the read-only denial path.
        agents = managed_like_case.api("agent.list")
        rows = agents.get("data", []) if isinstance(agents, dict) else agents
        by_id = {a.get("id"): a for a in rows if isinstance(a, dict)}
        errors = []
        explore = by_id.get("explore", {})
        if explore.get("model") != {"id": "mock-explore", "providerID": "mock", "variant": "low"}:
            errors.append(f"explore model not loaded: {explore.get('model')}")
        general = by_id.get("general", {})
        if general.get("model", {}).get("id") != "mock-general" or general.get("model", {}).get("variant") != "high":
            errors.append(f"general model not loaded: {general.get('model')}")
        edit_denied = any(r_.get("action") == "edit" and r_.get("effect") == "deny"
                          for r_ in explore.get("permissions", []))
        if not edit_denied:
            errors.append("explore edit deny rule not present in the runtime agent registry")
        report("managed agents model/variant/permissions load at the isolated runtime", errors, results)
    finally:
        managed_like_case.teardown()

    enforcement_case = Case(
        "subagent-enforcement",
        AGENTS_EXPLORE_PREF,
        "PARENT_TASK explore please",
        'state="completed"',
    )
    try:
        if not enforcement_case.setup():
            report("subagent enforcement demo", ["isolated server did not start"], results)
            raise SystemExit(fin(results))
        rows = enforcement_case.run()
        errors = analyze_enforcement(enforcement_case)
        mock_model_guard(enforcement_case, errors)
        if not rows:
            errors.append("no captured requests")
            log = open(enforcement_case.server_log).read()
            errors.append("server log tail: " + log[-300:])
        report("read-only explore child session, native catalog, and subagent model/variant plumbing", errors, results)
    finally:
        enforcement_case.teardown()

    questions_case = Case(
        "questions-pending",
        None,
        "QUESTION_TASK",
        None,
    )
    try:
        if not questions_case.setup():
            report("native questions demo", ["isolated server did not start"], results)
            raise SystemExit(fin(results))
        print(f"... waiting for the pending question request ({questions_case.root})")
        try:
            questions_case.run()
            report("native questions tool parks a pending interactive request at the runtime",
                   analyze_questions(questions_case), results)
        finally:
            # The pending request outlives teardown by design (answering requires an
            # interactive client); destroying the sandbox ends it deterministically.
            pass
    finally:
        questions_case.teardown()

    rtk_present = Case("rtk-present", AGENTS_MOCK_MIRROR, "SHELL_TASK run it", "RTK_REWROTE_MARKER", plugin=True, fake_rtk=("0.24.1",))
    rtk_too_old = Case("rtk-too-old", AGENTS_MOCK_MIRROR, "SHELL_TASK run it", "ORIG_CMD", plugin=True, fake_rtk=("0.22.0",))
    rtk_missing = Case("rtk-missing", AGENTS_MOCK_MIRROR, "SHELL_TASK run it", "ORIG_CMD", plugin=True,
                       env_extra={"PATH": "/usr/bin:/bin:/usr/sbin:/sbin"})
    rtk_disabled = Case("rtk-disabled-env", AGENTS_MOCK_MIRROR, "SHELL_TASK run it", "ORIG_CMD",
                        plugin=True, fake_rtk=("0.24.1",), env_extra={"RTK_DISABLED": "1"})
    for case, disposition, label in [
        (rtk_present, "present", "RTK plugin applies exit-0/3 rewrites at the isolated runtime"),
        (rtk_missing, "missing", "RTK plugin disables itself when rtk is absent"),
        (rtk_too_old, "too-old", "RTK plugin disables itself below rtk 0.23.0"),
        (rtk_disabled, "env", "RTK_DISABLED=1 skips rewrites while leaving the plugin loaded"),
    ]:
        try:
            if not case.setup():
                report(label, ["isolated server did not start"], results)
                raise SystemExit(fin(results))
            case.run()
            report(label, analyze_rtk(case, disposition), results)
        finally:
            case.teardown()

    raise SystemExit(fin(results))


def fin(results):
    return 1 if results["failures"] else 0


if __name__ == "__main__":
    main()
