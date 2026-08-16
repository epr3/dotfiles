---
name: prototype
description: Build a prototype that answers a design question with runnable code, then capture what it taught. Use when the user wants to prototype, sanity-check a data model or state machine, or see several UI options.
---

# Prototype

A prototype is **throwaway, runnable code that answers a design question**. Once it has answered, it is the **primary source** for that answer: the real code that follows is **secondary**, derived from what the prototype showed. The question decides the shape.

## Pick a branch

From the prompt, the surrounding code, or by asking the user (`grilling` owns how to ask):

- **"Does this logic / state model feel right?"** → [LOGIC.md](LOGIC.md) — a shareable HTML demo driving the state model through cases hard to reason about on paper.
- **"What should this look like?"** → [UI.md](UI.md) — several radically different UI variants on one route, switched via `?variant=` and a floating bottom bar.

Wrong branch wastes the whole prototype. Genuinely ambiguous + user unreachable → match the surrounding code (backend module → logic; page/component → UI) and state the assumption at the top.

## Rules (both branches)

1. **Throwaway and clearly marked from day one.** Locate it next to the module/page it serves; name it so a casual reader can see it is a prototype, not production code. UI routes follow the project's existing routing convention.
2. **One command to run** via the project's task runner (`pnpm <name>`, `python <path>`, …).
3. **No persistence by default.** State in memory. If the question *is* persistence, use a scratch DB/file named "PROTOTYPE — wipe me".
4. **Skip the polish.** No tests, no error handling beyond runnable, no abstractions.
5. **Surface the state** — print/render the full relevant state after every action (logic) or variant switch (UI).

## When done

**Capture what it taught** — the answer is the artifact everything downstream rests on. Record it durably (commit message, ADR, issue, or `NOTES.md` beside the prototype) paired with the question it answered and whichever snippet carries the answer most precisely: state machine, reducer, schema, type shape. `to-spec` and `to-tickets` inline exactly those decision-rich snippets, and they cite the prototype as their source. User unreachable → leave the placeholder for the verdict.

Then the code: the real implementation is a rewrite under production constraints, informed by the prototype rather than promoted from it. Keep the prototype while it's still being read from as the primary source; retire it once the answer is captured and the real code exists.
