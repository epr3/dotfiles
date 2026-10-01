#!/usr/bin/env bash
set -uo pipefail
# test-check-parity.sh — sandboxed contract tests for the pinned parity seam.
# No network: the "pinned upstream" is a local git fixture admitted through
# PARITY_UPSTREAM_DIR + PARITY_EXPECTED_COMMIT + PARITY_EXPECTED_DIRS +
# PARITY_UPSTREAM_SKILLS_SPEC (test escape hatches; production never sets
# them).

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

fail_count=0
ok()   { echo "ok  - $1"; }
fail() { echo "FAIL - $1" >&2; fail_count=$((fail_count+1)); }

L=$(mktemp -d "${TMPDIR:-/tmp}/paritytest.XXXXXX")
if [ -n "${PARITYTEST_KEEP:-}" ]; then echo "kept: $L"; else trap 'rm -rf "$L"' EXIT; fi
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
cd "$L"

# -- Fake pinned upstream repo (a checkout of one commit) --
up=$L/up
git init -q "$up"
cd "$up"
mkdir -p skills/engineering/gizmo/agents skills/productivity/mojito/agents
printf '%s\n' '---' 'name: gizmo' 'description: Gizmo skill.' 'disable-model-invocation: true' '---' \
  '# Gizmo' '' 'See [tests](./tests.md).' > skills/engineering/gizmo/SKILL.md
printf '%s\n' '# Tests fixture' > skills/engineering/gizmo/tests.md
printf '%s\n' 'openai packaging' > skills/engineering/gizmo/agents/openai.yaml
printf '%s\n' '---' 'name: mojito' 'description: Mojito skill.' '---' \
  '# Mojito' '' 'Body text.' > skills/productivity/mojito/SKILL.md
printf '%s\n' '{display}' > skills/productivity/mojito/agents/openai.yaml
git add -A && git commit -qm 'upstream fixture'
UP_SHA=$(git rev-parse HEAD)
cd "$L"

