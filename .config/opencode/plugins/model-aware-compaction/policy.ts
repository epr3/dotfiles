export interface ModelWindow {
  id: string
  limit?: { context?: number }
}

export interface ProviderModels {
  id: string
  models: Record<string, ModelWindow>
}

export interface UsageMessage {
  role?: string
  type?: string
  tokens?: {
    input?: number
    output?: number
    reasoning?: number
    cache?: { read?: number; write?: number }
  }
}

export const COMPACTION_FRACTION = 0.5
export const RECENT_CONTEXT_TOKENS = 8_000

export function advertisedWindow(
  providers: readonly ProviderModels[] | undefined,
  providerID: string | undefined,
  modelID: string | undefined,
): number | undefined {
  if (!providerID || !modelID) return undefined
  const model = providers?.find((provider) => provider.id === providerID)?.models?.[modelID]
  const context = model?.limit?.context
  return typeof context === "number" && Number.isFinite(context) && context > 0
    ? context
    : undefined
}

export function latestReportedUsage(messages: readonly UsageMessage[] | undefined): number | undefined {
  if (!messages) return undefined
  for (let i = messages.length - 1; i >= 0; i--) {
    const message = messages[i]
    if ((message?.role ?? message?.type) !== "assistant" || !message.tokens) continue
    const { input = 0, output = 0, reasoning = 0, cache } = message.tokens
    const used = input + output + reasoning + (cache?.read ?? 0) + (cache?.write ?? 0)
    if (Number.isFinite(used) && used > 0) return used
  }
  return undefined
}

export function thresholdReached(usedTokens: number | undefined, windowTokens: number | undefined): boolean {
  return (
    typeof usedTokens === "number" && Number.isFinite(usedTokens) && usedTokens >= 0 &&
    typeof windowTokens === "number" && Number.isFinite(windowTokens) && windowTokens > 0 &&
    usedTokens >= windowTokens * COMPACTION_FRACTION
  )
}
