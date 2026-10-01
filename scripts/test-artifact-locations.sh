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
ALL_CLASSES=(glossary adrs board research explainers)

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
  for cls in "${ALL_CLASSES[@]}"; do
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

# --- 4: glossary write + consumer lookup at the recorded location, new-name discovery only ---
# Canonical glossary lookup post-contraction (ticket 0013): the new names ONLY.
# Legacy CONTEXT.md / CONTEXT-MAP.md are no longer discovery candidates: a legacy-only
# location is simply not found -- clean exit 1, nothing printed.
lookup_glossary() { # <dir> -> prints the first name found GLOSSARY.md | GLOSSARY-MAP.md, else exit 1
  local d="$1" cand
  for cand in GLOSSARY.md GLOSSARY-MAP.md; do
    [ -f "$d/$cand" ] && { printf '%s' "$cand"; return 0; }
  done
  return 1   # not found: legacy names are not candidates anymore
}

t_glossary_roundtrip() {
  # Expand phase: writes use the NEW names only; lookup prefers new names yet
  # still discovers legacy CONTEXT.md / CONTEXT-MAP.md (the fallback ticket 0013 removes).
  local s="$sandbox/glossary"
  make_code_repo "$s"
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  local cf="$CTXROOT/artloc__repo/.agents"
  write_locations_doc "$cf" "glossary: custom:$s/gloss-store/{branch}"
  local dest found
  dest="$(resolve_in "$s/repo" glossary)"
  [ "$dest" = "$s/gloss-store/main" ] || fail "glossary custom destination resolve: got '$dest'"
  mkdir -p "$dest"
  # consumer writes a glossary under the NEW name at the recorded location
  printf '# Repo\n\n## Language\n\n**Artifact location**: a term.\n' > "$dest/GLOSSARY.md"
  found="$(lookup_glossary "$dest" && true)"
  if [ "$found" = "GLOSSARY.md" ] && grep -q "Artifact location" "$dest/$found"; then
    ok "new-name glossary written at the recorded destination and found first (context-repo setup)"
  else
    fail "glossary new-name roundtrip lookup: got '${found:-nothing}'"
  fi
  # legacy-only fixture: post-contraction (ticket 0013) the old names are NOT discovered --
  # lookup fails cleanly (nothing on stdout, exit 1); nothing legacy-only resolves.
  local legacy="$s/legacy"
  mkdir -p "$legacy/main"
  printf '# Legacy Repo\n' > "$legacy/main/CONTEXT.md"
  printf '# Legacy Map\n' > "$legacy/main/CONTEXT-MAP.md"
  if found="$(lookup_glossary "$legacy/main")"; then
    fail "legacy-only glossary must not be discovered anymore: helper matched '$found'"
  elif [ -n "$found" ]; then
    fail "legacy-only lookup must fail silently, got output '$found'"
  else
    ok "legacy-only CONTEXT.md/CONTEXT-MAP.md: lookup fails clean (no match, exit 1)"
  fi
  # new-name control: the same lookup still resolves the new names
  mkdir -p "$legacy/newmain"
  printf '# New Name Repo\n' > "$legacy/newmain/GLOSSARY.md"
  found="$(lookup_glossary "$legacy/newmain" && true)"
  if [ "$found" = "GLOSSARY.md" ] && grep -q "New Name Repo" "$legacy/newmain/$found"; then
    ok "new-name GLOSSARY.md still discovered by the same helper"
  else
    fail "new-name control lookup: got '${found:-nothing}'"
  fi
  # branch-scoped: glossary written on feature lives at feature's recorded destination only
  ( cd "$s/repo" && git checkout -q feature )
  local fdest
  fdest="$(resolve_in "$s/repo" glossary)"
  [ "$fdest" = "$s/gloss-store/feature" ] || fail "feature glossary destination: got '$fdest'"
  mkdir -p "$fdest"
  printf '# Feature\n' > "$fdest/GLOSSARY-MAP.md"
  if [ -f "$fdest/GLOSSARY-MAP.md" ] && [ ! -f "$s/gloss-store/feature/CONTEXT.md" ]; then
    ok "branch-specific glossary honors the recorded destination, written under the new name"
  else
    fail "branch-scoped glossary map (feature): map found: $([ -f "$fdest/GLOSSARY-MAP.md" ] \
      && echo yes || echo no), legacy wrote: $([ -f "$s/gloss-store/feature/CONTEXT.md" ] && echo yes || echo no)"
  fi
  ( cd "$s/repo" && git checkout -q main )
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
    # in-repo seeding starts from the NEW name only (ticket 0013: a legacy CONTEXT.md alone
    # no longer triggers in-repo detection); a term is present to look up in the same file.
    printf '# Repo\n\n## Language\n\n**In-repo glossary term**: definition.\n' > "$s/repo/GLOSSARY.md"
    mkdir -p docs/adr; touch docs/adr/2026-01-01-x.md
  )
  local out
  out="$(resolve_in "$s/repo" glossary)"
  if [ "$out" = "$s/repo" ] && grep -q "In-repo glossary term" "$out/GLOSSARY.md"; then
    ok "in-repo context (no block, in-tree docs) glossary -> code repo root, new name detected + found"
  else
    fail "in-repo glossary: got '${out:-nothing}' - $([ -f "$s/repo/GLOSSARY.md" ] && echo file || echo missing)"
  fi
  out="$(resolve_in "$s/repo" board)"
  [ "$out" = "$s/repo" ] && ok "in-repo board -> code repo root" || fail "in-repo board: got '$out'"
  # recorded doc under docs/agents wins
  mkdir -p "$s/repo/docs/agents"
  printf 'glossary: custom:%s/gh/{branch}\n' "$s/bucket" > "$s/repo/docs/agents/artifact-locations.md"
  out="$(resolve_in "$s/repo" glossary)"
  [ "$out" = "$s/bucket/gh/main" ] && ok "in-repo recorded doc read from docs/agents" \
    || fail "in-repo recorded doc: got '$out'"
}

