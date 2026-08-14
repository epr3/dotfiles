---
name: codebase-design
description: Shared vocabulary and principles for designing deep modules — a lot of behaviour behind a small interface, at a clean seam, testable through that interface. Use when designing or restructuring a module's interface or seam.
---

# Codebase Design

Design **deep modules** — a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface. This is the shared language for that work, wherever code is being designed or restructured.

The domain glossary names the *concepts*; this vocabulary names their *shape*. Use the project's domain language (`CONTEXT.md` in the context worktree; see [../domain-modeling/CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)) for *what* a module is — "the Order intake module," not "the FooBarHandler" — and the terms below for *how* it's built.

## Glossary

Use these terms exactly; each *Avoid* names the wording it displaces.

**Module** — anything with an interface and an implementation, and it has exactly one interface. Deliberately scale-agnostic: a function, class, package, or tier-spanning slice. *Avoid*: unit, component, service.

**Interface** — everything a caller must know to use the module correctly: the type signature, but also invariants, ordering constraints, error modes, required configuration, and performance characteristics. *Avoid*: API, signature (too narrow — they refer only to the type-level surface).

**Implementation** — what's inside a module, its body of code. Distinct from **Adapter**: a thing can be a small adapter with a large implementation (a Postgres repo) or a large adapter with a small implementation (an in-memory fake). Reach for "adapter" when the seam is the topic; "implementation" otherwise.

**Depth** — leverage at the interface: the amount of behaviour a caller (or test) can exercise per unit of interface they have to learn. A module is **deep** when a large amount of behaviour sits behind a small interface, **shallow** when the interface is nearly as complex as the implementation. Designing an interface is therefore a hunt for three things: fewer methods, simpler parameters, more complexity hidden inside. *Avoid*: depth as a ratio of implementation-lines to interface-lines (Ousterhout) — it rewards padding the implementation.

**Seam** *(Michael Feathers)* — a place where you can alter behaviour without editing in that place; the *location* at which a module's interface lives. Where to put the seam is its own design decision, distinct from what goes behind it. *Avoid*: boundary (overloaded with DDD's bounded context).

**Adapter** — a concrete thing that satisfies an interface at a seam. Describes *role* (what slot it fills), not substance (what's inside).

**Leverage** — what callers get from depth: more capability per unit of interface they learn. One implementation pays back across N call sites and M tests.

**Locality** — what maintainers get from depth: change, bugs, knowledge, and verification concentrate in one place rather than spreading across callers. Fix once, fixed everywhere.

## Principles

- **Depth is a property of the interface, not the implementation.** A deep module can be internally composed of small, mockable, swappable parts — they just aren't part of the interface. A module can have **internal seams** (private to its implementation, used by its own tests) as well as the **external seam** at its interface.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep. Count N — don't guess it: `lsp_references` (or `lsp_incoming_calls`) on the interface gives the real fan-in (grep misses dynamic + re-exported usages); that number is your evidence for depth and leverage, not an estimate.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test *past* the interface, the module is probably the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Introduce a seam where something actually varies across it.
- **Accept dependencies, don't create them.** A module handed its collaborators is exercisable through its interface; one that constructs them internally is not.
- **Return results, don't produce side effects.** A value crossing the interface is assertable; a mutation is reachable only past it.

## Going deeper

- **Deepening a cluster given its dependencies** — [DEEPENING.md](./DEEPENING.md): dependency categories, seam discipline, and replace-don't-layer testing.
- **Exploring alternative interfaces** — [DESIGN-IT-TWICE.md](./DESIGN-IT-TWICE.md): design the interface several radically different ways, then compare on depth, locality, and seam placement.
