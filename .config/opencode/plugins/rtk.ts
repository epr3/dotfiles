// RTK OpenCode plugin — rewrites commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// This is a thin delegating plugin: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth (src/discover/registry.rs).
// To add or change rewrite rules, edit the Rust registry — not this file.
//
// OpenCode V2 plugin API: default-export a definition with an `id` and a
// `setup(ctx)` function; hooks are registered on their domain in setup.

import { spawnSync } from "node:child_process"

function runRtk(args: string[]): { ok: boolean; stdout: string } {
  try {
    const result = spawnSync("rtk", args, { encoding: "utf8" })
    return { ok: result.status === 0, stdout: (result.stdout ?? "").trim() }
  } catch {
    return { ok: false, stdout: "" }
  }
}

export default {
  id: "rtk",
  async setup(ctx: any) {
    if (!runRtk(["--version"]).ok) {
      console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
      return
    }

    await ctx.tool.hook("execute.before", (event: any) => {
      const tool = String(event?.tool ?? "").toLowerCase()
      if (tool !== "bash" && tool !== "shell") return

      const input = event?.input
      if (!input || typeof input !== "object") return

      const command = input.command
      if (typeof command !== "string" || !command) return

      const { ok, stdout } = runRtk(["rewrite", command])
      if (ok && stdout && stdout !== command) {
        input.command = stdout
      }
    })
  },
}
