# OpenCode v2 native workflows and model preferences: compatibility report

> **Suite retired.** The isolated-runtime and catalog probes named below were run via `scripts/test-opencode-workflows.sh`, retired on 2026-10-04 under the standing no-maintained-test-suite policy (`adr/2026-10-04-no-maintained-dotfiles-test-suite.md`). References to it are historical evidence of checks run at the time, not a currently runnable or maintained check.

Ticket `0003` report. Evidence comes from the installed `v2.0.22` runtime itself: the live catalog (`opencode models`, `opencode api model.list`), the built-in `agent.list` registry, and the isolated-runtime probes then run via `scripts/test-opencode-workflows.sh` (since retired; mock provider, mock `rtk`, no production credentials, no paid calls). Findings recorded 2026-10-03 against the catalog snapshot of that day; both catalog contents and auth state changed substantively since ticket `0001`, so re-verify before relying on individual rows.

## Model and reasoning preference validation

Pi preferences come from `.pi/agent/settings.json`. Validation result per preference:

| Pi preference | v2 result | Evidence |
| --- | --- | --- |
| default provider `openai-codex` | Provider ID does not exist in the v2 catalog. The model itself exists under `openai`. | `opencode models` lists no `openai-codex/*`; `openai/gpt-6.1-sol` and the `-fast`/`-pro` siblings are catalog-listed. |
| default model `gpt-6.1-sol` | Carried over as the managed default: `model: openai/gpt-6.1-sol`. Catalog + variant data verified; provider authenticated (OpenAI OAuth stored). Not assumed equivalent — verified by exact catalog ID. | `opencode api model.list` variants for `openai/gpt-6.1-sol`: none-equivalent list `low, medium, high, xhigh, max`. |
| default thinking level `medium` | **Not encodable as the default.** v2.0.22 root `model` cannot retain a `#variant`, a bare agent-level `variant` is inert, and a root-less config leaves sessions without a default model (verified: no request dispatched). Reasoning level remains a per-session choice: `--model provider/model#variant` or the TUI picker. | Documented runtime probes; every combination was exercised with a local mock provider. |
| `subagents.explore.model = opencode-go/qwen3.8-flash`, recall `low` | Carried over and verified end-to-end: `agents.explore.model` loads at the isolated runtime and the child session's outgoing request carries the configured model plus `reasoning_effort: low`. `low` is a valid variant (catalog: `none, low, medium, xhigh` — no `high`). | `agent.list` reflection + streamed child request capture in `scripts/test-opencode-workflows.sh` (suite since retired). |
| `subagents.general.model = opencode-go/glm-5.3-flash`, recall `high` | Carried over into `agents.general`. Valid variant (`low, high, max` — no `medium`). | Same evidence path as explore. |
| `kimi-reviewer` preset (`opencode-go/kimi-k2.7-code`, thinking `high`) | Model is catalog-listed and the provider is authenticated (OpenCode Go key), but the model exposes **no variants** — the reasoning preference cannot be expressed. Unavailable combination; not silently substituted. | `model.list`: `"variants": []`. |
| `deepseek-v4.1-flash` preset (thinking `low`) | Available: `opencode-go/deepseek-v4.1-flash` has variants `low, high, max`. Not configured in the managed bundle — recorded as available for the developer to select. | `model.list`. |
| `gpt-6-luna` preset (thinking `medium`) | Available as `openai/gpt-6-luna` (also `openai/gpt-6-luna-fast`, `-pro`); variants `none … max`. Not configured. | `model.list` / `opencode models`. |
| `webFetch.extractionModel = opencode-go/mimo-v2.6-flash` (thinking `low`) | **Feature gap.** There is no web-fetch extraction-model selection in the v2.0.22 config schema at all, and `mimo-v2.6-flash` exposes no variants anyway. `opencode/mimo-v2.6-flash-free` also exists, but the choice mechanism is absent, so nothing was configured. | v2.0.22 config schema has no `webfetch` config object; `model.list` variants empty. |

Provider authentication: stored credentials cover `opencode-go` (OpenCode Go API key), `openai` (OAuth), and Google (OAuth) — verified by reading **provider IDs only** from the local auth store; no credential material is read, printed, or copied, and Pi's credentials were never touched.

### Hidden maintenance agents (title, compaction, summary)

V2 defines three hidden agents that perform maintenance and cannot be selected directly: `title`, `compaction`, and `summary`. They use the same `agents.<id>.model` shape as visible agents. Only `title` carries an assignment in the managed bundle; the other two are deliberately omitted for reasons scoped to the installed `v2.0.22`.

