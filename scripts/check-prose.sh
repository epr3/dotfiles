#!/usr/bin/env bash
set -euo pipefail
# check-prose.sh — skill suite policy + base-ref validation seam.
# Usage: check-prose.sh [base-ref]   (defaults to "main")

BASE_REF="${1:-main}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "FAIL: not in a git repository" >&2
  exit 1
}
FAILED=0

cd "$REPO_ROOT"

fail()  { echo "FAIL: $1: $2" >&2; FAILED=1; }
info()  { echo "INFO: $1"; }

# Extract YAML frontmatter (between first two --- markers).
get_frontmatter() {
  awk 'BEGIN{c=0} /^---$/{c++;next} c==1{print}' "$1"
}

# Get a field value from frontmatter text. Empty if absent.
get_field() {
  echo "$1" | (grep "^${2}:" || true) | head -1 | sed "s/^${2}:[[:space:]]*//"
}

# UTF-8 byte sequences.
EM_DASH=$'\xe2\x80\x94'    # U+2014
MARK_1=$'\xe2\x9d\x93'      # U+2753 ❓
MARK_2=$'\xe2\x9e\xa1'      # U+27A1 ➡

# -- Check 1: no U+2014 em dash in skill prose --
check_em_dash() {
  while IFS= read -r f; do
    if grep -qF "$EM_DASH" "$f"; then
      fail "$f" "contains U+2014 em dash (check 1)"
    fi
  done < <(find .pi/agent/skills -name '*.md' -type f)
}

# -- Check 2: protected question-format marks retained vs base --
check_protected_marks() {
  local all_files
  all_files=$({
    find .pi/agent/skills -name '*.md' -type f
    git ls-tree -r --name-only "$BASE_REF" -- .pi/agent/skills/ 2>/dev/null | grep '\.md$' || true
  } | sort -u)

  while IFS= read -r f; do
    [ -z "$f" ] && continue
    local base_has=false work_has=false

    local base_content
    base_content=$(git show "$BASE_REF:$f" 2>/dev/null) || true
    if echo "$base_content" | grep -qE "${MARK_1}|${MARK_2}"; then
      base_has=true
    fi

    if [ -f "$f" ] && grep -qE "${MARK_1}|${MARK_2}" "$f"; then
      work_has=true
    fi

    if [ "$base_has" = true ] && [ "$work_has" = false ]; then
      fail "$f" "lost protected question-format marks present at base ref (check 2)"
    fi
  done <<< "$all_files"
}

# -- Check 3a: skill frontmatter validity --
check_skill_frontmatter() {
  while IFS= read -r f; do
    local dir
    dir=$(basename "$(dirname "$f")")
    local fm
    fm=$(get_frontmatter "$f")

    if [ -z "$fm" ]; then
      fail "$f" "missing frontmatter (check 3)"
      continue
    fi

    local name_value desc_value
    name_value=$(get_field "$fm" "name")
    desc_value=$(get_field "$fm" "description")

    if [ -z "$name_value" ]; then
      fail "$f" "frontmatter missing 'name' field (check 3)"
    elif [ "$name_value" != "$dir" ]; then
      fail "$f" "frontmatter name '$name_value' does not match directory '$dir' (check 3)"
    fi

    if [ -z "$desc_value" ]; then
      fail "$f" "frontmatter missing 'description' field (check 3)"
    fi
  done < <(find .pi/agent/skills -name 'SKILL.md' -type f)
}

# -- Check 3b: local ticket schema validity --
check_ticket_schema() {
  while IFS= read -r f; do
    local fm
    fm=$(get_frontmatter "$f")

    if [ -z "$fm" ]; then
      fail "$f" "missing frontmatter (check 3)"
      continue
    fi

    local status type mode parent blocked_by
    status=$(get_field "$fm" "status")
    type=$(get_field "$fm" "type")
    mode=$(get_field "$fm" "mode")
    parent=$(get_field "$fm" "parent")
    blocked_by=$(get_field "$fm" "blocked_by")

    [ -z "$status" ]    && fail "$f" "frontmatter missing 'status' (check 3)"
    [ -z "$parent" ]    && fail "$f" "frontmatter missing 'parent' (check 3)"
    [ -z "$blocked_by" ] && fail "$f" "frontmatter missing 'blocked_by' (check 3)"

    if [ -n "$mode" ]; then
      # Unified schema: type is a kind, mode is HITL|AFK.
      case "$type" in
        research|prototype|grilling|task) ;;
        *) fail "$f" "unified schema: invalid type '$type' (check 3)"; continue ;;
      esac
      case "$mode" in
        HITL|AFK) ;;
        *) fail "$f" "unified schema: invalid mode '$mode' (check 3)"; continue ;;
      esac
      case "$type:$mode" in
        research:AFK|prototype:HITL|grilling:HITL|task:HITL|task:AFK) ;;
        *) fail "$f" "unified schema: invalid kind/mode pair $type/$mode (check 3)" ;;
      esac
    elif [ -n "$type" ]; then
      # Legacy schema: type is HITL|AFK (read as mode, kind defaults to task).
      case "$type" in
        HITL|AFK) info "$f legacy schema: type '$type' read as mode, kind defaults to 'task'" ;;
        *) fail "$f" "legacy schema: type must be HITL or AFK, got '$type' (check 3)" ;;
      esac
    else
      fail "$f" "frontmatter missing both 'type' and 'mode' (check 3)"
    fi
  # New local-board layout only (spec.md / map.md / issues/) — no legacy
  # tickets/ discovery remains (removed with the old-name contract).
  done < <(find .scratch -path '*/issues/*.md' -type f)
}

