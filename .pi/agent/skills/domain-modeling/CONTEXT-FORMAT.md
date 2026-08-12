# CONTEXT.md Format

```md
# {Context Name}

{One or two sentence description.}

## Language

**Order**: A concise description of the term.
_Avoid_: Purchase, transaction.

**Invoice**: A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request.

**Customer**: A person or organization that places orders.
_Avoid_: Client, buyer, account.

## Relationships

- An **Order** produces one or more **Invoices**
- An **Invoice** belongs to exactly one **Customer**

## Example dialogue

> **Dev:** "When a **Customer** places an **Order**, do we create the **Invoice** immediately?"
> **Domain expert:** "No — an **Invoice** is only generated once a **Fulfillment** is confirmed."

## Flagged ambiguities

- "account" was used to mean both **Customer** and **User** — resolved: these are distinct concepts.
```

## Rules

- **Opinionated.** Pick the best word, list others as aliases to avoid.
- **Flag conflicts explicitly** in "Flagged ambiguities" with resolution.
- **One sentence per term.** Define what it IS, not what it does.
- **Show cardinality.** Use bold term names in relationships.
- **Context-specific only.** Skip general programming concepts (timeouts, error types, utility patterns).
- **Group with subheadings** only if natural clusters emerge; flat list otherwise.
- **Example dialogue** — dev + domain expert demonstrating term boundaries.

## Growth & retention

Context files stay small by **splitting, summarizing, and deleting**. Summarize where prose has grown verbose — tighten wording, merge redundant lines — and prefer split when the detail still matters: a summary trades detail for size, a split keeps both.

- **Size valve = split.** When a glossary outgrows quick scanning (rule of thumb: ~40 terms or ~200 lines), promote it along the code structure: root `CONTEXT.md` -> `CONTEXT-MAP.md` + per-dir `CONTEXT.md` files (the multi-context mechanism below). Terms move whole — split is a relocation, not a rewrite.
- **Prune the dead.** A renamed concept's old name joins the successor's `_Avoid_` list; a concept that's genuinely obsolete is simply deleted — the glossary is the working set, and git history keeps the past.
- **Accumulating sections crystallise, then trim.** Before replacing a dialogue exchange or clearing a resolved ambiguity, fold what it taught into the term entries themselves (the definition sentence or `_Avoid_` list) — then the dialogue keeps only the few exchanges that best mark boundaries, and "Flagged ambiguities" holds only *open* flags.
- **ADRs that no longer matter can be deleted.** Where the history of the reversal is itself worth keeping, mark `superseded` and reference the successor instead ([ADR-FORMAT.md](./ADR-FORMAT.md)).

## Where it lives — the context store

One word per level, used exactly this way here and in every skill:

| term | means |
|---|---|
| **context store** | how a repo's context is stored — the model. Values: **context repo**, **in-repo context**. Never a directory. |
| **context repo** | the separate mirror of one code repo: a bare git repo holding one **context worktree** per code branch |
| **in-repo context** | context tracked with the code — `CONTEXT.md` / `CONTEXT-MAP.md` at the repo root, ADRs under `docs/adr/` |
| **context root** | the directory holding every **context repo** plus `INDEX.md`; `AGENT_CONTEXT_HOME` points at it |
| **context worktree** | one code branch's worktree inside a **context repo** |
| **context home** | the resolved directory for glossary + ADRs — the **context worktree**, or the code repo root under **in-repo context** |
| **config home** | the branch-independent directory for repo-wide conventions — `.agents/` at the **context repo** root, or `docs/agents/` |

### Resolving the context store

Resolve **code repo first**: a machine-wide config is a default for the *machine* and may describe **context repo**s belonging to other code repos, so it must never outrank what the code repo itself says. First hit wins, and the first hit is also the precedence winner.

1. The code repo's own instructions file (`AGENTS.md`, else `CLAUDE.md`) carries an `## Agent skills` block -> it decides; stop.
2. No block, but in-tree `CONTEXT.md` / `CONTEXT-MAP.md` / `docs/adr/` -> **in-repo context**: read them, initialise nothing, suggest `setup-context` to record the choice.
3. Still unresolved -> look for a **context repo** matching this repo's slug under the **context root**, and read its recorded block at `.agents/agent-skills.md`.
4. Nothing found -> the machine-wide `## Agent skills (defaults)` block supplies the default **model** only, never a path.

| situation | context home | config home |
|---|---|---|
| block says in-repo | code repo root | `docs/agents/` |
| block says context repo | `<context root>/<slug>/<branch>/` | `<context root>/<slug>/.agents/` |
| no block, in-tree docs | code repo root | `docs/agents/` (may not exist yet) |
| nothing anywhere | defaults to a **context repo**; `setup-context` has not run | — |

