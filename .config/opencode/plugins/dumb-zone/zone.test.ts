import { describe, expect, it } from "bun:test"
import {
  AWAITING_CONTEXT_TEXT,
  classify,
  configFromEnv,
  configFromOptions,
  formatStatusSegments,
  human,
  meter,
  meterWidthOf,
  DEFAULT_CONFIG,
  ZONE_DEFAULTS,
  ZONE_GLYPH,
  ZONE_LABEL,
  ZONE_TONE,
  type DumbZoneConfig,
  type Zone,
  type ZoneConfig,
} from "./zone.ts"

const PARTIAL_GLYPHS = /[\u258F\u258E\u258D\u258C\u258B\u258A\u2589]/ // ▏▎▍▌▋▊▉

function onlyWholeCells(s: string): boolean {
  return !PARTIAL_GLYPHS.test(s)
}

describe("headroom meter", () => {
  it("uses only whole filled and track cells", () => {
    for (const f of [0, 0.12, 0.25, 0.33, 0.5, 0.66, 0.75, 0.88, 1]) {
      const { filled, track } = meter(f, 10)
      expect(onlyWholeCells(filled)).toBe(true)
      expect(onlyWholeCells(track)).toBe(true)
    }
  })

  it("filled and track lengths sum to width for representative fractions", () => {
    for (const width of [4, 10, 20]) {
      for (let i = 0; i <= width; i++) {
        const { filled, track } = meter(i / width, width)
        expect(filled.length + track.length).toBe(width)
      }
    }
  })

  it("clamps below zero to empty and above one to full", () => {
    expect(meter(-0.5, 10)).toEqual({ filled: "", track: "░░░░░░░░░░" })
    expect(meter(0, 10)).toEqual({ filled: "", track: "░░░░░░░░░░" })
    expect(meter(1, 10)).toEqual({ filled: "██████████", track: "" })
    expect(meter(1.5, 10)).toEqual({ filled: "██████████", track: "" })
  })

  it("rounds fractional progress to nearest whole cell", () => {
    expect(meter(0.04, 10).filled.length).toBe(0)
    expect(meter(0.05, 10).filled.length).toBe(1)
    expect(meter(0.14, 10).filled.length).toBe(1)
    expect(meter(0.16, 10).filled.length).toBe(2)
    expect(meter(0.74, 10).filled.length).toBe(7)
    expect(meter(0.76, 10).filled.length).toBe(8)
    expect(meter(0.95, 10).filled.length).toBe(10)
  })
})

describe("dumb zone classification", () => {
  it("ships the deployed 200k contract with equal-third thresholds", () => {
    expect(ZONE_DEFAULTS.effectiveLimit).toBe(200_000)
    expect(ZONE_DEFAULTS.thresholds.sharp).toBeCloseTo(1 / 3, 10)
    expect(ZONE_DEFAULTS.thresholds.fading).toBeCloseTo(2 / 3, 10)
    expect(ZONE_DEFAULTS.thresholds.risky).toBe(1)
  })

  it("classifies the default stops immediately around every boundary", () => {
    const cases: [number, Zone][] = [
      [66_666, "sharp"],
      [66_667, "fading"],
      [133_333, "fading"],
      [133_334, "risky"],
      [199_999, "risky"],
      [200_000, "caveman"],
      [250_000, "caveman"],
    ]
    for (const [used, expected] of cases) {
      expect(classify(used, 400_000).zone).toBe(expected)
    }
  })

  it("enters caveman at exactly the effective limit (inclusive boundary)", () => {
    expect(classify(200_000, 400_000).zone).toBe("caveman")
    expect(classify(200_000, 200_000).zone).toBe("caveman") // window == limit
    expect(classify(199_999, 400_000).zone).toBe("risky") // just before stays risky
  })

  it("classifies plain fraction stops on a 2x window", () => {
    const limit = ZONE_DEFAULTS.effectiveLimit
    const cases: [number, Zone][] = [
      [limit * 0.1, "sharp"],
      [limit * 0.5, "fading"],
      [limit * 0.9, "risky"],
      [limit * 1.1, "caveman"],
    ]
    for (const [used, expected] of cases) {
      expect(classify(used, limit * 2).zone).toBe(expected)
    }
  })

  it("clamps the effective limit to smaller nominal windows", () => {
    expect(classify(32_000, 32_000).zone).toBe("caveman") // effective = 32k
    expect(classify(31_999, 32_000).zone).toBe("risky")
  })

  it("does not move the cliff for larger nominal windows", () => {
    expect(classify(200_000, 1_000_000).zone).toBe("caveman")
    expect(classify(199_999, 1_000_000).zone).toBe("risky")
    expect(classify(20_000, 1_000_000).zone).toBe("sharp") // 10% of 200k, not of 1M
  })

  it("degenerates defensively", () => {
    expect(classify(0, 400_000).zone).toBe("sharp")
    expect(classify(-1, 400_000).zone).toBe("sharp")
    expect(classify(1_000, 0).zone).toBe("sharp") // no window: unclamped default limit
  })

  it("honors managed and environment threshold overrides", () => {
    const config: ZoneConfig = {
      effectiveLimit: 100_000,
      thresholds: { sharp: 0.5, fading: 0.75, risky: 0.9 },
    }
    expect(classify(40_000, 300_000, config).zone).toBe("sharp") // 40% of 100k
    expect(classify(60_000, 300_000, config).zone).toBe("fading") // 60%
    expect(classify(85_000, 300_000, config).zone).toBe("risky") // 85%
    expect(classify(95_000, 300_000, config).zone).toBe("caveman") // 95%, at-or-over risky's 0.9 bound
    const viaEnv = configFromEnv({ Z_SHARP: "0.1", Z_FADING: "0.2", Z_RISKY: "0.3" }, {
      ...config,
      meterWidth: 10,
    })
    expect(classify(15_000, 300_000, viaEnv).zone).toBe("fading") // 15% of 100k, past the 10% sharp bound
    expect(classify(35_000, 300_000, viaEnv).zone).toBe("caveman") // 35%, at-or-over the 20% risky bound
  })
})