# -- Check 4: executable handoffs target model-invoked skills --
check_handoffs() {
  while IFS= read -r f; do
    while IFS=: read -r line_num line; do
      # Verb phrase must precede the backticked name.
      local before
      before=$(echo "$line" | sed 's/`.*//')
      if echo "$before" | grep -qiE '(^|[^a-z])(use|load|route|hand)([^a-z]|$)'; then
        local names
        names=$(echo "$line" | grep -oE '`[^`]+`[[:space:]]+skill' | sed -E 's/`([^`]+)`[[:space:]]+skill/\1/')
        while IFS= read -r skill_name; do
          [ -z "$skill_name" ] && continue
          local skill_file=".pi/agent/skills/$skill_name/SKILL.md"
          if [ -f "$skill_file" ] && grep -q '^disable-model-invocation: true' "$skill_file"; then
            fail "$f:$line_num" "executable handoff to user-invoked skill \`$skill_name\` (check 4)"
          fi
        done <<< "$names"
      fi
    done < <(grep -n -E '`[^`]+`[[:space:]]+skill' "$f" || true)
  done < <(find .pi/agent/skills -name '*.md' -type f)
}

# Skills whose removal the upstream-sync spec records. Removing one is a
# recorded inventory change, not an unrecorded invocation-mode flip.
SPEC_REMOVED=(caveman zoom-out solve resolving-merge-conflicts)

# The exact installed inventory the upstream-sync spec settles on, pinned to
# snapshot mattpocock/skills d81f3a183412e71a5b1e84ca21bc1a35eea03a60.
# Arithmetic (verified against the actual dirs and the snapshot): upstream
# engineering is 20 dirs incl. setup-matt-pocock-skills, which setup-context
# substitutes locally -> 19 upstream-named engineering skills; + 7 upstream
# productivity skills = 26 upstream-named; + 5 retained local skills
# (setup-context, merge-context, rebase-context, offload-context,
# explain-diff) = 31. The 4 spec-removed skills above are already absent from
# this list. Note: the task prose lists implement-spec but omits implement;
# upstream retains both, both exist in the tree, and 26+5=31 needs both -
# this list is taken from the actual dir listing.
EXPECTED_SKILLS=(
  ask-matt code-review codebase-design diagnosing-bugs domain-modeling
  grill-me grill-with-docs grilling handoff implement implement-spec
  improve-codebase-architecture pr prototype research retro tdd teach
  to-questionnaire to-spec to-tickets triage wait-what wayfinder wizard
  writing-for-agents
  setup-context merge-context rebase-context offload-context explain-diff
)

# Name-membership test for the recorded removal list.
is_spec_removed() {
  printf '%s\n' "${SPEC_REMOVED[@]}" | grep -qx "$1"
}

# -- Check 5: invocation inventory vs base --
check_inventory() {
  if ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null 2>&1; then
    fail "$BASE_REF" "is not a valid ref (check 5 cannot run)"
    return
  fi
  local base_user work_user
  base_user=$({ git ls-tree -r --name-only "$BASE_REF" -- .pi/agent/skills/ 2>/dev/null \
    | grep 'SKILL.md$' || true; } \
    | while read -r p; do
        local d; d=$(basename "$(dirname "$p")")
        git show "$BASE_REF:$p" 2>/dev/null | grep -q '^disable-model-invocation: true' && echo "$d" || true
      done | sort)

  work_user=$(find .pi/agent/skills -name 'SKILL.md' -type f \
    | while read -r p; do
        local d; d=$(basename "$(dirname "$p")")
        grep -q '^disable-model-invocation: true' "$p" && echo "$d"
      done | sort)

  local added removed
  added=$(comm -13 <(echo "$base_user") <(echo "$work_user"))
  removed=$(comm -23 <(echo "$base_user") <(echo "$work_user"))

  while IFS= read -r s; do
    [ -z "$s" ] && continue
    if [ "$s" = "handoff" ]; then
      info "$s flipped user-invoked (allowed inventory change, check 5)"
    elif ! git ls-tree -r --name-only "$BASE_REF" -- ".pi/agent/skills/$s/" 2>/dev/null | grep -q .; then
      info "$s is a new skill at work tree (not a flip, check 5)"
    else
      fail ".pi/agent/skills/$s/SKILL.md" "unrecorded invocation-mode change: $s became user-invoked (check 5)"
    fi
  done <<< "$added"

  while IFS= read -r s; do
    [ -z "$s" ] && continue
    if is_spec_removed "$s"; then
      info "$s removed by spec (recorded inventory change, check 5)"
    else
      fail ".pi/agent/skills/$s/SKILL.md" "unrecorded invocation-mode change: $s no longer user-invoked (check 5)"
    fi
  done <<< "$removed"
}

