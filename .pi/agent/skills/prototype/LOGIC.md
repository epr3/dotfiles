# Logic Prototype

A **shareable HTML demo**: one page the user drives by hand, watching a state model react. For **business logic, state transitions, data shape** — looks fine on paper, only feels wrong under real cases. "What should this look like?" → wrong branch, [UI.md](UI.md).

Right shape for: "does this state machine handle X then Y", "can this data model represent…", "feel out the API before writing it" — anything where the user wants to **press buttons and watch state change**. HTML rather than a terminal script because the demo is the primary source for the answer: a single file opens for anyone, and can be attached to the ticket or sent to whoever holds the decision.

## Process

1. **State the question.** One paragraph, at the top of the page and in the module, before any other code. Wrong question = pure waste; explicit = checkable later, watched or AFK.
2. **Pick the language** — the host project's; no new runtimes or package managers. Browser-native host (TS/JS) → the module loads straight into the page. Otherwise the module stays in the host language and the page drives it over a tiny local endpoint that the run command starts.
3. **Isolate the logic in a portable module.** The bit answering the question goes behind a small pure interface, liftable into the real codebase. Shape fits the question, not demo convenience:
   - **Pure reducer** `(state, action) => state` — discrete events, single state value
   - **State machine** — when "which actions are legal right now" is part of the question
   - **Pure functions over plain data** — no implicit current state, just transformations
   - **Class/module with a clear method surface** — logic genuinely owns ongoing state
   Pure: no I/O, no DOM, no logging as control flow. The page imports it; nothing flows back. This is what makes the answer liftable — validated logic gets rewritten into the real code, the page gets retired.
4. **Smallest page that exposes the state.** One self-contained HTML file, no build step and no framework. Each interaction re-renders the whole frame: (1) the current state in full, one field per row, monospace, names **bold** and context dimmed, fields that just changed highlighted; (2) one button per action, each carrying whatever inputs it needs, and greyed when the action is illegal in the current state — that greying is how a state machine's legality becomes visible; (3) an action log, so a surprising sequence can be replayed and described exactly. Whole frame fits one screen.
5. **One command** in the project's task runner to open or serve it; no runner → the command at the top of the page's README.
6. **Hand it over.** Give the command and the file path. The interesting moments are "wait, that shouldn't be possible" — bugs in the *idea*. New actions wanted → add them; prototypes evolve.
7. **Capture the answer.** User around → ask what it taught them. AFK → `NOTES.md` beside the prototype for the verdict.

## Anti-patterns

- **Tests** — a prototype needing tests isn't a prototype.
- **A real database** — in-memory unless persistence *is* the question.
- **Generalising** — one question; "what if we later want X" belongs to the real code.
- **Logic mixed into the page** — a reducer touching the DOM stops being portable, and the module is the keepable part.
