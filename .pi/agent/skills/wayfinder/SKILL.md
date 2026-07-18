---
name: wayfinder
description: Plan a huge chunk of work — more than one agent session can hold — as a shared map of investigation tickets on the issue tracker, and resolve them one at a time until the way to the destination is clear. Use only when invoked; for turning an already-clear thread into a spec use to-spec, for slicing an understood plan use to-tickets.
disable-model-invocation: true
argument-hint: "the effort to chart, or the ticket to resolve next"
---

# Wayfinder

A loose idea has arrived — too big for one agent session, and wrapped in fog: the way from here to the **destination** isn't visible yet. Wayfinding is about finding that way, not charging at the destination. This skill charts the way as a **shared map** on the repo's issue tracker, then works its tickets one at a time until the route is clear.

It **plans, it doesn't build**: every ticket resolves a decision, and the map is done when nothing is left to decide before someone goes and builds the thing — decisions, not deliverables.

The destination varies per effort, and naming it is the first act of charting — it shapes every ticket. It might be a spec to hand off, a decision to lock before planning starts, or a change made in place.

**Where the map, its child tickets, blocking, and frontier queries physically live is tracker-specific.** Consult `issue-tracker.md` in the config home (the "Wayfinding operations" section) for how *this* repo expresses them. If that doc is absent, default to the local-markdown form (`.scratch/<effort-slug>/MAP.md` + `tickets/`, at the context home).

## The map body

The whole map at low resolution, loaded once per session. Open tickets are **not** listed — they are open child tickets, found by query.

```markdown
## Destination
<what reaching the end of this map looks like — the spec, decision, or change this effort is finding its way to. One or two lines; every session orients to it before choosing a ticket.>

## Notes
<domain; skills every session should consult; standing preferences for this effort>

## Decisions so far
<!-- the index — one line per closed ticket: enough to judge relevance, then zoom the link for the detail the ticket holds -->
- [<closed ticket title>](link) — <one-line gist of the answer>

## Not yet specified
<!-- fog of war: in-scope decisions you can feel coming but can't yet state precisely -->
```

The map is an **index, not a store**: each decision lives in exactly one place (its ticket); the map only gists and links, never restates.

## Fog of war

Beyond the live tickets lies fog — decisions you can tell are coming but can't yet pin down. The test for ticket vs fog: **can you state the question precisely now?** Precise question -> ticket (with its blocking edges). Only a shape -> a line under "Not yet specified". Resolving tickets converts fog into new tickets.

## A session

1. **Orient** — load the map (destination, notes, decisions index). Zoom into linked tickets only where relevant.
2. **Pick from the frontier** — an open ticket whose blockers are all resolved (or the one the user named).
3. **Resolve it** — one decision, sized to one session. Lean on [`grilling`](../grilling/SKILL.md) + [`domain-modeling`](../domain-modeling/SKILL.md) to sharpen it; [`prototype`](../prototype/SKILL.md) or [`research`](../research/SKILL.md) where the ticket calls for exploring or reading.
4. **Record** — the full decision in the ticket (close it per the tracker conventions); a one-line gist + link under "Decisions so far"; new tickets or fog lines the decision revealed.
5. **Stop cleanly** — the map is the handoff; the next session re-orients from it.

## Done

The map is cleared when nothing is left to decide. Hand the way found to `to-spec` to schedule the build — or, if the effort turned out small, straight to `implement`.
