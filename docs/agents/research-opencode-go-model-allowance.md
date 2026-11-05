# Research: OpenCode Go model allowance and output pricing, with medium-thinking candidates for tester/researcher/reviewer

**Date:** 2026-11-05 · **Question:** how does opencode.ai estimate Go-plan requests and price outputs, and which `opencode-go/*` models expose a `medium` thinking/effort level — suited for the repo's tester/researcher/reviewer roles, which must stay at or below medium effort?
**Scope:** read-only. Writes one research artifact; fetches official docs and the models.dev catalog; runs `opencode api --standalone model.list` for live variant ladders. No API request was ever sent to OpenCode Go, so no spend and no key material is reproduced here.

## Sources

- [OpenCode Go doc](https://opencode.ai/v2/docs/console/go/) (`#usage-limits`, `#estimated-requests`, `#privacy`) — plan table, dollar-based allowances, token prices, assumed per-request token counts, estimated request tables.
- [Console Models doc](https://opencode.ai/v2/docs/console/models/) — pay-as-you-go pricing context; no variant info.
- [Models doc](https://opencode.ai/v2/docs/models/) — `capabilities.reasoning` / `#variant` selection and `reasoningEffort` settings.
- [models.dev `api.json`](https://models.dev/api.json), fetched 2026-11-05 — catalog cost/limit data per the `opencode-go` provider.
- Live runtime ladders: `opencode api --standalone model.list` on the installed **opencode v2.2.5** CLI (2026-11-05). Variants are built by opencode at runtime from the catalog's reasoning controls; the models.dev JSON and the stale local `~/.cache/opencode/models.json` both show empty variant objects, so the CLI is the authoritative rung list.
- Cross-reference: `docs/opencode-v2-workflows.md` (local, verified-on-runtime observations from ticket `specialist-subagent-routing`), corroborating the recorded `qwen3.8-flash`, `glm-5.3-flash`, `deepseek-v4.1-flash`, and `kimi-k2.7-code` ladders.

## 1. Plans and allowance mechanics (Go doc)

- Plans: **Go $10/mo**, **Go Plus $40/mo**, **Go Teams $20/member/mo** ($5 more than Go on every model, i.e. Go Teams monthly ≈ Go/Plus-plus-5 per model; single-member workspaces can upgrade to Teams with the unused part of the month credited). Go is optional and works like any other provider via `/connect` + `/models`.
- Usage limits are **defined as monthly dollar amounts**, and "Token pricing is the same for Go, Go Plus, and Go Teams." Each model gets: 5-hour = **20%** of its monthly limit, weekly = **50%**, monthly = **100%**.
- Each response reports consumed allowance as `opencode.allowance` ([Inference API doc, `#cost`](https://opencode.ai/v2/docs/console/api/inference)).
- If the usage limit is hit, the free/limited-time models remain usable, and **Extra Usage** can fall back to the pay-as-you-go Console balance ([models pricing](https://opencode.ai/v2/docs/console/models#pricing)); Go Teams starts with Extra Usage on.

## 2. Estimated requests — mechanism (Go doc, `#estimated-requests`)

"The tables below estimate request counts based on typical Go usage patterns. Go Plus and Go Teams estimates scale with each model's higher usage limit." The estimates assume fixed per-request token mixes (input + cached + output), e.g. GPT 6 Luna: 1,000 input / 50,000 cached / 220 output; GLM-5.3/5.2: 700 / 52,000 / 150; Claude Haiku 5.5: 1,100 / 55,000 / 240; MiniMax M3.1 Flash: 500 / 49,400 / 360; Step 5 Preview: 1,000 / 55,000 / 200. **"actual usage varies"** — these are planning numbers, not quotas.

## 3. Estimated requests and output pricing for the medium-capable `opencode-go` models

Output and input prices are **per 1M tokens**, identical on Go, Plus, Teams (Go doc usage-limits tables). Monthly request estimates are the **Go plan** column (5-hour = first table column; Plus/Teams scale with higher limits). Tiered rows are context-tier dependent.

| Model | Variants (live 2026-11-05) | `medium`? | Output price | Est. req/mo (Go) |
| --- | --- | --- | --- | --- |
| `gpt-6-luna` | none, low, **medium**, high, xhigh, max | ✅ | $0.50 (≤272K) / $0.75 | 21,130 |
| `minimax-m3.1-flash` | low, **medium**, high, xhigh, max | ✅ | $0.60 | 19,380 |
| `claude-haiku-5-5` | none, low, **medium**, high, xhigh, max | ✅ | $0.50 (≤100K) / $2.50 | 19,230 |
| `qwen3.8-flash` | none, low, **medium**, xhigh (no `high`) | ✅ | $0.47 | 27,000 |
| `step-5-preview` | low, **medium**, high | ✅ | $2.70 | 2,130 |
| `gemini-4-argon` | low, **medium**, high | ✅ | $10.00 (50% off through 2026-11-30) | 2,120 |
| `grok-4.7` | low, **medium**, high, xhigh | ✅ | $6.00 (≤200K) / $12.00 | 845 |
| `qwen3.8-max` | none, low, **medium**, xhigh | ✅ | $6.00 | 810 |
| `gpt-5.6-luna` | none, low, **medium**, high, xhigh, max | ✅ | $1.20 (≤272K) / $1.80 | 10,250 |
| `muse-spark-1.2/1.3-contributor` | minimal, low, **medium**, high, xhigh | ✅ | $0.20 ⚠️ trains on request data ⚠️ | 226,600 |
| `beam-free` | low, **medium**, high, xhigh, max | ✅ | free (limited time/regions) | unlimited |
| `glm-5.3-flash` | low, high, max | ❌ | $0.50 | 31,580 |
| `glm-5.3` / `glm-5.2` | low/high/max (5.3); high/max (5.2) | ❌ | $4.40 | 1,080 / 4,300 |
| `deepseek-v4.1-flash` | low, high, max | ❌ | $1.20 peak / $0.60 off-peak | 216,670 |
| `deepseek-v4-pro` | high, max | ❌ | $3.96 peak / $1.98 off-peak | 5,200 |
| `kimi-k3.1-pro` | low, high, max | ❌ | $10.00 | 735 |
| `kimi-k3` | max only | ❌ | $15.00 | 490 |
| `kimi-k2.7-code` | — none (empty ladder) | ❌ | $4.00 | 6,750 |
| `mimo-v2.6-flash/-pro`, `mimo-v2.5/-pro`, `longcat-2.0`, `iceman-contributor-free` | — none | ❌ | $0.28 (mimo-flash), $0.87 (mimo-pro), $1.20 (longcat), free | high (mimo/free) |
| `hy4` / `hy4-preview` | none, high | ❌ | $2.501 | 13,500 / 6,770 |
| `hy3` | none, low, high | ❌ | $0.58 | 21,500 |
| `qwen3.7-plus` | none, high (16K budget), max (32K) | ❌ | $1.60 (≤256K) | 21,600 |
| `minimax-m3` | none, thinking | ❌ | $1.20 (≤512K) | 16,000 |

## 4. "Medium" is the operative ceiling for subagent roles

Per `.pi/agent/AGENTS.md`, subagents must be "at or below medium effort using a supported provider-specific effort level." Effort maps to `#variant` on the model selector (models doc: `openai/gpt-6.1-sol#high` style; `providerId/modelId#variant` per the repo's established wiring), surfaced on the wire as `reasoning_effort` (repo-verified for `agents.explore.model`). Variant names come from each model's catalog metadata and "an unknown variant produces a model-resolution error" ([models doc](https://opencode.ai/v2/docs/models/)).

Consequences for tester/researcher/reviewer on opencode-go:

- Models with a `medium` rung can honestly host the ceiling (e.g. `opencode-go/gpt-6-luna#medium`, `opencode-go/minimax-m3.1-flash#medium`, `opencode-go/qwen3.8-flash#medium`).
- Models with `high` but no `medium` (`glm-5.3*`, `deepseek-v4.1-flash`, `deepseek-v4-pro`, `kimi-k3.1-pro`, `qwen3.7-plus`, `hy*`) cap at `low` inside the medium ceiling — the repo already took exactly that path for `glm-5.3-flash` (workflows doc, ticket `specialist-subagent-routing/01`).
- Empty-ladder models (`kimi-k2.7-code`, `mimo-*`, `longcat-2.0`) cannot express any effort preference at all.

## 5. Suitability read (value inside the medium ceiling, Go plan)

- **Cheap + abundant + `medium` rung:** `gpt-6-luna` ($0.50 out, ~21k req/mo, full ladder incl. `none`), `minimax-m3.1-flash` ($0.60 out, ~19k, full low→max ladder), `claude-haiku-5-5` ($0.50 out ≤100K ctx; drops under its >100K tier, ~19k), `qwen3.8-flash` ($0.47 out, ~27k, but no `high` rung beyond medium — `xhigh` exists yet exceeds the ceiling; historically the repo's explore/title role).
- **Mid-tier:** `step-5-preview` ($2.70 out, ~2.1k req/mo) or `gpt-5.6-luna` ($1.20 out, ~10k) if a stronger medium-capable model is wanted; output ceiling 65k (step) / 131k (luna).
- **Ideas-only/background:** `beam-free` (free, all rungs) — but "limited time," region-restricted, 30-day retention; `muse-spark-*` (free-ish economics: 226,600 req/mo, $0.20 out) trade *compatibility of purpose*: "Heavily discounted token pricing in exchange for permission to use your prompts and completions to train future Meta models" — not appropriate for private repo research/review.
- **Overpriced for the purpose:** `qwen3.8-max` ($6.00 out, ~810 req/mo), `grok-4.7` ($6.00/$12.00 out, ~845 req/mo), `gemini-4-argon` ($10.00 out, 65k output cap, ~2.1k req/mo) — all meet medium but burn an allowance quickly.
- Current managed config already pins `reviewer`/`researcher`/`tester`/`implementer`/`merger` to `openai/gpt-6.1-sol` variant `medium` (workflows doc); swapping any of them to an opencode-go medium-capable model is an explicit choice, not a default inferred from this research.

## Caveats and unverified items

- **No live spend test:** no inference request was executed against opencode-go; allowance accounting/`opencode.allowance` behavior is doc-claimed, not executed.
- **Snapshot timing:** prices, limits, model list, and variant ladders are as documented/observed on 2026-11-05. The Go doc warns "The list of models may change as we test and add new ones" and "Usage limits may change as we learn from early usage and feedback"; `minimax-m3.1-flash`, `qwen3.8-flash`, `gpt-6-luna` etc. were recently rotating entries. Re-run `opencode api --standalone model.list` before relying on a specific rung.
- The local catalog cache (`~/.cache/opencode/models.json`) is stale (missing 2026-era models, empty variant objects); models.dev's `opencode-go` entry also lists models absent from the Go doc (`cat-jam-free`, `space-bunny`, `-free` mirrors, `minimax-m2.7`) — the CLI runtime's dedup'ed view is what opencode actually serves.
- Implicit-output reasoning: some ladders emit `reasoning.encrypted_content` (luna/grok/muse families); compatibility of encrypted reasoning with arbitrary third-party transports was not tested.
- No secrets recorded: no Go API key was read or written anywhere in this research.
