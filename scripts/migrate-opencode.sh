#!/usr/bin/env bash
# Guarded, local OpenCode configuration backup/restore used by Bootstrap.
set -euo pipefail
umask 077

ACTION=${1:-prepare}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOME_DIR=${HOME:?HOME must be set}
say() { printf 'OpenCode migration: %s\n' "$*" >&2; }
fail() { say "ERROR: $*"; exit 1; }

DEFAULT_CONFIG_DIR="$HOME_DIR/.config"
if [ -z "${OPENCODE_MIGRATION_CONFIG:-}" ] && [ -n "${XDG_CONFIG_HOME:-}" ]; then
  xdg_config=${XDG_CONFIG_HOME%/}
  [ "$xdg_config" = "$DEFAULT_CONFIG_DIR" ] || fail "Bootstrap links ~/.config; refusing custom XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
fi
CONFIG_DIR=${OPENCODE_MIGRATION_CONFIG:-${XDG_CONFIG_HOME:-$DEFAULT_CONFIG_DIR}/opencode}
MANAGED_CONFIG=${OPENCODE_MIGRATION_MANAGED_CONFIG:-$REPO_DIR/.config/opencode}
DATA_HOME=${XDG_DATA_HOME:-$HOME_DIR/.local/share}
STATE_HOME=${XDG_STATE_HOME:-$HOME_DIR/.local/state}
BACKUP_ROOT=${OPENCODE_MIGRATION_BACKUP_ROOT:-$DATA_HOME/dotfiles/opencode-backups}
PENDING="$BACKUP_ROOT/.pending"

read_pending() {
  [ -f "$PENDING" ] || return 1
  IFS= read -r PENDING_BACKUP < "$PENDING" || return 1
  [ -n "$PENDING_BACKUP" ] && [ -d "$PENDING_BACKUP" ]
}

remove_managed_link_or_fail() {
  if [ -L "$CONFIG_DIR" ]; then
    current=$(readlink "$CONFIG_DIR")
    [ "$current" = "$MANAGED_CONFIG" ] || fail "refusing to remove unexpected config symlink: $CONFIG_DIR -> $current"
    rm "$CONFIG_DIR"
  elif [ -e "$CONFIG_DIR" ]; then
    fail "refusing to overwrite unexpected config path: $CONFIG_DIR"
  fi
}

