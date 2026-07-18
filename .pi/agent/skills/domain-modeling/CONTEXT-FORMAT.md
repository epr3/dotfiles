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

## Where it lives — a separate context repo

**Context home** = where context lives: the branch's **context worktree** under the store model, or the **code repo itself** when relocated in-repo. **Resolving which:** the recorded `## Agent skills` block decides — check it *before* writing anywhere (in-repo puts it in the repo's own instructions file, already auto-loaded; the store keeps it at `.agents/agent-skills.md`). No block anywhere -> store default. Every skill that says "context home" means this, resolution included.

Context is **personal to the codebase** and lives, by default, in a separate **context repo**, never in the code tree. You edit it **directly in that repo's worktree** — there is no in-tree copy and nothing to sync; the worktree *is* the source of truth.

**Context home override:** a repo's own `## Agent skills` block (written by `setup-context`) may relocate context **in-repo** — `CONTEXT.md`/`CONTEXT-MAP.md` at the repo root, ADRs under `docs/adr/`, committed with the code. When it does, every "worktree root" reference in this file and in the skills reads as the code repo root, the store/scripts don't apply, and `offload-context`/`merge-context`/`rebase-context` are no-ops — plain git on the code repo carries the context. Everything below describes the default store model.

**Config home (repo-wide, branch-independent):** the `## Agent skills` block and the convention docs (issue tracker, triage labels, out-of-scope) are rules for the whole repo, not one branch. Store model: **once at the store root**, `$AGENT_CONTEXT_HOME/<slug>/.agents/` — a single copy per context repo, used by all its branch worktrees, never duplicated into them; plain files, edit in place; never imported into global or repo instructions files — skills read them at orientation. In-repo: `docs/agents/` in the code repo, committed with the code, and the block sits in the repo's instructions file (auto-loaded; its lines may reference the `docs/agents/` files directly). "Config home" means whichever applies.

`domain.md` lives **globally** at `.agents/domain.md` under the store model — written once per context repo, used by all of its branches, edit-in-place; no per-branch copies. When orienting, resolve it there (in-repo context: at `docs/agents/domain.md` — the config home holds it in both modes).

### Layout

The context repo is a **bare git repo**, one per code repo, with a **team remote** and one **`git worktree` per code branch**:

      $AGENT_CONTEXT_HOME/<slug>/        # slug = <org>__<repo> from the code repo's origin
      # bare repo at <slug>/.git; worktrees are siblings <slug>/<branch>; default root ~/.claude/ctx
      # (Pi: ~/.pi/agent/ctx, OpenCode: ~/.config/opencode/ctx)

`<slug>` derives from `remote.origin.url` (no remote -> the repo's folder name). Set `AGENT_CONTEXT_HOME` via your harness config to relocate or share the root. Inside a worktree, files **mirror the code paths**:

- `<dir>/CONTEXT.md` — the glossary for that code dir.
- `CONTEXT-MAP.md` at the worktree root; `domain.md` globally at `.agents/domain.md` (see the config-home note above).
- ADRs at `docs/adr/` (system-wide) and `<dir>/adr/` (per context).

`grill-with-docs` and `domain-modeling` read and write these files in the worktree. A new branch's context worktree is **forked to mirror the code repo's branch graph** — off the context branch matching its base in the code repo (the branch it was cut from, e.g. `feature-3` off `feature-2`), falling back to the designated master — so it inherits its ancestry's glossary + ADRs.

### Publish + reconcile across branches

- **Offload** (`offload-context` / `offload-context.sh`) commits the worktree and pushes the branch to the team remote — it just saves your context work; there is no in-tree copy to reconcile.
- **Into trunk** is a deliberate `git merge` **you** run in the context repo, then `merge-context` to interview + sharpen the merged glossary (a line merge can leave a crept-back alias or two surviving definitions for one concept that need a human call). Reconciliation = `git merge` (mechanical) + `merge-context` (semantic). To move a branch's context onto an advanced base, `rebase-context` (`git rebase` + the same interview).

**Where to run the scripts:** run `ctx-init.sh`, `offload-context.sh`, and `manifest.sh` from inside the **code repo** (they read the repo + branch from your cwd to resolve the worktree / manifest), invoking each by its path; `ctx-index.sh` scans the whole store (`AGENT_CONTEXT_HOME`) and is cwd-independent.

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
