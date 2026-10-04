#!/usr/bin/env bash
# Sandboxed contract tests for the OpenCode config swap (tickets 0001, 0006).
# Never use live HOME. Every cycle runs on fixtures; no credentials, no Pi edits.
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
export OPENCODE_MIGRATION_BACKUP_ROOT="$SANDBOX/data/backups"
export OPENCODE_MIGRATION_MANAGED_CONFIG="$REPO/.config/opencode"
CONFIG_DIR="$XDG_CONFIG_HOME/opencode"

mkdir -p "$SANDBOX/bin" "$CONFIG_DIR/skills/legacy-rtk" "$CONFIG_DIR/plugins" \
  "$XDG_DATA_HOME/opencode/storage/sessions" "$XDG_STATE_HOME/opencode" "$XDG_CACHE_HOME/opencode" \
  "$HOME/.pi" "$SANDBOX/pi-source/agent/skills/local" "$SANDBOX/data"
printf 'legacy skill\n' > "$CONFIG_DIR/skills/legacy-rtk/SKILL.md"
printf '#!/bin/sh\necho legacy plugin\n' > "$CONFIG_DIR/plugins/legacy-rtk.js"
printf 'secret-sentinel\n' > "$CONFIG_DIR/auth.json"
printf 'session-sentinel\n' > "$CONFIG_DIR/session.db"
printf '{"model": "opencode/gpt-5"}\n' > "$CONFIG_DIR/opencode.json"
printf 'data-credential-sentinel\n' > "$XDG_DATA_HOME/opencode/auth.json"
printf 'session-database-sentinel\n' > "$XDG_DATA_HOME/opencode/opencode.db"
printf '{"session": "fixture"}\n' > "$XDG_DATA_HOME/opencode/storage/sessions/session.json"
printf '{"pi": "settings"}\n' > "$SANDBOX/pi-source/agent/settings.json"
printf '{"pi": "skill"}\n' > "$SANDBOX/pi-source/agent/skills/local/SKILL.md"
# The Pi fixture mirrors the machine topology: a dotbot-managed symlink.
ln -s "$SANDBOX/pi-source/agent" "$HOME/.pi/agent"

# mock_opencode <bin-dir>: answers --version and `debug paths` from the fixture env.
mock_opencode() {
  mkdir -p "$1"
  cat >"$1/opencode" <<'EOF'
#!/bin/sh
if [ "$1" = "--version" ]; then printf 'opencode v1.15.13\n'; exit 0; fi
if [ "${1:-}" = debug ] && [ "${2:-}" = paths ]; then
  printf 'home       %s\n' "$HOME"
  printf 'data       %s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/opencode"
  printf 'cache      %s\n' "${XDG_CACHE_HOME:-$HOME/.cache}/opencode"
  printf 'config     %s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  printf 'state      %s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/opencode"
  printf 'tmp        %s\n' "${TMPDIR:-$HOME/tmp}"
  printf 'bin        %s/bin\n' "${XDG_CACHE_HOME:-$HOME/.cache}/opencode"
  printf 'log        %s/log\n' "${XDG_DATA_HOME:-$HOME/.local/share}/opencode"
  printf 'repos      %s/repos\n' "${XDG_DATA_HOME:-$HOME/.local/share}/opencode"
  printf 'db         %s/opencode.db\n' "${XDG_DATA_HOME:-$HOME/.local/share}/opencode"
  exit 0
fi
exit 1
EOF
  chmod +x "$1/opencode"
}
mock_opencode "$SANDBOX/bin"
export PATH="$SANDBOX/bin:$PATH"

# treecsum returns a stable per-node digest list for comparing before/after
# across locations (relative paths inside the tree, not absolute ones).
treecsum() { (cd "$1" && find . \( -type f -o -type d \) -print0 | sort -z | xargs -0 shasum -a 256 2>/dev/null); }
v1_snapshot=$(treecsum "$CONFIG_DIR")
data_snapshot=$(treecsum "$XDG_DATA_HOME/opencode")
pi_snapshot=$(treecsum "$SANDBOX/pi-source")
bin_snapshot=$(shasum -a 256 "$SANDBOX/bin/opencode")

run() { "$REPO/scripts/migrate-opencode.sh" "$@"; }
backup_count() { find "$1" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' '; }

