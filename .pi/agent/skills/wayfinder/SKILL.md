---
name: wayfinder
description: Chart an effort too big for one agent session as a shared map of decision tickets, then resolve them one at a time until the way to the destination is clear. (An already-clear thread goes to to-spec; an understood plan to to-tickets.)
disable-model-invocation: true
argument-hint: "the effort to chart, or the ticket to resolve next"
---

# Wayfinder

A loose idea has arrived: too big for one agent session, and wrapped in fog; the way from here to the **destination** isn't visible yet. Wayfinding is about finding that way, not charging at the destination. This skill charts the way as a **shared map** on the repo's issue tracker, then works its **decision ticket**s one at a time until the route is clear.

The destination varies per effort, and naming it is the first act of charting; it shapes every ticket. It might be a spec to hand off, a decision to lock before planning starts, or a change made in place like a data migration.

## Plan, don't do

Wayfinder **plans, it doesn't build**: every decision ticket resolves one decision, and the map is done when the way is clear, with nothing left to decide before someone goes and builds the thing. The pull to just do the work is usually the signal you've reached the edge of the map and it's time to hand off. An effort can override this in its **Notes**, carrying execution into the map itself (a data migration walked in place, for instance); absent that override, produce decisions, not deliverables.

## Refer by name

Every map and ticket has a **name**: its title. In everything the human reads (narration, Decisions-so-far entries), refer to tickets by that name, never a bare id, number, or slug; the link carries the identifier inside it.

**Where the map, its child decision tickets, blocking, and frontier queries physically live is tracker-specific.** Consult `issue-tracker.md` in the config home (the "Wayfinding operations" section) for how *this* repo expresses them. If that doc is absent, default to the local-markdown form (`.scratch/<effort-slug>/MAP.md` + `tickets/`, at the context home).

## The map body

The whole map at low resolution, loaded once per session. Open tickets stay off it; they live as open child tickets, found by query.

```markdown
## Destination
<what reaching the end of this map looks like: the spec, decision, or change this effort is finding its way to. One or two lines; every session orients to it before choosing a ticket.>

## Notes
<domain; skills every session should consult; standing preferences for this effort; any override of "plan, don't do">

## Decisions so far
<!-- the index: one line per closed decision ticket: enough to judge relevance, then zoom the link for the detail the ticket holds -->
- [<closed decision ticket title>](link): <one-line gist of the answer>

## Not yet specified
<!-- fog of war: in-scope decisions you can feel coming but can't yet state precisely -->

## Out of scope
<!-- work consciously ruled beyond the destination: scope, not sharpness; closed, never graduates -->
```

The map is an **index, not a store**: each decision lives in exactly one place (its ticket); the map only gists and links, never restates.

## Ticket types

Every decision ticket carries a **type** and a **mode**. The mode is **HITL** (worked with a human who speaks for themselves) or **AFK** (driven by the agent alone). A HITL ticket only resolves through the live exchange; an agent that answers its own grilling questions has broken it.

| Type | Mode | Reach for it when | Resolved by |
| --- | --- | --- | --- |
| `grilling` | HITL | The default: the question can be settled by talking it through. | the `grilling` skill plus the `domain-modeling` skill, in conversation |
| `prototype` | HITL | "How should this look" or "how should this behave": a question talking cannot settle. | the `prototype` skill, with the built artifact linked from the ticket |
| `research` | AFK | A fact outside the working directory is blocking a decision. | a `general` sub-agent running the `research` skill, burned down in parallel |
| `task` | HITL or AFK | Nothing to decide, but manual work blocks a decision: provisioning access, signing up for a service, moving data so its shape can be seen. | the agent alone where it can; otherwise a precise checklist for the human |

`task` is the only type that *does* rather than decides, and it earns its place by unblocking a decision, never by delivering a piece of the destination. This is the type that goes wrong most often: an agent reads it as an implementation step and starts writing product code inside the map.

## Claims