case "$ACTION" in
  prepare)
    mkdir -p "$(dirname "$CONFIG_DIR")" "$BACKUP_ROOT"
    read_pending && fail "unfinished migration has backup $PENDING_BACKUP; run rollback first"
    if [ -L "$CONFIG_DIR" ]; then
      current=$(readlink "$CONFIG_DIR")
      if [ "$current" = "$MANAGED_CONFIG" ]; then
        say 'managed configuration already active; no backup or replacement needed'
        exit 0
      fi
      fail "refusing to replace foreign config symlink: $CONFIG_DIR -> $current"
    fi
    if [ ! -e "$CONFIG_DIR" ]; then
      stamp=$(date '+%Y%m%d-%H%M%S')
      backup=$(mktemp -d "$BACKUP_ROOT/${stamp}.XXXXXX") || fail 'cannot create migration record'
      printf 'fresh-config=true\nconfig-path=%s\nbackup-created=%s\n' "$CONFIG_DIR" "$stamp" > "$backup/manifest"
      chmod 600 "$backup/manifest"
      printf '%s\n' "$backup" > "$PENDING"
      say 'no pre-existing config; prepared fresh setup'
      exit 0
    fi

    executable=$(command -v opencode || true)
    version=unavailable
    if [ -n "$executable" ]; then
      version=$("$executable" --version 2>/dev/null | head -1 || true)
      [ -n "$version" ] || version=unavailable
    fi

    # Discover the actual machine-local locations from the installed CLI
    # itself (`opencode debug paths`); nothing below is guessed. The evidence
    # source is recorded in the manifest, and no migration decision depends
    # on these rows: only the config directory is replaced.
    discovery=unavailable
    debug_paths=$("$executable" debug paths 2>/dev/null || true)
    [ -n "$debug_paths" ] && discovery=opencode-debug-paths
    discovered_row() { # <key> -> prints the tool-reported path (or empty); rc 0 always
      if [ "$discovery" = opencode-debug-paths ]; then
        awk -v key="$1" '$1==key {$1=""; sub(/^ +/, ""); print; exit}' <<< "$debug_paths"
      fi
      return 0
    }
    record_credential() { # <key> <path> -> manifest row; locations only, never contents
      if [ -e "$2" ]; then
        printf '%s=%s\n' "$1" "$2"
      else
        printf '%s=not-found\n' "$1"
      fi
    }
    data_row=$(discovered_row data)
    data_dir=$data_row
    [ -n "$data_dir" ] || data_dir=$DATA_HOME/opencode
    state_dir=$(discovered_row state)
    [ -n "$state_dir" ] || state_dir=$STATE_HOME/opencode

    stamp=$(date '+%Y%m%d-%H%M%S')
    backup=$(mktemp -d "$BACKUP_ROOT/${stamp}.XXXXXX") || fail 'cannot create backup directory'
    if ! cp -a "$CONFIG_DIR" "$backup/config.verify"; then
      rm -rf "$backup"
      fail 'configuration backup failed; active config was not intentionally changed'
    fi
    if ! diff -qr "$CONFIG_DIR" "$backup/config.verify" >/dev/null 2>&1; then
      rm -rf "$backup"
      fail 'configuration backup verification failed; active config is unchanged'
    fi
    {
      printf 'previous-version=%s\n' "$version"
      printf 'previous-executable=%s\n' "${executable:-unavailable}"
      printf 'config-path=%s\n' "$CONFIG_DIR"
      printf 'discovery=%s\n' "$discovery"
      printf 'data-path=%s\n' "$data_dir"
      printf 'state-path=%s\n' "$state_dir"
      if [ "$discovery" = opencode-debug-paths ]; then
        row=$(discovered_row config)
        [ -n "$row" ] && printf 'discovered-config-path=%s\n' "$row"
        row=$(discovered_row cache)
        [ -n "$row" ] && printf 'discovered-cache-path=%s\n' "$row"
        row=$(discovered_row bin)
        [ -n "$row" ] && printf 'discovered-bin-cache-path=%s\n' "$row"
        row=$(discovered_row db)
        [ -n "$row" ] && printf 'discovered-session-database=%s\n' "$row"
        [ -n "$data_row" ] && [ -d "$data_row/storage" ] && printf 'discovered-session-storage=%s\n' "$data_row/storage"
      fi
      # Record credential stores by location only; contents are never read.
      record_credential credential-store-config "$CONFIG_DIR/auth.json"
      record_credential credential-store-data "$data_dir/auth.json"
      printf 'backup-created=%s\n' "$stamp"
    } > "$backup/manifest"
    chmod 600 "$backup/manifest"
    # Keep a verified copy until the config directory is moved successfully.
    if ! mv "$CONFIG_DIR" "$backup/config"; then
      if [ ! -e "$CONFIG_DIR" ] && [ -d "$backup/config.verify" ]; then
        mv "$backup/config.verify" "$CONFIG_DIR"
      fi
      rm -rf "$backup"
      fail 'could not move old config after backup; restored it when possible'
    fi
    rm -rf "$backup/config.verify"
    printf '%s\n' "$backup" > "$PENDING"
    say "backed up previous config; executable version: $version"
    say "location discovery: $discovery (recorded in the backup manifest)"
    say "backup: $backup"
    ;;

  commit)
    if read_pending; then
      printf 'migration-status=activated\n' >> "$PENDING_BACKUP/manifest"
      rm -f "$PENDING"
      say "managed configuration activated; backup retained at $PENDING_BACKUP"
    else
      say 'nothing to commit'
    fi
    ;;

  rollback)
    if ! read_pending; then
      say 'no pending migration to roll back'
      exit 0
    fi
    remove_managed_link_or_fail
    mkdir -p "$(dirname "$CONFIG_DIR")"
    if [ -d "$PENDING_BACKUP/config" ]; then
      restore_tmp="${CONFIG_DIR}.restore.$$"
      [ ! -e "$restore_tmp" ] || fail "refusing to overwrite restore staging path: $restore_tmp"
      if ! cp -a "$PENDING_BACKUP/config" "$restore_tmp" || ! diff -qr "$PENDING_BACKUP/config" "$restore_tmp" >/dev/null 2>&1; then
        rm -rf "$restore_tmp"
        fail "could not verify rollback copy from $PENDING_BACKUP/config"
      fi
      if ! mv "$restore_tmp" "$CONFIG_DIR"; then
        rm -rf "$restore_tmp"
        fail "could not activate rollback copy from $PENDING_BACKUP/config"
      fi
      say "previous config restored from $PENDING_BACKUP; verified backup retained and OpenCode databases were not downgraded"
    elif grep -qx 'fresh-config=true' "$PENDING_BACKUP/manifest"; then
      say 'fresh setup rolled back; no prior config existed'
    else
      fail "backup config missing at $PENDING_BACKUP/config"
    fi
    rm -f "$PENDING"
    ;;

  restore)
    [ "$#" -eq 2 ] || fail 'usage: migrate-opencode.sh restore BACKUP_DIRECTORY'
    backup=$2
    [ -d "$backup/config" ] || fail "no backed-up config at $backup/config"
    remove_managed_link_or_fail
    mkdir -p "$(dirname "$CONFIG_DIR")"
    cp -a "$backup/config" "$CONFIG_DIR"
    say "configuration restored from $backup; no database downgrade attempted"
    ;;

  *) fail 'usage: migrate-opencode.sh {prepare|commit|rollback|restore BACKUP_DIRECTORY}' ;;
esac
