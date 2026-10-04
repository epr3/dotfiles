#!/usr/bin/env bash
set -uo pipefail
# check-parity.sh — pinned upstream parity seam.
#
# Compares the curated skill suite (.pi/agent/skills) against
# mattpocock/skills at the pinned commit, over complete retained directories:
# main SKILL.md, supporting references, templates, examples, credits, and
# invocation/agent metadata. Inventory rules distinguish retained upstream
# counterparts, the recorded retirements (ask-matt, implement-spec), the
# setup substitution, and the five local-only skills. Permitted departures
# exist only as entries in
# scripts/parity/exceptions/ naming the upstream counterpart, the exact
# change, and the rationale; whole-skill exclusions and pre-existing-fork
# exemptions are rejected, and a changed region without a recorded exact
# change fails even inside an otherwise approved file.
#
# Usage:
#   scripts/check-parity.sh --full              (default) whole-suite report; any drift fails
#   scripts/check-parity.sh <skill-dir>...      scoped run; a scoped pass does NOT imply a
#                                               suite pass: out-of-scope drift is reported,
#                                               not hidden. Scope failures exit 1.
#   scripts/check-parity.sh --is-exact-file <p> helper for check-prose.sh; exit 0 iff the
#                                               file is byte-identical upstream.

PARITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/parity"
# shellcheck source=parity/map.sh
source "$PARITY_DIR/map.sh"
shopt -s globstar

REPO_ROOT=$(parity_repo_root) || { echo "FAIL: parity: not in a git repository" >&2; exit 2; }
cd "$REPO_ROOT"

SCOPE=() PRETTY_SCOPE=''
case ${1-} in
  '') ;;
  --full) shift ;;
  --is-exact-file)
    [ $# -eq 2 ] || { echo 'FAIL: parity: --is-exact-file needs a path' >&2; exit 2; }
    parity_is_exact_file "$2"; exit $?
    ;;
  *)
    for a in "$@"; do
      [ -d ".pi/agent/skills/$a" ] || { echo "FAIL: parity: unknown or non-skill directory: $a" >&2; exit 2; }
      SCOPE+=("$a")
      PRETTY_SCOPE="${PRETTY_SCOPE:+$PRETTY_SCOPE, }$a"
    done
    ;;
esac
IS_SCOPED=${#SCOPE[@]}

FAILED=0
DRIFT_OUT_OF_SCOPE=0

in_scope() { # <skill dir name> -> rc 0 if covered by this run
  local d
  [ "$IS_SCOPED" -eq 0 ] && return 0
  for d in "${SCOPE[@]}"; do [ "$d" = "$1" ] && return 0; done
  return 1
}
fail()       { echo "FAIL: parity: $1: $2" >&2; FAILED=$((FAILED+1)); }
fail_scope() { # <skill-dir> <path> <reason>
  if in_scope "$1"; then
    fail "$2" "$3"
  else
    DRIFT_OUT_OF_SCOPE=$((DRIFT_OUT_OF_SCOPE+1))
    echo "DRIFT (out of scope): $2: $3" >&2
  fi
}

UP=$(mktemp -d "${TMPDIR:-/tmp}/parity-up.XXXXXX")
cleanup() { rm -rf "$UP"; }
trap cleanup EXIT
if ! parity_snapshot "$UP"; then
  echo 'FAIL: parity: pinned upstream snapshot unavailable; parity cannot be evaluated' >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Exception registry: one entry file per permitted departure, each carrying
# kind (substitution | inventory | metadata | packaging), an upstream
# counterpart path or glob, a local path/glob (or 'absent'), a rationale,
# and — for substitution entries — "- " list markers of the exact expected
# content. Markers are enforced against the real diff, so an unrecorded edit
# inside an approved file fails.

EXC_DIR=scripts/parity/exceptions
EX_KIND=() EX_UP=() EX_LOC=() EX_FILE=() EX_MARKERS=()

exc_frontmatter_field() { # <file> <field>
  awk 'BEGIN{c=0} /^---$/{c++;next} c==1{print}' "$1" \
    | (grep "^$2:" || true) | head -1 | sed "s/^$2:[[:space:]]*//"
}
exc_body_markers() { # <file>
  awk '/^---$/{c++;next} c==2{print}' "$1" | grep '^[[:space:]]*- ' \
    | sed 's/^[[:space:]]*-[[:space:]]*//' | grep -v '^$' || true
}

load_exceptions() {
  local f kind up loc body i=0 entries=0
  for f in "$EXC_DIR"/*.md; do
    [ -f "$f" ] || continue
    entries=$((entries+1))
    kind=$(exc_frontmatter_field "$f" kind)
    up=$(exc_frontmatter_field "$f" upstream)
    loc=$(exc_frontmatter_field "$f" local)
    if [ -z "$kind" ] || [ -z "$up" ] || [ -z "$loc" ]; then
      fail "$f" 'exception entry missing kind/upstream/local frontmatter'
      continue
    fi
    case $kind in
      substitution|metadata|inventory|packaging) ;;
      *) fail "$f" "exception entry has unknown kind '$kind'"; continue ;;
    esac
    if [ "$kind" = substitution ]; then
      case $up in
        */|'absent') fail "$f" "substitution entry must name a specific upstream file, not a directory ('$up')"; continue ;;
      esac
      case $loc in
        */|'absent') fail "$f" "substitution entry must name a specific local file, not a directory ('$loc')"; continue ;;
      esac
      [ -f "$UP/$up" ] || fail "$f" "substitution entry targets missing upstream file $up"
      [ -f "$REPO_ROOT/$loc" ] || fail "$f" "substitution entry targets missing local file $loc"
      body=$(exc_body_markers "$f")
      if [ -z "$body" ]; then
        fail "$f" 'substitution entry has no exact-change markers (list the lines expected in the local file)'
        continue
      fi
    fi
    if [ -z "$(exc_frontmatter_field "$f" rationale)" ]; then
      fail "$f" 'exception entry missing rationale'
      continue
    fi
    EX_KIND[i]=$kind; EX_UP[i]=$up; EX_LOC[i]=$loc; EX_FILE[i]=$f
    EX_MARKERS[i]=$(exc_body_markers "$f")
    i=$((i+1))
  done
  if [ "$entries" -eq 0 ]; then
    fail "$EXC_DIR" 'exception registry is empty; departures cannot be reviewed'
  fi
  return 0
}