| Hidden agent | Managed assignment | Status in `v2.0.22` |
| --- | --- | --- |
| `title` | `opencode-go/qwen3.8-flash` variant `low` | **Supported and configured.** Session titles are generated natively through this hidden agent. The assignment is present in the loaded managed config (`opencode debug config`); that confirms the key is accepted and loaded, not that a title request has been exercised. |
| `compaction` | none — omitted | **Ineffective in this version.** The `agents.compaction.model` key is accepted, but the `v2.0.22` compaction runner uses the **session model** (`openai/gpt-6.1-sol`) rather than the hidden agent's model, so a GLM/`high` assignment would not take effect. |
| `summary` | none — omitted | **Unverified in this version.** The runtime defines the hidden agent, but no local invocation path was found, so support is neither confirmed nor ruled out. |

Title is a **new role choice, not a carry-over**: Pi's `session-name` extension is a manual `/session-name` command and Pi exposes no title-generation model mapping to migrate. The model is Pi-sourced — the same `opencode-go/qwen3.8-flash` Pi sets for `subagents.explore` (variant `low`) — keeping metadata generation on a cheap, already-authenticated provider.

These findings are scoped to the installed `v2.0.22`. Re-check the hidden-agent behavior after an OpenCode upgrade before adding the omitted overrides; the summary gap in particular is version-specific evidence, not a claim that summary is unsupported in every release. The non-hidden settings (`model`, `compaction.auto: false`, `compaction.keep.tokens: 8000`, and the `explore`/`general` assignments) are unchanged by this addition.

### Required developer choices (not silently decided)

Confirmed by the developer on 2026-10-04 at the ticket `0007` approval gate: (1) keep the provider-default reasoning variant, (2) keep Kimi as-is, (3) and (4) acknowledged as unsupported gaps — no substitution was requested for any of them.

1. **Default reasoning level:** sessions start on `openai/gpt-6.1-sol` with the provider-default variant. If the Pi `medium` level should be pinned, either pass `--model openai/gpt-6.1-sol#medium` per invocation/alias or store it once OpenCode gains a root-level variant setting; the managed config deliberately does not encode it.
2. **Kimi reviewer workflow:** `opencode-go/kimi-k2.7-code` runs without reasoning-level control. If the `high` reasoning behavior matters, pick a model with the desired effort ladder (for example `glm-5.3-flash#max`) — explicit choice, not an automatic substitution.
3. **Web extraction model:** not supported by v2.0.22; Pi's cheap-extraction configuration has no target.
4. **Preset cycling** (see gaps below): Pi's `modelPresets.cycle` has no native equivalent.

## Native workflows: demonstrated at the installed-runtime boundary

All demonstrations run inside an isolated HOME/XDG/TMP sandbox with a scripted local mock provider (`scripts/test-opencode-workflows.sh`, since retired), so no production credentials or paid calls are involved.

- **Subagents:** a primary session issued a scripted `subagent` tool call; the runner created a child session (`parentID` links, `agent: "explore"` honored, child titled from the call description), ran it to completion, and returned `<subagent sessionID=… state="completed">` to the parent.
- **Questions:** the native `question` tool is present in the primary agent's tool catalog, and a scripted `question` call is **accepted by the runtime and parked as a pending interactive request** (assistant tool part with `state.status = "running"`, `executed: false`) until a client answers — headless runtimes have no answering endpoint, so the request stays pending (verifiable in the sandbox message history; the driver case `questions-pending` asserts it). Answering requires an interactive client that renders the form.
- **Hard read-only exploration:** the explore child's runtime tool catalog contained only `glob`, `grep`, `read`, `webfetch`, `websearch` — even with **no** configured deny rules. A scripted `write` attempt was rejected in the transcript (`No tool named "write" is currently available`) and the fixture file was never created. Read-only is enforced by the built-in agent definition's toolset, not merely prompted. The managed bundle additionally carries `edit`/`shell` deny rules for `explore` as defense against future built-in changes; they do not change the v2.0.22 child toolset.
- **Subagent model/reasoning preferences:** the child request's `model` came from the configured `agents.explore.model`, and the configured variant was lowered into `reasoning_effort: low` on the wire.
- **Code Mode:** the `execute` tool is part of the primary catalog — JavaScript that may call and combine catalog tools only (no direct filesystem, imports, or timers). Runtime scope note: **v2.0.22 removes `execute` (and `question`, `skill`, `subagent`) from subagent children**, so Code Mode is primary-only.
- **Web:** `webfetch` and `websearch` are available to both the primary agent and the explore child.
- **Todos:** there is **no native todo tool in v2.0.22** — the runtime primary catalog contains none, and the release's own v1→v2 migration map lists `todowrite` as a tool that "is no longer available". Pi's todo extension therefore has no v2 native counterpart to adopt.
- **LSP (agent-facing):** v2.0.22 exposes no `lsp_*` agent tools. A config `lsp` key defines language servers, but nothing agent-facing was found in the runtime catalog. Pi's LSP extension toolset (definitions/references/hover/diagnostics) has no native v2 tool equivalent at this release.

