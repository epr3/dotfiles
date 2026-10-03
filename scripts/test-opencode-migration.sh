#!/usr/bin/env bash
# Sandboxed contract tests for the OpenCode config swap. Never use live HOME.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/opencode-migration.XXXXXX")
trap 'rm -rf "$SANDBOX"' EXIT

failures=0
ok() { printf 'ok  - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1" >&2; failures=$((failures + 1)); }

HOME="$SANDBOX/home"
export HOME
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$SANDBOX/xdg-data"
export XDG_STATE_HOME="$SANDBOX/xdg-state"
export XDG_CACHE_HOME="$SANDBOX/xdg-cache"
mkdir -p "$HOME/.config/opencode/skills/legacy" "$SANDBOX/bin" "$SANDBOX/data" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
printf 'legacy skill\n' > "$HOME/.config/opencode/skills/legacy/SKILL.md"
printf 'secret-sentinel\n' > "$HOME/.config/opencode/auth.json"
printf 'session-sentinel\n' > "$HOME/.config/opencode/session.db"
printf '#!/bin/sh\necho "opencode v1.15.13"\n' > "$SANDBOX/bin/opencode"
chmod +x "$SANDBOX/bin/opencode"
export PATH="$SANDBOX/bin:$PATH"
export OPENCODE_MIGRATION_BACKUP_ROOT="$SANDBOX/data/backups"
export OPENCODE_MIGRATION_MANAGED_CONFIG="$REPO/.config/opencode"

run() { "$REPO/scripts/migrate-opencode.sh" "$@"; }

# Existing config is moved into a private backup, without reading its secrets.
if run prepare >"$SANDBOX/out" 2>&1 && [ ! -e "$HOME/.config/opencode" ]; then
  backup=$(find "$OPENCODE_MIGRATION_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | head -1)
  if [ -n "$backup" ] && grep -q 'secret-sentinel' "$backup/config/auth.json" && grep -q 'session-sentinel' "$backup/config/session.db"; then
    ok 'existing configuration is recoverably backed up'
  else
    fail 'backup contains config and machine-local state'
  fi
else
  fail 'prepare moves the old config only after successful backup'
fi

# A duplicate prepare must not replace or create another backup.
before=$(find "$OPENCODE_MIGRATION_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
run prepare >/dev/null 2>&1
# Test rollback after simulating Dotbot's managed link.
ln -s "$OPENCODE_MIGRATION_MANAGED_CONFIG" "$HOME/.config/opencode"
if run rollback >/dev/null 2>&1 && [ -d "$HOME/.config/opencode" ] && [ ! -L "$HOME/.config/opencode" ] && grep -q 'legacy skill' "$HOME/.config/opencode/skills/legacy/SKILL.md" && [ -d "$backup/config" ] && grep -q 'legacy skill' "$backup/config/skills/legacy/SKILL.md"; then
  ok 'rollback restores the prior config and retains its verified backup'
else
  fail 'rollback restores the prior config and retains its verified backup'
fi

mv "$HOME/.config/opencode" "$SANDBOX/opencode.hold"
if run restore "$backup" >/dev/null 2>&1 && grep -q 'legacy skill' "$HOME/.config/opencode/skills/legacy/SKILL.md" && [ -d "$backup/config" ]; then
  ok 'explicit restore copies the retained backup without consuming it'
else
  fail 'explicit restore copies the retained backup without consuming it'
fi
rm -rf "$HOME/.config/opencode"
mv "$SANDBOX/opencode.hold" "$HOME/.config/opencode"

after=$(find "$OPENCODE_MIGRATION_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
[ "$before" = "$after" ] && ok 'repeat prepare preserves the original backup' || fail 'repeat prepare preserves the original backup'

# A backup-root failure must leave the active directory untouched.
rm -rf "$HOME/.config/opencode"
mkdir -p "$HOME/.config/opencode"
printf 'keep-me\n' > "$HOME/.config/opencode/keep"
export OPENCODE_MIGRATION_BACKUP_ROOT="$SANDBOX/not-a-directory/backups"
printf 'not a directory\n' > "$SANDBOX/not-a-directory"
if run prepare >"$SANDBOX/out" 2>&1; then
  fail 'backup failure aborts migration'
else
  [ -f "$HOME/.config/opencode/keep" ] && ok 'backup failure leaves active config intact' || fail 'backup failure leaves active config intact'
fi

# Refuse an XDG path that the Dotbot link configuration does not manage.
export XDG_CONFIG_HOME="$SANDBOX/custom-config"
mkdir -p "$XDG_CONFIG_HOME/opencode"
printf 'keep-custom-path\n' > "$XDG_CONFIG_HOME/opencode/keep"
if run prepare >"$SANDBOX/out" 2>&1; then
  fail 'custom XDG_CONFIG_HOME is rejected'
else
  [ -f "$XDG_CONFIG_HOME/opencode/keep" ] && ok 'custom XDG_CONFIG_HOME is rejected without touching it' || fail 'custom XDG_CONFIG_HOME is rejected without touching it'
fi
export XDG_CONFIG_HOME="$HOME/.config"

# Fresh setup can be committed, and can also be rolled back without inventing an old config.
export OPENCODE_MIGRATION_BACKUP_ROOT="$SANDBOX/data/backups"
rm -rf "$HOME/.config/opencode"
if run prepare >"$SANDBOX/out" 2>&1; then
  fresh_backup=""
  while IFS= read -r candidate; do
    if grep -qx 'fresh-config=true' "$candidate/manifest" 2>/dev/null; then fresh_backup=$candidate; break; fi
  done < <(find "$OPENCODE_MIGRATION_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d)
  if [ -n "$fresh_backup" ]; then
    ln -s "$OPENCODE_MIGRATION_MANAGED_CONFIG" "$HOME/.config/opencode"
    if run commit >/dev/null 2>&1 && [ -L "$HOME/.config/opencode" ]; then
      ok 'fresh managed setup can be committed'
    else
      fail 'fresh managed setup can be committed'
    fi
    rm -f "$HOME/.config/opencode"
    if run prepare >/dev/null 2>&1; then
      ln -s "$OPENCODE_MIGRATION_MANAGED_CONFIG" "$HOME/.config/opencode"
      if run rollback >/dev/null 2>&1 && [ ! -e "$HOME/.config/opencode" ]; then
        ok 'fresh setup rollback leaves no synthetic prior config'
      else
        fail 'fresh setup rollback leaves no synthetic prior config'
      fi
    else
      fail 'fresh setup rollback preparation'
    fi
  else
    fail 'fresh setup records that no prior config existed'
  fi
else
  fail 'fresh setup preparation succeeds'
fi

# Dotbot's generic config pass leaves OpenCode alone; the guarded standalone script owns that path.
export OPENCODE_MIGRATION_BACKUP_ROOT="$SANDBOX/data/bootstrap-backups"
if "$REPO/install" --only link >"$SANDBOX/install.log" 2>&1 && [ ! -e "$HOME/.config/opencode" ]; then
  ok 'Dotbot install leaves the separately managed OpenCode config untouched'
else
  fail 'Dotbot install leaves the separately managed OpenCode config untouched'
  tail -30 "$SANDBOX/install.log" >&2
fi

if "$REPO/scripts/install-opencode.sh" >"$SANDBOX/opencode-install.log" 2>&1 && [ -L "$HOME/.config/opencode" ] && [ "$(readlink "$HOME/.config/opencode")" = "$OPENCODE_MIGRATION_MANAGED_CONFIG" ]; then
  bootstrap_backups=$(find "$OPENCODE_MIGRATION_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  if "$REPO/scripts/install-opencode.sh" >>"$SANDBOX/opencode-install.log" 2>&1 && [ -L "$HOME/.config/opencode" ]; then
    repeated_backups=$(find "$OPENCODE_MIGRATION_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    [ "$bootstrap_backups" = "$repeated_backups" ] && ok 'guarded OpenCode activation is idempotent without duplicate backup' || fail 'guarded OpenCode activation is idempotent without duplicate backup'
  else
    fail 'guarded OpenCode activation remains valid on repeated invocation'
  fi
else
  fail 'guarded OpenCode activation uses isolated backup and managed paths'
  tail -30 "$SANDBOX/opencode-install.log" >&2
fi

[ "$failures" -eq 0 ] || exit 1
printf 'PASS OpenCode migration contract tests\n'
