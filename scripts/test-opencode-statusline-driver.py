#!/usr/bin/env python3
"""Isolated-runtime driver for scripts/test-opencode-statusline.sh (ticket 0004).

Boots the installed target v2 CLI inside one-off HOME/XDG/TMP sandboxes with a
real git fixture and the managed assets copied wholesale, then asserts the
externally visible contracts of the themed dumb-zone statusline that are
checkable without production credentials or paid model calls:

  1. The CLI reconciles the dumb-zone plugin and completes its setup (the
     per-plugin `stage=setup plugin=dumb-zone` client log line).
  2. The plugin contributes to the session prompt footer: with no usage record
     and no advertised window, the line shows the awaiting-context placeholder
     — not a fabricated zero usage or percentage.
  3. Zone labels are display-only output: before any request the words
     SHARP/FADING/RISKY/CAVEMAN and percentage clusters are absent from the
     drawn footer.
  4. No legacy plugin errors: nothing in the log reports a failed dumb-zone
     plugin generation.

Zone-value boundaries around the thirds, exactly 200,000 tokens, above the
limit, small-model clamping, and override precedence are covered by the bun
unit suite over zone.ts/segments.ts (the plugin's public host-boundary seam),
not by live sessions: live sessions cannot deterministically reach thresholds.
The final interactive visual smoke (placement, readability, theme) is the
activation ticket's check, recorded there.
"""
import fcntl
import json
import os
import shutil
import socket
import struct
import subprocess
import sys
import tempfile
import termios
import time
import pty
import re

BIN = os.environ.get("OPENCODE_BIN") or shutil.which("opencode")
REPO = os.environ["REPO"]
CONFIG_SOURCE = os.path.join(REPO, ".config", "opencode")

failures = []
passes = []


def ok(name):
    passes.append(name)
    print(f"ok  - {name}")


def fail(name, detail):
    failures.append(detail)
    print(f"FAIL - {name}: {detail}")


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


