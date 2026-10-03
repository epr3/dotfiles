// Dumb-zone degradation model for OpenCode v2 — the statusline contract
// established by docs/adr/2026-08-20-dumb-zone-contract-200k.md, expressed here
// as an independent implementation for the OpenCode CLI footer plugin.
// No Pi code, theme, or runtime extension is imported.
//
// Effective context is an *absolute* budget, not a fraction of the advertised
// window: degradation sets in past a fixed token count regardless of how big
// the nominal window is. Zones map onto a fixed effective limit (200,000
// tokens, clamped to the nominal window only for small models), and each
// boundary is a real step down, not a gradient:
//
//   sharp    below the first third of the effective limit
//   fading   from the first third up to the second third
//   risky    from the second third up to (but not including) the limit
//   caveman  at or over the limit — the boundary is inclusive
//
// The default thresholds are the contract's exact thirds; the boundary tests
// pin both sides of every default stop (66,666/66,667, 133,333/133,334,
// 199,999, 200,000) so the fractional comparisons cannot drift.

export type Zone = "sharp" | "fading" | "risky" | "caveman";

export interface ZoneConfig {
  /** Effective context budget in tokens — absolute, independent of the model's window. */
  effectiveLimit: number;
  /** Upper bounds as fractions of the limit; risky's bound is 1 — caveman begins at the limit itself. */
  thresholds: { sharp: number; fading: number; risky: number };
}

/** The full runtime config: the ADR contract plus the meter width. */
export type DumbZoneConfig = ZoneConfig & { meterWidth: number };

export interface ZoneResult {
  zone: Zone;
  /** Used / effective window. */
  fracEff: number;
  /** Used / nominal window. */
  fracNom: number;
}

/** The deployed 200k contract: effective limit with equal-third thresholds. */
export const ZONE_DEFAULTS: ZoneConfig = {
  effectiveLimit: 200_000,
  thresholds: { sharp: 1 / 3, fading: 2 / 3, risky: 1 },
};

/** The runtime defaults: the contract plus the ten-cell meter. */
export const DEFAULT_CONFIG: DumbZoneConfig = { ...ZONE_DEFAULTS, meterWidth: 10 };

/** Zone → OpenCode theme feedback token: sharp green, degraded yellow, caveman red. */
export const ZONE_TONE: Record<Zone, "success" | "warning" | "error"> = {
  sharp: "success",
  fading: "warning",
  risky: "warning",
  caveman: "error",
};

/** Glyph per zone: a circle showing *remaining* effective headroom. */
export const ZONE_GLYPH: Record<Zone, string> = {
  sharp: "\u25CF", // ● full
  fading: "\u25D5", // ◕ three-quarters
  risky: "\u25D1", // ◑ half
  caveman: "\u25D4", // ◔ a sliver
};

/** Display labels — explicit, decoupled from the Zone type value casing. */
export const ZONE_LABEL: Record<Zone, string> = {
  sharp: "SHARP",
  fading: "FADING",
  risky: "RISKY",
  caveman: "CAVEMAN",
};

