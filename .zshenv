# Shared Zsh environment.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export XDG_CONFIG_HOME="$HOME/.config"
export AGENT_CONTEXT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/agent/ctx"
export HOMEBREW_PREFIX=/opt/homebrew

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
path_append "$HOMEBREW_PREFIX/bin"
path_append "$HOME/go/bin"
path_append "$HOME/.poetry/bin"
path_append "$HOME/.local/bin"
path_append "$HOME/.cargo/bin"
path_append "$HOME/.lmstudio/bin"
case ":$PATH:" in
  *":$HOME/.opencode/bin:"*) ;;
  *) PATH="$HOME/.opencode/bin:$PATH" ;;
esac
export PATH SHELL="$HOMEBREW_PREFIX/bin/zsh"
unset -f path_append
