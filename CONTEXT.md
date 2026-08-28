# Dotfiles

Repository-level shell, install, bootstrap, and dotfile conventions.

## Language

**Dotfile-managed tool config**: Declarative, non-secret configuration owned by this repository and linked into the home directory by the bootstrap.
_Avoid_: installation, local state, cache.

**Curated Pi assets**: The non-secret Pi agent files, skills, themes, and extensions that define the agent environment without including credentials, sessions, installed packages, or context worktrees.
_Avoid_: whole .pi mirror, Pi cache.

**Dumb-zone contract**: The Pi statusline's fixed token thresholds that move an agent through sharp, fading, risky, and caveman response modes.
_Avoid_: model limit, context-window budget.

**Caveman boundary**: The inclusive dumb-zone threshold at which Pi enters caveman mode, independent of a model's advertised context window.
_Avoid_: overflow limit, remaining-context warning.

**Upstream**: github.com/mattpocock/skills — the curated skill suite's source of ideas, not a runtime dependency; sync record: selectively ported `6654f6b` (2026-08-25).

**Agent context store**: The tool-neutral directory pointed to by `AGENT_CONTEXT_HOME`, shared by agent harnesses for branch-aware context worktrees.
_Avoid_: Pi context, Claude context.

**Out-of-scope knowledge base**: Per-repository records in the config home that preserve rejected enhancement decisions and let triage identify equivalent later requests.
_Avoid_: rejected-issue list, feature backlog.

**Decision ticket**: A wayfinding ticket that resolves one uncertainty before execution and is typed as research, prototype, grilling, or task.
_Avoid_: investigation ticket, issue number.

**Research ticket**: A **decision ticket** whose uncertainty is resolved by gathering evidence from authoritative sources.
_Avoid_: investigation ticket, research task.

**HITL**: A ticket mode that requires human input at a decision or review point while work is underway.
_Avoid_: manual ticket, interactive type.

**AFK**: A ticket mode that can proceed without human input after the work is claimed.
_Avoid_: automatic ticket, unattended type.

**Tracer bullet**: An implementation ticket that delivers a thin, independently verifiable slice through every required layer.
_Avoid_: horizontal task, partial layer.

**Bootstrap**: The repeatable entrypoint that links dotfiles and runs guarded setup stages for package managers, packages, shell tools, editor extensions, and git identity.
_Avoid_: install script, setup script.

## Relationships

- **Bootstrap** links **Dotfile-managed tool config** into the home directory.
- **Curated Pi assets** exclude the **Agent context store** and other machine-local Pi state.
- **Agent context store** is configured by shell environment, not by the linked Pi config itself.
- A **Decision ticket** has one kind and one mode: **Research ticket** is **AFK**, prototype and grilling are **HITL**, and task may be either.
- A **Tracer bullet** is an implementation task rather than a **Decision ticket**.

## Example dialogue

> **Dev:** "Should we commit all of `~/.pi` so a new machine is identical?"
> **Domain expert:** "No — commit **Curated Pi assets** only, and point every harness at the shared **Agent context store** via `AGENT_CONTEXT_HOME`."

## Flagged ambiguities

- "moving installations here" resolved to **Dotfile-managed tool config** plus guarded package installation, not committing generated local state.
- "investigation ticket" resolved to **Decision ticket**; **Research ticket** names the evidence-gathering subtype only.
- `type` records ticket kind and `mode` records **HITL** or **AFK**; using `type` for both was rejected.
