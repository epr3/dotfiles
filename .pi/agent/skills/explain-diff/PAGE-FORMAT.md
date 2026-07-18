# Page Format

The craft for an explainer page: what each section does, then the container conventions.

## Sections

1. **Background** — the existing system relevant to this change; broadly explore the surrounding code first. The reader's prior knowledge is unknown: deep background for beginners (marked skippable), then a narrow background directly relevant to the change. Use the project's glossary terms where a `CONTEXT.md` exists.
2. **Intuition** — the core intuition before any code: the goal in one line, then the concepts needed to see why this approach works. Essence, not details.
3. **Literate diff** — the changes walked as prose, in a sensible teaching order (never file-alphabetical), each step with surrounding explanation and the relevant snippet embedded. Faster to absorb than the raw diff; the raw diff stays the reference, this is the guide.
4. **Data flow & diagrams** — how data moves through the changed paths; inline SVG or simple interactive figures where a picture beats prose.
5. **Quiz** — five interactive multiple-choice questions of medium difficulty: hard enough that answering requires understanding the substance, no gotchas — readers verify they understood, not get tricked. Options and feedback per [QUIZ-FORMAT.md](./QUIZ-FORMAT.md).

## Container

One self-contained HTML file — CSS and JavaScript inlined, no external requests. One long page: section headers + a table of contents, no top-level tabs. Basic responsive styling so it reads on a phone.
