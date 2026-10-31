#!/usr/bin/env bash
# Bootstrap Pi's external extensions from the pinned upstream revision into the
# agent directory (docs/adr/2026-07-18-curated-tool-config-bootstrap.md —
# imperative setup lives in guarded, idempotent scripts). settings.json
# references these packages as agent-dir-relative paths
# (packages/pi-extensions/packages/*), so this stage makes any fresh or
# isolated agent directory self-sufficient: it clones
# github.com/epr3/pi-extensions at the pinned commit into
# <agent-dir>/packages/pi-extensions and installs the monorepo's production
# dependencies, reusing an existing correct checkout without touching it.
#
# Overrides: set PI_CODING_AGENT_DIR to bootstrap a different (e.g. isolated,
# test) agent directory — the same variable Pi itself honors.
set -euo pipefail

REPO_URL="https://github.com/epr3/pi-extensions.git"
PINNED_SHA="a7d95daeaf9f50d66f82ccd715e418b637f9b48b"

AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
TARGET="$AGENT_DIR/packages/pi-extensions"

fail() {
  echo "$1" >&2
  exit 1
}

# Explicit mise execution: this stage runs with the locked Node from the
# tracked global configuration, even without a previously activated shell
# (docs/mise-node-migration.md). Re-exec resolves from $HOME — outside this
# repository — so project configuration cannot participate, matching
# scripts/install-pi.sh.
source "$(cd "$(dirname "$0")" && pwd)/mise-stage-helpers.sh"
mise_stage_resolve
if [[ "${MISE_PI_EXTENSIONS_STAGE:-}" != "1" ]]; then
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  export MISE_PI_EXTENSIONS_STAGE=1
  mise_stage_cd_home
  exec mise x -- bash "$script_dir/$(basename "$0")"
fi

# pnpm's standalone install location may not be on PATH in a fresh shell.
if ! command -v pnpm &>/dev/null; then
  PNPM_HOME="$HOME/Library/pnpm"
  if [ -x "$PNPM_HOME/pnpm" ]; then
    export PNPM_HOME
    export PATH="$PNPM_HOME:$PATH"
  fi
fi

if ! command -v git &>/dev/null; then
  fail "git is required to fetch pi-extensions."
fi
if ! command -v pnpm &>/dev/null; then
  fail "pnpm is required to install pi-extensions dependencies. Run the pnpm Bootstrap stage first."
fi

mkdir -p "$AGENT_DIR/packages" || fail "Cannot create $AGENT_DIR/packages."
if [ -e "$TARGET" ] && [ ! -d "$TARGET" ]; then
  fail "$TARGET exists but is not a directory; refusing to replace it."
fi

need_install=0

if [ -e "$TARGET" ]; then
  if [ ! -d "$TARGET/.git" ]; then
    fail "$TARGET is not a git checkout; refusing to touch a non-bootstrap directory."
  fi
  if [ -n "$(git -C "$TARGET" status --porcelain)" ]; then
    fail "$TARGET has uncommitted local changes; resolve them manually — local work is never discarded."
  fi
  head="$(git -C "$TARGET" rev-parse HEAD)"
  if [ "$head" = "$PINNED_SHA" ]; then
    echo "pi-extensions already pinned at $PINNED_SHA."
    if [ ! -d "$TARGET/node_modules" ]; then
      echo "node_modules is missing; reinstalling dependencies."
      need_install=1
    fi
  else
    echo "pi-extensions is at $head; fetching the pinned revision $PINNED_SHA..."
    git -C "$TARGET" fetch origin "$PINNED_SHA" ||
      git -C "$TARGET" fetch origin ||
        fail "Could not fetch $REPO_URL. Check network access, then rerun."
    git -C "$TARGET" cat-file -e "$PINNED_SHA^{commit}" ||
      fail "Pinned revision $PINNED_SHA not found in $REPO_URL after fetching."
    git -C "$TARGET" checkout --detach "$PINNED_SHA" ||
      fail "Could not check out $PINNED_SHA in $TARGET."
    need_install=1
  fi
else
  echo "Cloning pi-extensions into $TARGET..."
  git clone "$REPO_URL" "$TARGET" ||
    fail "Could not clone $REPO_URL. Check network access, then rerun."
  head="$(git -C "$TARGET" rev-parse HEAD)"
  if [ "$head" != "$PINNED_SHA" ]; then
    git -C "$TARGET" cat-file -e "$PINNED_SHA^{commit}" ||
      fail "Pinned revision $PINNED_SHA not found in $REPO_URL after cloning."
    echo "Checking out pinned revision $PINNED_SHA..."
    git -C "$TARGET" checkout --detach "$PINNED_SHA" ||
      fail "Could not check out $PINNED_SHA in $TARGET."
  fi
  need_install=1
fi

if [ "$need_install" = 1 ]; then
  echo "Installing pi-extensions dependencies (--frozen-lockfile --prod)..."
  # --prod: extensions are TypeScript loaded by Pi via jiti — no build step, so
  # the devDependencies (typescript, vitest, oxlint, ...) are not needed at
  # runtime. --frozen-lockfile keeps the upstream lockfile authoritative.
  (cd "$TARGET" && pnpm install --frozen-lockfile --prod) ||
    fail "pnpm install failed in $TARGET. Check network and registry access, then rerun. Resolution: the monorepo pins pnpm@10.33.0 via packageManager; the Bootstrap stage provides pnpm from scripts/install-pnpm.sh (same major line)."
  echo "pi-extensions pinned at $PINNED_SHA in $TARGET with dependencies installed."
else
  echo "Skipping dependency installation (checkout unchanged and dependencies present)."
fi
