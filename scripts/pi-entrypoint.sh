#!/usr/bin/env bash
# Manage the PATH-visible `pi` entry point that launches Pi-Bolt, the
# Homebrew-owned compiled Pi runtime (docs/adr/2026-11-04-homebrew-owned-pi-bolt.md).
#
# The entry point is a `pi` symlink in PI_ENTRYPOINT_DIR
# (default "${XDG_DATA_HOME:-$HOME/.local/share}/pi/bin"; .zshenv prepends that
# dir to PATH only while the symlink exists, ahead of $PNPM_HOME and mise
# shims). Usage:
#
#   activate    Create the symlink so `pi` resolves to pi-bolt. Refuses to
#               clobber a non-symlink or a foreign symlink: it reports and
#               exits without changing anything.
#   deactivate  Remove only OUR symlink (one pointing at pi-bolt), restoring
#               the previous resolution in new shells (typically the pnpm Pi).
#               Leaves the entry point directory and every local state alone,
#               and never deletes a foreign `pi`.
#   status      Report whether the entry point exists and what `pi` resolves
#               to with the entry point dir first on PATH.
#
# This script never touches the pnpm Pi (~/Library/pnpm/pi) or ~/.pi/agent
# runtime state (auth, sessions, packages, settings). Homebrew owns installs
# and upgrades (`brew upgrade pi-bolt`; never run `pi-bolt update`). All
# subcommands are idempotent: repeated runs report instead of redoing work.
set -euo pipefail

entrypoint_usage() {
  echo "usage: pi-entrypoint.sh activate|deactivate|status" >&2
}

fail() {
  echo "pi-entrypoint: $1" >&2
  exit 1
}

[ "$#" -eq 1 ] || { entrypoint_usage; exit 1; }
action="$1"
case "$action" in
  activate|deactivate|status) ;;
  *) entrypoint_usage; exit 1 ;;
esac

source "$(cd "$(dirname "$0")" && pwd)/pi-bolt-helpers.sh"

PI_ENTRYPOINT_DIR="$(pi_bolt_entrypoint_dir)"
entrypoint_pi="$PI_ENTRYPOINT_DIR/pi"

# Resolve brew via the shared pi-bolt helpers.
pi_bolt_require_brew "pi-entrypoint: brew is required to locate the Homebrew-owned pi-bolt. Run the Homebrew Bootstrap stage first."

target="$(brew --prefix)/bin/pi-bolt"

# The entry point must point at a Homebrew-owned pi-bolt; resolution and
# Cellar ownership live in the shared helpers.
homebrew_pi_bolt_ok() {
  [ -e "$target" ] || return 1
  pi_bolt_resolved_in_cellar "$(pi_bolt_cellar_path "$target")"
}

# Print "path (version)" for the `pi` resolving first on the current PATH.
resolve_pi() {
  local resolved version
  resolved="$(command -v pi 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    version="$(pi --version 2>/dev/null | head -1 || echo unknown)"
    echo "$resolved (${version})"
  else
    echo "none"
  fi
}

case "$action" in
  status)
    if homebrew_pi_bolt_ok; then
      echo "pi-bolt target: $(pi_bolt_cellar_path "$target")"
    else
      echo "pi-bolt target: NOT found at $target (activate requires a Homebrew-owned pi-bolt: 'brew install opensec-git/tap/pi-bolt')."
    fi
    if [ -L "$entrypoint_pi" ]; then
      if [ -e "$entrypoint_pi" ]; then
        echo "entry point: $entrypoint_pi -> $(readlink "$entrypoint_pi")"
      else
        echo "entry point: $entrypoint_pi is a dangling symlink -> $(readlink "$entrypoint_pi") (target missing)."
      fi
    elif [ -e "$entrypoint_pi" ]; then
      echo "entry point: $entrypoint_pi exists but is not a symlink."
    else
      echo "entry point: absent at $entrypoint_pi."
    fi
    echo "pi with entry point dir first on PATH: $(PATH="$PI_ENTRYPOINT_DIR:$PATH" resolve_pi)"
    echo "pi with PATH as inherited by this script: $(resolve_pi)"
    ;;
  activate)
    if ! homebrew_pi_bolt_ok; then
      fail "no Homebrew-owned pi-bolt at $target. Install it with 'brew install opensec-git/tap/pi-bolt' (the Brewfile declares it), then rerun."
    fi
    if [ -e "$entrypoint_pi" ] || [ -L "$entrypoint_pi" ]; then
      if [ ! -L "$entrypoint_pi" ]; then
        fail "$entrypoint_pi exists but is not a symlink — not touching it. Inspect it, remove or rename it yourself, then rerun activate."
      fi
      resolved="$(pi_bolt_cellar_path "$entrypoint_pi")"
      if [ "$resolved" = "$(pi_bolt_cellar_path "$target")" ]; then
        echo "pi-entrypoint: already active — $entrypoint_pi -> $(readlink "$entrypoint_pi") ($($entrypoint_pi --version 2>/dev/null | head -1 || echo 'version unknown'))."
        exit 0
      fi
      fail "$entrypoint_pi exists but points at $resolved, which is not this machine's Homebrew pi-bolt — not touching it. Inspect it, remove or rename it yourself, then rerun activate."
    fi
    mkdir -p "$PI_ENTRYPOINT_DIR"
    ln -s "$target" "$entrypoint_pi"
    echo "pi-entrypoint: activated — $entrypoint_pi -> $(readlink "$entrypoint_pi")"
    echo "  pi in new Zsh shells resolves to: $(PATH="$PI_ENTRYPOINT_DIR:$PATH" resolve_pi)"
    echo "  pnpm Pi (~/Library/pnpm/pi) and ~/.pi/agent local state are untouched."
    echo "  Rollback: scripts/pi-entrypoint.sh deactivate"
    ;;
  deactivate)
    if [ ! -e "$entrypoint_pi" ] && [ ! -L "$entrypoint_pi" ]; then
      echo "pi-entrypoint: not active — no $entrypoint_pi. Nothing to do; new shells fall back to the previous resolution."
      exit 0
    fi
    if [ ! -L "$entrypoint_pi" ]; then
      fail "$entrypoint_pi exists but is not a symlink — not touching it. Inspect it before removing it yourself."
    fi
    resolved="$(pi_bolt_cellar_path "$entrypoint_pi")"
    case "$resolved" in
      "$(brew --prefix)"/Cellar/pi-bolt/*|/opt/homebrew/Cellar/pi-bolt/*|*/Cellar/pi-bolt/*)
        ;;
      *)
        fail "$entrypoint_pi points at $resolved, which is not a Homebrew-owned pi-bolt — not touching it. Inspect it before removing it yourself."
        ;;
    esac
    rm "$entrypoint_pi"
    echo "pi-entrypoint: deactivated — removed $entrypoint_pi and left $PI_ENTRYPOINT_DIR in place."
    echo "  New shells fall back to the previous resolution (currently: $(resolve_pi))."
    echo "  Local state untouched: ~/.pi/agent (settings, sessions, credentials, packages), ~/Library/pnpm/pi."
    ;;
esac
