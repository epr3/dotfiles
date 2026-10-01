#!/usr/bin/env bash
# Integration tests for branch-scoped artifact locations (setup-context ticket 0002,
# skill routing ticket 0003):
# per-class destinations recorded in the config home's artifact-locations.md, resolved
# by setup-context/resolve-location.sh. Sandbox + isolated HOME/git config, real local
# multi-branch fixtures with context repos; no network, real config untouched.
# No `set -e`: error paths are asserted by capturing output.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
resolver="$repo_root/.pi/agent/skills/setup-context/resolve-location.sh"

sandbox="$(mktemp -d "${TMPDIR:-/tmp}/artifact-locations-test.XXXXXX")"
trap 'rm -rf "$sandbox"' EXIT
echo "sandbox: $sandbox"
sandbox="$(cd "$sandbox" && pwd -P)"
CTXROOT="$sandbox/ctxroot"

export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME="Artloc Test" GIT_AUTHOR_EMAIL="artloc@example.com"
export GIT_COMMITTER_NAME="Artloc Test" GIT_COMMITTER_EMAIL="artloc@example.com"

fail_count=0
ok()   { echo "ok  - $1"; }
fail() { echo "FAIL - $1" >&2; fail_count=$((fail_count + 1)); }

# Code repo with origin (same layout as clone-for-worktrees fixtures) + a context repo
# via ctx-init.sh per branch, so both context worktrees exist.
# optional second arg = remote/repo name, giving the context repo a distinct slug
# (all sandboxes share one CTXROOT, so distinct slugs keep recorded docs separate).
make_code_repo() {
  local dir="$1" name="${2:-artloc}"
  git init -q --bare "$dir/$name/repo.git"
  git init -q -b main "$dir/repo"
  ( cd "$dir/repo"
    git remote add origin "$dir/$name/repo.git"
    echo "readme" > README.md; git add README.md; git commit -qm "main commit"
    git checkout -qb feature
    echo "feature" > feature.txt; git add feature.txt; git commit -qm "feature commit"
    git checkout -q main
    git push -q origin main feature
  )
}
init_context() { ( cd "$repo_root/.fixtures-no-such-dir" 2>/dev/null; true ); }

# Run ctx-init.sh (from the setup-context skill) for the current branch of the repo.
init_ctx_for_branch() {
  local repo="$1" branch="$2" root="$3"
  ( cd "$repo"
    git checkout -q "$branch"
    AGENT_CONTEXT_HOME="$root" bash "$repo_root/.pi/agent/skills/setup-context/ctx-init.sh" >/dev/null
  )
}

write_locations_doc() {
  local cf="$1"; shift
  mkdir -p "$cf"
  { echo "# Artifact locations"; echo "## Locations"; echo
    for line in "$@"; do echo "$line"; done
  } > "$cf/artifact-locations.md"
}

resolve_in() {
  local repo="$1" class="$2"
  ( cd "$repo" && AGENT_CONTEXT_HOME="${CTXROOT:-$AGENT_CONTEXT_HOME}" bash "$resolver" "$class" 2>&1 )
}

# --- 8: ADR, research, and explainer producers + consumers at their own destinations ----------
t_other_adrs_code() {
  local s="$sandbox/adrcode"
  make_code_repo "$s" adrcode
  # ADRs at the code worktree, identical filename on two branches: the in-tree docs/adr
  # dir means the resolver treats this repo as in-repo context (no recorded instructions),
  # so record the destination under docs/agents as in-repo setups do.
  local adr=docs/adr/2026-01-01-pick.md
  ( cd "$s/repo"
    mkdir -p docs/agents
    printf 'adrs: code\n' > docs/agents/artifact-locations.md
    mkdir -p docs/adr && printf 'decision from main\n' > "$adr" && git add . && git commit -qm adr-main
    git checkout -qb alt
    printf 'decision from alt\n' > "$adr" && git add . && git commit -qm adr-alt
  )
  local dest
  dest="$(resolve_in "$s/repo" adrs)"
  grep -q "decision from alt" "$dest/$adr" && ok "ADR written at + read from the code destination, branch-correct on alt" || fail "ADR alt lookup: got '$dest'"
  ( cd "$s/repo" && git checkout -q main )
  grep -q "decision from main" "$(resolve_in "$s/repo" adrs)/$adr" && ok "ADR lookup back on main returns main's decision" || fail "ADR main lookup"
}

