import { advertisedWindow, latestReportedUsage, thresholdReached } from "./model-aware-compaction/policy.ts"

const ModelAwareCompaction = {
  id: "model-aware-compaction",
  setup(ctx: any) {
    const pending = new Set<string>()
    const warned = new Set<string>()
    const controller = new AbortController()

    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          const sessionID = event.properties?.sessionID ?? event.data?.sessionID
          if (event.type === "session.compacted" || event.type === "session.compaction.ended") {
            if (sessionID) pending.delete(sessionID)
            continue
          }
          if (event.type !== "session.idle" && event.type !== "session.execution.succeeded") continue

          if (!sessionID) continue
          if (pending.has(sessionID)) continue
          try {
            const [messages, models] = await Promise.all([
              ctx.session.context({ sessionID }),
              ctx.model.list(),
            ])
            const catalog = Array.isArray(models) ? models : models?.data ?? models?.models ?? []
            const message = [...messages].reverse().find((item: any) => (item.info ?? item).role === "assistant" || (item.info ?? item).type === "assistant")
            const info = message?.info ?? message
            const used = latestReportedUsage(message ? [message] : undefined)
            if (!message || used === undefined) continue

            const providerID = info.providerID ?? info.model?.providerID
            const modelID = info.modelID ?? info.model?.id
            const key = `${providerID}/${modelID}`
            const model = catalog.find((candidate: any) => candidate.providerID === providerID && (candidate.id ?? candidate.modelID) === modelID)
            const window = advertisedWindow(
              model ? [{ id: providerID, models: { [modelID]: { id: modelID, limit: model.limit } } }] : undefined,
              providerID,
              modelID,
            )
            if (window === undefined) {
              if (!warned.has(key)) {
                warned.add(key)
                console.warn(`[model-aware-compaction] no advertised context window for ${key}; automatic compaction skipped`)
              }
              continue
            }
            if (!thresholdReached(used, window)) continue

            pending.add(sessionID)
            console.info(`[model-aware-compaction] threshold reached: model=${key} usage=${used} window=${window}`)
            await ctx.session.compact({ sessionID })
          } catch (error) {
            pending.delete(sessionID)
            console.error(`[model-aware-compaction] failed to evaluate or queue compaction for ${sessionID}`, error)
          }
        }
      } catch (error) {
        if (!controller.signal.aborted) console.error("[model-aware-compaction] event subscription failed", error)
      }
    })()

    return () => controller.abort()
  },
}

export default ModelAwareCompaction
