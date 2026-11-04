#!/usr/bin/env bash
# Guarded stage after `brew bundle`: verify that Homebrew's pi-bolt (the
# compiled Pi runtime, installed from the Brewfile's tap opensec-git/tap) is
# present, and report Pi-Bolt, bundled-Pi, and current `pi` versions.
#
# Homebrew owns installation and upgrades (`brew upgrade pi-bolt`; no pin, no
# custom formula — docs/adr/2026-11-04-homebrew-owned-pi-bolt.md). This stage
# never runs `pi-bolt update`, never touches the existing pnpm pi
# (~/Library/pnpm/pi), never edits ~/.pi/agent runtime state, and never changes
# what `pi` resolves to: activating Pi-Bolt as `pi` is a separate, explicit
# step. Safe to rerun.
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

# Make brew available the way the shared mise stage helpers resolve Homebrew.
if ! command -v brew &>/dev/null; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    fail "brew is required to check pi-bolt. Run the Homebrew Bootstrap stage first."
  fi
fi

if ! brew list --versions pi-bolt &>/dev/null; then
  fail "Homebrew has no pi-bolt installed. Bootstrap runs this stage after 'brew bundle', which installs pi-bolt from the Brewfile (tap opensec-git/tap, formula pi-bolt). Run 'brew bundle' — or 'brew install opensec-git/tap/pi-bolt' directly — then rerun this stage."
fi

pi_bolt_bin="$(command -v pi-bolt || true)"
if [ -z "$pi_bolt_bin" ]; then
  fail "Homebrew has pi-bolt installed, but it is not on PATH. Homebrew links it at \"$(brew --prefix)/bin/pi-bolt\": ensure \"$(brew --prefix)/bin\" is on PATH, then rerun."
fi
pi_bolt_bin_resolved="$(readlink -f "$pi_bolt_bin")"
case "$pi_bolt_bin_resolved" in
  "$(brew --prefix)"/Cellar/*|/opt/homebrew/Cellar/*) ;;
  *)
    fail "pi-bolt resolves to a non-Homebrew-owned binary: $pi_bolt_bin_resolved.Resolution: resolve the conflicting PATH entry; the Homebrew install lives at \"$(brew --prefix)/Cellar/pi-bolt\"."
    ;;
esac

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

cat <<'EOF'
Next steps:
1. Validate Pi-Bolt directly against the existing config — it uses ~/.pi/agent
   (settings, themes, extensions, sessions, credentials, skills) as is. Run
   `pi-bolt` from a throwaway directory for an interactive check, or e.g.
   `pi-bolt -p '...'` for a noninteractive one.
2. Activating Pi-Bolt as `pi` is a separate, explicit step and is intentionally
   NOT performed by this stage; an existing `pi` keeps resolving unchanged.
EOF