# marker_in <markers multiline> <text> — any marker occurs as a substring.
marker_in() {
  local m text=$2
  while IFS= read -r m; do
    [ -z "$m" ] && continue
    case $text in *"$m"*) return 0 ;; esac
  done <<< "$1"
  return 1
}

# exc_cover <kinds comma-list> <upstream path or 'absent'> <local path or 'absent'> -> idx
exc_cover() {
  local idx kinds=$1 up=$2 loc=$3
  for idx in ${EX_UP[@]+"${!EX_UP[@]}"}; do
    case ",$kinds," in *",${EX_KIND[idx]},"*) ;; *) continue ;; esac
    pattern_match "${EX_UP[idx]}" "$up" || continue
    pattern_match "${EX_LOC[idx]}" "$loc" || continue
    echo "$idx"
    return 0
  done
  return 1
}

# pattern_match <pattern> <path or 'absent'>. A pattern ending in '/' is a
# directory rule: any file below it matches (matched against each ancestor).
pattern_match() {
  local pat=$1 path=$2
  if [ "$path" = absent ]; then
    [ "$pat" = absent ]
    return $?
  fi
  case $pat in
    'absent') return 1 ;;
    */)
      local d=${pat%/} anc="$path"
      while [[ $anc == */* ]]; do
        anc=${anc%/*}
        [[ $anc == $d ]] && return 0
      done
      return 1 ;;
    *) [[ $path == $pat ]] ;;
  esac
}

# verify_covered_file <skill dir> <entry idx> <upstream file> <local file path> — every
# changed line (+ local side / - upstream side) must itself carry one of that
# entry's exact-change markers: line-level accounting keeps an unrecorded edit
# beside the approved substitution failing even when hunks merge.
verify_covered_file() {
  local sk=$1 idx=$2 u=$3 l=$4 raw line ok_line
  raw=$(diff -U0 "$u" "$l" 2>/dev/null | tail -n +3)
  while IFS= read -r line; do
    case $line in
      '@@'*|'+++'*|'---'*) ;;
      +*) ok_line="${line#+}"; [ -z "$ok_line" ] && continue
           marker_in "${EX_MARKERS[idx]}" "$ok_line" \
             || fail_scope "$sk" "$l" "changed line lacks an exact-change marker: $ok_line"
           ;;
      -*) ok_line="${line#-}"; [ -z "$ok_line" ] && continue
           marker_in "${EX_MARKERS[idx]}" "$ok_line" \
             || fail_scope "$sk" "$l" "removed line lacks an exact-change marker: $ok_line"
           ;;
    esac
  done <<< "$raw"
  return 0
}

# ---------------------------------------------------------------------------
# Checks

check_inventory() {
  local expected actual d extra missing
  expected=$(parity_expected_dirs | sort)
  actual=$(find .pi/agent/skills -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort)
  extra=$(comm -13 <(echo "$expected") <(echo "$actual"))
  missing=$(comm -23 <(echo "$expected") <(echo "$actual"))
  report_extra() {
    fail '.pi/agent/skills' "directory not in the recorded inventory: $1 (unrecorded local-only skill or stray dir)"
  }
  report_missing() {
    fail '.pi/agent/skills' "recorded inventory member is missing: $1"
  }
  if [ "$IS_SCOPED" -eq 0 ]; then
    while IFS= read -r d; do [ -n "$d" ] && report_extra "$d"; done <<< "$extra"
    while IFS= read -r d; do [ -n "$d" ] && report_missing "$d"; done <<< "$missing"
  else
    # scoped runs validate scoped membership and report everything else as drift remains
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      if grep -qx "$d" <<< "$expected"; then continue; fi
      fail_scope "$d" ".pi/agent/skills" "directory not in the recorded inventory: $d"
    done <<< "$extra"
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      fail_scope "$d" '.pi/agent/skills' "recorded inventory member is missing: $d"
    done <<< "$missing"
  fi
  # Hard-accounted rules: the recorded retirements and the substituted
  # upstream entrypoint must never be installed (exceptions 0003, 0022, 0004).
  for d in "${PARITY_RETIRED[@]}" "$PARITY_SETUP_UPSTREAM"; do
    if [ -d ".pi/agent/skills/$d" ]; then
      fail ".pi/agent/skills/$d" 'recorded-retired/substituted skill present in the inventory'
    fi
  done
  return 0
}

FRONT_FILE_SET_KINDS='metadata,inventory,packaging'
SUBSTITUTION_KINDS='substitution'

# Packaging decision (exceptions 0002): flat packaging means no category
# index files and no nested packaging tree under the skill root.
check_packaging() {
  local p
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if [ -e "$p" ]; then
      fail "$p" "category index or nested packaging present; flat packaging recorded for the suite"
    fi
  done <<'PACKAGING_FLAT'
.pi/agent/skills/README.md
.pi/agent/skills/engineering
.pi/agent/skills/productivity
.pi/agent/skills/in-progress
.pi/agent/skills/misc
PACKAGING_FLAT
}

# Local-only retention (exceptions 0005): the recorded five must exist and not
# silently disappear.
check_local_only() {
  local d
  for d in "${PARITY_LOCAL_ONLY[@]}"; do
    [ -d ".pi/agent/skills/$d" ] || fail ".pi/agent/skills/$d" 'recorded local-only skill dir is missing'
  done
}

# Category index files must exist at the pinned snapshot — proves the pinned
# commit is the one they describe (garbage snapshot fails here too).
check_snapshot_matches_pin() {
  # fixtures that override the counterpart list don't ship upstream's index tree
  [ -n "${PARITY_UPSTREAM_SKILLS_SPEC:-}" ] && return 0
  local p
  for p in "${PARITY_CATEGORY_INDEXES[@]}"; do
    [ -f "$UP/$p" ] || fail "$UP" "pinned snapshot lacks $p: wrong revision materialized?"
  done
}

check_directories() {
  local sk udir ldir rel cov uplist llist
  declare -A FAM
  for entry in "${PARITY_UPSTREAM_SKILLS[@]}"; do FAM[${entry%=*}]=${entry#*=}; done
  for sk in "${!FAM[@]}"; do
    [ -d ".pi/agent/skills/$sk" ] || continue
    local quiet=0
    in_scope "$sk" || quiet=1
    udir="$UP/$(parity_upstream_rel "$sk")"
    ldir=".pi/agent/skills/$sk"
    if [ ! -d "$udir" ]; then
      fail_scope "$sk" "$ldir" 'upstream counterpart not found at the pinned snapshot'
      continue
    fi
    uplist=$({ cd "$udir" && find . -type f; } | sort)
    llist=$({ cd "$ldir" && find . -type f; } | sort)
    # missing locally: present upstream, absent here — pass only under a
    # recorded inventory/metadata/packaging decision
    while IFS= read -r rel; do
      [ -z "$rel" ] && continue
      rel=${rel#./}
      cov=$(exc_cover "$FRONT_FILE_SET_KINDS" "$(parity_upstream_rel "$sk")/$rel" "$ldir/$rel")
      if [ -n "$cov" ]; then
        [ "$quiet" = 1 ] || echo "ok  - parity: recorded decision covers missing $ldir/$rel"
      else
        fail_scope "$sk" "$ldir/$rel" "missing file vs pinned upstream: $rel"
      fi
    done <<< "$(comm -23 <(echo "$uplist") <(echo "$llist"))"
    # extra locally: absent upstream — pass only under a recorded decision
    while IFS= read -r rel; do
      [ -z "$rel" ] && continue
      rel=${rel#./}
      cov=$(exc_cover "$FRONT_FILE_SET_KINDS" absent "$ldir/$rel")
      if [ -n "$cov" ]; then
        [ "$quiet" = 1 ] || echo "ok  - parity: recorded decision covers extra $ldir/$rel"
      else
        fail_scope "$sk" "$ldir/$rel" 'extra file not in the pinned upstream (no recorded decision)'
      fi
    done <<< "$(comm -13 <(echo "$uplist") <(echo "$llist"))"
    # modified: byte-exact, or a recorded substitution with line-level markers
    while IFS= read -r rel; do
      [ -z "$rel" ] && continue
      rel=${rel#./}
      cov=$(exc_cover "$SUBSTITUTION_KINDS" "$(parity_upstream_rel "$sk")/$rel" "$ldir/$rel")
      if [ -n "$cov" ]; then
        verify_covered_file "$sk" "$cov" "$udir/$rel" "$ldir/$rel"
      elif cmp -s "$udir/$rel" "$ldir/$rel"; then
        [ "$quiet" = 1 ] || echo "ok  - parity: byte-exact $ldir/$rel"
      else
        fail_scope "$sk" "$ldir/$rel" 'modified vs pinned upstream (no recorded substitution entry)'
      fi
    done <<< "$(comm -12 <(echo "$uplist") <(echo "$llist"))"
  done
  return 0
}

# Relative supporting references must resolve. Drift is a reference that
# resolves at the pinned upstream but not locally; a reference unresolved on
# both sides is carried by upstream itself, so it stays informational and
# cannot hide a local break or fake one.
check_references() {
  local md dir link target sk updir ufile
  while IFS= read -r md; do
    dir=$(dirname "$md")
    sk=$(skill_dir_of "$md")
    case $sk in
      */*) continue ;;  # deeper than a skill dir (none exists)
    esac
    updir="$UP/$(parity_upstream_rel "$sk")"
    while IFS= read -r link; do
      [ -z "$link" ] && continue
      case $link in
        http://*|https://*|mailto:*|\#*) continue ;;
      esac
      target="${link%%#*}"
      [ -n "$target" ] || continue
      case $target in
        *.md|*.sh|*.yaml|*.txt) ;;
        *) continue ;;
      esac
      if [ ! -e "$dir/$target" ]; then
        local rel=${md#".pi/agent/skills/$sk/"}
        [ "$rel" = "$md" ] && { rel=${md#"$REPO_ROOT/.pi/agent/skills/$sk/"}; }
        ufile="$updir/$(dirname "$rel")/$target"
        if [ -e "$ufile" ]; then
          fail_scope "$sk" "$md" "resolves upstream but not locally: $link"
        else
          echo "info - parity: $md: reference unresolved both sides (upstream carries it): $link"
        fi
      fi
    done < <(grep -oE '\]\([^)]+' "$md" | sed -E 's/^\]\(//')
  done < <(find .pi/agent/skills -name '*.md' -type f)
  return 0
}

skill_dir_of() { # <path under .pi/agent/skills> -> dir name
  local p=${1#.pi/agent/skills/}
  printf '%s\n' "${p%%/*}"
}

# -- Run --
load_exceptions
check_snapshot_matches_pin
check_inventory
check_packaging
check_local_only
check_directories
check_references

if [ "$IS_SCOPED" -gt 0 ]; then
  if [ "$FAILED" -eq 0 ]; then
    echo "SCOPED PASS: parity green for [$PRETTY_SCOPE]"
    if [ "$DRIFT_OUT_OF_SCOPE" -gt 0 ]; then
      echo "SCOPED PASS does not imply a suite pass: $DRIFT_OUT_OF_SCOPE out-of-scope drift item(s) remain."
    fi
    exit 0
  fi
  echo "FAIL: parity scoped run: $FAILED scope failure(s) for [$PRETTY_SCOPE]" >&2
  exit 1
fi

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: pinned parity green (upstream $PARITY_PINNED_COMMIT)"
else
  echo "FAIL: parity: $FAILED drift item(s) vs upstream $PARITY_PINNED_COMMIT" >&2
fi
exit "$FAILED"