# --- 10: old/new name collision: new names win, nothing overwritten/merged/deleted -----------
t_glossary_new_name_wins() {
  local s="$sandbox/collision"
  make_code_repo "$s" collision
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  local cf="$CTXROOT/collision__repo/.agents"
  write_locations_doc "$cf" "glossary: custom:$s/gloss-store/{branch}"
  local dest found
  dest="$(resolve_in "$s/repo" glossary)"
  [ "$dest" = "$s/gloss-store/main" ] || fail "collision destination: got '$dest'"
  mkdir -p "$dest"
  printf '# New glossary content\n' > "$dest/GLOSSARY.md"
  printf '# Legacy glossary content\n' > "$dest/CONTEXT.md"
  # seam: Lookup_glossary (test helper, new-only candidates) must pick the new name's content
  found="$(lookup_glossary "$dest" && true)"
  if [ "$found" = "GLOSSARY.md" ] && grep -q "New glossary content" "$dest/$found"; then
    ok "collision: lookup resolves the new-name file's content (helper seam, new-only candidates)"
  else
    fail "collision lookup: got '${found:-nothing}'"
  fi
  # nothing overwritten, merged, or deleted: both files survive byte-identical
  if [ -f "$dest/CONTEXT.md" ] && [ -f "$dest/GLOSSARY.md" ] \
     && [ "$(cat "$dest/CONTEXT.md")" = "# Legacy glossary content" ] \
     && [ "$(cat "$dest/GLOSSARY.md")" = "# New glossary content" ]; then
    ok "collision: both old and new files still exist, contents untouched"
  else
    fail "collision mutated the seeded files: legacy=$([ -f "$dest/CONTEXT.md" ] && echo present || echo MISSING) new=$([ -f "$dest/GLOSSARY.md" ] && echo present || echo MISSING)"
  fi
  # seam: resolve-location.sh itself must not accept legacy-only detection (ticket 0013
  # deletes the legacy OR-arms). A repo with ONLY CONTEXT.md in-tree (no recorded block,
  # no GLOSSARY.md / docs/adr) must NOT resolve as in-repo context (i.e. to the code root).
  local lg="$sandbox/legonly" out
  make_code_repo "$lg" legonly
  printf '# Legacy only\n' > "$lg/repo/CONTEXT.md"
  out="$(resolve_in "$lg/repo" glossary)"
  if [ "$out" = "$CTXROOT/legonly__repo/main" ]; then
    ok "resolve-location.sh: legacy-only CONTEXT.md does not trigger in-repo context (context default)"
  else
    fail "resolve-location.sh still accepts legacy-only detection: glossary resolved to '$out' (expected context default $CTXROOT/legonly__repo/main)"
  fi
}

