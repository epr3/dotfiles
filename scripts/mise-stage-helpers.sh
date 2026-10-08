#!/usr/bin/env bash
# Shared helpers for guarded Bootstrap stages that drive mise. Sourced, not
# executed — see install-mise-tools.sh, install-cocoapods.sh, install-pi.sh.

# Make brew and mise available; fail loudly when mise is absent. Stage-specific
# messages live in the stages that call this after their own guards.
mise_stage_resolve() {
  if ! command -v mise &>/dev/null && [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  if ! command -v mise &>/dev/null; then
    echo "mise is required. Run the Homebrew and mise Bootstrap stages first." >&2
    exit 1
  fi
}

# Resolve outside the dotfiles repository so project configuration cannot
# participate; the tracked global configuration and lockfile own the install.
mise_stage_cd_home() {
  cd "$HOME"
}

# Fail unless the given executable path resolves inside mise's data directory.
mise_stage_check_path() {
  local resolved="$1" name="$2"
  case "$resolved" in
    "$HOME"/.local/share/mise/*) ;;
    *) echo "$name does not resolve to a mise-managed install: $resolved" >&2; exit 1 ;;
  esac
}
