# parity/map.sh — shared constants and helpers for the pinned parity seam.
# Sourced (do not execute). Consumers: scripts/check-parity.sh,
# scripts/check-prose.sh, scripts/test-check-parity.sh.

# Pinned upstream snapshot: do not upgrade as part of any other work.
PARITY_PINNED_COMMIT='d81f3a183412e71a5b1e84ca21bc1a35eea03a60'
PARITY_UPSTREAM_URL='https://github.com/mattpocock/skills.git'

# Upstream keeps skills under category families; the curated suite is flat.
# Upstream-derived counterparts, "skill=family". PARITY_UPSTREAM_SKILLS_SPEC
# (test escape hatch, like PARITY_UPSTREAM_DIR) overrides the list.
PARITY_UPSTREAM_SKILLS_SPEC="${PARITY_UPSTREAM_SKILLS_SPEC:-}"
if [ -n "$PARITY_UPSTREAM_SKILLS_SPEC" ]; then
  # shellcheck disable=SC2206
  PARITY_UPSTREAM_SKILLS=($PARITY_UPSTREAM_SKILLS_SPEC)
else
PARITY_UPSTREAM_SKILLS=(
  code-review=engineering codebase-design=engineering diagnosing-bugs=engineering
  domain-modeling=engineering grill-with-docs=engineering implement=engineering
  improve-codebase-architecture=engineering
  pr=engineering prototype=engineering research=engineering retro=engineering
  tdd=engineering to-spec=engineering to-tickets=engineering triage=engineering
  wayfinder=engineering wizard=engineering
  grill-me=productivity grilling=productivity handoff=productivity
  teach=productivity to-questionnaire=productivity wait-what=productivity
  writing-for-agents=productivity
)
fi

# Local-only skills: no upstream counterpart, provenance rules in exceptions/.
PARITY_LOCAL_ONLY=(setup-context merge-context offload-context rebase-context explain-diff)

# Recorded retirements: present at the pinned snapshot, dropped locally by
# explicit user request (exceptions 0003 and 0022). Recorded inventory
# decisions, not wording or behavior exceptions.
PARITY_RETIRED=(ask-matt implement-spec)

# Upstream's setup entrypoint does not run here: the local context-repo
# setup replaces it. One entrypoint, not two competing setup workflows.
PARITY_SETUP_UPSTREAM=setup-matt-pocock-skills
PARITY_SETUP_LOCAL=setup-context

# Upstream path of the category index files (dropped in flat packaging).
PARITY_CATEGORY_INDEXES=(
  'skills/engineering/README.md'
  'skills/productivity/README.md'
  'skills/in-progress/README.md'
  'skills/misc/README.md'
  'skills/deprecated/README.md'
)

parity_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

