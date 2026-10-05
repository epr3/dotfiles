# Interactive Zsh startup (.zshrc).
#
# Interactive-only configuration. The shared environment (PATH, exports,
# Managed tool shims) lives in .zshenv, which is sourced for every Zsh
# invocation; everything below runs for interactive shells only.
#
# Sections: Zinit (plugins & snippets) — Completion — Keybindings — History —
# Aliases — Integrations. Keep integration order stable when editing:
# fzf → mise → zoxide → oh-my-posh → worktrunk.

# =====================================================================
# Zinit — plugin manager, plugins, snippets, completions
# =====================================================================

# First launch: install Zinit into the data-home-derived location when its
# loader is absent. Every expansion is quoted, so the path also works when
# XDG_DATA_HOME contains spaces. An installation failure is reported
# directly here and handled by the load guard below — nothing depends on
# this attempt succeeding.
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
ZINIT_LOADER="${ZINIT_HOME}/zinit.zsh"

if [[ ! -e "$ZINIT_LOADER" ]]; then
  mkdir -p -- "$(dirname -- "$ZINIT_HOME")" && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Load Zinit only when its loader sources successfully. A failed install
# (loader absent) or an unusable loader skips every Zinit-dependent step
# instead of cascading loader/plugin errors; the else branch keeps
# completion working on its own. The rest of startup — history,
# keybindings, aliases, integrations — never depends on this block.
if [[ -e "$ZINIT_LOADER" ]] && source "$ZINIT_LOADER"; then
  # Add in zsh plugins
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit light Aloxaf/fzf-tab

  # Add in snippets
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZP::command-not-found

  # Load completions, then replay the plugins' completion definitions
  autoload -Uz compinit && compinit
  zinit cdreplay -q
else
  # No usable Zinit loader: initialize completion standalone so tab
  # completion keeps working without the plugin-provided completions.
  autoload -Uz compinit && compinit
fi

# =====================================================================
# Completion styling
# =====================================================================

# Case-insensitive matching: lowercase typed input matches capitalized
# candidates.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# Color the completion list from the session's LS_COLORS.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# Static completion list; no automatic menu walk.
zstyle ':completion:*' menu no
# fzf-tab directory previews: macOS-native BSD ls coloring (-G), not the GNU
# `--color` flag. `command` bypasses the ls alias; the preview argument stays
# safely quoted, so directory names containing spaces work.
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'command ls -G -- "$realpath"'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'command ls -G -- "$realpath"'

# =====================================================================
# Keybindings
# =====================================================================

bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# =====================================================================
# History
# =====================================================================

HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
# History policy lives in these options; HISTDUP is intentionally not set.
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# =====================================================================
# Aliases
# =====================================================================

# Listing: macOS-native BSD coloring (-G). `command` bypasses the alias so
# the definition cannot recurse; ls resolves to /bin/ls as before.
alias ls='command ls -G'
# One Vim-to-Neovim alias (a duplicate declaration was removed 2026-10).
alias vim='nvim'
alias c='clear'

# eza-based listings stay as-is: they intentionally gain no ls fallback.
alias ll="eza -l -g --icons --git"
alias llt="eza -1 --icons --tree --git-ignore"

# =====================================================================
# Integrations
# =====================================================================

# Optional integrations initialize only when their command is available, so a
# missing tool is skipped instead of erroring command-not-found at startup.
# Keep the relative order stable when editing:
# fzf → mise → zoxide → oh-my-posh → worktrunk.

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

# mise owns Managed tool versions — Node, Python, Ruby, Go
# (docs/mise-node-migration.md, docs/mise-runtime-migration.md). The rbenv and
# pyenv activation hooks were retired here: their shims would compete with
# mise's resolution. Those managers and their installations remain on disk
# untouched until separately approved cleanup; CocoaPods is reinstalled
# explicitly into the mise ruby by scripts/install-cocoapods.sh.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# Apple Terminal keeps its current prompt behavior: oh-my-posh initializes
# only in other terminal contexts, and only when the command is available.
if [ "$TERM_PROGRAM" != "Apple_Terminal" ] && command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/base.toml)"
fi

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