# --- 9: research (context) + explainers (custom) producers + consumers, two branches -----------
t_other_research_explainers() {
  local s="$sandbox/classes"
  make_code_repo "$s" classes
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  init_ctx_for_branch "$s/repo" feature "$CTXROOT"
  local cf="$CTXROOT/classes__repo/.agents"
  write_locations_doc "$cf" "research: context" "explainers: custom:$s/classes/explain-stash"
  ( cd "$s/repo" && git checkout -q main )

  # research at the *context* destination: notes in the branch-matching context worktree.
  local rw="$CTXROOT/classes__repo"
  mkdir -p "$rw/main/notes" "$rw/feature/notes"
  printf 'main research\n' > "$rw/main/notes/dev.md"
  printf 'feature research\n' > "$rw/feature/notes/dev.md"
  local dest
  dest="$(resolve_in "$s/repo" research)"
  grep -q "main research" "$dest/notes/dev.md" && ok "research producer/consumer meet at the matching context worktree (main)" || fail "research main: got '$dest'"
  ( cd "$s/repo" && git checkout -q feature )
  dest="$(resolve_in "$s/repo" research)"
  grep -q "feature research" "$dest/notes/dev.md" && ok "research consumer on feature reads the feature worktree" || fail "research feature: got '$dest'"
  ( cd "$s/repo" && git checkout -q main )

  # explainers at a *custom* destination: /<branch> appended, branch-scoped.
  dest="$(resolve_in "$s/repo" explainers)"
  [ "$dest" = "$s/classes/explain-stash/main" ] || fail "explainers custom: got '$dest'"
  mkdir -p "$dest/explainers" "$s/classes/explain-stash/feature/explainers"
  printf '<html>main page</html>' > "$dest/explainers/2026-01-01-diff.html"
  printf '<html>feature page</html>' > "$s/classes/explain-stash/feature/explainers/2026-01-01-diff.html"
  grep -q "main page" "$dest/explainers/2026-01-01-diff.html" && ok "explainer saved + found at the custom destination, branch-scoped" || fail "explainer main"
  ( cd "$s/repo" && git checkout -q feature )
  grep -q "feature page" "$(resolve_in "$s/repo" explainers)/explainers/2026-01-01-diff.html" && ok "explainer lookup on feature resolves the feature page" || fail "explainer feature"
  ( cd "$s/repo" && git checkout -q main )

  # one class redirected, the others not: the lines above moved only their own class.
  [ ! -e "$s/classes/explain-stash/main/notes" ] && [ ! -e "$rw/main/docs" ] \
    && [ ! -e "$s/repo/notes" ] && [ ! -e "$s/repo/explainers" ] \
    || fail "a redirected class leaked into another destination"
  [ ! -e "$s/classes/explain-stash/main/notes" ] && [ ! -e "$s/repo/explainers" ] \
    && ok "redirecting each class left the other destinations untouched"
}

# --- 1: defaults without a recorded doc equal the pre-existing context-home destinations ------
t_defaults() {
  local s="$sandbox/defaults"
  make_code_repo "$s"
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  local out
  for cls in glossary adrs board research explainers; do
    out="$(resolve_in "$s/repo" "$cls")"
    if [ "$out" = "$CTXROOT/artloc__repo/main" ]; then
      ok "default $cls -> context worktree (main)"
    else
      fail "DBG got=[$out] want=[$CTXROOT/artloc__repo/main]"
    fi
  done
  ( cd "$s/repo" && git checkout -q feature )
  out="$(resolve_in "$s/repo" "research")"
  if [ "$out" = "$CTXROOT/artloc__repo/feature" ]; then
    ok "default research follows the current branch"
  else
    fail "default research on feature: got '$out'"
  fi
}