# --- 11: local boards: new .scratch layout resolves; legacy board names do not ----------------
t_board_local_layout() {
  local s="$sandbox/boards" out
  # new-layout repo: convention board (.scratch/<slug>/spec.md + issues/0001-x.md), with a
  # recorded Store: in-repo block like this dotfiles repo's AGENTS.md. Board discovery is
  # convention-level: assert what resolve-location.sh exposes -- the board destination.
  make_code_repo "$s" boardloc
  ( cd "$s/repo"
    cat > AGENTS.md <<'EOF'
## Agent skills

Store: in-repo
- Issues: local markdown files under `.scratch/`; no triage labels
EOF
    mkdir -p .scratch/boardloc/issues
    printf '# boardloc spec\n' > .scratch/boardloc/spec.md
    printf '## 0001-first\n\nopen\n' > .scratch/boardloc/issues/0001-first.md
    git add AGENTS.md && git commit -qm "record in-repo store"
    git checkout -qb feature2
  )
  out="$(resolve_in "$s/repo" board)"
  if [ "$out" = "$s/repo" ] && [ -f "$out/.scratch/boardloc/spec.md" ] \
     && [ -f "$out/.scratch/boardloc/issues/0001-first.md" ]; then
    ok "new-layout local board: board destination resolves to the repo root holding it (main)"
  else
    fail "new-layout board resolve on main: got '$out'"
  fi
  ( cd "$s/repo" && git checkout -q feature2 )
  out="$(resolve_in "$s/repo" board)"
  if [ "$out" = "$s/repo" ] && grep -q "boardloc spec" "$out/.scratch/boardloc/spec.md"; then
    ok "new-layout local board: same convention-level destination on feature2 (per-branch consistent)"
  else
    fail "new-layout board on feature2: got '$out'"
  fi
  ( cd "$s/repo" && git checkout -q main )

  # legacy board names (SPEC.md / MAP.md / tickets/) must NOT resolve: a repo with only
  # legacy board markers (no block, no new-name docs) keeps the context default --
  # seam: resolve-location.sh store detection (ticket 0013 deletes the legacy arms).
  local lg="$s/legboard"
  make_code_repo "$lg" legboard
  ( cd "$lg/repo"
    mkdir -p tickets
    printf '## 0001-old\n\nopen\n' > tickets/0001-old.md
    printf '# old spec\n' > SPEC.md
    printf '# old map\n' > MAP.md
  )
  out="$(resolve_in "$lg/repo" board)"
  if [ "$out" = "$CTXROOT/legboard__repo/main" ]; then
    ok "legacy board names (SPEC.md/MAP.md/tickets/) do not resolve as a board destination (context default)"
  else
    fail "legacy board still resolves: got '$out' (expected context default $CTXROOT/legboard__repo/main)"
  fi
  [ "$out" != "$lg/repo" ] || fail "legacy board resolved to the code repo root"
}

# --- 12: partial artifact-locations doc: recorded lines win, absent classes keep defaults ------
t_partial_locations_doc() {
  local s="$sandbox/partial"
  make_code_repo "$s" partial
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  local cf="$CTXROOT/partial__repo/.agents"
  # hand-written partial record: only glossary carries a line
  write_locations_doc "$cf" "glossary: code"
  local out cls
  out="$(resolve_in "$s/repo" glossary)"
  [ "$out" = "$s/repo" ] && ok "partial doc: class with a recorded line resolves to it (glossary: code)" \
    || fail "partial recorded class: got '$out'"
  for cls in adrs board research explainers; do
    out="$(resolve_in "$s/repo" "$cls")"; local rc=$?
    if [ "$rc" -eq 0 ] && [ "$out" = "$CTXROOT/partial__repo/main" ]; then
      ok "partial doc: absent class '$cls' resolves to its default without erroring"
    else
      fail "partial doc absent class '$cls': rc=$rc out='$out'"
    fi
  done
}

