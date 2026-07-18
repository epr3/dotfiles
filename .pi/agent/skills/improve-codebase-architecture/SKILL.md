---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase, informed by the personal CONTEXT.md and ADRs. Use when the user wants to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, or make a codebase more testable and AI-navigable.
---

# Improve Codebase Architecture

Surface architectural friction, propose **deepening opportunities** — refactors turning shallow modules deep. Aim: testability + AI-navigability.

## Vocabulary

Use the [codebase-design](../codebase-design/SKILL.md) vocabulary — **module, interface, depth, seam, adapter, leverage, locality** — and its principles (deletion test · interface = test surface · one adapter = hypothetical seam, two = real) in every suggestion. Don't drift into "component," "service," "API," or "boundary." Domain language names good seams; ADRs record decisions not to re-litigate.

## Process

### 1. Explore

Read `CONTEXT.md` from the code repo first — in the relevant folder (see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)). ADRs: grep `docs/adr/` + `<dir>/adr/` (see [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md)) for area terms, read matches — don't enumerate as authoritative (partial + racy).

Explore codebase: dispatch read-only `explore` agent via `Agent` tool if available (can't touch repo — that's what makes this step safe), else `read`/`grep`/`find`/`ls`. Prefer LSP (`lsp_references`, `lsp_definition`, `lsp_document_symbols`) over grep for tracing usage when available. Walk organically. Note friction:

- One concept -> bouncing between many small modules
- Shallow modules (interface ≈ implementation)
- Pure fns extracted for testability, bugs hide in how they're called
- Tightly-coupled modules leaking across seams
- Untested / hard-to-test through current interface

Deletion test on suspected shallow modules. "Concentrates" = signal.

### 2. HTML report

Write `<tmpdir>/architecture-review-<timestamp>.html` — temp dir so nothing lands in repo; timestamp so each run fresh. Open via `bash` (`xdg-open`/`open`/`start`); report absolute path either way.

Tailwind CDN + Mermaid CDN. Mermaid for graph-shaped; hand-built divs/SVG for editorial. Each candidate: before/after visualization.

Per candidate (card):

- **Files** — involved files/modules
- **Problem** — friction, one sentence
- **Solution** — change, one sentence
- **Wins** — bullets ≤6 words, glossary terms (locality/leverage, how tests improve)
- **Before/After diagram** — side by side, shallowness -> depth
- **Strength badge** — `Strong` / `Worth exploring` / `Speculative`
- **ADR conflict** — only if friction warrants revisiting. Amber callout: _"contradicts ADR `2026-01-12-event-sourced-orders` — but worth reopening because…"_

End with **Top recommendation**: which candidate first, why.

`CONTEXT.md` vocabulary for domain, [codebase-design](../codebase-design/SKILL.md) for architecture. No drift.

Full scaffold + diagram patterns: [HTML-REPORT.md](HTML-REPORT.md).

Do NOT propose interfaces yet. After writing, ask which candidate to explore — `question` tool if available (one option per candidate, recommended first, plus "None — re-explore"), else same in prose. Stop, wait.

### 3. Grilling loop

Walk design tree with user — constraints, dependencies, shape of deepened module, what sits behind seam, what tests survive. Ask via `question` tool if available, else prose (2–4 options, `(recommended)`, one-line reason, stop), one question at a time.

Side effects inline:

- Module named after concept not in `CONTEXT.md` -> add per [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md). Lazy-create.
- Fuzzy term sharpened -> update `CONTEXT.md`.
- User rejects candidate, load-bearing reason -> offer ADR per [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md). Only when future explorer needs it to avoid re-suggesting — skip ephemeral ("not worth it now") + self-evident reasons.
- Want alternative interfaces -> [codebase-design's design-it-twice](../codebase-design/DESIGN-IT-TWICE.md).

### 4. Stop at the design boundary

This skill produces *understanding and recorded decisions* — the HTML report, a sharpened `CONTEXT.md`, any ADRs, optional interface designs. It does NOT implement the refactor. When grilling settles, don't roll into editing production code — that eagerness is the failure mode here.

Hand the chosen deepening to the pipeline as its own deliberate step: `to-spec` -> `to-tickets` -> `implement`. Implement directly only if the user explicitly asks to, now, as a separate action. Close by reporting: chosen candidate, where decisions were recorded (report path, `CONTEXT.md`, ADRs), and the suggested next step.