# Upstream snapshot path for an upstream-derived local skill dir name.
parity_upstream_rel() {
  local dir=$1 fam entry
  for entry in "${PARITY_UPSTREAM_SKILLS[@]}"; do
    local s=${entry%=*}
    if [ "$s" = "$dir" ]; then fam=${entry#*=}; printf 'skills/%s/%s\n' "$fam" "$dir"; return 0; fi
  done
  printf 'skills/%s/%s\n' engineering "$dir"
}

# Cache location for the pinned snapshot (fetched once, reused).
PARITY_CACHE="${PARITY_CACHE:-${TMPDIR:-/tmp}/dotfiles-parity}"

# Expected upstream commit used by snapshot verification. Defaults to the
# pinned commit; PARITY_UPSTREAM_DIR fixtures set it to their own HEAD (test
# escape hatch the same way PARITY_UPSTREAM_DIR is one).
PARITY_EXPECTED_COMMIT="${PARITY_EXPECTED_COMMIT:-$PARITY_PINNED_COMMIT}"

# parity_snapshot <out-dir> — materialize the pinned upstream tree into
# <out-dir> (parent must exist). Uses PARITY_UPSTREAM_DIR (a checkout of the
# pinned commit) instead of the network when set — test escape hatch only;
# production runs always go through the verified pinned fetch.
parity_snapshot() { # <out-dir>
  local out=$1
  if [ -n "${PARITY_UPSTREAM_DIR:-}" ]; then
    local want_pin
    want_pin=$(git -C "$PARITY_UPSTREAM_DIR" rev-parse HEAD 2>/dev/null || true)
    if [ "$want_pin" != "$PARITY_EXPECTED_COMMIT" ]; then
      echo "FAIL: parity: PARITY_UPSTREAM_DIR is at $want_pin, pinned commit required ($PARITY_PINNED_COMMIT)" >&2
      return 1
    fi
    cp -R "$PARITY_UPSTREAM_DIR/." "$out/"
    return 0
  fi
  local cache=$PARITY_CACHE
  mkdir -p "$cache"
  if [ ! -d "$cache/.git" ]; then
    git init -q "$cache"
    git -C "$cache" remote add origin "$PARITY_UPSTREAM_URL"
  fi
  if ! git -C "$cache" cat-file -e "$PARITY_PINNED_COMMIT" 2>/dev/null; then
    if ! git -C "$cache" fetch --quiet origin "$PARITY_PINNED_COMMIT"; then
      echo "FAIL: parity: cannot fetch pinned upstream $PARITY_PINNED_COMMIT (offline?)" >&2
      return 1
    fi
  fi
  git -C "$cache" archive "$PARITY_PINNED_COMMIT" | tar -x -C "$out"
  return 0
}

# parity_is_exact_file <repo-relative-or-abs path to a file under
# .pi/agent/skills> — exit 0 when the file is byte-identical to its pinned
# upstream counterpart. Local-only skill files and other paths are never
# exact. Prints nothing.
parity_is_exact_file() { # <repo-relative-or-abs path under .pi/agent/skills>
  local f=$1 root dir is_local_only=0 e upfile tmp rc
  root=$(parity_repo_root) || return 1
  f=${f#"$root"/}
  case $f in .pi/agent/skills/*) ;; *) return 1 ;; esac
  dir=${f#.pi/agent/skills/}; dir=${dir%%/*}
  case $dir in *'/'*) return 1 ;; esac  # stray path outside a skill dir
  for e in "${PARITY_LOCAL_ONLY[@]}"; do
    [ "$e" = "$dir" ] && is_local_only=1
  done
  [ "$is_local_only" = 0 ] || return 1
  tmp=$(mktemp -d) || return 1
  {
    mkdir -p "$tmp/up" &&
    parity_snapshot "$tmp/up" >/dev/null &&
    # preserve any nested path components below the skill dir
    upfile="$tmp/up/$(parity_upstream_rel "$dir")/${f#.pi/agent/skills/$dir/}" &&
    [ -f "$upfile" ] &&
    cmp -s "$upfile" "$root/$f"
  } >/dev/null 2>&1
  rc=$?
  rm -rf "$tmp"
  return $rc
}

parity_expected_dirs() {
  if [ -n "${PARITY_EXPECTED_DIRS:-}" ]; then
    printf '%s\n' "$PARITY_EXPECTED_DIRS"
    return 0
  fi
  local entry
  for entry in "${PARITY_UPSTREAM_SKILLS[@]}"; do echo "${entry%=*}"; done
  for e in "${PARITY_LOCAL_ONLY[@]}"; do echo "$e"; done
}

# parity_is_upstream_skill <skill-dir> — rc 0 when the dir has a pinned
# upstream counterpart. Its frontmatter (including invocation mode) is then
# owned by the parity seam: either byte-exact upstream or covered by a
# recorded substitution, so a prose/policy check must not demand a fork.
parity_is_upstream_skill() { # <skill-dir>
  local d=$1 entry
  for entry in "${PARITY_UPSTREAM_SKILLS[@]}"; do
    [ "${entry%=*}" = "$d" ] && return 0
  done
  return 1
}