# -- Fixture code repo (curated suite) --
work=$L/work
git init -q "$work"
cd "$work"
cp -R "$REPO/scripts" scripts
rm -rf scripts/parity/exceptions && mkdir -p scripts/parity/exceptions
# Only the recorded harness-metadata and local-only inventory decisions are
# carried into the fixture; per-test entries are added locally.
cat > scripts/parity/exceptions/agent-metadata.md <<'EOF'
---
kind: metadata
upstream: skills/*/*/agents/
local: .pi/agent/skills/*/agents/
rationale: Harness packaging metadata is not retained in the curated suite.
---

Recorded removal.
EOF
mkdir -p .pi/agent/skills
cp -R "$up/skills/engineering/gizmo" .pi/agent/skills/gizmo
cp -R "$up/skills/productivity/mojito" .pi/agent/skills/mojito
for s in setup-context merge-context offload-context rebase-context explain-diff; do
  mkdir -p ".pi/agent/skills/$s" && printf 'local only %s\n' "$s" > ".pi/agent/skills/$s/SKILL.md"
done
git add -A && git commit -qm 'fixture work repo'

export PARITY_UPSTREAM_DIR=$up PARITY_EXPECTED_COMMIT=$UP_SHA PARITY_CACHE=$L/cache
export PARITY_EXPECTED_DIRS=$'gizmo\nmojito\nsetup-context\nmerge-context\noffload-context\nrebase-context\nexplain-diff'
export PARITY_UPSTREAM_SKILLS_SPEC='gizmo=engineering mojito=productivity'

run_check() { ./scripts/check-parity.sh "$@" 2>&1; }

# t1: byte-exact counterparts pass in full mode.
out=$(run_check --full); rc=$?
if [ "$rc" -eq 0 ] && echo "$out" | grep -q '^PASS'; then
  ok "t1 byte-exact suite passes in full mode"
else
  fail "t1 byte-exact suite should pass; got: $out"
fi

# t2: unapproved wording edit in a counterpart fails.
printf '%s\n' '# Gizmo EDITED' >> .pi/agent/skills/gizmo/SKILL.md
out=$(run_check --full)
if echo "$out" | grep -q 'gizmo/SKILL.md: modified vs pinned upstream' && echo "$out" | grep -q '^FAIL'; then
  ok "t2 unapproved wording edit fails parity"
else
  fail "t2 unapproved edit should fail; got: $out"
fi
git checkout -q -- .pi/agent/skills/gizmo/SKILL.md

# t3: a recorded substitution with exact-change markers passes...
cat > scripts/parity/exceptions/gizmo-setup-ref.md <<'EOF'
---
kind: substitution
upstream: skills/engineering/gizmo/SKILL.md
local: .pi/agent/skills/gizmo/SKILL.md
rationale: Replaces the upstream setup entrypoint reference per the context mechanism.
---

- Setup is provided by setup-context (substituted entrypoint).
EOF
printf '%s\n' 'Setup is provided by setup-context (substituted entrypoint).' >> .pi/agent/skills/gizmo/SKILL.md
out=$(run_check --full)
if echo "$out" | grep -q '^PASS'; then
  ok "t3 approved substitution with exact marker passes"
else
  fail "t3 recorded substitution should pass; got: $out"
fi

# t3b: ...and an unrelated edit inside the same covered file still fails.
printf '%s\n' 'Unrelated extra sentence.' >> .pi/agent/skills/gizmo/SKILL.md
out=$(run_check --full)
if echo "$out" | grep -q 'changed line lacks an exact-change marker.*Unrelated extra sentence' && echo "$out" | grep -q '^FAIL'; then
  ok "t3b unrelated edit inside an approved file still fails"
else
  fail "t3b unrelated edit should fail; got: $out"
fi
git checkout -q -- .pi/agent/skills/gizmo/SKILL.md
rm scripts/parity/exceptions/gizmo-setup-ref.md

# t4: extra file without a decision fails; with a recorded packaging decision passes.
printf 'extra\n' > .pi/agent/skills/gizmo/EXTRA.md
out=$(run_check --full)
if echo "$out" | grep -q 'gizmo/EXTRA.md: extra file' && echo "$out" | grep -q '^FAIL'; then
  ok "t4 extra unrecorded file fails"
else
  fail "t4 EXTRA.md should fail; got: $out"
fi
cat > scripts/parity/exceptions/gizmo-extra.md <<'EOF'
---
kind: packaging
upstream: absent
local: .pi/agent/skills/gizmo/EXTRA.md
rationale: Recorded packaging decision for this annex file.
---

Recorded extra.
EOF
out=$(run_check --full)
if echo "$out" | grep -q '^PASS'; then
  ok "t4b recorded extra packaging decision passes"
else
  fail "t4b recorded extra should pass; got: $out"
fi
rm .pi/agent/skills/gizmo/EXTRA.md scripts/parity/exceptions/gizmo-extra.md

# t5: missing supporting file with no decision fails; agents/ metadata covered.
rm .pi/agent/skills/gizmo/tests.md
out=$(run_check --full)
if echo "$out" | grep -q 'missing file vs pinned upstream: tests.md' && echo "$out" | grep -q '^FAIL'; then
  ok "t5 missing supporting file with no recorded decision fails"
else
  fail "t5 tests.md removal should fail; got: $out"
fi
# restore, then remove only the agents/ metadata: covered by the recorded decision
cp -R "$up/skills/engineering/gizmo/tests.md" .pi/agent/skills/gizmo/tests.md
rm .pi/agent/skills/mojito/agents/openai.yaml
out=$(run_check --full)
if echo "$out" | grep -q 'recorded decision covers missing .pi/agent/skills/mojito/agents/openai.yaml' && echo "$out" | grep -q '^PASS'; then
  ok "t5b missing agents/openai.yaml covered by recorded metadata decision"
else
  fail "t5b should pass with the metadata decision; got: $out"
fi
# simulate restoring it later for the rest of the tests
mkdir -p .pi/agent/skills/mojito/agents && printf '{display}\n' > .pi/agent/skills/mojito/agents/openai.yaml

# t6: recorded retirement and substituted entrypoint never installed; stray dirs fail.
out=$(run_check --full)
if echo "$out" | grep -q '^PASS'; then ok "t6 clean inventory passes"; else fail "t6 got: $out"; fi
mkdir .pi/agent/skills/ask-matt
out=$(run_check --full)
if echo "$out" | grep -q 'ask-matt' && echo "$out" | grep -q '^FAIL'; then
  ok "t6b retired ask-matt cannot pass"
else
  fail "t6b got: $out"
fi
rmdir .pi/agent/skills/ask-matt
mkdir .pi/agent/skills/setup-matt-pocock-skills
out=$(run_check --full)
if echo "$out" | grep -q 'setup-matt-pocock-skills' && echo "$out" | grep -q '^FAIL'; then
  ok "t6c substituted upstream entrypoint cannot pass"
else
  fail "t6c got: $out"
fi
rmdir .pi/agent/skills/setup-matt-pocock-skills

# t7: scoped pass does not imply a suite pass.
printf '%s\n' 'drift into gizmo' >> .pi/agent/skills/gizmo/SKILL.md
out=$(run_check mojito); scoped_rc=$?
if [ "$scoped_rc" -eq 0 ] && echo "$out" | grep -q 'SCOPED PASS' && echo "$out" | grep -q 'does not imply a suite pass'; then
  ok "t7 scoped pass reports remaining drift, exits per scope"
else
  fail "t7 scoped contract; got rc=$scoped_rc out: $out"
fi
full=$(run_check --full); full_rc=$?
if [ "$full_rc" -ne 0 ]; then ok "t7b full mode fails while gizmo drifts"; else fail "t7b full mode should fail; got: $full"; fi
out=$(run_check gizmo); gscoped_rc=$?
if [ "$gscoped_rc" -eq 1 ]; then ok "t7c scoped run over the drifting skill exits 1"; else fail "t7c got rc=$gscoped_rc: $out"; fi
git checkout -q -- .pi/agent/skills/gizmo/SKILL.md

# t8: --is-exact-file helper
./scripts/check-parity.sh --is-exact-file .pi/agent/skills/mojito/SKILL.md && \
  ok "t8 exact counterpart file reports 0" || fail "t8 exact file should exit 0"
printf '%s\n' 'X' >> .pi/agent/skills/mojito/SKILL.md
if ./scripts/check-parity.sh --is-exact-file .pi/agent/skills/mojito/SKILL.md; then
  fail "t8b drifted file should exit 1"
else
  ok "t8b drifted file reports 1"
fi
git checkout -q -- .pi/agent/skills/mojito/SKILL.md

# t9: reference resolving upstream but not locally fails; both-sides unresolved is info.
printf '%s\n' 'See [gone](./tests.md).' >> .pi/agent/skills/gizmo/SKILL.md
cat > scripts/parity/exceptions/gizmo-t9-ref.md <<'T9EXC'
---
kind: substitution
upstream: skills/engineering/gizmo/SKILL.md
local: .pi/agent/skills/gizmo/SKILL.md
rationale: Recorded wording substitution used to exercise reference tracking.
---

- See [gone](./tests.md).
T9EXC
rm .pi/agent/skills/gizmo/tests.md
out=$(run_check --full)
if echo "$out" | grep -q 'resolves upstream but not locally' && echo "$out" | grep -q '^FAIL'; then
  ok "t9 supporting reference resolution participates in comparison"
else
  fail "t9 got: $out"
fi
rm scripts/parity/exceptions/gizmo-t9-ref.md
cp -R "$up/skills/engineering/gizmo/tests.md" .pi/agent/skills/gizmo/tests.md
printf '%s\n' 'See [ghost](./nowhere.md).' >> .pi/agent/skills/gizmo/SKILL.md
cat > scripts/parity/exceptions/gizmo-t9b-ref.md <<'T9EXC'
---
kind: substitution
upstream: skills/engineering/gizmo/SKILL.md
local: .pi/agent/skills/gizmo/SKILL.md
rationale: Recorded wording substitution used to exercise reference tracking.
---

- See [gone](./tests.md).
- See [ghost](./nowhere.md).
T9EXC
out=$(run_check --full)
if echo "$out" | grep -q 'unresolved both sides' && echo "$out" | grep -q '^PASS'; then
  ok "t9b upstream-inherited unresolved reference is info, not drift"
else
  fail "t9b got: $out"
fi
rm -f scripts/parity/exceptions/gizmo-t9-ref.md scripts/parity/exceptions/gizmo-t9b-ref.md
git checkout -q -- .pi/agent/skills/gizmo/SKILL.md .pi/agent/skills/gizmo/tests.md

# t10: substitution entry naming a directory (whole-skill exclusion) is rejected.
printf '%s\n' 'approved line' >> .pi/agent/skills/gizmo/tests.md
cat > scripts/parity/exceptions/whole-skill.md <<'EOF'
---
kind: substitution
upstream: skills/engineering/gizmo/
local: .pi/agent/skills/gizmo/
rationale: Blanket exemption attempt.
---

- approved line
EOF
out=$(run_check --full)
if echo "$out" | grep -q 'specific upstream file' && echo "$out" | grep -q '^FAIL'; then
  ok "t10 whole-skill substitution entry rejected"
else
  fail "t10 got: $out"
fi
rm scripts/parity/exceptions/whole-skill.md
git checkout -q -- .pi/agent/skills/gizmo/tests.md

# t11: entry missing rationale rejected; empty registry rejected.
printf '%s\n' 'approved line' > .pi/agent/skills/gizmo/notes.md
cat > scripts/parity/exceptions/no-rat.md <<'EOF'
---
kind: packaging
upstream: absent
local: .pi/agent/skills/gizmo/notes.md
---

No rationale here.
EOF
out=$(run_check --full)
if echo "$out" | grep -q 'missing rationale' && echo "$out" | grep -q '^FAIL'; then
  ok "t11 rationale is mandatory"
else
  fail "t11 got: $out"
fi
rm scripts/parity/exceptions/no-rat.md .pi/agent/skills/gizmo/notes.md
mv scripts/parity/exceptions "$L/exc-stash"
out=$(run_check --full)
if echo "$out" | grep -q 'exception registry is empty' && echo "$out" | grep -q '^FAIL'; then
  ok "t11b empty registry fails"
else
  fail "t11b got: $out"
fi
mv "$L/exc-stash" scripts/parity/exceptions

cd "$HERE"
if [ "$fail_count" -eq 0 ]; then
  echo "PASS: all check-parity contract checks green"
else
  echo "FAIL: $fail_count check(s) failed" >&2
fi
exit "$fail_count"