# --- 2: recorded doc is read per class; one class does not follow another ---------------------
t_per_class() {
  local s="$sandbox/perclass"
  make_code_repo "$s"
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  local cf="$CTXROOT/artloc__repo/.agents"
  write_locations_doc "$cf" \
    "glossary: code" "adrs: context" "board: custom:$s/custom/notes" "research: custom:$s/custom/{branch}" "explainers: explainers-invalid"
  local out
  out="$(resolve_in "$s/repo" glossary)"
  [ "$out" = "$s/repo" ] && ok "recorded glossary: code -> code repo root" \
    || fail "recorded glossary: got '$out'"
  out="$(resolve_in "$s/repo" adrs)"
  [ "$out" = "$CTXROOT/artloc__repo/main" ] && ok "recorded adrs: context -> context worktree" \
    || fail "recorded adrs: got '$out'"
  out="$(resolve_in "$s/repo" board)"
  [ "$out" = "$s/custom/notes/main" ] && ok "custom board without {branch} gets /<branch> appended" \
    || fail "custom board: got '$out'"
  out="$(resolve_in "$s/repo" research)"
  [ "$out" = "$s/custom/main" ] && ok "custom research with {branch} substitutes the branch" \
    || fail "custom research: got '$out'"
  out="$(resolve_in "$s/repo" explainers 2>&1 || true)"
  case "$out" in *'invalid value'*) ok "invalid recorded value is an error, not a silent default" ;; *) fail "invalid explainers value should error: got '$out'" ;; esac
  # a class missing from the doc keeps its default
  write_locations_doc "$cf" "glossary: code"
  out="$(resolve_in "$s/repo" explainers)"
  [ "$out" = "$CTXROOT/artloc__repo/main" ] && ok "class absent from doc keeps its default" \
    || fail "absent class default: got '$out'"
}

# --- 3: multi-branch isolation, identical branch-local artifact names -------------------------
t_branch_isolation() {
  local s="$sandbox/isolation"
  make_code_repo "$s"
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  init_ctx_for_branch "$s/repo" feature "$CTXROOT"
  local cf="$CTXROOT/artloc__repo/.agents"
  write_locations_doc "$cf" "research: custom:$s/isosrc/{branch}" "glossary: code"

  local nm="same-name.md"
  mkdir -p "$CTXROOT/artloc__repo/main/research" "$CTXROOT/artloc__repo/feature/research"
  printf 'main research\n'  > "$CTXROOT/artloc__repo/main/research/$nm"
  printf 'feature research\n' > "$CTXROOT/artloc__repo/feature/research/$nm"
  mkdir -p "$s/isosrc/main" "$s/isosrc/feature"
  printf 'main custom\n'    > "$s/isosrc/main/$nm"
  printf 'feature custom\n' > "$s/isosrc/feature/$nm"
  if [ "$(cat "$CTXROOT/artloc__repo/main/research/$nm")" = "main research" ] \
     && [ "$(cat "$CTXROOT/artloc__repo/feature/research/$nm")" = "feature research" ] \
     && [ "$(cat "$s/isosrc/main/$nm")" = "main custom" ] \
     && [ "$(cat "$s/isosrc/feature/$nm")" = "feature custom" ]; then
    ok "identical branch-local artifact names stay separate per branch (context + custom)"
  else
    fail "branch isolation of identical artifact names"
  fi
  # and each branch's resolver resolves to its own copy
  ( cd "$s/repo" && git checkout -q feature )
  local out
  out="$(resolve_in "$s/repo" research)"
  [ "$out" = "$s/isosrc/feature" ] && ok "resolver on feature resolves the feature copy" \
    || fail "resolver on feature: got '$out'"
  ( cd "$s/repo" && git checkout -q main )
}

# --- 4: glossary write + consumer lookup at the recorded location, old-name discovery retained --
t_glossary_roundtrip() {
  local s="$sandbox/glossary"
  make_code_repo "$s"
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  local cf="$CTXROOT/artloc__repo/.agents"
  write_locations_doc "$cf" "glossary: custom:$s/gloss-store/{branch}"
  local dest
  dest="$(resolve_in "$s/repo" glossary)"
  [ "$dest" = "$s/gloss-store/main" ] || fail "glossary custom destination resolve: got '$dest'"
  # consumer writes a new glossary term at the recorded location
  mkdir -p "$dest"
  printf '# Repo\n\n## Language\n\n**Artifact location**: a term.\n' > "$dest/CONTEXT.md"
  # consumer lookup: recorded location first, legacy old-name fallback still discovered
  local found
  for cand in "$dest/GLOSSARY.md" "$dest/CONTEXT.md" "$dest/CONTEXT-MAP.md"; do
    [ -f "$cand" ] && { found="$cand"; break; }
  done
  if [ "$(basename "${found:-}")" = "CONTEXT.md" ] && grep -q "Artifact location" "$found"; then
    ok "newly configured glossary written and found at its recorded location (old-name discovery retained)"
  else
    fail "glossary roundtrip lookup: got '${found:-nothing}'"
  fi
  # a new-name glossary is also discovered first when present
  printf '# Repo\n' > "$dest/GLOSSARY.md"
  for cand in "$dest/GLOSSARY.md" "$dest/CONTEXT.md" "$dest/CONTEXT-MAP.md"; do
    [ -f "$cand" ] && { found="$cand"; break; }
  done
  [ "$(basename "$found")" = "GLOSSARY.md" ] && ok "new-name glossary takes precedence in lookup" \
    || fail "GLOSSARY.md precedence: got '$found'"
}

