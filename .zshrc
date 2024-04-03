export XDG_CONFIG_HOME=$HOME/.config
export HOMEBREW_PREFIX=/opt/homebrew
export PATH=$PATH:/opt/homebrew/bin
# pnpm
export PNPM_HOME="/Users/eduardpredescu/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export GOROOT="/opt/homebrew/opt/go/libexec"
export GOPATH=$HOME/go

export PYENV_ROOT=$HOME/.pyenv
export PATH=$PATH:$PYENV_ROOT/bin

export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin
export PATH=$PATH:$HOME/.poetry/bin
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/flutter/bin
export PATH=$PATH:$HOME/.rbenv/bin
eval "$(rbenv init -)"
eval "$(pyenv init -)"

eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"

alias ll="exa -l -g --icons --git"
alias llt="exa -1 --icons --tree --git-ignore"
alias vim=nvim
export SHELL=$HOMEBREW_PREFIX/bin/zsh
