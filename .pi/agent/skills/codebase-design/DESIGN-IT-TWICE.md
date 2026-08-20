# Design It Twice

When the user wants to explore alternative interfaces for a chosen deepening candidate, design it several ways before committing, after Ousterhout's "Design It Twice": your first idea is unlikely to be the best. Uses the vocabulary in [SKILL.md](./SKILL.md): **module**, **interface**, **seam**, **adapter**, **leverage**.

## Process

### 1. Frame the problem space

Write a user-facing explanation of the problem space for the chosen candidate:

- The constraints any new interface would need to satisfy.
- The dependencies it would rely on, and which category they fall into (see [DEEPENING.md](./DEEPENING.md)).
- A rough illustrative code sketch to ground the constraints. Not a proposal, just a way to make the constraints concrete.

Show it, then go straight to step 2; the user reads and thinks while the designs are produced.

### 2. Generate radically different designs

**Spawn 3+ `general` sub-agents** via `Agent` calls in one message so they run in parallel, each producing a **radically different** interface for the deepened module. Keeps generation off the main context. (`general`, not `explore`: design needs to write, not just read.) **If you're already running inside a sub-agent** (sub-agents can't spawn more): design the alternatives yourself, sequentially, in the main context; still 3+, still radically different, and say you're doing them in sequence.

Give each design a different constraint:

- **Minimal**: minimize the interface, aim for 1-3 entry points max; maximise leverage per entry point.
- **Flexible**: support many use cases and extension.
- **Common-case**: optimise for the most common caller; make the default case trivial.
- **Ports & adapters** (if applicable): design around ports & adapters for cross-seam dependencies.

Brief each design with the technical details (file paths, coupling, dependency category from [DEEPENING.md](./DEEPENING.md), what sits behind the seam), plus both this skill's vocabulary and the project's domain glossary (`CONTEXT.md` in the context worktree; see [../domain-modeling/CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)).

Each design outputs:

1. Interface (types, methods, params; plus invariants, ordering, error modes).
2. Usage example showing how callers use it.
3. What the implementation hides behind the seam.
4. Dependency strategy and adapters.
5. Trade-offs: where leverage is high, where it's thin.

### 3. Present and compare

Present designs sequentially so the user can absorb each one, then compare them in prose. Contrast by **depth** (leverage at the interface), **locality** (where change concentrates), and **seam placement**.

After comparing, give your own recommendation: which design is strongest and why. If elements from different designs would combine well, propose a hybrid. Be opinionated; the user wants a strong read, not a menu.
