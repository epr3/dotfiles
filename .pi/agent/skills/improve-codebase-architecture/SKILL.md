---
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase — refactors that turn shallow modules deep — informed by CONTEXT.md and ADRs. Use when the user wants the architecture improved or refactoring opportunities found.
---

# Improve Codebase Architecture

Surface architectural friction, propose **deepening opportunities** — refactors turning shallow modules deep. Aim: testability + AI-navigability.

Every suggestion is phrased in the `codebase-design` vocabulary — **module, interface, depth, seam, adapter, leverage, locality** — and judged by its principles. Invoke that skill and use its terms; domain language from `CONTEXT.md` names good seams, and ADRs record decisions not to re-litigate.

## Process

### 1. Scope, then explore

Scan **where change is actually landing** — a deepening in code nobody is touching is a suggestion nobody will act on. Take the area from the user when they name one; otherwise derive it from the current branch's diff, recent commit churn (`git log --format= --name-only -n 100 | sort | uniq -c | sort -rn`), and what the open specs/tickets point at. State the scope before scanning, and widen it only when friction found inside plainly originates outside.

Read `CONTEXT.md` for that area first — in the relevant folder (see [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)). ADRs: grep `docs/adr/` + `<dir>/adr/` (see [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md)) for area terms, read matches — treat the grep as partial and racy rather than an authoritative list.

Explore the scoped area with a read-only `explore` sub-agent (`Agent` tool, `subagent_type: "explore"`) — it can't touch the repo, which is what makes this step safe. Walk organically. Note friction:

- One concept -> bouncing between many small modules
- Shallow modules (interface ≈ implementation)
- Pure fns extracted for testability, bugs hide in how they're called
- Tightly-coupled modules leaking across seams
- Untested / hard-to-test through current interface

Run the **deletion test** on suspected shallow modules. "Concentrates" = signal.

### 2. HTML report

Write `<tmpdir>/architecture-review-<timestamp>.html` — temp dir so nothing lands in the repo, timestamp so each run is fresh. One card per candidate, ending with a **Top recommendation**: which candidate first, why. Card fields, scaffold, and diagram patterns: [HTML-REPORT.md](HTML-REPORT.md). Open via `bash` (`xdg-open`/`open`/`start`); report the absolute path either way.

Stop at candidates — interfaces come in the next step. After writing, ask which candidate to explore, in `grilling`'s question format: one option per candidate plus "None — re-explore". Wait for the answer.

### 3. Grilling loop

Run the `grilling` loop over the chosen candidate — constraints, dependencies, the shape of the deepened module, what sits behind the seam, which tests survive.

Side effects inline:

- Module named after a concept not in `CONTEXT.md` -> add it per [CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md). Lazy-create.
- Fuzzy term sharpened -> update `CONTEXT.md`.
- User rejects a candidate for a load-bearing reason -> offer an ADR per [ADR-FORMAT.md](../domain-modeling/ADR-FORMAT.md). Only when a future explorer needs it to avoid re-suggesting — skip ephemeral ("not worth it now") and self-evident reasons.
- Want alternative interfaces -> [codebase-design's design-it-twice](../codebase-design/DESIGN-IT-TWICE.md).

### 4. Stop at the design boundary

This skill produces *understanding and recorded decisions* — the HTML report, a sharpened `CONTEXT.md`, any ADRs, optional interface designs — and stops there. When the grilling settles, hand the chosen deepening onward as its own deliberate step: `to-spec` -> `to-tickets` -> `implement`. Rolling straight into production edits is the failure mode here; implement now only when the user explicitly asks for it as a separate action.

Close by reporting: chosen candidate, where decisions were recorded, and the suggested next step.
