// Footer-run assembly for the dumb-zone statusline: pure presentation, no
// OpenCode host imports, so the whole visible contract can be asserted without
// a terminal. The TUI entry (tui.tsx) feeds this module exactly the shapes the
// host delivers — the working directory, the VCS branch, the session's message
// records, the model catalog, and the active model selection — and maps each
// run's tone to OpenCode's resolved theme tokens.
//
// Anatomy (plain Unicode, no Nerd Font needed):
//
//   dotfiles │ ⎇ main │ ◑ RISKY ██████░░░░ 130k/200k │ cache hit 80%
//
// Unavailable reads stay honest: with no usage record or no advertised window,
// the zone cluster is replaced by the awaiting-context placeholder — never a
// fabricated zero usage or percentage. A missing branch (outside a git
// repository) simply omits the branch segment and keeps the directory.

import {
  AWAITING_CONTEXT_TEXT,
  classify,
  human,
  meter,
  meterWidthOf,
  DEFAULT_CONFIG,
  ZONE_GLYPH,
  ZONE_LABEL,
  ZONE_TONE,
  type DumbZoneConfig,
  type Zone,
  type ZoneResult,
} from "./zone.ts"

/** Theme token roles a run may draw with; `undefined` is the default foreground. */
export type Tone = "muted" | "success" | "warning" | "error"

export interface Run {
  text: string
  tone?: Tone
}

/** The shape of a host token record (a session message's `tokens`). */
export interface TokenRecord {
  input?: number
  output?: number
  reasoning?: number
  cache?: { read?: number; write?: number }
}

/** The model reference a session record or message carries (`{id, providerID}`-shaped). */
export interface ModelRef {
  id?: string
  modelID?: string
  providerID?: string
}

/** The shape of a host message record this plugin reads. */
export interface MessageRecord {
  type?: string
  tokens?: TokenRecord
  model?: ModelRef
}

/** The shape of a catalog entry in the location's model list. */
export interface CatalogEntry extends ModelRef {
  limit?: { context?: number }
}

/** Everything the current context occupies — the sum OpenCode's own display uses. */
export function sumTokens(tokens?: TokenRecord): number {
  if (!tokens) return 0
  return (
    (tokens.input ?? 0) +
    (tokens.output ?? 0) +
    (tokens.reasoning ?? 0) +
    (tokens.cache?.read ?? 0) +
    (tokens.cache?.write ?? 0)
  )
}

/**
 * The window's occupant: the newest assistant message that reported usage.
 * The session record's token totals are cumulative across turns — summing
 * them would report every prompt ever sent — so the footer reads the last
 * request's own record instead, with that request's model reference.
 */
export function newestAssistantUsage(
  messages: readonly MessageRecord[] | undefined,
): { usedTokens: number; model?: ModelRef; cacheHitPercent?: number } | undefined {
  if (!messages) return undefined
  let found: { usedTokens: number; model?: ModelRef; cacheHitPercent?: number } | undefined
  for (const message of messages) {
    if (message?.type !== "assistant" || !message.tokens) continue
    const used = sumTokens(message.tokens)
    if (used > 0) {
      const { input, cache } = message.tokens
      const read = cache?.read
      const write = cache?.write ?? 0
      const valid = (n: unknown): n is number => typeof n === "number" && Number.isFinite(n) && n >= 0
      const total = valid(input) && valid(read) && valid(write) ? input + read + write : 0
      found = { usedTokens: used, model: message.model, cacheHitPercent: total > 0 ? 100 * read! / total : undefined }
    }
  }
  return found
}

/**
 * The advertised context window for a model reference, where the location's
 * catalog declares one. A model absent from the catalog, or listed without a
 * positive `limit.context`, reads as unavailable — the caller shows the
 * honest placeholder rather than a percentage of nothing.
 */
export function catalogWindow(
  entries: readonly CatalogEntry[] | undefined,
  ref: ModelRef | undefined,
): number | undefined {
  const wanted = ref?.modelID ?? ref?.id
  if (!ref?.providerID || !wanted) return undefined
  for (const entry of entries ?? []) {
    if (entry?.id === wanted && entry?.providerID === ref.providerID) {
      const limit = entry.limit?.context
      if (typeof limit === "number" && limit > 0) return limit
    }
  }
  return undefined
}

/** Where the session works: the directory's own name, and its git branch. */
export interface FooterContext {
  /** The session's working directory; empty or missing omits the segment. */
  directory?: string | null
  /** The git branch; empty or missing (no repository) omits the segment. */
  branch?: string | null
}

/** The usage the host reports for the newest request, when it reports any. */
export interface FooterUsage {
  usedTokens: number
  windowTokens: number
}

/** The folder's own name, from either path separator. */
export function basename(p: string | undefined | null): string {
  if (!p) return ""
  const parts = p.replace(/[/\\]+$/, "").split(/[/\\]/)
  return parts[parts.length - 1] ?? ""
}

/** The separator between top-level segments, drawn in the muted ink. */
export const SEGMENT_SEPARATOR = " │ "

/** The zone block (glyph, label, meter) for an available reading. */
export function zoneRuns(result: ZoneResult, usage: FooterUsage, width: number): Run[] {
  const tone = ZONE_TONE[result.zone]
  const m = meter(result.fracEff, width)
  return [
    { text: `${ZONE_GLYPH[result.zone]} ${ZONE_LABEL[result.zone]}`, tone },
    { text: " " },
    { text: m.filled, tone },
    { text: m.track, tone: "muted" },
    { text: ` ${human(usage.usedTokens)}/${human(usage.windowTokens)}`, tone: "muted" },
  ]
}

/**
 * The whole footer for one paint. `usage` arrives as the host's own metadata:
 * the newest assistant request's token occupancy and the active model's
 * advertised context window. A session with neither — before the first
 * response, a model without an advertised window, a fresh session — shows the
 * awaiting-context placeholder instead of zeros.
 */
export function footerRuns(
  context: FooterContext,
  usage: FooterUsage | undefined,
  config: DumbZoneConfig = DEFAULT_CONFIG,
  cacheHitPercent?: number,
): Run[] {
  const segments: Run[][] = []
  const folder = basename(context.directory)
  if (folder) segments.push([{ text: folder, tone: "muted" }])
  const branch = (context.branch ?? "").trim()
  if (branch) segments.push([{ text: `\u2387 ${branch}`, tone: "muted" }]) // ⎇

  const available = usage !== undefined && usage.usedTokens > 0 && usage.windowTokens > 0
  if (available) {
    const result = classify(usage.usedTokens, usage.windowTokens, config)
    segments.push(zoneRuns(result, usage, meterWidthOf(config)))
  } else {
    segments.push([{ text: AWAITING_CONTEXT_TEXT, tone: "muted" }])
  }
  if (typeof cacheHitPercent === "number" && Number.isFinite(cacheHitPercent) && cacheHitPercent >= 0 && cacheHitPercent <= 100) {
    segments.push([{ text: `cache hit ${Math.round(cacheHitPercent)}%`, tone: "muted" }])
  }

  const runs: Run[] = []
  for (const segment of segments) {
    if (runs.length > 0) runs.push({ text: SEGMENT_SEPARATOR, tone: "muted" })
    runs.push(...segment)
  }
  return runs
}

export type { Zone, ZoneResult }