A session **claims** a decision ticket before any work: the first write after selection records the claim (locally, `claimed_by: pi:$PI_SESSION_ID` in the ticket's frontmatter), then re-reads to confirm it landed. The claim is cooperative and best-effort: no silent steal; explicit takeover or release is a comment on the ticket. The **frontier** is the open, unblocked, *unclaimed* tickets, the edge of the known: a claimed ticket is off the frontier for every other session.

## Fog of war

Beyond the live tickets lies fog: decisions you can tell are coming but can't yet pin down. The test for ticket vs fog: **can you state the question precisely now** (not whether you can answer it now)? Precise question -> decision ticket (with its blocking edges). Only a shape -> a line under "Not yet specified". Resolving tickets converts fog into new tickets. Don't pre-slice the fog into ticket-sized pieces: one patch may graduate into several tickets, or none, once the frontier reaches it.

## Out of scope

Fog only ever gathers *toward* the destination. The destination fixes the scope, so work beyond it is **out of scope**: it isn't fog, and it doesn't belong under "Not yet specified". Scope, not sharpness, lands it there, and it never graduates; it returns only if the destination is redrawn, and then as a fresh effort.

Ruling something out of scope is a scoping act, not a step on the route. When a ticket that already exists turns out to sit past the destination (mis-scoped while charting, or exposed by a resolution), **close it** and leave one line under "Out of scope": the gist plus why, linking the closed ticket. It stays out of Decisions so far, which records the route actually walked; a scope boundary isn't a step on it.

## Research capture

Research findings land beside the map, one file per ticket: `research/<ticket-slug>.md` in the effort directory, linked from the research ticket and named in the sub-agent's brief. This overrides the `research` skill's default destination, and only for wayfinding.

## Invocation

Two modes. Either way, **resolve at most one decision ticket per session**; research tickets are the exception, dispatched in parallel as sub-agents.

### Chart the map

User invokes with a loose idea.

1. **Name the destination**: use the `grilling` skill plus the `domain-modeling` skill to pin down what this map is finding its way to. The destination fixes the scope, so it's settled first.
2. **Map the frontier**: grill again, breadth-first, fanning out across the whole space rather than deep on any thread, surfacing the open decisions and the first steps takeable now. **If this surfaces no fog**, the way to the destination is already clear and the whole journey fits one session: stop, and ask the user how to proceed (no map needed).
3. **Create the map**: Destination and Notes filled in, Decisions so far empty, the fog sketched into "Not yet specified".
4. **Create the tickets you can specify now**, then wire blocking edges in a **second pass**: a ticket needs to exist before another can name it. Wiring sorts them into the frontier and the blocked; everything still too vague stays in the fog.
5. **Fire the research sub-agents**: one `general` sub-agent per research ticket (the `Agent` tool, all dispatched in a single message), each briefed with its ticket and capture path, running in parallel.
6. **Stop**: charting is one session's work; it hand-resolves nothing.

### Work through the map

User invokes with a map. A ticket is optional: without one, pick the next decision from the frontier, don't wait to be told.

1. **Orient**: load the map (destination, notes, decisions index). Zoom into linked tickets only where relevant.
2. **Claim**: take the first frontier ticket in order (or the one the user named), and record the claim as the first write before any work.
3. **Resolve it**: one decision, sized to one session. Call the `grilling` and `domain-modeling` skills for conversation; the `prototype` skill where a concrete artifact answers the question; the `research` skill for source-backed reading. **The user decides**: put the question to them and wait; the answers are theirs to give, not yours to supply. A HITL ticket only resolves through that exchange.
4. **Record**: the full decision in the ticket (close it per the tracker conventions); a one-line gist + link under "Decisions so far"; new tickets or fog lines the decision revealed. If the answer shows a ticket sits beyond the destination, rule it out of scope instead.
5. **Stop cleanly**: the map is the handoff; the next session re-orients from it.

## Done

The map is cleared when nothing is left to decide before someone goes and builds the thing. Hand the way found to the `to-spec` skill to schedule the build; or, if the effort turned out small, straight to the `implement` skill.
