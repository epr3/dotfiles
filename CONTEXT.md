# Dotfiles

Repository-level shell, install, bootstrap, and dotfile conventions.

## Language

**Dotfile-managed tool config**: Declarative, non-secret configuration owned by this repository and linked into the home directory by the bootstrap.
_Avoid_: installation, local state, cache.

**Curated Pi assets**: The non-secret Pi agent files, skills, themes, and extensions that define the agent environment without including credentials, sessions, installed packages, or context worktrees.
_Avoid_: whole .pi mirror, Pi cache.

**Agent context store**: The tool-neutral directory pointed to by `AGENT_CONTEXT_HOME`, shared by agent harnesses for branch-aware context worktrees.
_Avoid_: Pi context, Claude context.

**Bootstrap**: The repeatable entrypoint that links dotfiles and runs guarded setup stages for package managers, packages, shell tools, editor extensions, and git identity.
_Avoid_: install script, setup script.

## Relationships

- **Bootstrap** links **Dotfile-managed tool config** into the home directory.
- **Curated Pi assets** exclude the **Agent context store** and other machine-local Pi state.
- **Agent context store** is configured by shell environment, not by the linked Pi config itself.

## Example dialogue

> **Dev:** "Should we commit all of `~/.pi` so a new machine is identical?"
> **Domain expert:** "No — commit **Curated Pi assets** only, and point every harness at the shared **Agent context store** via `AGENT_CONTEXT_HOME`."

## Flagged ambiguities

- "moving installations here" resolved to **Dotfile-managed tool config** plus guarded package installation, not committing generated local state.