describe("zone presentation", () => {
  it("keeps glyphs unchanged", () => {
    expect(ZONE_GLYPH.sharp).toBe("●")
    expect(ZONE_GLYPH.fading).toBe("◕")
    expect(ZONE_GLYPH.risky).toBe("◑")
    expect(ZONE_GLYPH.caveman).toBe("◔")
  })

  it("maps each zone to its uppercase display label", () => {
    expect(ZONE_LABEL.sharp).toBe("SHARP")
    expect(ZONE_LABEL.fading).toBe("FADING")
    expect(ZONE_LABEL.risky).toBe("RISKY")
    expect(ZONE_LABEL.caveman).toBe("CAVEMAN")
  })

  it("maps each zone to the expected theme feedback token", () => {
    expect(ZONE_TONE.sharp).toBe("success")
    expect(ZONE_TONE.fading).toBe("warning")
    expect(ZONE_TONE.risky).toBe("warning")
    expect(ZONE_TONE.caveman).toBe("error")
  })

  it("formats token counts as k or M", () => {
    expect(human(1_500)).toBe("2k")
    expect(human(1_200_000)).toBe("1.2M")
    expect(human(200_000)).toBe("200k")
    expect(human(1_000_000)).toBe("1.0M")
    expect(human(999)).toBe("999")
  })
})

describe("managed options layer", () => {
  it("uses defaults when no options are given", () => {
    const c = configFromOptions(undefined)
    expect(c.effectiveLimit).toBe(200_000)
    expect(c.thresholds.sharp).toBeCloseTo(1 / 3, 10)
    expect(c.meterWidth).toBe(10)
  })

  it("carries the managed shape (effectiveLimit, thresholds, meterWidth)", () => {
    const c = configFromOptions({
      effectiveLimit: 100_000,
      thresholds: { sharp: 0.25, fading: 0.75, risky: 0.9 },
      meterWidth: 6,
    })
    expect(c.effectiveLimit).toBe(100_000)
    expect(c.thresholds).toEqual({ sharp: 0.25, fading: 0.75, risky: 0.9 })
    expect(c.meterWidth).toBe(6)
  })

  it("falls back per value on invalid options and floors tiny meter widths", () => {
    const c = configFromOptions({
      effectiveLimit: -5,
      thresholds: { sharp: "0.1", risky: 0 },
      meterWidth: 1,
    })
    expect(c.effectiveLimit).toBe(200_000)
    expect(c.thresholds.sharp).toBeCloseTo(1 / 3, 10)
    expect(c.thresholds.risky).toBe(1)
    expect(c.meterWidth).toBe(4)
  })

  it("keeps custom meter widths working for classification consumers", () => {
    const c = configFromOptions({ meterWidth: 20 })
    expect(c.meterWidth).toBe(20)
  })
})

