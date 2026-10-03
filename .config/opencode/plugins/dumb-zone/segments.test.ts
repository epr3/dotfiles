import { describe, expect, it } from "bun:test"
import {
  footerRuns,
  basename,
  SEGMENT_SEPARATOR,
  sumTokens,
  newestAssistantUsage,
  catalogWindow,
  type FooterContext,
  type FooterUsage,
} from "./segments.ts"
import { AWAITING_CONTEXT_TEXT, configFromOptions, ZONE_GLYPH } from "./zone.ts"

const SEP = SEGMENT_SEPARATOR

function text(runs: { text: string }[]): string {
  return runs.map((run) => run.text).join("")
}

const usage = (usedTokens: number, windowTokens: number): FooterUsage => ({ usedTokens, windowTokens })

describe("basename", () => {
  it("returns the folder's own name from either path separator", () => {
    expect(basename("/Users/me/projects/dotfiles")).toBe("dotfiles")
    expect(basename("C:\\work\\repo")).toBe("repo")
    expect(basename("/repo/")).toBe("repo")
    expect(basename("")).toBe("")
    expect(basename(null)).toBe("")
  })
})

describe("host-shape readers", () => {
  it("sums the five token fields the host reports, reading defensively", () => {
    expect(sumTokens({ input: 544, output: 167, reasoning: 0, cache: { read: 118016, write: 2 } })).toBe(118729)
    expect(sumTokens({})).toBe(0)
    expect(sumTokens(undefined)).toBe(0)
    expect(sumTokens({ input: 10, cache: undefined } as never)).toBe(10)
  })

  it("reads the newest assistant message that reported usage, with its model", () => {
    const messages = [
      { type: "user" },
      { type: "assistant", tokens: { input: 100 }, model: { id: "old-model", providerID: "mock" } },
      { type: "assistant", tokens: { input: 0, output: 0 }, model: { id: "skipped", providerID: "mock" } },
      { type: "assistant", tokens: { input: 40_000, cache: { read: 80_000 } }, model: { id: "new-model", providerID: "mock" } },
    ]
    const found = newestAssistantUsage(messages as never)
    expect(found?.usedTokens).toBe(120_000)
    expect(found?.model?.id).toBe("new-model")
    expect(newestAssistantUsage(undefined)).toBeUndefined()
    expect(newestAssistantUsage([{ type: "assistant", tokens: { input: 0 } }] as never)).toBeUndefined()
  })

  it("looks up the advertised window in the location catalog", () => {
    const entries = [
      { id: "mock-build", providerID: "mock", limit: { context: 100_000 } },
      { id: "other", providerID: "other", limit: { context: 500_000 } },
      { id: "no-limit", providerID: "mock" },
    ]
    expect(catalogWindow(entries, { modelID: "mock-build", providerID: "mock" })).toBe(100_000)
    expect(catalogWindow(entries, { id: "mock-build", providerID: "mock" })).toBe(100_000)
    expect(catalogWindow(entries, { modelID: "no-limit", providerID: "mock" })).toBeUndefined()
    expect(catalogWindow(entries, { modelID: "absent", providerID: "mock" })).toBeUndefined()
    expect(catalogWindow(entries, { modelID: "other", providerID: "other" })).toBe(500_000)
    expect(catalogWindow(entries, undefined)).toBeUndefined()
    expect(catalogWindow(undefined, { modelID: "mock-build", providerID: "mock" })).toBeUndefined()
  })
})

describe("the working context segments", () => {
  it("shows the directory and the git branch when both exist", () => {
    const runs = footerRuns({ directory: "/Users/me/projects/dotfiles", branch: "main" }, undefined)
    expect(text(runs)).toBe(`dotfiles${SEP}\u2387 main${SEP}${AWAITING_CONTEXT_TEXT}`)
  })

  it("keeps the directory and drops the branch outside a git repository", () => {
    const runs = footerRuns({ directory: "/tmp/standalone", branch: "" }, undefined)
    expect(text(runs)).toBe(`/tmp/standalone${SEP}`.replace(`/tmp/standalone`, "standalone") + AWAITING_CONTEXT_TEXT)
  })

  it("shows only the awaiting placeholder when the directory is missing", () => {
    const runs = footerRuns({ branch: "main" }, undefined)
    expect(text(runs)).toBe(`\u2387 main${SEP}${AWAITING_CONTEXT_TEXT}`)
    expect(text(footerRuns({}, undefined))).toBe(AWAITING_CONTEXT_TEXT)
  })
})

