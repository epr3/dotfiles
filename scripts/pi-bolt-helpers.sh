#!/usr/bin/env bash
# Shared helpers for the Pi-Bolt Bootstrap stage and the pi entry point
# manager. Sourced, not executed — see install-pi-bolt.sh, pi-entrypoint.sh.

# Make brew available the way the Homebrew Bootstrap stage does; exit with the
# given actionable message when brew cannot be made available.
pi_bolt_require_brew() {
  if ! command -v brew &>/dev/null; then
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      echo "$1" >&2
      exit 1
    fi
  fi
}

# Print readlink -f of $1 — the resolved path behind a candidate binary or
# symlink. The Homebrew-owned pi-bolt lives under Cellar/<formula>/<version>/.
pi_bolt_cellar_path() {
  readlink -f "$1"
}

# 0/1: is the already-resolved path $1 inside the Homebrew Cellar?
pi_bolt_resolved_in_cellar() {
  case "$1" in
    "$(brew --prefix)"/Cellar/*|/opt/homebrew/Cellar/*) return 0 ;;
    *) return 1 ;;
  esac
}

# Print the pi entry-point directory, honoring a pre-set PI_ENTRYPOINT_DIR.
# This is the single definition of the default; .zshenv retypes it because it
# cannot reliably source repository scripts.
pi_bolt_entrypoint_dir() {
  echo "${PI_ENTRYPOINT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/pi/bin}"
}
