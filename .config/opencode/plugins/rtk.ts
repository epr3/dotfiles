// RTK OpenCode plugin — rewrites shell commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH (the version where `rtk rewrite` appeared).
//
// This is a thin delegating plugin: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth. To add or change rewrite rules, edit
// the Rust registry — not this file.
//
// Exit code contract for `rtk rewrite` (verified against rtk 0.50.0):
//   0 + stdout  Rewrite found → mutate command
//   1           No RTK equivalent → pass through unchanged
//   3 + stdout  Rewrite (advisory) → mutate command
//
// OpenCode V2 plugin API: default-export a definition with an `id` and a
// `setup(ctx)` function; hooks are registered on their domain in setup and
// run before the tool executes. The hook never blocks execution: on any
// failure the original command is used unchanged (fail-open).
//
// Environment:
//   RTK_DISABLED=1  Skip all rewrites (checked per command, like the Pi extension).

import { spawnSync } from "node:child_process"

const REWRITE_TIMEOUT_MS = 2_000
const MIN_SUPPORTED_RTK_MINOR = 23

// Parse "X.Y.Z" (optionally prefixed, e.g. "rtk 0.23.1"); return [major, minor, patch].
function parseSemver(raw: string): [number, number, number] | null {
  const m = raw.trim().match(/(\d+)\.(\d+)\.(\d+)/)
  if (!m) return null
  return [parseInt(m[1], 10), parseInt(m[2], 10), parseInt(m[3], 10)]
}

function runRtk(args: string[]): { code: number; stdout: string } {
  try {
    const result = spawnSync("rtk", args, { encoding: "utf8", timeout: REWRITE_TIMEOUT_MS })
    return { code: result.status ?? -1, stdout: (result.stdout ?? "").trim() }
  } catch {
    return { code: -1, stdout: "" }
  }
}

// A rewrite is accepted when rtk reports one: exit 0 or 3 (advisory).
// Exit 1 means "no RTK equivalent" and passes the command through unchanged.
function rewriteOutput(code: number, stdout: string): string | null {
  if ((code !== 0 && code !== 3) || !stdout) return null
  return stdout
}

export default {
  id: "rtk",
  async setup(ctx: any) {
    const ver = runRtk(["--version"])
    if (ver.code !== 0) {
      console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
      return
    }
    const parsed = parseSemver(ver.stdout)
    if (parsed) {
      const [major, minor] = parsed
      if (major === 0 && minor < MIN_SUPPORTED_RTK_MINOR) {
        console.warn(
          `[rtk] rtk ${parsed.join(".")} is too old (need >= 0.${MIN_SUPPORTED_RTK_MINOR}.0) — plugin disabled`,
        )
        return
      }
    }

    await ctx.tool.hook("execute.before", (event: any) => {
      try {
        const tool = String(event?.tool ?? "").toLowerCase()
        if (tool !== "bash" && tool !== "shell") return

        const input = event?.input
        if (!input || typeof input !== "object") return

        const command = input.command
        if (typeof command !== "string" || command.trim() === "") return
        if (command.startsWith("rtk ")) return
        if (process.env.RTK_DISABLED === "1") return

        const { code, stdout } = runRtk(["rewrite", command])
        const rewritten = rewriteOutput(code, stdout)
        if (rewritten && rewritten !== command) {
          input.command = rewritten
        }
      } catch (err) {
        // Fail open: never block execution on an unexpected plugin error.
        console.warn("[rtk] unexpected error in execute.before hook; passing through command", err)
      }
    })
  },
}