# --- Existing-v1 migration: discover, record, back up before replacement ----
if run prepare >"$SANDBOX/out" 2>&1 && [ ! -e "$CONFIG_DIR" ]; then
  backup=$(find "$OPENCODE_MIGRATION_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | head -1)
  if [ -n "$backup" ] \
    && grep -q 'secret-sentinel' "$backup/config/auth.json" \
    && grep -q 'session-sentinel' "$backup/config/session.db"; then
    ok 'existing configuration is recoverably backed up'
  else
    fail 'backup contains config and machine-local state'
  fi
else
  fail 'prepare moves the old config only after successful backup'
fi

# The manifest records actual locations reported by the installed CLI, never
# guesses, and never credential contents.
if [ -n "${backup:-}" ] \
  && [ "$(stat -f %Lp "$backup/manifest")" = 600 ] \
  && grep -Fqx 'previous-version=opencode v1.15.13' "$backup/manifest" \
  && grep -Fqx "previous-executable=$SANDBOX/bin/opencode" "$backup/manifest" \
  && grep -Fqx "config-path=$CONFIG_DIR" "$backup/manifest" \
  && grep -Fqx 'discovery=opencode-debug-paths' "$backup/manifest" \
  && grep -Fqx "discovered-config-path=$CONFIG_DIR" "$backup/manifest" \
  && grep -Fqx "data-path=$XDG_DATA_HOME/opencode" "$backup/manifest" \
  && grep -Fqx "discovered-cache-path=$XDG_CACHE_HOME/opencode" "$backup/manifest" \
  && grep -Fqx "discovered-bin-cache-path=$XDG_CACHE_HOME/opencode/bin" "$backup/manifest" \
  && grep -Fqx "discovered-session-database=$XDG_DATA_HOME/opencode/opencode.db" "$backup/manifest" \
  && grep -Fqx "discovered-session-storage=$XDG_DATA_HOME/opencode/storage" "$backup/manifest" \
  && grep -Fqx "credential-store-config=$CONFIG_DIR/auth.json" "$backup/manifest" \
  && grep -Fqx "credential-store-data=$XDG_DATA_HOME/opencode/auth.json" "$backup/manifest" \
  && ! grep -q 'sentinel' "$backup/manifest"; then
  ok 'manifest records executable/version and discovered locations without credential contents'
else
  fail 'manifest records executable/version and discovered locations without credential contents'
fi

# The backup holds the whole old asset collection and none of the session tree.
if [ -f "$backup/config/skills/legacy-rtk/SKILL.md" ] \
  && [ -f "$backup/config/plugins/legacy-rtk.js" ] \
  && [ "0" = "$(find "$backup" -name 'opencode.db' | wc -l | tr -d ' ')" ]; then
  ok 'backup retains the full old collection and never touches the session tree'
else
  fail 'backup retains the full old collection and never touches the session tree'
fi

# A duplicate prepare must not replace or create another backup.
before=$(backup_count "$OPENCODE_MIGRATION_BACKUP_ROOT")
run prepare >/dev/null 2>&1
# Test rollback after simulating Dotbot's managed link.
ln -s "$OPENCODE_MIGRATION_MANAGED_CONFIG" "$CONFIG_DIR"
if run rollback >/dev/null 2>&1 && [ -d "$CONFIG_DIR" ] && [ ! -L "$CONFIG_DIR" ] \
  && [ "$v1_snapshot" = "$(treecsum "$CONFIG_DIR")" ] \
  && [ -d "$backup/config" ] && [ "$v1_snapshot" = "$(treecsum "$backup/config")" ]; then
  ok 'rollback restores the prior config and retains its verified backup'
else
  fail 'rollback restores the prior config and retains its verified backup'
fi

# Explicit restore from the first backup after another prepare cycle; the
# recorded executable selection is never touched.
mv "$CONFIG_DIR" "$SANDBOX/opencode.hold"
rest_rc=0
run restore "$backup" >/dev/null 2>&1 || rest_rc=1
if [ "$rest_rc" -eq 0 ] && [ -d "$CONFIG_DIR" ] && [ "$v1_snapshot" = "$(treecsum "$CONFIG_DIR")" ] \
  && [ -d "$backup/config" ] && [ "$v1_snapshot" = "$(treecsum "$backup/config")" ] \
  && [ "$bin_snapshot" = "$(shasum -a 256 "$SANDBOX/bin/opencode")" ]; then
  ok 'explicit restore copies the retained backup without consuming it and leaves the executable untouched'
else
  fail 'explicit restore copies the retained backup without consuming it and leaves the executable untouched'
fi

after=$(backup_count "$OPENCODE_MIGRATION_BACKUP_ROOT")
[ "$before" = "$after" ] && ok 'repeat prepare preserves the original backup' || fail 'repeat prepare preserves the original backup'

if [ "$data_snapshot" = "$(treecsum "$XDG_DATA_HOME/opencode")" ]; then
  ok 'fixture data credentials and sessions are byte-identical after migration steps'
else
  fail 'fixture data credentials and sessions are byte-identical after migration steps'
fi

# --- Backup failure must leave the active directory untouched ---------------
rm -rf "$CONFIG_DIR" "$SANDBOX/opencode.hold"
mkdir -p "$CONFIG_DIR"
printf 'keep-me\n' > "$CONFIG_DIR/keep"
export OPENCODE_MIGRATION_BACKUP_ROOT="$SANDBOX/not-a-directory/backups"
printf 'not a directory\n' > "$SANDBOX/not-a-directory"
if run prepare >"$SANDBOX/out" 2>&1; then
  fail 'backup failure aborts migration'
else
  [ -f "$CONFIG_DIR/keep" ] && ok 'backup failure leaves active config intact' || fail 'backup failure leaves active config intact'
fi

# --- Refuse an XDG path that the Dotbot link configuration does not manage ---
export XDG_CONFIG_HOME="$SANDBOX/custom-config"
mkdir -p "$XDG_CONFIG_HOME/opencode"
printf 'keep-custom-path\n' > "$XDG_CONFIG_HOME/opencode/keep"
if run prepare >"$SANDBOX/out" 2>&1; then
  fail 'custom XDG_CONFIG_HOME is rejected'
else
  [ -f "$XDG_CONFIG_HOME/opencode/keep" ] && ok 'custom XDG_CONFIG_HOME is rejected without touching it' || fail 'custom XDG_CONFIG_HOME is rejected without touching it'
fi
export XDG_CONFIG_HOME="$HOME/.config"

# --- Fresh setup commits; rollback invents nothing ---------------------------
export OPENCODE_MIGRATION_BACKUP_ROOT="$SANDBOX/data/backups"
rm -rf "$CONFIG_DIR"
if run prepare >"$SANDBOX/out" 2>&1; then
  fresh_backup=""
  while IFS= read -r candidate; do
    if grep -qx 'fresh-config=true' "$candidate/manifest" 2>/dev/null; then fresh_backup=$candidate; break; fi
  done < <(find "$OPENCODE_MIGRATION_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d)
  if [ -n "$fresh_backup" ]; then
    ln -s "$OPENCODE_MIGRATION_MANAGED_CONFIG" "$CONFIG_DIR"
    if run commit >/dev/null 2>&1 && [ -L "$CONFIG_DIR" ]; then
      ok 'fresh managed setup can be committed'
    else
      fail 'fresh managed setup can be committed'
    fi
    rm -f "$CONFIG_DIR"
    if run prepare >/dev/null 2>&1; then
      ln -s "$OPENCODE_MIGRATION_MANAGED_CONFIG" "$CONFIG_DIR"
      if run rollback >/dev/null 2>&1 && [ ! -e "$CONFIG_DIR" ]; then
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

# --- Failed activation leaves the working prior environment ------------------
# Recreate the pristine v1 fixture, then make the activation's `ln` fail.
rm -rf "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR/skills/legacy-rtk" "$CONFIG_DIR/plugins"
printf 'legacy skill\n' > "$CONFIG_DIR/skills/legacy-rtk/SKILL.md"
printf '#!/bin/sh\necho legacy plugin\n' > "$CONFIG_DIR/plugins/legacy-rtk.js"
printf 'secret-sentinel\n' > "$CONFIG_DIR/auth.json"
printf 'session-sentinel\n' > "$CONFIG_DIR/session.db"
printf '{"model": "opencode/gpt-5"}\n' > "$CONFIG_DIR/opencode.json"
printf 'installed-not-yet\n' > "$CONFIG_DIR/act-marker"
marked_snapshot=$(treecsum "$CONFIG_DIR")
mkdir -p "$SANDBOX/broken-ln"
printf '#!/bin/sh\nexit 1\n' > "$SANDBOX/broken-ln/ln"
chmod +x "$SANDBOX/broken-ln/ln"
PATH="$SANDBOX/broken-ln:$PATH" "$REPO/scripts/install-opencode.sh" >"$SANDBOX/failed-install.log" 2>&1
failed_rc=$?
if [ "$failed_rc" -ne 0 ] \
  && [ -f "$CONFIG_DIR/act-marker" ] \
  && [ "$marked_snapshot" = "$(treecsum "$CONFIG_DIR")" ] \
  && [ -f "$backup/config/auth.json" ] \
  && [ ! -e "$OPENCODE_MIGRATION_BACKUP_ROOT/.pending" ]; then
  ok 'failed activation rolls back to the working prior environment'
else
  fail "failed activation rolls back to the working prior environment (rc=$failed_rc)"
  tail -30 "$SANDBOX/failed-install.log" >&2
fi
rm -f "$CONFIG_DIR/act-marker" "$SANDBOX/broken-ln/ln"

# --- Existing-v1 activation replaces the whole active asset collection -------
backups_before_replace=$(backup_count "$OPENCODE_MIGRATION_BACKUP_ROOT")
if "$REPO/scripts/install-opencode.sh" >"$SANDBOX/replacement-install.log" 2>&1 \
  && [ -L "$CONFIG_DIR" ] && [ "$(readlink "$CONFIG_DIR")" = "$OPENCODE_MIGRATION_MANAGED_CONFIG" ] \
  && [ "0" = "$(find "$OPENCODE_MIGRATION_MANAGED_CONFIG/skills" "$OPENCODE_MIGRATION_MANAGED_CONFIG/plugins" -name 'legacy-rtk*' 2>/dev/null | wc -l | tr -d ' ')" ] \
  && [ -f "$backup/config/skills/legacy-rtk/SKILL.md" ] \
  && [ -f "$backup/config/plugins/legacy-rtk.js" ]; then
  ok 'activation replaces the old collection: no legacy skill or plugin merges into the active bundle; both survive in backup'
else
  fail 'activation replaces the old collection: no legacy skill or plugin merges into the active bundle; both survive in backup'
  tail -30 "$SANDBOX/replacement-install.log" >&2
fi
replaced_backups=$(backup_count "$OPENCODE_MIGRATION_BACKUP_ROOT")
[ "$replaced_backups" = $((backups_before_replace + 1)) ] && ok 'v1 migration creates its own new backup' || fail 'v1 migration creates its own new backup'

# Guarded re-running on the already-managed link must not duplicate backups.
if "$REPO/scripts/install-opencode.sh" >>"$SANDBOX/replacement-install.log" 2>&1 \
  && [ -L "$CONFIG_DIR" ] \
  && [ "$replaced_backups" = "$(backup_count "$OPENCODE_MIGRATION_BACKUP_ROOT")" ]; then
  ok 'guarded OpenCode activation is idempotent without duplicate backup'
else
  fail 'guarded OpenCode activation is idempotent without duplicate backup'
fi

# --- Repeated full invocation: new backups, never overwriting prior ones -----
cycles_before=$(backup_count "$OPENCODE_MIGRATION_BACKUP_ROOT")
rm -f "$CONFIG_DIR"
run prepare >/dev/null 2>&1
ln -s "$OPENCODE_MIGRATION_MANAGED_CONFIG" "$CONFIG_DIR"
run commit >/dev/null 2>&1
cycles_after=$(backup_count "$OPENCODE_MIGRATION_BACKUP_ROOT")
if [ "$cycles_after" = $((cycles_before + 1)) ] \
  && [ -f "$backup/manifest" ] \
  && grep -Fqx 'previous-version=opencode v1.15.13' "$backup/manifest" \
  && [ "$data_snapshot" = "$(treecsum "$XDG_DATA_HOME/opencode")" ]; then
  ok 'repeated invocation keeps prior backups and machine-local state intact'
else
  fail 'repeated invocation keeps prior backups and machine-local state intact'
fi

# --- Deploying the evolving managed bundle stays decoupled -------------------
# A bundle copy in the sandbox is evolved in place; migration/Bootstrap logic
# never inspects bundle internals (no footer/compaction coupling).
EVOLVE="$SANDBOX/evolve"
mkdir -p "$EVOLVE"
cp -R "$REPO/.config/opencode" "$EVOLVE/bundle"
if OPENCODE_MIGRATION_CONFIG="$EVOLVE/config" \
   OPENCODE_MIGRATION_MANAGED_CONFIG="$EVOLVE/bundle" \
   OPENCODE_MIGRATION_BACKUP_ROOT="$EVOLVE/backups" \
   "$REPO/scripts/install-opencode.sh" >"$EVOLVE/install.log" 2>&1 \
  && [ -L "$EVOLVE/config" ] && [ "$(readlink "$EVOLVE/config")" = "$EVOLVE/bundle" ] \
  && [ "1" = "$(backup_count "$EVOLVE/backups")" ]; then
  mkdir -p "$EVOLVE/bundle/skills/evolved-fixture"
  printf '# evolved fixture skill\n' > "$EVOLVE/bundle/skills/evolved-fixture/SKILL.md"
  if OPENCODE_MIGRATION_CONFIG="$EVOLVE/config" \
     OPENCODE_MIGRATION_MANAGED_CONFIG="$EVOLVE/bundle" \
     OPENCODE_MIGRATION_BACKUP_ROOT="$EVOLVE/backups" \
     "$REPO/scripts/install-opencode.sh" >>"$EVOLVE/install.log" 2>&1 \
    && [ -e "$EVOLVE/config/skills/evolved-fixture/SKILL.md" ] \
    && [ "1" = "$(backup_count "$EVOLVE/backups")" ]; then
    ok 'evolving managed bundle deploys through the entrypoint without a new backup or coupling'
  else
    fail 'evolving managed bundle deploys through the entrypoint without a new backup or coupling'
  fi
else
  fail 'evolving managed bundle initial deployment'
  tail -30 "$EVOLVE/install.log" >&2
fi

# --- Migration entrypoints are not coupled to plugin internals ---------------
if ! grep -qE 'dumb-zone|model-aware-compaction|plugins/' "$REPO/scripts/migrate-opencode.sh" \
  && ! grep -qE 'dumb-zone|model-aware-compaction|plugins/' "$REPO/scripts/install-opencode.sh"; then
  ok 'migration and Bootstrap scripts reference no plugin internals; evolving bundle stays decoupled'
else
  fail 'migration and Bootstrap scripts reference no plugin internals; evolving bundle stays decoupled'
fi

# --- Tracked-asset exclusions ------------------------------------------------
ignore_ok=1
for p in .config/opencode/auth.json .config/opencode/antigravity-accounts.json \
         .config/opencode/opencode.db .config/opencode/node_modules/x \
         .config/opencode/service.json .config/opencode/yarn.lock; do
  git -C "$REPO" check-ignore -q "$p" || ignore_ok=0
done
backup_root_in_repo=0
case $OPENCODE_MIGRATION_BACKUP_ROOT in "$REPO"|"$REPO"/*) backup_root_in_repo=1 ;; esac
case $EVOLVE in "$REPO"|"$REPO"/*) evolve_in_repo=1 ;; *) evolve_in_repo=0 ;; esac
if [ "$ignore_ok" -eq 1 ] && [ "$backup_root_in_repo" -eq 0 ] && [ "$evolve_in_repo" -eq 0 ]; then
  ok 'credential/session/cache/dependency paths and backup roots stay outside tracked assets'
else
  fail 'credential/session/cache/dependency paths and backup roots stay outside tracked assets'
fi

# --- Dotbot's generic pass never manages the OpenCode config -----------------
# Capture the current state (link, dir, or absent) and require it unchanged.
dotbot_state() {
  if [ -L "$CONFIG_DIR" ]; then printf 'link:%s' "$(readlink "$CONFIG_DIR")"
  elif [ -e "$CONFIG_DIR" ]; then printf 'dir'
  else printf 'absent'; fi
}
state_before_dotbot=$(dotbot_state)
if "$REPO/install" --only link >"$SANDBOX/install.log" 2>&1 && [ "$(dotbot_state)" = "$state_before_dotbot" ]; then
  ok 'Dotbot install leaves the separately managed OpenCode config untouched'
else
  fail 'Dotbot install leaves the separately managed OpenCode config untouched'
  tail -30 "$SANDBOX/install.log" >&2
fi

# --- Pi source, the recorded executable, and machine-local data untouched ---
# (Dotbot relinks ~/.pi/agent itself; the asserted invariant is that nothing we
# do mutates the Pi tree bytes, the executable, or the data tree.)
final_ok=1
[ "$pi_snapshot" = "$(treecsum "$SANDBOX/pi-source")" ] || { final_ok=0; fail 'the Pi fixture tree bytes changed'; }
[ "$bin_snapshot" = "$(shasum -a 256 "$SANDBOX/bin/opencode")" ] || { final_ok=0; fail 'the recorded executable bytes changed'; }
[ "$data_snapshot" = "$(treecsum "$XDG_DATA_HOME/opencode")" ] || { final_ok=0; fail 'fixture data credentials or sessions changed'; }
if [ "$final_ok" -eq 1 ]; then
  ok 'Pi tree, executable, and fixture data tree are byte-identical after the full matrix'
else
  fail 'Pi tree, executable, and fixture data tree are byte-identical after the full matrix'
fi

[ "$failures" -eq 0 ] || exit 1
printf 'PASS OpenCode migration contract tests\n'
