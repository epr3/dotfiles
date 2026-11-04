#!/usr/bin/env bash
# Guarded stage after `brew bundle`: verify that Homebrew's pi-bolt (the
# compiled Pi runtime, installed from the Brewfile's tap opensec-git/tap) is
# present, and report Pi-Bolt, bundled-Pi, and current `pi` versions.
#
# Homebrew owns installation and upgrades (`brew upgrade pi-bolt`; no pin, no
# custom formula — docs/adr/2026-11-04-homebrew-owned-pi-bolt.md). This stage
# never runs `pi-bolt update`, never touches the existing pnpm pi
# (~/Library/pnpm/pi), never edits ~/.pi/agent runtime state, and never changes
# what `pi` resolves to on a machine that already has a Pi: on a fresh machine
# with no `pi` at all it activates the entry point; when any prior `pi` exists
# it prints the validate → activate → rollback steps instead (docs/adr/
# 2026-11-04-homebrew-owned-pi-bolt.md). Safe to rerun.
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

source "$(cd "$(dirname "$0")" && pwd)/pi-bolt-helpers.sh"

pi_bolt_require_brew "brew is required to check pi-bolt. Run the Homebrew Bootstrap stage first."

if ! brew list --versions pi-bolt &>/dev/null; then
  fail "Homebrew has no pi-bolt installed. Bootstrap runs this stage after 'brew bundle', which installs pi-bolt from the Brewfile (tap opensec-git/tap, formula pi-bolt). Run 'brew bundle' — or 'brew install opensec-git/tap/pi-bolt' directly — then rerun this stage."
fi

pi_bolt_bin="$(command -v pi-bolt || true)"
if [ -z "$pi_bolt_bin" ]; then
  fail "Homebrew has pi-bolt installed, but it is not on PATH. Homebrew links it at \"$(brew --prefix)/bin/pi-bolt\": ensure \"$(brew --prefix)/bin\" is on PATH, then rerun."
fi
pi_bolt_bin_resolved="$(pi_bolt_cellar_path "$pi_bolt_bin")"
if ! pi_bolt_resolved_in_cellar "$pi_bolt_bin_resolved"; then
  fail "pi-bolt resolves to a non-Homebrew-owned binary: $pi_bolt_bin_resolved. Resolution: resolve the conflicting PATH entry; the Homebrew install lives at \"$(brew --prefix)/Cellar/pi-bolt\"."
fi

pi_bolt_version_raw="$(pi-bolt --version)"
# pi-bolt --version prints "<bundled Pi version> (Pi-Bolt <Pi-Bolt version>, ...)".
bundled_pi_version="${pi_bolt_version_raw%% *}"
pi_bolt_version="$(sed -n 's/.*(Pi-Bolt \([^,]*\),.*/\1/p' <<<"$pi_bolt_version_raw")"
echo "Homebrew pi-bolt: $pi_bolt_bin_resolved — Pi-Bolt ${pi_bolt_version:-?}, bundled Pi ${bundled_pi_version:-?}."

resolved_pi="$(command -v pi || true)"
if [ -n "$resolved_pi" ]; then
  pi_version="$(pi --version 2>/dev/null | head -1 || echo unknown)"
  echo "Current pi resolution: $resolved_pi (${pi_version}). Unchanged by this stage."
else
  echo "No pi is on PATH yet. Unchanged by this stage."
fi

# Fresh-machine rule: activate Pi-Bolt as `pi` ONLY when no prior `pi` exists
# anywhere — not on PATH, not "${PNPM_HOME:-$HOME/Library/pnpm}/pi". When any
# prior `pi` exists, resolution must NOT change: the human decides after the
# interactive validation. Repeated Bootstrap runs on an already-active entry
# point just report it (pi-entrypoint.sh is idempotent).
pnpm_pi="${PNPM_HOME:-$HOME/Library/pnpm}/pi"
entrypoint_dir="$(pi_bolt_entrypoint_dir)"
if command -v pi &>/dev/null || [ -x "$pnpm_pi" ] || [ -L "$pnpm_pi" ]; then
  prior_pi="$(command -v pi 2>/dev/null || true)"
  [ -n "$prior_pi" ] || prior_pi="$pnpm_pi"
  # Already-active entry point: report it, change nothing.
  if [ "$(readlink -f "$prior_pi" 2>/dev/null || true)" = "$(readlink -f "$entrypoint_dir/pi" 2>/dev/null || true)" ]; then
    echo "Pi-Bolt entry point is already active: $prior_pi (--version: $("$prior_pi" --version 2>/dev/null | head -1 || echo unknown)). No changes made."
    exit 0
  fi
  pi_version="$("$prior_pi" --version 2>/dev/null | head -1 || echo unknown)"
  echo "An existing pi was found ($prior_pi, ${pi_version}) — leaving command resolution unchanged."
  cat <<'EOF'
To take over command resolution after validating Pi-Bolt against your config
(it uses ~/.pi/agent — settings, themes, extensions, sessions, credentials,
skills — as is):
1. Validate: run `pi-bolt` from a throwaway directory for an interactive
   check, or e.g. `pi-bolt -p '...'` for a noninteractive one.
2. Activate: scripts/pi-entrypoint.sh activate
3. Rollback (keeps pnpm Pi and all local state; new shells):
   scripts/pi-entrypoint.sh deactivate
EOF
  exit 0
fi

echo "No prior pi exists (nothing on PATH, nothing at $pnpm_pi) — activating the pi entry point for Pi-Bolt."
"$(dirname "$0")/pi-entrypoint.sh" activate