describe("the degradation segments at the zone boundaries", () => {
  const ctx: FooterContext = { directory: "/Users/me/dotfiles", branch: "feat/zone" }

  it("renders SHARP below the first third", () => {
    const runs = footerRuns(ctx, usage(10_000, 400_000))
    expect(text(runs)).toBe(`dotfiles${SEP}\u2387 feat/zone${SEP}\u25CF SHARP █░░░░░░░░░ 5% eff \u00B7 10k/400k \u00B7 3% nom`)
  })

  it("renders FADING immediately around the first third", () => {
    expect(text(footerRuns(ctx, usage(66_666, 400_000)))).toBe(
      `dotfiles${SEP}\u2387 feat/zone${SEP}\u25CF SHARP ███░░░░░░░ 33% eff \u00B7 67k/400k \u00B7 17% nom`,
    )
    expect(text(footerRuns(ctx, usage(66_667, 400_000)))).toBe(
      `dotfiles${SEP}\u2387 feat/zone${SEP}\u25D5 FADING ███░░░░░░░ 33% eff \u00B7 67k/400k \u00B7 17% nom`,
    )
  })

  it("renders RISKY immediately around the second third and up to the limit", () => {
    expect(text(footerRuns(ctx, usage(133_333, 400_000)))).toBe(
      `dotfiles${SEP}\u2387 feat/zone${SEP}\u25D5 FADING ███████░░░ 67% eff \u00B7 133k/400k \u00B7 33% nom`,
    )
    expect(text(footerRuns(ctx, usage(133_334, 400_000)))).toBe(
      `dotfiles${SEP}\u2387 feat/zone${SEP}\u25D1 RISKY ███████░░░ 67% eff \u00B7 133k/400k \u00B7 33% nom`,
    )
    expect(text(footerRuns(ctx, usage(199_999, 400_000)))).toBe(
      `dotfiles${SEP}\u2387 feat/zone${SEP}\u25D1 RISKY ██████████ 100% eff \u00B7 200k/400k \u00B7 50% nom`,
    )
  })

  it("renders CAVEMAN exactly at the limit and above it", () => {
    expect(text(footerRuns(ctx, usage(200_000, 400_000)))).toBe(
      `dotfiles${SEP}\u2387 feat/zone${SEP}\u25D4 CAVEMAN ██████████ 100% eff \u00B7 200k/400k \u00B7 50% nom`,
    )
    expect(text(footerRuns(ctx, usage(250_000, 400_000)))).toBe(
      `dotfiles${SEP}\u2387 feat/zone${SEP}\u25D4 CAVEMAN ██████████ 125% eff \u00B7 250k/400k \u00B7 63% nom`,
    )
  })

  it("colors the zone glyph, meter fill and percentage, and mutes track and metadata", () => {
    const runs = footerRuns(ctx, usage(150_000, 400_000))
    const tones = runs.map((run) => run.tone)
    // [folder, sep, branch, sep, glyphLabel, space, fill, track, space, effPct, meta]
    expect(tones).toEqual([
      "muted", "muted", "muted", "muted",
      "warning", undefined, "warning", "muted", undefined, "warning", "muted",
    ])
  })
})

describe("small-model clamping and window scaling", () => {
  const ctx: FooterContext = { directory: "/repo", branch: "main" }

  it("zones out a small model by its own window, not the 200k contract", () => {
    expect(text(footerRuns(ctx, usage(32_000, 32_000)))).toBe(
      `repo${SEP}\u2387 main${SEP}\u25D4 CAVEMAN ██████████ 100% eff \u00B7 32k/32k \u00B7 100% nom`,
    )
    expect(text(footerRuns(ctx, usage(31_999, 32_000)))).toBe(
      `repo${SEP}\u2387 main${SEP}\u25D1 RISKY ██████████ 100% eff \u00B7 32k/32k \u00B7 100% nom`,
    )
  })

  it("does not scale the fixed budget for larger advertised windows", () => {
    expect(text(footerRuns(ctx, usage(199_999, 1_000_000)))).toBe(
      `repo${SEP}\u2387 main${SEP}\u25D1 RISKY ██████████ 100% eff \u00B7 200k/1.0M \u00B7 20% nom`,
    )
    expect(text(footerRuns(ctx, usage(200_000, 1_000_000)))).toBe(
      `repo${SEP}\u2387 main${SEP}\u25D4 CAVEMAN ██████████ 100% eff \u00B7 200k/1.0M \u00B7 20% nom`,
    )
  })
})

describe("honest unavailable display", () => {
  const ctx: FooterContext = { directory: "/repo", branch: "main" }

  it("shows the placeholder when usage is missing", () => {
    expect(text(footerRuns(ctx, undefined))).toBe(`repo${SEP}\u2387 main${SEP}${AWAITING_CONTEXT_TEXT}`)
    expect(text(footerRuns(ctx, usage(0, 400_000)))).toBe(`repo${SEP}\u2387 main${SEP}${AWAITING_CONTEXT_TEXT}`)
  })

  it("shows the placeholder when the window is missing — never a fabricated percentage", () => {
    expect(text(footerRuns(ctx, usage(130_000, 0)))).toBe(`repo${SEP}\u2387 main${SEP}${AWAITING_CONTEXT_TEXT}`)
  })
})

describe("managed configuration reaching the footer", () => {
  const ctx: FooterContext = { directory: "/repo", branch: "main" }

  it("applies the configured meter width and effective limit", () => {
    const config = configFromOptions({ effectiveLimit: 100_000, meterWidth: 6 })
    expect(text(footerRuns(ctx, usage(50_000, 200_000), config))).toBe(
      `repo${SEP}\u2387 main${SEP}\u25D5 FADING ███░░░ 50% eff \u00B7 50k/200k \u00B7 25% nom`,
    )
  })

  it("applies environment overrides layered over the managed options", () => {
    const base = configFromOptions({ effectiveLimit: 100_000, meterWidth: 6 })
    // Mirror the entry's layering with the same helper under test: env replaces
    // only the keys it names, so the managed meter width survives.
    const config = { ...base, effectiveLimit: 200_000 }
    expect(text(footerRuns(ctx, usage(150_000, 300_000), config))).toBe(
      `repo${SEP}\u2387 main${SEP}\u25D1 RISKY █████░ 75% eff \u00B7 150k/300k \u00B7 50% nom`,
    )
  })
})