function num(v: string | undefined, fallback: number): number {
  const n = v ? Number(v) : NaN;
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

/** Token counts accept k/M suffixes: "200k", "0.5M", or plain "200000". */
function tokens(v: string | undefined, fallback: number): number {
  if (!v) return fallback;
  const m = /^(\d+(?:\.\d+)?)\s*([kKmM]?)$/.exec(v.trim());
  if (!m) return fallback;
  const mult = m[2]!.toLowerCase() === "m" ? 1_000_000 : m[2]!.toLowerCase() === "k" ? 1_000 : 1;
  const n = Number(m[1]) * mult;
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

/**
 * Layer env tunables (EFFECTIVE_LIMIT in tokens, Z_SHARP, Z_FADING, Z_RISKY)
 * over a base config — the base being the managed plugin options or the code
 * defaults. Env wins: it is the quick-experiment layer of the deployed
 * override precedence (defaults < managed options < environment). Env replaces
 * only the keys it names; everything else in the base (meterWidth included)
 * passes through unchanged.
 */
export function configFromEnv(
  env: NodeJS.ProcessEnv = process.env,
  base: DumbZoneConfig = DEFAULT_CONFIG,
): DumbZoneConfig {
  return {
    ...DEFAULT_CONFIG,
    ...base,
    effectiveLimit: tokens(env.EFFECTIVE_LIMIT, base.effectiveLimit),
    thresholds: {
      sharp: num(env.Z_SHARP, base.thresholds.sharp),
      fading: num(env.Z_FADING, base.thresholds.fading),
      risky: num(env.Z_RISKY, base.thresholds.risky),
    },
  };
}

/**
 * The managed plugin options layer: the same shape Pi's settings.json carried
 * (effectiveLimit, thresholds{sharp,fading,risky}), plus meterWidth. Invalid
 * values fall back to the code defaults rather than disabling the line.
 */
export function configFromOptions(
  options: unknown = {},
  base: DumbZoneConfig = DEFAULT_CONFIG,
): DumbZoneConfig {
  const raw = (options && typeof options === "object" && !Array.isArray(options) ? options : {}) as {
    effectiveLimit?: unknown;
    thresholds?: { sharp?: unknown; fading?: unknown; risky?: unknown };
    meterWidth?: unknown;
  };
  const fraction = (v: unknown, fallback: number): number =>
    typeof v === "number" && Number.isFinite(v) && v > 0 ? v : fallback;
  const thresholds = (raw.thresholds && typeof raw.thresholds === "object" ? raw.thresholds : {}) as {
    sharp?: unknown;
    fading?: unknown;
    risky?: unknown;
  };
  const width = Math.floor(Number(raw.meterWidth));
  return {
    effectiveLimit: fraction(raw.effectiveLimit, base.effectiveLimit),
    thresholds: {
      sharp: fraction(thresholds.sharp, base.thresholds.sharp),
      fading: fraction(thresholds.fading, base.thresholds.fading),
      risky: fraction(thresholds.risky, base.thresholds.risky),
    },
    meterWidth: Number.isFinite(width) && width > 0 ? Math.max(4, width) : base.meterWidth,
  };
}

/**
 * The meter width from a config: floored, never below four cells, defaulting
 * to ten. The single clamp both the options layer and the footer use.
 */
export function meterWidthOf(config: { meterWidth?: unknown }): number {
  const width = Math.floor(Number(config.meterWidth));
  return Number.isFinite(width) && width > 0 ? Math.max(4, width) : 10;
}

/**
 * Classify a session against the cliff. The budget is absolute; a bigger
 * advertised window does not move it. Clamp to the nominal window only so
 * models *smaller* than the limit zone out before they overflow. Zones compare
 * the effective fraction against the config's thresholds — the deployed
 * contract's fractional thirds by default, overridable through the managed
 * options or the Z_* environment.
 */
export function classify(
  usedTokens: number,
  window: number,
  config: ZoneConfig = ZONE_DEFAULTS,
): ZoneResult {
  const effective = window > 0 ? Math.min(config.effectiveLimit, window) : config.effectiveLimit;
  const fracEff = effective > 0 ? usedTokens / effective : 0;
  const fracNom = window > 0 ? usedTokens / window : 0;
  const t = config.thresholds;
  const zone: Zone =
    fracEff < t.sharp
      ? "sharp"
      : fracEff < t.fading
        ? "fading"
        : fracEff < t.risky
          ? "risky"
          : "caveman";
  return { zone, fracEff, fracNom };
}

/**
 * Contiguous whole-cell meter. Fractions round to the nearest whole cell,
 * clamped to an empty or full bar. Returns filled and track separately so
 * the renderer can color them independently (zone fill, muted track).
 */
export function meter(fracEff: number, width = 10): { filled: string; track: string } {
  const f = Math.max(0, Math.min(1, fracEff));
  const used = Math.max(0, Math.min(width, Math.round(f * width)));
  return { filled: "\u2588".repeat(used), track: "\u2591".repeat(width - used) };
}

export function human(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${Math.round(n / 1_000)}k`;
  return `${n}`;
}

/** Pre-first-response placeholder text: honest unavailability, not zeros. */
export const AWAITING_CONTEXT_TEXT = "\u25CB awaiting context"; // ○

function pct(f: number): string {
  return `${Math.round(f * 100)}%`;
}

/**
 * Pure status text segments, one per themed region: the zone glyph and label,
 * the effective-budget percentage, and the usage metadata (used tokens over
 * the nominal window, and the nominal-window percentage).
 */
export function formatStatusSegments(
  zone: Zone,
  fracEff: number,
  fracNom: number,
  usedTokens: number,
  window: number,
): { glyphAndLabel: string; effPct: string; usageMeta: string } {
  return {
    glyphAndLabel: `${ZONE_GLYPH[zone]} ${ZONE_LABEL[zone]}`,
    effPct: pct(fracEff),
    usageMeta: `eff \u00B7 ${human(usedTokens)}/${human(window)} \u00B7 ${pct(fracNom)} nom`,
  };
}
