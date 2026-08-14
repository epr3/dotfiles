---
name: writing-for-agents
description: Reference for writing any document an agent consumes — the vocabulary and levers that make an agent's behaviour predictable. Use when creating or editing a skill, when modifying AGENTS.md or CLAUDE.md, when a document an agent reads has grown too long or fires unreliably.
---

# Writing for Agents

Every document an agent consumes — a skill, `CLAUDE.md`, `AGENTS.md`, any doc reached by a pointer — exists to wrangle determinism out of a stochastic system. **Predictability** — the agent taking the same *process* every run, not producing the same output — is the root virtue; every lever below serves it. (A brainstorming skill should *predictably* diverge: its tokens vary, its behaviour doesn't.) Cost and maintainability are symptoms of predictability, not rivals to it.

Skill-specific mechanics — frontmatter, the invocation choice, splitting by invocation, router skills — live in [SKILL-MECHANICS.md](./SKILL-MECHANICS.md). Read them when the document you're writing *is* a skill.

## Context pointers and the two loads

A **context pointer** is a reference held in the agent's context that names out-of-context material and encodes the condition for reaching it. Its *wording*, not its target, decides when the agent reaches — and how reliably. A must-have target behind a weakly worded pointer is a variance bug: sharpen the wording first, and inline the material only if that fails.

Every document is paid for in one of two currencies:

- **Context load** — the cost of always-loaded material on the agent's window, spent every turn whether or not it fires. An `AGENTS.md` or `CLAUDE.md` is pure context load; a skill's `description` is its always-loaded slice.
- **Cognitive load** — the cost on the human of remembering the document exists and when to reach for it. Not a cost to minimise: it is the price of human agency. Spend it where human judgement matters; remove it where it doesn't.

## Information hierarchy

A document is built from two content types — **steps** and **reference** — that mix freely: all steps, all reference, or both. The core decision is which to use and where each sits on the **information hierarchy**, a ladder ranked by how immediately the agent needs the material:

1. **In-file step** — an ordered action, the primary tier: what the agent does, in order. Each step ends on a **completion criterion**.
2. **In-file reference** — a definition, rule, or fact consulted on demand: parameters, examples, conditional instructions. Often a legitimately flat peer-set (every rule of a review on one rung) — a fine arrangement, not a smell. *This document is all reference.*
3. **External reference** — reference pushed out into a separate file, reached by a **context pointer**, loaded only when the pointer fires. Spans *disclosed* reference — a sibling file, still part of the skill, like `SKILL-MECHANICS.md` here — through fully external reference that lives outside the skill system and any skill can point at. External reference is the only shared home two **user-invoked** skills can use, since neither can fire the other.

When a document has steps, in-file reference that should be disclosed buries them and turns attending to them into a coin-flip — a variance lever, not just a legibility one. Push too little down and the top bloats; push too much and you hide material the agent actually needs. That tension is the whole decision.

**Progressive disclosure** is the move down the ladder so the top stays legible. Mechanics: a linked `.md` file beside the document, named for what it holds. Some documents are used in more than one way, and each distinct way is a **branch** — different runs taking different paths through it. Branching is the cleanest disclosure test: inline what every branch needs, push behind a pointer what only some branches reach.

Where the ladder decides *how far down* a piece sits, **co-location** decides *what sits beside it* once there: keep a concept's definition, rules, and caveats under one heading rather than scattered, so reading one part brings its neighbours with it. There is no formula for the right format of a body of reference; the test is that it should read like documentation written for the agent, and grouped material reads that way where scattered material does not.

## Completion criteria

A **completion criterion** is the condition that tells the agent a unit of work is done. Two independent properties make it a lever:

- **Clarity** — can the agent tell done from not-done? A vague bound ("understanding reached") lets the agent declare done and slip to the next step, so clarity is what resists **premature completion**. This axis needs *steps* to bite.
- **Demand** — how much does it require? "Every modified model accounted for" forces thorough work where "produce a change list" does not. Demand sets **legwork**: the work the agent does behind the scenes within a single unit — reading files, exploring, digging up what it needs rather than offloading to the user. Legwork is never written as its own step; it's latent in the wording. This axis is *not* step-bound — "every rule applied" binds a body of flat reference just as "every step done" binds a sequence, which is how a document with no steps still carries an exhaustiveness bar.

Diagnose against both: a unit that quits early has a clarity problem, a unit that does shallow work has a demand problem. The strongest criteria are both checkable and exhaustive.

## Splitting by sequence

Split a run of **steps** when the steps still ahead — a step's **post-completion steps** — tempt the agent to rush the one in front of it. The more it sees, the stronger the tug; keeping them out of view encourages more legwork on the current task. Hiding only works across a real context boundary (a hand-off or a subagent dispatch); an inline call leaves the later steps in context and clears nothing.

Reach for this second. Sharpening the completion criterion is local and cheap; split only when the bound is irreducibly fuzzy *and* you actually observe the rush.

## Leading words

A **leading word** is a compact concept already living in the model's pretraining that the agent thinks with while reading (e.g. *lesson*, *fog of war*, *tracer bullets*). Repeated as a token — never as a sentence — it accumulates a distributed definition and anchors a whole region of behaviour in the fewest tokens, by recruiting priors the model already holds. Coining your own works if you define it clearly, but a made-up word recruits no priors: you pay in definition tokens what a pretrained word gives free. Reach for an existing word first.

It serves predictability twice. In the body it anchors *execution*: the agent reaches for the same behaviour every time the word appears, and inside flat reference it focuses attention on a class of thing to look for. In a skill's `description` it anchors *invocation*: when the same word lives in your prompts, docs, and code, the agent links that shared language to the skill and fires it more reliably.

Hunt for chances to refactor toward them. A triad spelled out at three sites, a sentence gesturing at one idea — each is a passage begging to collapse into a single token. Examples:

- "fast, deterministic, low-overhead" -> *tight* — one quality restated across a phase, collapsed into a pretrained word (a *tight* loop).
- "a loop you believe in" -> *red* — a fuzzy gate converted into a binary observable state.

You win twice: fewer tokens, *and* a sharper hook for the agent to hang its thinking on. Assume every document is carrying restatements that leading words retire.

## Negation

Steering by prohibition backfires. Naming the behaviour you don't want drags it into context and makes it *more* available — the agent has to represent the forbidden action to avoid it, and representation is most of the way to doing it. Prompt the positive target instead: replace "don't write vague criteria" with "make each criterion checkable", "never dump questions unordered" with "ask the settled frontier in one round".

Prohibition earns its place only where the positive form genuinely doesn't exist — a hard boundary with no target behind it ("out of scope: X"). Everywhere else, state the target.

## Pruning

Keep each meaning in a **single source of truth**: one authoritative place, so changing the behaviour is a one-place edit.

Treat the **environment** as a source of truth in its own right. Config files, scripts, directory layout, and command output are already available to the agent, so a document restating them is a *cache* — it earns its load only when the lookup is expensive or the material is genuinely undiscoverable (a convention with no artifact, a *why* the code doesn't record). Caches go stale silently, and a stale cache is worse than no cache: the agent trusts it over the environment. Prefer telling the agent where to look over telling it what it will find.

Check every line for **relevance**: does it still bear on what the document does? A line loses relevance by never bearing on the task (mere exposition, or a branch that should be disclosed) or by going stale as the world it describes changes. Shorter documents stay relevant more easily, because each line is cheaper to check.

Then hunt the failure modes below sentence by sentence, not line by line: run each test on a sentence in isolation, and when one fails, delete the whole sentence rather than trim words from it. Be aggressive — most prose that fails should go, not be rewritten.

## Failure modes

Use these to diagnose issues the user is having with a document.

- **No-op** — a line the model already obeys by default, so you pay load to say nothing. The test: does it change behaviour versus the default? A line can be perfectly relevant and still be a no-op. This is model-relative, not reader-relative: two people disagreeing over whether a line is a no-op disagree about the default, and settle it by running the document, not by debate. A weak leading word (*be thorough* when the agent is already thorough-ish) is a no-op; the fix is a stronger word (*relentless*), not a different technique — so the no-op test is also how you grade whether a leading word earns its repetitions.
- **Premature completion** — ending a step before it's genuinely done, attention slipping to *being done*. A between-steps failure: a document with no steps that quits early isn't premature completion but thin legwork under an unmet demand. A tug-of-war between visible **post-completion steps** (the pull) and the completion criterion's **clarity** (the resistance). Fuzziness is the necessary condition, so a step that never rushes needs no defending. Defence, in order: sharpen the criterion, then split the sequence.
- **Duplication** — the same meaning in more than one place. Costs maintenance, costs tokens, and inflates a meaning's prominence on the ladder past its real rank. The accidental inverse of a leading word, which raises attention on purpose by repeating a *token*, never the meaning. Distinct from scattering, which fragments a single meaning across many places — the failure **co-location** cures.
- **Sediment** — stale layers that settle because adding feels safe and removing feels risky, so you must core down through them to find what's still live. The default fate of any document without a pruning discipline; the slow erosion of relevance, where duplication is a repeated meaning.
- **Sprawl** — simply too long, even when every line is live and unique. Costs readability (the agent wades through more before it can act, and attention thins across the excess), maintainability, and tokens. The cure is the ladder: disclose reference behind pointers, and split by branch or sequence so each path carries only what it needs.