Managed assets were corrected accordingly: `.config/opencode/AGENTS.md` now states the real v2.0.22 tool surface (no promising todos or LSP tools), how read-only explore is enforced, and what replaces each Pi workflow.

## Reported semantic gaps (no custom equivalents built — out of confirmed scope)

| Pi behavior | v2.0.22 status | Gap |
| --- | --- | --- |
| Tool discovery (`tool_search`) | No equivalent. The runtime tool catalog is fixed per agent; MCP tools are always attached. | Report only. Pi's `+tool_search` default-tool setting has no v2 counterpart; discovery-based context trimming cannot be reproduced with config. |
| Codemode | Equivalent exists natively (`execute`, primary agents only). | Semantic difference: subagent children do not receive `execute`, while Pi granted `explore` codemode explicitly. Documented in AGENTS.md. |
| Webfetch extraction model | No config surface. | Report only (see table above). |
| Subagent concurrency (`maxConcurrency: 4`) | No config key; the subagent tool supports foreground and background children with no concurrency cap. | Report only. |
| Model-preset cycling (`modelPresets`) | No native preset/cycle mechanism verified on 2.0.22. | Report only. Manual mitigations: `--model provider/model#variant`, the TUI model picker, and in-session model switching. No wrapper script or plugin was built — the confirmed scope excludes custom equivalents without a demonstrated need. |
| Notes tooling | v2 supports `references`, `commands`, and skill-side instructions. | Pi's agent context-store flows over skills remain usable; no ticket action. |

Also recorded for completeness: v2 renamed core tools relative to v1 (`bash`→`shell`, `task`→`subagent`, `apply_patch`→`patch`), and the installed-release schema still *accepts* unknown config keys without strict rejection (consistent with ticket `0001`) — acceptance is not the same as application, which is why every claim here was checked at the runtime rather than the schema.

## Isolated-harness hazard observed during verification

When the runtime starts without a usable configuration (for example, an environment bug pointing `XDG_CONFIG_HOME` at the wrong directory), v2.0.22 does **not** fail closed: sessions were silently answered by an auto-selected free model from the built-in `opencode/*` pool (observed: `opencode/longcat-2.5-preview-free`) without any model call error. For interactive use this substitutes an unconfigured model; for fixture-based testing it silently invalidates the experiment. The workflow driver therefore guards every case against non-mock models (`mock_model_guard`) and uses sandbox-relative fixture paths, so a mis-configured run fails loudly instead of generating output through a fallback model.

## Legacy RTK disposition

Pi's `.pi/agent/extensions/rtk.ts` was **not** loaded unchanged (the Pi extension API is not OpenCode's plugin API). A v2-platform equivalent now lives at `.config/opencode/plugins/rtk.ts` — a thin delegating plugin that keeps all rewrite rules inside `rtk rewrite` (the single source of truth) and reproduces the Pi extension's semantics:

- probes `rtk --version` and disables itself when the binary is missing or older than `0.23.0` (the version where `rtk rewrite` appeared), warning in the server log;
- honors `RTK_DISABLED=1` per command and skips commands already starting with `rtk `;
- caps the rewrite call at 2 seconds and fails open: any error passes the original command through, never blocking execution;
- applies rewrites on rtk's exit-code contract — `0` (rewrite) and `3` (advisory rewrite) accept, `1` passes through. The advisory exit code was verified live against the installed `rtk 0.50.0` (`rtk rewrite 'ls -la /etc'` → `rtk ls -la /etc`, exit `3`) and is exercised at the isolated runtime with a mock binary.

Difference vs the Pi extension: OpenCode v2 has no per-session status-slot API consumed by this plugin, so disable notices surface as server-line warnings instead of Pi's status indicator. The Pi file remains byte-unchanged.

## Reproducibility

- The managed bundle (`.config/opencode/`) carries all of this without secrets: `opencode.json` (defaults + agent model/variant/permission preferences), `plugins/rtk.ts`, and the corrected `AGENTS.md`. Credentials stay in the machine-local auth store; sessions/caches/databases are untouched and untracked.
- Verification at the time: `scripts/test-opencode-workflows.sh` (static + live catalog/auth + isolated runtime), alongside the existing asset, runtime, and migration suites. All of those suites have since been retired under the standing no-maintained-test-suite policy; the recorded result is that they passed with these changes, and no currently maintained suite re-runs them.
- Lives changed on activation: the running background service loads global plugins from the config directory it serves, so newly started sessions will load `rtk.ts` (self-disabling without `rtk` in PATH; `rtk 0.50.0` is installed here).
