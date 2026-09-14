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

path_append() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
  esac
}

export GOROOT="$HOMEBREW_PREFIX/opt/go/libexec"
export GOPATH="$HOME/go"
export PYENV_ROOT="$HOME/.pyenv"

path_append "$HOMEBREW_PREFIX/bin"
path_append "$PYENV_ROOT/bin"
path_append "$GOPATH/bin"
path_append "$GOROOT/bin"
path_append "$HOME/.poetry/bin"
path_append "$HOME/.local/bin"
path_append "$HOME/.cargo/bin"
path_append "$HOME/.rbenv/bin"
path_append "$HOME/.lmstudio/bin"
case ":$PATH:" in
  *":$HOME/.opencode/bin:"*) ;;
  *) PATH="$HOME/.opencode/bin:$PATH" ;;
esac
export PATH SHELL="$HOMEBREW_PREFIX/bin/zsh"
unset -f path_append
