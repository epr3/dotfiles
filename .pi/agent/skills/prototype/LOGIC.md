# Logic Prototype

Tiny interactive terminal app: the user drives a state model by hand. For **business logic, state transitions, data shape** — looks fine on paper, only feels wrong under real cases. "What should this look like?" → wrong branch, [UI.md](UI.md).

Right shape for: "does this state machine handle X then Y", "can this data model represent…", "feel out the API before writing it" — anything where the user wants to **press buttons and watch state change**.

## Process

1. **State the question.** One paragraph, top-of-file comment or README, before any code. Wrong question = pure waste; explicit = checkable later, watched or AFK.
2. **Pick the language** — whatever the host project uses; no new runtimes/package managers. No obvious runtime → ask.
3. **Isolate the logic in a portable module.** The bit answering the question goes behind a small pure interface, liftable into the real codebase. Shape fits the question, not TUI convenience:
   - **Pure reducer** `(state, action) => state` — discrete events, single state value
   - **State machine** — when "which actions are legal right now" is part of the question
   - **Pure functions over plain data** — no implicit current state, just transformations
   - **Class/module with a clear method surface** — logic genuinely owns ongoing state
   Pure: no I/O, no terminal code, no `console.log` control flow. TUI imports it; nothing flows back. This makes the prototype outlive itself — validated logic gets lifted, TUI shell gets deleted.
4. **Smallest TUI exposing the state.** Each tick: clear screen (`console.clear()` / `\033[2J\033[H`), re-render the whole frame — one stable view, not scrollback. Frame = (1) current state pretty-printed, one field per line or formatted JSON, **bold** names / dim context (ANSI `\x1b[1m`/`\x1b[2m`/`\x1b[0m`, no styling lib unless already present); (2) shortcuts at the bottom: `[a] add user  [d] delete  [t] tick  [q] quit`. Init state → render → one keystroke (or one line) at a time → dispatch → re-render → loop until quit. Whole frame fits one screen.
5. **One command** in the project's task runner; no runner → command at the top of the README.
6. **Hand it over.** Give the run command. The interesting moments are "wait, that shouldn't be possible" — bugs in the *idea*. New actions wanted → add them; prototypes evolve.
7. **Capture the answer.** User around → ask what it taught them. AFK → `NOTES.md` next to the prototype for the verdict before deletion.

## Anti-patterns

- **No tests** — a prototype needing tests isn't a prototype.
- **No real database** — in-memory unless persistence *is* the question.
- **No generalising** — no "what if we later want X". One question.
- **No blurring logic and TUI** — reducer touching `console.log`/prompts/escape codes is no longer portable.
- **Never ship the TUI shell** — the logic module is the keepable part.
