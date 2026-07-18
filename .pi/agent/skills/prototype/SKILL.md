---
name: prototype
description: Build a throwaway prototype to flesh out a design — a runnable terminal app for state/business-logic questions, or several radically different UI variations on one route. Use when the user wants to prototype, sanity-check a data model or state machine, mock up a UI, explore design options, or says "prototype this", "let me play with it", "try a few designs" — or when another skill (e.g. wayfinder) needs a design question answered with runnable code.
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

From the prompt, the surrounding code, or by asking (`question` tool if available):

- **"Does this logic / state model feel right?"** → [LOGIC.md](LOGIC.md) — tiny interactive terminal app driving the state machine through cases hard to reason about on paper.
- **"What should this look like?"** → [UI.md](UI.md) — several radically different UI variants on one route, switched via `?variant=` and a floating bottom bar.

Wrong branch wastes the whole prototype. Genuinely ambiguous + user unreachable → match the surrounding code (backend module → logic; page/component → UI) and state the assumption at the top.

## Rules (both branches)

1. **Throwaway from day one, marked as such.** Locate next to the module/page it serves; name it so it's obviously a prototype. UI routes follow the project's existing routing convention.
2. **One command to run** via the project's task runner (`pnpm <name>`, `python <path>`, …).
3. **No persistence by default.** State in memory. If the question *is* persistence, use a scratch DB/file named "PROTOTYPE — wipe me".
4. **Skip the polish.** No tests, no error handling beyond runnable, no abstractions.
5. **Surface the state** — print/render the full relevant state after every action (logic) or variant switch (UI).
6. **Delete or absorb when done.** Never leave it rotting.

## When done

The *answer* is the only keepable artifact. Capture it durably — commit message, ADR, issue, or `NOTES.md` next to the prototype — with the question it answered. (`to-spec`/`to-tickets` templates expect decision-rich prototype snippets — state machine, reducer, schema, type shape.) User unreachable → leave the placeholder for the verdict before deletion.
