import { describe, expect, it } from "bun:test"
import { advertisedWindow, latestReportedUsage, thresholdReached } from "./policy.ts"

describe("model-aware compaction policy", () => {
  const models = [
    { id: "small", models: { m: { id: "m", limit: { context: 128_000 } } } },
    { id: "large", models: { m: { id: "m", limit: { context: 512_000 } } } },
  ]

  it("uses the active advertised model window and does not invent missing capacity", () => {
    expect(advertisedWindow(models, "small", "m")).toBe(128_000)
    expect(advertisedWindow(models, "large", "m")).toBe(512_000)
    expect(advertisedWindow(models, "missing", "m")).toBeUndefined()
    expect(advertisedWindow([{ id: "x", models: { m: { id: "m" } } }], "x", "m")).toBeUndefined()
  })

  it("triggers inclusively at half each window, not against the Dumb-zone 200k limit", () => {
    for (const window of [128_000, 512_000]) {
      const halfway = window / 2
      expect(thresholdReached(halfway - 1, window)).toBe(false)
      expect(thresholdReached(halfway, window)).toBe(true)
      expect(thresholdReached(halfway + 1, window)).toBe(true)
    }
    expect(thresholdReached(200_000, 512_000)).toBe(false)
    expect(thresholdReached(200_000, 128_000)).toBe(true)
  })

  it("reads the newest assistant usage and ignores records without usable metadata", () => {
    expect(latestReportedUsage([
      { role: "assistant", tokens: { input: 30_000 } },
      { role: "user", tokens: { input: 100_000 } },
      { role: "assistant", tokens: { input: 20_000, cache: { read: 5_000 } } },
    ])).toBe(25_000)
    expect(latestReportedUsage([{ type: "assistant", tokens: { input: 32_000, output: 2 } }])).toBe(32_002)
    expect(latestReportedUsage([{ role: "assistant" }])).toBeUndefined()
  })
})