# --- 13: reruns are idempotent: byte-identical artifacts, same recorded destinations -----------
t_rerun_no_overwrite() {
  local s="$sandbox/rerun"
  make_code_repo "$s" rerun
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  local proj="$CTXROOT/rerun__repo"
  # seeded artifacts at their default destinations
  mkdir -p "$proj/main/research" "$proj/main/explainers" "$proj/main/docs/adr"
  printf '# rerun glossary\n' > "$proj/main/GLOSSARY.md"
  printf 'decision\n' > "$proj/main/docs/adr/2026-01-01-x.md"
  printf 'note\n' > "$proj/main/research/note.md"
  printf '<html>x</html>' > "$proj/main/explainers/x.html"
  local classes=("${ALL_CLASSES[@]}")
  local files=("$proj/main/GLOSSARY.md" "$proj/main/docs/adr/2026-01-01-x.md" \
               "$proj/main/research/note.md" "$proj/main/explainers/x.html")
  local hashes_before hashes_after i
  hashes_before="$(for f in "${files[@]}"; do shasum -a 256 "$f"; done)"
  # first pass: resolve every class + run the index step
  local r1=() r2=() cls same=true
  for cls in "${classes[@]}"; do r1+=("$(resolve_in "$s/repo" "$cls")"); done
  ( cd "$s/repo" && AGENT_CONTEXT_HOME="$CTXROOT" \
      bash "$repo_root/.pi/agent/skills/setup-context/ctx-index.sh" >/dev/null )
  # second pass: everything runs again
  for cls in "${classes[@]}"; do r2+=("$(resolve_in "$s/repo" "$cls")"); done
  ( cd "$s/repo" && AGENT_CONTEXT_HOME="$CTXROOT" \
      bash "$repo_root/.pi/agent/skills/setup-context/ctx-index.sh" >/dev/null )
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  hashes_after="$(for f in "${files[@]}"; do shasum -a 256 "$f"; done)"
  [ "$hashes_before" = "$hashes_after" ] \
    && ok "rerun: every seeded artifact byte-identical (no overwrite)" \
    || fail "rerun mutated seeded artifacts"
  for i in 0 1 2 3 4; do
    if [ "${r1[$i]}" = "${r2[$i]}" ]; then
      ok "rerun: class '${classes[$i]}' recorded destination stable across runs (${r1[$i]})"
    else
      same=false; fail "rerun: class ${classes[$i]} destination changed: '${r1[$i]}' -> '${r2[$i]}'"
    fi
  done
  $same || fail "rerun destinations diverged"
  # the index still lists the repo once per run (no duplicate rows)
  [ "$(grep -c 'rerun__repo' "$CTXROOT/INDEX.md" || true)" -eq 1 ] \
    && ok "rerun: ctx-index keeps one row per context repo (no duplicates)" \
    || fail "ctx-index duplicated rows for rerun__repo"
}

# --- 14: dirty code repo (untracked + modified) does not block resolution or mutate files ------
t_dirty_tree_resolution() {
  local s="$sandbox/dirty"
  make_code_repo "$s" dirty
  init_ctx_for_branch "$s/repo" main "$CTXROOT"
  local cf="$CTXROOT/dirty__repo/.agents"
  write_locations_doc "$cf" "glossary: context"
  # unrelated untracked + modified files -> the tree is dirty; the resolver asserts
  # nothing about a clean tree.
  ( cd "$s/repo"
    printf 'untracked scratch\n' > untracked.log
    printf 'modified\n' >> README.md
  )
  local hashes_before hashes_after st_before st_after out
  hashes_before="$(for f in "$s/repo/untracked.log" "$s/repo/README.md"; do shasum -a 256 "$f"; done)"
  st_before="$( cd "$s/repo" && git status --porcelain )"
  out="$(resolve_in "$s/repo" glossary)"; local rc=$?
  if [ "$rc" -eq 0 ] && [ "$out" = "$CTXROOT/dirty__repo/main" ]; then
    ok "dirty tree (untracked + modified): resolution still succeeds"
  else
    fail "dirty tree resolution: rc=$rc out='$out'"
  fi
  hashes_after="$(for f in "$s/repo/untracked.log" "$s/repo/README.md"; do shasum -a 256 "$f"; done)"
  st_after="$( cd "$s/repo" && git status --porcelain )"
  [ "$hashes_before" = "$hashes_after" ] \
    && ok "dirty tree: running the resolver changed no seeded/edited file's hash" \
    || fail "resolver mutated dirty-tree files"
  [ "$st_before" = "$st_after" ] \
    && ok "dirty tree: resolver leaves git status untouched (nothing staged or committed)" \
    || fail "resolver changed the dirty tree's git status"
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
t_glossary_new_name_wins
t_board_local_layout
t_partial_locations_doc
t_rerun_no_overwrite
t_dirty_tree_resolution
t_rules_in_config_home
t_in_repo
t_usage

echo "checks run; failed: $fail_count"
[ "$fail_count" -eq 0 ] || exit 1
