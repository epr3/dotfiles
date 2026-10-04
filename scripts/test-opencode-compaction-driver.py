#!/usr/bin/env python3
"""Isolated installed-v2 contract probe for model-aware compaction.

The local OpenAI-compatible fixture reports controlled token usage. No real
provider credentials or paid calls are used.
"""
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

BIN = os.environ.get("OPENCODE_BIN") or shutil.which("opencode")
REPO = os.environ["REPO"]


def free_port():
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
    sock.close()
    return port


def main():
    if not BIN:
        print("SKIP installed v2 runtime probe (opencode not found)")
        return 0
    root = tempfile.mkdtemp(prefix="opencode-compaction.")
    processes = []
    try:
        home = os.path.join(root, "home")
        conf = os.path.join(home, ".config", "opencode")
        project = os.path.join(root, "project")
        for path in (conf, project, os.path.join(root, "data"), os.path.join(root, "state"),
                     os.path.join(root, "cache"), os.path.join(root, "tmp")):
            os.makedirs(path, exist_ok=True)
        plugin_dir = os.path.join(conf, "plugins")
        os.makedirs(plugin_dir, exist_ok=True)
        shutil.copy(os.path.join(REPO, ".config", "opencode", "plugins", "model-aware-compaction.ts"),
                    plugin_dir)
        shutil.copytree(os.path.join(REPO, ".config", "opencode", "plugins", "model-aware-compaction"),
                        os.path.join(plugin_dir, "model-aware-compaction"))
        capture = os.path.join(root, "provider.jsonl")
        provider_port, server_port = free_port(), free_port()

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *_args):
                pass

            def do_POST(self):
                body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
                with open(capture, "a", encoding="utf-8") as out:
                    out.write(json.dumps(body) + "\n")
                text = " ".join(str(m.get("content", "")) for m in body.get("messages", []))
                match = re.search(r"TOKENS=(\d+)", text)
                tokens = max(0, int(match.group(1)) - 1) if match else 100
                model = body.get("model", "small")
                chunks = [
                    {"id": "probe", "object": "chat.completion.chunk", "created": 1,
                     "model": model, "choices": [{"index": 0,
                     "delta": {"role": "assistant", "content": "fixture response"}, "finish_reason": None}]},
                    {"id": "probe", "object": "chat.completion.chunk", "created": 1,
                     "model": model, "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
                     "usage": {"prompt_tokens": tokens, "completion_tokens": 1, "total_tokens": tokens + 1}},
                ]
                payload = "".join("data: " + json.dumps(chunk) + "\n\n" for chunk in chunks) + "data: [DONE]\n\n"
                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream")
                self.end_headers()
                self.wfile.write(payload.encode())

            def do_GET(self):
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"object":"list","data":[]}')

        provider = HTTPServer(("127.0.0.1", provider_port), Handler)
        provider_thread = threading.Thread(target=provider.serve_forever, daemon=True)
        provider_thread.start()

        config = {
            "$schema": "https://opencode.ai/config.json",
            "model": "probe/small",
            "compaction": {"auto": False, "keep": {"tokens": 8000}},
            "providers": {"probe": {
                "name": "Local probe", "env": [],
                "package": "@opencode/ai/providers/openai-compatible",
                "settings": {"baseURL": f"http://127.0.0.1:{provider_port}/v1"},
                "models": {
                    "small": {"name": "Small fixture", "limit": {"context": 128000, "output": 4096}},
                    "large": {"name": "Large fixture", "limit": {"context": 512000, "output": 4096}},
                },
            }},
        }
        with open(os.path.join(conf, "opencode.json"), "w", encoding="utf-8") as out:
            json.dump(config, out)
        env = {**os.environ, "HOME": home, "XDG_CONFIG_HOME": os.path.join(home, ".config"),
               "XDG_DATA_HOME": os.path.join(root, "data"), "XDG_STATE_HOME": os.path.join(root, "state"),
               "XDG_CACHE_HOME": os.path.join(root, "cache"), "TMPDIR": os.path.join(root, "tmp"),
               "OPENCODE_DISABLE_MODELS_FETCH": "1"}
        log_path = os.path.join(root, "server.log")
        server_log = open(log_path, "w", encoding="utf-8")
        server = subprocess.Popen([BIN, "serve", "--hostname", "127.0.0.1", "--port", str(server_port)],
                                 cwd=project, env=env, stdout=server_log, stderr=subprocess.STDOUT)
        processes.append(server)
        for _ in range(30):
            if server.poll() is not None:
                raise RuntimeError("v2 server stopped: " + open(log_path, encoding="utf-8").read()[:1000])
            try:
                with socket.create_connection(("127.0.0.1", server_port), timeout=.2):
                    break
            except OSError:
                time.sleep(.2)
        else:
            raise RuntimeError("v2 server did not start")
        password = None
        for _ in range(30):
            text = open(log_path, encoding="utf-8").read()
            match = re.search(r"server password ([^\s]+)", text)
            if match:
                password = match.group(1)
                break
            time.sleep(.2)
        if not password:
            raise RuntimeError("isolated server did not report its local API password")
        api_env = {**env, "OPENCODE_PASSWORD": password}

        def api(*args, timeout=45):
            result = subprocess.run([BIN, "api", "--server", f"http://127.0.0.1:{server_port}", *args],
                                    cwd=project, env=api_env, capture_output=True, text=True, timeout=timeout)
            if result.returncode:
                raise RuntimeError(f"opencode api {' '.join(args)} failed: {result.stderr[:500]}")
            return json.loads(result.stdout)

        checks = []

        def prompt(sid, model, text):
            api("session.prompt", "--param", f"sessionID={sid}", "--data",
                json.dumps({"text": text, "model": {"providerID": "probe", "modelID": model}}))

        # The v2 public prompt endpoint in 2.0.22 ignores per-message model
        # overrides in this isolated server, so runtime model selection can
        # only be proven for the configured default here. The pure policy tests
        # cover both advertised windows; do not pretend this probes switching.
        for model, window in (("small", 128000),):
            for label, used, expected in (("below", window // 2 - 1, False),
                                          ("at", window // 2, True),
                                          ("above", window // 2 + 1, True)):
                created = api("session.create", "--data", json.dumps({"title": f"{model}-{label}"}))
                sid = created.get("id") or created.get("data", {}).get("id")
                if not sid:
                    raise RuntimeError("session.create returned no id")
                prompt(sid, model, f"TOKENS={used}")
                prompt(sid, model, "follow-up")
                time.sleep(.4)
                logs = open(log_path, encoding="utf-8").read()
                fired = f"threshold reached: model=probe/{model} usage={used} window={window}" in logs
                if fired != expected:
                    messages = api("session.message.list", "--param", f"sessionID={sid}")
                    try:
                        plugins = api("plugin.list")
                    except Exception as error:
                        plugins = str(error)
                    plugin_rows = plugins.get("data", []) if isinstance(plugins, dict) else []
                    active_plugin = [row for row in plugin_rows if row.get("id") == "model-aware-compaction"]
                    infos = [row.get("info", row) for row in messages.get("data", []) if row.get("type") == "assistant"]
                    details = [(item.get("model"), item.get("tokens")) for item in infos]
                    relevant_logs = [line for line in logs.splitlines() if "model-aware-compaction" in line and ("threshold" in line or "failed" in line or "advertised" in line)]
                    raise RuntimeError(f"{model} {label} runtime boundary: expected fired={expected}, got {fired}; plugin={active_plugin}; assistants={details}; logs={relevant_logs[-8:]}")
                checks.append(f"{model} {label} ({used}/{window})")

        for check in checks:
            print("ok  - installed runtime compaction " + check)
        print("SKIP installed runtime model-switch / second-window checks (v2.0.22 prompt API ignores per-message model overrides)")
        print("PASS installed v2 model-aware compaction runtime contracts")
        return 0
    finally:
        for proc in processes:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
        try:
            provider.shutdown()
        except Exception:
            pass
        shutil.rmtree(root, ignore_errors=True)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        print(f"FAIL installed v2 model-aware compaction runtime probe: {error}", file=sys.stderr)
        sys.exit(1)