describe("environment layer", () => {
  it("uses defaults when no env vars are set", () => {
    const c = configFromEnv({}, DEFAULT_CONFIG)
    expect(c.effectiveLimit).toBe(ZONE_DEFAULTS.effectiveLimit)
    expect(c.thresholds.sharp).toBe(ZONE_DEFAULTS.thresholds.sharp)
    expect(c.thresholds.fading).toBe(ZONE_DEFAULTS.thresholds.fading)
    expect(c.thresholds.risky).toBe(ZONE_DEFAULTS.thresholds.risky)
    expect(c.meterWidth).toBe(10)
  })

  it("wins over the managed options layer, replacing only what it names", () => {
    const base = configFromOptions({ effectiveLimit: 100_000, thresholds: { sharp: 0.5, fading: 0.75, risky: 0.9 }, meterWidth: 6 })
    const c = configFromEnv({ EFFECTIVE_LIMIT: "200k" }, base)
    expect(c.effectiveLimit).toBe(200_000)
    expect(c.thresholds.sharp).toBe(0.5) // env does not touch what it does not name
    expect(c.meterWidth).toBe(6) // the managed meter width survives the env layer
  })

  it("accepts k-suffix token counts and overrides individual thresholds", () => {
    const c = configFromEnv({ EFFECTIVE_LIMIT: "200k", Z_SHARP: "0.5", Z_RISKY: "0.9" }, ZONE_DEFAULTS)
    expect(c.effectiveLimit).toBe(200_000)
    expect(c.thresholds.sharp).toBe(0.5)
    expect(c.thresholds.fading).toBe(ZONE_DEFAULTS.thresholds.fading)
    expect(c.thresholds.risky).toBe(0.9)
  })

  it("handles M-suffix and plain number token limits", () => {
    expect(configFromEnv({ EFFECTIVE_LIMIT: "0.5M" }, ZONE_DEFAULTS).effectiveLimit).toBe(500_000)
    expect(configFromEnv({ EFFECTIVE_LIMIT: "80000" }, ZONE_DEFAULTS).effectiveLimit).toBe(80_000)
  })

  it("ignores malformed values rather than zeroing the contract", () => {
    const c = configFromEnv({ EFFECTIVE_LIMIT: "abc", Z_SHARP: "x" }, ZONE_DEFAULTS)
    expect(c.effectiveLimit).toBe(200_000)
    expect(c.thresholds.sharp).toBeCloseTo(1 / 3, 10)
  })

  it("applies an env-derived effective limit to classification", () => {
    const base: DumbZoneConfig = { ...ZONE_DEFAULTS, meterWidth: 10, effectiveLimit: 100_000 }
    const c = configFromEnv({ EFFECTIVE_LIMIT: "200k" }, base)
    expect(c.effectiveLimit).toBe(200_000)
    expect(classify(150_000, 300_000, c).zone).toBe("risky") // 75% of 200k
    expect(classify(200_000, 400_000, c).zone).toBe("caveman")
  })
})

describe("formatStatusSegments", () => {
  it("returns correct glyphAndLabel and effPct for each zone", () => {
    const limit = ZONE_DEFAULTS.effectiveLimit
    const cases: [number, string, string][] = [
      [limit * 0.1, `${ZONE_GLYPH.sharp} SHARP`, "10%"],
      [limit * 0.34, `${ZONE_GLYPH.fading} FADING`, "34%"],
      [limit * 0.67, `${ZONE_GLYPH.risky} RISKY`, "67%"],
      [limit * 1.0, `${ZONE_GLYPH.caveman} CAVEMAN`, "100%"],
    ]
    for (const [used, expectedGlyphAndLabel, expectedEff] of cases) {
      const { zone, fracEff, fracNom } = classify(used, limit * 2)
      const segs = formatStatusSegments(zone, fracEff, fracNom, used, limit * 2)
      expect(segs.glyphAndLabel).toBe(expectedGlyphAndLabel)
      expect(segs.effPct).toBe(expectedEff)
    }
  })

  it("usageMeta contains expected wording and separator structure", () => {
    const used = 40_000
    const window = 200_000
    const { zone, fracEff, fracNom } = classify(used, window)
    const segs = formatStatusSegments(zone, fracEff, fracNom, used, window)
    expect(segs.usageMeta).toMatch(/^eff \u00B7 40k\/200k \u00B7 20% nom$/)
  })

  it("usageMeta adapts to different token counts", () => {
    const window = 200_000
    const { zone: z1, fracEff: e1, fracNom: n1 } = classify(1, window)
    const segs1 = formatStatusSegments(z1, e1, n1, 1, window)
    expect(segs1.usageMeta).toMatch(/^eff \u00B7 1\/200k \u00B7 0% nom$/)

    const { zone: z2, fracEff: e2, fracNom: n2 } = classify(200_000, window)
    const segs2 = formatStatusSegments(z2, e2, n2, 200_000, window)
    expect(segs2.usageMeta).toMatch(/^eff \u00B7 200k\/200k \u00B7 100% nom$/)
  })
})

describe("statusline constants", () => {
  it("AWAITING_CONTEXT_TEXT is the expected placeholder string", () => {
    expect(AWAITING_CONTEXT_TEXT).toBe("\u25CB awaiting context")
  })
})
