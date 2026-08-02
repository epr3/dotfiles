---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase — refactors that turn shallow modules deep — informed by CONTEXT.md and ADRs. Use when the user wants the architecture improved or refactoring opportunities found.
---

# Improve Codebase Architecture

Surface architectural friction, propose **deepening opportunities** — refactors turning shallow modules deep. Aim: testability + AI-navigability.

Every suggestion is phrased in the `codebase-design` vocabulary — **module, interface, depth, seam, adapter, leverage, locality** — and judged by its principles. Invoke that skill and use its terms; domain language from `CONTEXT.md` names good seams, and ADRs record decisions not to re-litigate.

## Process

### 1. Explore

Read `CONTEXT.md` from the code repo first — in the relevant folder (see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)). ADRs: grep `docs/adr/` + `<dir>/adr/` (see [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md)) for area terms, read matches — don't enumerate as authoritative (partial + racy).

Explore the codebase with a read-only `explore` sub-agent (`Agent` tool, `subagent_type: "explore"`) — it can't touch the repo, which is what makes this step safe. Walk organically. Note friction:

- One concept -> bouncing between many small modules
- Shallow modules (interface ≈ implementation)
- Pure fns extracted for testability, bugs hide in how they're called
- Tightly-coupled modules leaking across seams
- Untested / hard-to-test through current interface

Run the **deletion test** on suspected shallow modules. "Concentrates" = signal.

### 2. HTML report

Write `<tmpdir>/architecture-review-<timestamp>.html` — temp dir so nothing lands in the repo, timestamp so each run is fresh. Open via `bash` (`xdg-open`/`open`/`start`); report the absolute path either way. Full scaffold + diagram patterns: [HTML-REPORT.md](HTML-REPORT.md).

Per candidate (a card):

- **Files** — involved files/modules
- **Problem** — the friction, one sentence
- **Solution** — the change, one sentence
- **Wins** — bullets ≤6 words, in glossary terms (locality/leverage, how tests improve)
- **Before/After diagram** — side by side, shallowness -> depth
- **Strength badge** — `Strong` / `Worth exploring` / `Speculative`
- **ADR conflict** — only if the friction warrants revisiting. Amber callout: _"contradicts ADR `2026-01-12-event-sourced-orders` — but worth reopening because…"_

End with **Top recommendation**: which candidate first, why.

Do NOT propose interfaces yet. After writing, ask which candidate to explore — `question` tool (prose if unavailable), one option per candidate plus "None — re-explore". Stop, wait.

### 3. Grilling loop

Run the `grilling` loop over the chosen candidate — constraints, dependencies, the shape of the deepened module, what sits behind the seam, which tests survive.

Side effects inline:

- Module named after a concept not in `CONTEXT.md` -> add it per [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md). Lazy-create.
- Fuzzy term sharpened -> update `CONTEXT.md`.
- User rejects a candidate for a load-bearing reason -> offer an ADR per [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md). Only when a future explorer needs it to avoid re-suggesting — skip ephemeral ("not worth it now") and self-evident reasons.
- Want alternative interfaces -> [codebase-design's design-it-twice](../codebase-design/DESIGN-IT-TWICE.md).

### 4. Stop at the design boundary

This skill produces *understanding and recorded decisions* — the HTML report, a sharpened `CONTEXT.md`, any ADRs, optional interface designs. It does NOT implement the refactor. When the grilling settles, don't roll into editing production code; that eagerness is the failure mode here. Hand the chosen deepening onward as its own deliberate step: `to-spec` -> `to-tickets` -> `implement`. Implement directly only if the user explicitly asks, now, as a separate action.

Close by reporting: chosen candidate, where decisions were recorded, and the suggested next step.
