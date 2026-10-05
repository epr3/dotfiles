# Shared Zsh environment (.zshenv) — sourced for every Zsh invocation,
# including noninteractive shells (scripts, editor-spawned processes).
# Interactive-only setup lives in .zshrc.
# Managed tool resolution: docs/mise-gui-editor-access.md,
# docs/mise-runtime-migration.md.

# Homebrew: executables on PATH for all shells.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export XDG_CONFIG_HOME="$HOME/.config"
export AGENT_CONTEXT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/agent/ctx"
export HOMEBREW_PREFIX=/opt/homebrew

# pnpm: prepend once, never duplicating an inherited entry.
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# mise shims resolve Managed tools (Node, Python, Ruby, Go) in noninteractive
# Zsh (scripts, editors) without shell activation; interactive Zsh re-resolves
# via mise activate (docs/mise-node-migration.md, docs/mise-runtime-migration.md).
# Prepending keeps mise ahead of pnpm's node.
MISE_SHIMS="$HOME/.local/share/mise/shims"
if [[ -d "$MISE_SHIMS" ]]; then
  case ":$PATH:" in
    *":$MISE_SHIMS:"*) ;;
    *) export PATH="$MISE_SHIMS:$PATH" ;;
  esac
fi

# Append-only PATH helper: adds a directory at the end without duplicating
# an inherited entry.
path_append() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
  esac
}

# Go runtime selection moved to mise, so GOROOT must not pin Homebrew's Go
# (mise's go would pick up the wrong GOROOT). GOPATH keeps its default (~/go).
# `~/go/bin` stays on PATH: existing `go install`-ed tools (gopls, dlv, …)
# keep resolving there.
# Homebrew's bin, then user tool bins — appended with deduplication, in the
# established order and precedence.
path_append "$HOMEBREW_PREFIX/bin"
path_append "$HOME/go/bin"
path_append "$HOME/.poetry/bin"
path_append "$HOME/.local/bin"
path_append "$HOME/.cargo/bin"
path_append "$HOME/.lmstudio/bin"
# OpenCode: prepend the standalone copy so it wins over Homebrew's.
case ":$PATH:" in
  *":$HOME/.opencode/bin:"*) ;;
  *) PATH="$HOME/.opencode/bin:$PATH" ;;
esac
# Make the chosen PATH and Homebrew's zsh visible to child processes.
export PATH SHELL="$HOMEBREW_PREFIX/bin/zsh"
unset -f path_append
