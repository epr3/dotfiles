# Design It Twice

When the user wants to explore alternative interfaces for a chosen deepening candidate, design it several ways before committing. Based on "Design It Twice" (Ousterhout) — your first idea is unlikely to be the best.

Uses the vocabulary in [SKILL.md](./SKILL.md) — **module**, **interface**, **seam**, **adapter**, **leverage**.

## Process

### 1. Frame the problem space

Before generating designs, write a user-facing explanation of the problem space for the chosen candidate:

- The constraints any new interface would need to satisfy.
- The dependencies it would rely on, and which category they fall into (see [DEEPENING.md](./DEEPENING.md)).
- A rough illustrative code sketch to ground the constraints — not a proposal, just a way to make the constraints concrete.

Show this to the user, then immediately proceed to Step 2. The user reads and thinks while the designs are produced.

### 2. Generate radically different designs

**If the `Agent` sub-agent tool is available**, spawn 3+ `general` agents in one turn with `run_in_background: true`, each producing a **radically different** interface for the deepened module; collect via `get_subagent_result`. This keeps generation off the main context. (Use `general`, not `explore` — design needs to write, not just read.) **No `Agent` tool, or already running inside one** (sub-agents can't spawn further): design the alternatives yourself, sequentially — still 3+, still radically different. Tell the user you're doing them in sequence.

Give each design a different constraint:

- **Minimal** — minimize the interface, aim for 1-3 entry points max; maximise leverage per entry point.
- **Flexible** — support many use cases and extension.
- **Common-case** — optimise for the most common caller; make the default case trivial.
- **Ports & adapters** (if applicable) — design around ports & adapters for cross-seam dependencies.

Brief each design with the technical details (file paths, coupling, dependency category from [DEEPENING.md](./DEEPENING.md), what sits behind the seam). Include both this skill's vocabulary and the project's domain glossary (`CONTEXT.md` in the context worktree; see [../domain-modeling/CONTEXT-FORMAT.md](../domain-modeling/CONTEXT-FORMAT.md)) so each design names things consistently with the architecture language and the project's domain language.

Each design outputs:

1. Interface (types, methods, params — plus invariants, ordering, error modes).
2. Usage example showing how callers use it.
3. What the implementation hides behind the seam.
4. Dependency strategy and adapters (see [DEEPENING.md](./DEEPENING.md)).
5. Trade-offs — where leverage is high, where it's thin.

### 3. Present and compare

Present designs sequentially so the user can absorb each one, then compare them in prose. Contrast by **depth** (leverage at the interface), **locality** (where change concentrates), and **seam placement**.

After comparing, give your own recommendation: which design is strongest and why. If elements from different designs would combine well, propose a hybrid. Be opinionated — the user wants a strong read, not a menu.