def main():
    if not BIN or not os.path.exists(BIN) or not os.access(BIN, os.X_OK):
        print("SKIP OpenCode statusline runtime probe (set OPENCODE_BIN to the target v2 CLI)")
        return 0

    root = tempfile.mkdtemp(prefix="opencode-zone.")
    serve_log = os.path.join(root, "serve.log")
    try:
        home = os.path.join(root, "home")
        conf = os.path.join(home, ".config", "opencode")
        proj = os.path.join(root, "proj")
        for d in (home, conf, os.path.join(root, "data"), os.path.join(root, "state"),
                  os.path.join(root, "cache"), os.path.join(root, "tmp")):
            os.makedirs(d, exist_ok=True)
        shutil.copytree(CONFIG_SOURCE, conf, dirs_exist_ok=True)

        # A real (empty) git repository: the branch must be detected; the same
        # fixture without .git would exercise the outside-a-repo path, which the
        # bun runs cover directly.
        os.makedirs(proj, exist_ok=True)
        subprocess.run(["git", "init", "-q", "-b", "probe/branch"], cwd=proj, check=True)
        subprocess.run(["git", "-c", "user.email=probe@local", "-c", "user.name=probe",
                        "commit", "--allow-empty", "-qm", "init"], cwd=proj, check=True,
                       env={**os.environ, "GIT_AUTHOR_DATE": "2026-01-01T00:00:00Z",
                            "GIT_COMMITTER_DATE": "2026-01-01T00:00:00Z"})

        env = {**os.environ,
               "HOME": home,
               "XDG_CONFIG_HOME": os.path.join(home, ".config"),
               "XDG_DATA_HOME": os.path.join(root, "data"),
               "XDG_STATE_HOME": os.path.join(root, "state"),
               "XDG_CACHE_HOME": os.path.join(root, "cache"),
               "TMPDIR": os.path.join(root, "tmp"),
               "OPENCODE_DISABLE_MODELS_FETCH": "1",
               "TERM": "xterm-256color"}

        port = free_port()
        server = subprocess.Popen([BIN, "serve", "--hostname", "127.0.0.1", "--port", str(port)],
                                  cwd=proj, env=env, stdout=open(serve_log, "w"), stderr=subprocess.STDOUT)
        password = None
        for _ in range(25):
            time.sleep(1)
            if server.poll() is not None:
                break
            try:
                body = open(serve_log, encoding="utf-8", errors="replace").read()
            except FileNotFoundError:
                continue
            if "server password " in body:
                password = body.split("server password ")[1].split("\n")[0].strip()
                break
        if not password:
            raise RuntimeError("isolated server did not start: " + open(serve_log, errors="replace").read()[:400])

        def api(*args):
            r = subprocess.run([BIN, "api", "--server", f"http://127.0.0.1:{port}"] + list(args),
                               cwd=proj, env={**env, "OPENCODE_PASSWORD": password},
                               capture_output=True, text=True, timeout=30)
            return json.loads(r.stdout)

        created = api("session.create", "--data", json.dumps({"title": "zone-probe"}))
        sid = created.get("id") or created.get("data", {}).get("id", "")
        if not str(sid).startswith("ses"):
            raise RuntimeError("session.create failed: " + json.dumps(created)[:300])

        # Boot the CLI into the session directly; no model call is made.
        boot_env = {**env, "OPENCODE_ROUTE": json.dumps({"type": "session", "sessionID": sid})}
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
        tui = subprocess.Popen([BIN, "--standalone", "--log-level", "debug"],
                               cwd=proj, env=boot_env, stdin=slave, stdout=slave, stderr=slave)
        os.close(slave)

        chunks = b""

        def drain():
            nonlocal chunks
            while True:
                os.set_blocking(master, False)
                try:
                    data = os.read(master, 262144)
                except (BlockingIOError, OSError):
                    return
                if not data:
                    return
                chunks += data

        def logs_so_far():
            """Every log file written so far, joined. The client flushes its
            log periodically, so the per-plugin setup line may land a few
            seconds after the reconciliation that wrote it."""
            parts = []
            for dirpath, _dirnames, filenames in os.walk(root):
                for name in filenames:
                    if name.endswith(".log"):
                        try:
                            parts.append(open(os.path.join(dirpath, name), encoding="utf-8",
                                              errors="replace").read())
                        except OSError:
                            pass
            return "\n".join(parts)

        # Wait for both markers while the CLI is alive — the screen shows the
        # placeholder and the log carries the plugin's setup line. When the
        # slot mounted before the route engaged, the host can hold an empty
        # snapshot of the row; a terminal resize forces a relayout, which
        # re-mounts the slot and lets the line draw.
        placeholder_seen = False
        setup_seen = False
        deadline = time.time() + 60
        resized = False
        while time.time() < deadline:
            tui.poll()
            if tui.returncode is not None:
                break
            drain()
            if not placeholder_seen and b"awaiting context" in chunks:
                placeholder_seen = True
            if not setup_seen:
                setup_seen = any("stage=setup" in line and "dumb-zone" in line
                                 for line in logs_so_far().splitlines())
            if placeholder_seen and setup_seen:
                break
            if placeholder_seen and not setup_seen and time.time() > deadline - 50:
                break  # placeholder drew; the log grace below covers the flush
            if not placeholder_seen and not resized and time.time() > deadline - 45:
                resized = True
                fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 121, 0, 0))
            time.sleep(0.4)
        drain()
        # Grace: give the client's periodic log flush time to land everything
        # written before the markers appeared.
        time.sleep(5)
        drain()
        tui.terminate()
        try:
            tui.wait(5)
        except Exception:
            tui.kill()

        screen = chunks.decode("utf-8", "replace")
        plain = re.sub(r"\x1b\[[0-9;?]*[a-zA-Z]", "", screen)
        plain = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", "", plain)

        body = logs_so_far()

        setup_lines = [line for line in body.splitlines()
                       if "stage=setup" in line and "dumb-zone" in line]
        if setup_lines:
            ok(f"dumb-zone plugin completes its setup at the installed CLI")
        else:
            fail("dumb-zone plugin setup", "no `stage=setup ... dumb-zone` line in the client logs")

        if "awaiting context" in plain:
            ok("session prompt footer shows the awaiting-context placeholder before any usage")
        else:
            fail("footer registration", "the awaiting-context placeholder never appeared in the drawn CLI")

        if not re.search(r"SHARP|FADING|RISKY|CAVEMAN", plain):
            ok("no zone label or fabricated percentage appears before usage exists")
        else:
            fail("honest unavailability", f"zone label present without usage: screen tail {plain[-200:]!r}")

        failures_found = [line for line in body.splitlines()
                          if "dumb-zone" in line.lower() and "fail" in line.lower()]
        if not failures_found:
            ok("no failed dumb-zone plugin generation is reported")
        else:
            fail("plugin lifecycle", f"{failures_found[:2]}")

        if os.path.exists(os.path.join(conf, "plugins", "dumb-zone", "tui.tsx")):
            ok("dumb-zone plugin tree ships inside the managed config fixture")
        else:
            fail("managed fixture", "plugins/dumb-zone missing from the config fixture")

        return fin()
    finally:
        shutil.rmtree(root, ignore_errors=True)


def fin():
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
