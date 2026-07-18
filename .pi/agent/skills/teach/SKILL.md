---
name: teach
description: Teach the user a skill or concept over multiple sessions, in this workspace. Use when the user wants to learn something, asks for lessons, or says "teach me".
disable-model-invocation: true
argument-hint: "What would you like to learn about?"
---

# Teach

Stateful: the user learns over multiple sessions. The current directory is the teaching workspace.

## Workspace files

- `MISSION.md` — *why* they're learning; grounds all teaching. [MISSION-FORMAT.md](./MISSION-FORMAT.md).
- `GLOSSARY.md` — canonical terms; adhere to it in every lesson. [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md).
- `RESOURCES.md` — trusted sources for knowledge + communities for wisdom. [RESOURCES-FORMAT.md](./RESOURCES-FORMAT.md).
- `./lessons/0001-<slug>.html` — the primary teaching unit, incrementing.
- `./reference/*.html` — compressed learnings: cheat sheets, syntax, sequences, glossary printouts. Beautiful, print-friendly, quick-reference.
- `./learning-records/0001-<slug>.md` — the ADRs of learning. [LEARNING-RECORD-FORMAT.md](./LEARNING-RECORD-FORMAT.md).
- `NOTES.md` — scratchpad for teaching preferences and working notes.

Create everything lazily.

## Philosophy

Deep learning = **knowledge** (from high-trust resources — never trust parametric knowledge; populate `RESOURCES.md` first), **skills** (interactive lessons you design from that knowledge), **wisdom** (real-world interaction with practitioners). Topic sets the mix: theoretical physics skews knowledge, yoga skews skills.

## The mission

Everything ties to the mission. `MISSION.md` missing or vague → first job is interviewing the user on *why* (`question` tool if available). No mission → abstract lessons and no basis for what's next. Missions shift as skills grow — normal; confirm with the user, update `MISSION.md`, add a learning record.

## Zone of proximal development

Each lesson should challenge "just enough". User names a topic → teach it. Otherwise: read `learning-records`, pick the most mission-relevant thing inside the zone. "Already know that" → record it as a learning record.

## Lessons

One self-contained HTML file in `./lessons/`, beautiful (clean typography — the user reviews these later), teaching **ONE thing**, completable quickly, ending in a tangible win the user can build on, mission-tied, in the zone. Opening = one CLI command. Lessons anchor-link to other lessons and reference docs. Litter with citations to `RESOURCES.md` sources — trustworthy claims, deeper paths. Each lesson reminds the user to ask the agent follow-ups.

Teach knowledge first, then practice the skill through a **tight feedback loop** — ideally immediate and automatic: in-browser quizzes and light tasks, guided real-world steps (e.g. poses), or in-agent scenario quizzes. Multiple-choice options follow [QUIZ-FORMAT.md](../explain-diff/QUIZ-FORMAT.md) — no giveaway length, terminology, or fabricated distractors.

## Wisdom

Questions needing wisdom: attempt an answer, then delegate to a **community** — high-reputation forum, subreddit, class, local group. Find them; respect an opt-out (note it in `RESOURCES.md`).

## Reference docs

Created alongside lessons; lessons are rarely revisited, references are. Compressed essence, quick-reference format: syntax/snippets, algorithms/flowcharts, pose sequences, routines, glossaries. The glossary is essential — once created, every lesson adheres to it.