# -- Check 6: no removed skill remains in the installed inventory --
check_removed_skills() {
  while IFS= read -r f; do
    local d
    d=$(basename "$(dirname "$f")")
    if is_spec_removed "$d"; then
      fail "$f" "removed-by-spec skill still in the installed inventory (check 6)"
    fi
  done < <(find .pi/agent/skills -name 'SKILL.md' -type f)
}

# -- Check 6b: no live skill file references a removed skill --
check_removed_references() {
  local names
  names=$(printf '%s|' "${SPEC_REMOVED[@]}")
  names="\\b(${names%|})\\b"
  while IFS= read -r f; do
    if grep -qE "$names" "$f"; then
      fail "$f" "references a removed skill (check 6b)"
    fi
  done < <(find .pi/agent/skills -name '*.md' -type f)
}

# -- Check 7: installed skill dirs exactly equal the expected inventory --
check_expected_inventory() {
  local actual expected diff_out
  actual=$(find .pi/agent/skills -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort)
  expected=$(printf '%s\n' "${EXPECTED_SKILLS[@]}" | sort)
  diff_out=$(diff <(echo "$expected") <(echo "$actual")) || true
  if [ -n "$diff_out" ]; then
    fail ".pi/agent/skills/" "installed inventory differs from the expected skill set (check 7) — diff (< expected, > actual):
$diff_out"
  fi
}

# -- Check 8: no stale domain-artifact names where they denote artifacts --
# Old names that must never be read or written as domain artifacts. Matched as
# path-bearing references: the (^|[^[:alnum:]_-]) marker keeps the hyphenated
# tail of `GLOSSARY-MAP.md` (a legitimate current name) out of the match.
STALE_NAME_PAT='CONTEXT\.md|CONTEXT-MAP\.md|(^|[^[:alnum:]_-])(SPEC|MAP)\.md|`tickets/`'

# Allowlist (line-level, grep -v'd before matching). Legitimate uses kept:
# 1. domain-modeling/GLOSSARY-FORMAT.md — its naming note explains that a
#    CONTEXT.md / CONTEXT-MAP.md artifact found in a repo is a leftover that
#    is NOT read as the glossary (suggest renaming). Only those two lines
#    (3 and 94) are allowlisted, not the whole file, so new old-name
#    path references elsewhere in it still fail. The renamed-file anchor:
#    a path reference to CONTEXT-FORMAT.md matches none of these old
#    name patterns either way, and GLOSSARY-FORMAT.md must not be caught.
# 2. docs/agents/issue-tracker.md — documents the one-time rename ("rename
#    its SPEC.md / MAP.md and tickets/ files"); only the legacy-layout
#    lines that name the old layout are allowlisted (line-level, not whole
#    file) so a fresh old-name path reference added elsewhere in it fails.
# 3. Legacy ticket metadata compat (`type: HITL|AFK`) in implement and
#    to-tickets is allowed and never matches these patterns anyway.
# Anything under .scratch/ is out of scope (never scanned). Bare "context"
# words — model context, context repo, context worktree, context store, and
# the other storage terms — denote storage or model context, not artifacts,
# and never match these patterns.
STALE_NAME_ALLOW='domain-modeling/GLOSSARY-FORMAT\.md:(3|94):|docs/agents/issue-tracker\.md:[0-9]+:.+rename its `SPEC'

check_stale_names() {
  local hits h
  hits=$( { grep -rn -E "$STALE_NAME_PAT" .pi/agent/skills docs AGENTS.md .pi/agent/AGENTS.md 2>/dev/null || true; } \
    | grep -vE "$STALE_NAME_ALLOW" || true )
  while IFS= read -r h; do
    [ -z "$h" ] && continue
    fail "${h%%:*}" "stale domain-artifact name (old contract): $h (check 8)"
  done <<< "$hits"
}

# -- Run --
check_em_dash
check_protected_marks
check_skill_frontmatter
check_ticket_schema
check_handoffs
check_inventory
check_removed_skills
check_removed_references
check_expected_inventory
check_stale_names

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: all checks green"
else
  echo "FAIL: one or more checks failed" >&2
fi
exit "$FAILED"
