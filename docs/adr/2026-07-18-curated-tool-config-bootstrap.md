# Curate tool config and bootstrap through guarded stages

This dotfiles repository will own declarative, non-secret tool configuration rather than full runtime directories: `worktrunk`, `gh-dash`, and `oh-my-posh` live under `.config/`, while Pi is mirrored as curated `.pi/agent` assets excluding auth, sessions, installed packages, and context worktrees. Agent context moves behind a tool-neutral `AGENT_CONTEXT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/agent/ctx"`, and the bootstrap remains Dotbot-based but delegates imperative setup to guarded scripts so repeated installs do not reinstall package managers, force prompts, or fail when optional tools are absent.

## Considered Options

- Mirror whole runtime directories: rejected because `~/.pi` contains credentials, generated sessions, package installs, and context worktrees.
- Keep context under Pi: rejected because the context store is shared agent state, not Pi-specific configuration.
- Replace Dotbot entirely: rejected because the current entrypoint already handles linking well; scripts are a smaller seam for idempotent setup.