Every skill saying "context home" or "config home" means the row this resolves to — resolve it *before* writing anywhere. Under **in-repo context** every "worktree root" reference in this file and in the skills reads as the code repo root, the **context repo** machinery and its scripts don't apply, and `offload-context` / `merge-context` / `rebase-context` are no-ops: plain git on the code repo carries the context. Everything below describes the **context repo**.

**What sits in the config home:** the `## Agent skills` block and the convention docs (issue tracker, triage labels, out-of-scope) plus `domain.md` — rules for the whole repo, not one branch. Under a **context repo** that is `.agents/` at the context repo root: one copy shared by every **context worktree**, never duplicated into them; plain files, edit in place; never imported into global or repo instructions files — skills read them at orientation. Under **in-repo context** it is `docs/agents/`, committed with the code, and the block sits in the repo's instructions file (auto-loaded; its lines may reference the `docs/agents/` files directly).

**Running the helper scripts** (stated once, here): invoke each **by its path, with cwd inside the code repo** — `ctx-init.sh`, `offload-context.sh` and `manifest.sh` read the repo + branch from the cwd to resolve the worktree / manifest, and locate their siblings via `$(dirname "$0")`; never `cd` into the skill folder. `ctx-index.sh` scans the whole **context root** and is cwd-independent.

### Layout

A **context repo** is a **bare git repo**, one per code repo, with a **team remote** and one **`git worktree` per code branch**. Context is **personal to the codebase** and never lives in the code tree; you edit it **directly in the context worktree** — there is no in-tree copy and nothing to sync, the worktree *is* the source of truth.

      $AGENT_CONTEXT_HOME/<slug>/        # slug = <org>__<repo> from the code repo's origin
      # bare repo at <slug>/.git; worktrees are siblings <slug>/<branch>
      # default context root ~/.pi/agent/ctx (Claude: ~/.claude/ctx, OpenCode: ~/.config/opencode/ctx)

`<slug>` derives from `remote.origin.url` (no remote -> the repo's folder name). `AGENT_CONTEXT_HOME` points at the **context root**; set it via your harness config to relocate or share that root. Inside a **context worktree**, files **mirror the code paths**:

- `<dir>/CONTEXT.md` — the glossary for that code dir.
- `CONTEXT-MAP.md` at the worktree root; `domain.md` globally at `.agents/domain.md` (see the config-home note above).
- ADRs at `docs/adr/` (system-wide) and `<dir>/adr/` (per context).

`grill-with-docs` and `domain-modeling` read and write these files in the worktree. A new branch's context worktree is **forked to mirror the code repo's branch graph** — off the context branch matching its base in the code repo (the branch it was cut from, e.g. `feature-3` off `feature-2`), falling back to the designated master — so it inherits its ancestry's glossary + ADRs.

### Publish + reconcile across branches

- **Offload** (`offload-context` / `offload-context.sh`) commits the worktree and pushes the branch to the team remote — it just saves your context work; there is no in-tree copy to reconcile.
- **Into trunk** is a deliberate `git merge` **you** run in the context repo, then `merge-context` to interview + sharpen the merged glossary (a line merge can leave a crept-back alias or two surviving definitions for one concept that need a human call). Reconciliation = `git merge` (mechanical) + `merge-context` (semantic). To move a branch's context onto an advanced base, `rebase-context` (`git rebase` + the same interview).

### Grounded mirror — no concepts that don't exist yet

The structure is **generated from the code, not invented by agents**. Allowed paths come from a manifest of the code repo (`git ls-files`, via `manifest.sh`), branch-accurate by construction.

- Context attaches **only at a path the manifest contains** — a `CONTEXT.md` or a `CONTEXT-MAP.md` link pointing at a path not in the manifest is **flagged dangling, not created**.
- `setup-context` scaffolds the skeleton from the manifest; agents extend it only along real paths.
- Liveness — whether a grounded term's *symbol* still exists — is a separate LSP check (`lsp_references` / `lsp_workspace_symbols`). The manifest grounds *paths*; LSP grounds *symbols*.

## Single vs multi-context

- **Single context:** one `CONTEXT.md` at the worktree root (mirroring the code repo root).
- **Multiple:** `CONTEXT-MAP.md` at the worktree root lists contexts + relationships:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) — generates invoices and processes payments

## Relationships

- **Ordering → Fulfillment**: `OrderPlaced` events trigger picking
- **Fulfillment → Billing**: `ShipmentDispatched` events trigger invoices
- **Ordering ↔ Billing**: shared `CustomerId`, `Money`
```

`CONTEXT-MAP.md` links are relative to the repo root and mirror code-relative paths, so `./src/ordering/CONTEXT.md` is the glossary for that code dir, in the worktree. Inference: `CONTEXT-MAP.md` exists → multi. Only root `CONTEXT.md` → single. Neither → create `CONTEXT.md` at the worktree root lazily on first term. Infer current context from topic; ask if unclear.