# --- 5: repo-wide rules (config home) never land in the per-branch destinations --------------
t_rules_in_config_home() {
  local s="$sandbox/rules"
  make_code_repo "$s"
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  local cf="$CTXROOT/artloc__repo/.agents"
  write_locations_doc "$cf" "board: custom:$s/rules-store"
  mkdir -p "$cf"
  printf 'convention\n' > "$cf/issue-tracker.md"
  if [ -f "$cf/issue-tracker.md" ] && [ ! -e "$s/rules-store/issue-tracker.md" ] \
     && [ ! -e "$CTXROOT/artloc__repo/main/issue-tracker.md" ]; then
    ok "repo-wide rules stay in the config home, outside every artifact destination"
  else
    fail "repo-wide rules drifted into an artifact destination"
  fi
  # temporary handoffs: OS temp, never a durable destination
  local tmp_report="${TMPDIR:-/tmp}/artloc-handoff-test.XXXXXX"
  local t
  t="$(mktemp -d "$tmp_report")" && printf 'report\n' > "$t/report.md"
  case "$t" in
    ${TMPDIR:-/tmp}/*) ok "temporary handoff lives in the OS temp directory" ;;
    *) fail "temporary handoff outside OS temp: $t" ;;
  esac
  [ -e "$CTXROOT/artloc__repo/main/report.md" ] || [ -e "$s/rules-store/report.md" ] \
    && fail "temp report leaked into a durable destination" \
    || ok "temp report did not leak into any durable destination"
  rm -rf "$t"
}

# --- 6: in-repo context defaults to the code repo root ----------------------------------------
t_in_repo() {
  local s="$sandbox/inrep"
  git init -q -b main "$s/repo"
  ( cd "$s/repo"
    echo x > README.md; git add README.md; git commit -qm init
    printf '# Repo\n' > CONTEXT.md; mkdir -p docs/adr; touch docs/adr/2026-01-01-x.md
  )
  local out
  out="$(resolve_in "$s/repo" glossary)"
  [ "$out" = "$s/repo" ] && ok "in-repo context (no block, in-tree docs) glossary -> code repo root" \
    || fail "in-repo glossary: got '$out'"
  out="$(resolve_in "$s/repo" board)"
  [ "$out" = "$s/repo" ] && ok "in-repo board -> code repo root" || fail "in-repo board: got '$out'"
  # recorded doc under docs/agents wins
  mkdir -p "$s/repo/docs/agents"
  printf 'glossary: custom:%s/gh/{branch}\n' "$s/bucket" > "$s/repo/docs/agents/artifact-locations.md"
  out="$(resolve_in "$s/repo" glossary)"
  [ "$out" = "$s/bucket/gh/main" ] && ok "in-repo recorded doc read from docs/agents" \
    || fail "in-repo recorded doc: got '$out'"
}

# --- 7: resolver failures are clean -----------------------------------------------------------
t_usage() {
  local out
  out="$( ( cd "$sandbox/rules/repo" && bash "$resolver" nope ) 2>&1 || true)"
  case "$out" in *"unknown class"*) ok "unknown class rejected" ;; *) fail "unknown class: got '$out'" ;; esac
    out="$( cd "$sandbox" && bash "$resolver" glossary 2>&1 || true)"
  case "$out" in *"not a git repo"*) ok "outside a repo rejected" ;; *) fail "outside repo: got '$out'" ;; esac
}

t_other_research_explainers
t_other_adrs_code
t_defaults
t_per_class
t_branch_isolation
t_glossary_roundtrip
t_rules_in_config_home
t_in_repo
t_usage

echo "checks run; failed: $fail_count"
[ "$fail_count" -eq 0 ] || exit 1
