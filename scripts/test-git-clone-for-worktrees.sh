#!/usr/bin/env bash
# Integration tests for the clone-for-worktrees bootstrap link + alias stage + helper.
# Isolated HOME and Git config, real local multi-branch fixtures, deterministic
# failure injection only; no network access, real user config untouched,
# and no unrelated bootstrap stages execute.
# No `set -e`: error paths are asserted by capturing command output into
# variables, so failures must not abort the script.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helper="$repo_root/scripts/git-clone-bare-for-worktrees.sh"
register="$repo_root/scripts/setup-git-clone-for-worktrees-alias.sh"
config="$repo_root/install.conf.yaml"
# Contract pin: must mirror the value the registration script installs.
alias_value='!bash "$HOME/git-clone-bare-for-worktrees.sh"'

sandbox="$(mktemp -d "${TMPDIR:-/tmp}/clone-for-worktrees-test.XXXXXX")"
trap 'rm -rf "$sandbox"' EXIT
echo "sandbox: $sandbox"
sandbox="$(cd "$sandbox" && pwd -P)"

export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME="Clfwt Test" GIT_AUTHOR_EMAIL="clfwt@example.com"
export GIT_COMMITTER_NAME="Clfwt Test" GIT_COMMITTER_EMAIL="clfwt@example.com"

fail_count=0
ok()   { echo "ok  - $1"; }
fail() { echo "FAIL - $1" >&2; fail_count=$((fail_count + 1)); }

# Simulated link effect: the tracked helper placed in the home directory.
link_helper_into_home() {
  local home="$1"
  mkdir -p "$home"
  cp "$helper" "$home/git-clone-bare-for-worktrees.sh"
}

# Local fixture with multiple branches, each with its own commit.
make_fixture() {
  local dir="$1"
  git init -q "$dir"
  git -C "$dir" symbolic-ref HEAD refs/heads/main
  echo "main content" > "$dir/file.txt"
  git -C "$dir" add file.txt
  git -C "$dir" commit -qm "main commit"
  git -C "$dir" checkout -qb feature
  echo "feature content" > "$dir/feature.txt"
  git -C "$dir" add feature.txt
  git -C "$dir" commit -qm "feature commit"
  git -C "$dir" checkout -qb topic
  echo "topic content" > "$dir/topic.txt"
  git -C "$dir" add topic.txt
  git -C "$dir" commit -qm "topic commit"
  git -C "$dir" checkout -q main
}

# --- Bootstrap wiring (declarative link + imperative alias stage) ---
t_config_link() {
  if grep -Fq '~/git-clone-bare-for-worktrees.sh: scripts/git-clone-bare-for-worktrees.sh' "$config" \
     && grep -Fq 'setup-git-clone-for-worktrees-alias.sh' "$config"; then
    ok "bootstrap declares helper link and separate alias-registration stage"
  else
    fail "bootstrap declares helper link and separate alias-registration stage"
  fi
}

# --- Alias registration: install / idempotent / conflict / preservation ---
t_register_absent() {
  local home="$sandbox/reg-home dir"
  local cfg="$home/.gitconfig"
  link_helper_into_home "$home"
  local out
  if out=$(HOME="$home" GIT_CONFIG_GLOBAL="$cfg" bash "$register" 2>&1); then
    local got
    got=$(HOME="$home" GIT_CONFIG_GLOBAL="$cfg" git config --global --get alias.clone-for-worktrees || true)
    if [ "$got" = "$alias_value" ]; then
      ok "registration installs absent alias with exact value"
    else
      fail "registration installs absent alias (got '$got')"
    fi
  else
    fail "registration installs absent alias (script failed: $out)"
  fi
}

t_register_idempotent() {
  local home="$sandbox/reg-idem-home"
  local cfg="$home/.gitconfig"
  link_helper_into_home "$home"
  HOME="$home" GIT_CONFIG_GLOBAL="$cfg" bash "$register" >/dev/null 2>&1
  local out
  if ! out=$(HOME="$home" GIT_CONFIG_GLOBAL="$cfg" bash "$register" 2>&1); then
    fail "second registration itself failed"
  elif ! echo "$out" | grep -q "already configured"; then
    fail "second registration leaves identical value unchanged (no 'already' notice)"
  else
    ok "second registration leaves identical value unchanged"
  fi
  local got
  got=$(HOME="$home" GIT_CONFIG_GLOBAL="$cfg" git config --global --get alias.clone-for-worktrees || true)
  [ "$got" = "$alias_value" ] && ok "value after repeat still exact" || fail "value after repeat changed: '$got'"
}

t_register_conflict() {
  local home="$sandbox/reg-conflict-home"
  local cfg="$home/.gitconfig"
  link_helper_into_home "$home"
  GIT_CONFIG_GLOBAL="$cfg" git config --global alias.clone-for-worktrees '!echo other'
  local out
  if out=$(HOME="$home" GIT_CONFIG_GLOBAL="$cfg" bash "$register" 2>&1); then
    local got
    got=$(HOME="$home" GIT_CONFIG_GLOBAL="$cfg" git config --global --get alias.clone-for-worktrees || true)
    if [ "$got" = '!echo other' ] && echo "$out" | grep -qi "different value"; then
      ok "conflicting alias preserved with warning, setup still succeeds"
    else
      fail "conflicting alias preserved with warning (got '$got', out: $out)"
    fi
  else
    fail "conflicting alias should not fail setup"
  fi
}

t_register_preserves() {
  local home="$sandbox/reg-preserve-home"
  local cfg="$home/.gitconfig"
  link_helper_into_home "$home"
  GIT_CONFIG_GLOBAL="$cfg" git config --global user.name "Real User"
  GIT_CONFIG_GLOBAL="$cfg" git config --global user.email "real@example.com"
  GIT_CONFIG_GLOBAL="$cfg" git config --global color.ui auto
  GIT_CONFIG_GLOBAL="$cfg" git config --global core.editor vim
  local out
  out=$(HOME="$home" GIT_CONFIG_GLOBAL="$cfg" bash "$register" 2>&1)
  local name email cui editor
  name=$(GIT_CONFIG_GLOBAL="$cfg" git config --global --get user.name || true)
  email=$(GIT_CONFIG_GLOBAL="$cfg" git config --global --get user.email || true)
  cui=$(GIT_CONFIG_GLOBAL="$cfg" git config --global --get color.ui || true)
  editor=$(GIT_CONFIG_GLOBAL="$cfg" git config --global --get core.editor || true)
  if [ "$name" = "Real User" ] && [ "$email" = "real@example.com" ] \
     && [ "$cui" = auto ] && [ "$editor" = vim ]; then
    ok "registration preserves existing identity and unrelated configuration"
  else
    fail "registration preserved identity/unrelated config (name=$name email=$email cui=$cui editor=$editor)"
  fi
  if echo "$out" | grep -qi "enter git"; then
    fail "registration prompts for identity"
  else
    ok "registration never prompts for identity"
  fi
}

# --- Shared main environment: spaced HOME, spaced source, spaced destination ---
main_home="$sandbox/home dir"
main_cfg="$main_home/.gitconfig"
link_helper_into_home "$main_home"
HOME="$main_home"
GIT_CONFIG_GLOBAL="$main_cfg"
export HOME GIT_CONFIG_GLOBAL
bash "$register" >/dev/null 2>&1

fixture="$sandbox/source repo dir"
make_fixture "$fixture"
dest="$sandbox/container dir"

# --- Usage errors: before any container creation ---
t_usage() {
  local dest_empty="$sandbox/usage-empty-src-dest"
  local dest_excess="$sandbox/usage-excess-dest"
  local out rc

  # 0 args
  if out=$(git clone-for-worktrees 2>&1); then
    fail "usage: zero arguments fails"
  else
    echo "$out" | grep -q "Usage:" && ok "usage: zero arguments fail with usage" || fail "usage: zero arguments (no Usage text)"
  fi

  # 1 arg (missing destination)
  if out=$(git clone-for-worktrees "$fixture" 2>&1); then
    fail "usage: missing destination fails"
  else
    echo "$out" | grep -q "Usage:" && ok "usage: missing destination fails with usage" || fail "usage: missing destination (no Usage text)"
  fi

  # 3 args (excess)
  if out=$(git clone-for-worktrees "$fixture" "$dest_excess" extra 2>&1); then
    fail "usage: excess arguments fail"
  elif [ -e "$dest_excess" ]; then
    fail "usage: excess arguments created a container anyway"
  else
    echo "$out" | grep -q "Usage:" && ok "usage: excess arguments fail before creation" || fail "usage: excess arguments (no Usage text)"
  fi

  # empty source
  if out=$(git clone-for-worktrees "" "$dest_empty" 2>&1); then
    fail "usage: empty source fails"
  elif [ -e "$dest_empty" ]; then
    fail "usage: empty source created a container anyway"
  else
    echo "$out" | grep -q "Usage:" && ok "usage: empty source fails before creation" || fail "usage: empty source (no Usage text)"
  fi

  # empty destination
  if out=$(git clone-for-worktrees "$fixture" "" 2>&1); then
    fail "usage: empty destination fails"
  else
    echo "$out" | grep -q "Usage:" && ok "usage: empty destination fails with usage" || fail "usage: empty destination (no Usage text)"
  fi
}

# --- Destination refusal ---
t_reject_dest() {
  local out

  # existing empty directory
  local d_empty="$sandbox/reject-empty"
  mkdir -p "$d_empty"
  if out=$(git clone-for-worktrees "$fixture" "$d_empty" 2>&1); then
    fail "existing empty directory rejected"
  elif [ -d "$d_empty" ] && [ -z "$(ls -A "$d_empty")" ]; then
    ok "existing empty directory rejected, untouched"
  else
    fail "existing empty directory modified"
  fi

  # existing nonempty directory
  local d_non="$sandbox/reject-nonempty"
  mkdir -p "$d_non" && echo keep > "$d_non/precious.txt"
  if out=$(git clone-for-worktrees "$fixture" "$d_non" 2>&1); then
    fail "existing nonempty directory rejected"
  elif [ "$(cat "$d_non/precious.txt")" = keep ] && [ ! -e "$d_non/.git" ]; then
    ok "existing nonempty directory rejected, untouched"
  else
    fail "existing nonempty directory modified"
  fi

  # existing file
  local f_plain="$sandbox/reject-file"
  echo keep > "$f_plain"
  if out=$(git clone-for-worktrees "$fixture" "$f_plain" 2>&1); then
    fail "existing file rejected"
  elif [ "$(cat "$f_plain")" = keep ]; then
    ok "existing file rejected, untouched"
  else
    fail "existing file modified"
  fi

  # symlink (valid target)
  local link_target="$sandbox/link-target"
  echo keep > "$link_target"
  local link="$sandbox/reject-link"
  ln -s "$link_target" "$link"
  if out=$(git clone-for-worktrees "$fixture" "$link" 2>&1); then
    fail "existing symlink rejected"
  elif [ -L "$link" ] && [ "$(cat "$link_target")" = keep ]; then
    ok "existing symlink rejected, link and target untouched"
  else
    fail "existing symlink modified"
  fi

  # dangling symlink
  local dangling="$sandbox/reject-dangling"
  ln -s "$sandbox/no-such-target" "$dangling"
  if out=$(git clone-for-worktrees "$fixture" "$dangling" 2>&1); then
    fail "dangling symlink rejected"
  elif [ -L "$dangling" ] && [ ! -e "$sandbox/no-such-target" ]; then
    ok "dangling symlink rejected, target not created"
  else
    fail "dangling symlink modified"
  fi
}

# --- Missing parent ---
t_missing_parent() {
  local parent="$sandbox/no-parent"
  local child="$parent/child"
  local out
  if out=$(git clone-for-worktrees "$fixture" "$child" 2>&1); then
    fail "destination with absent parent fails"
  elif [ ! -e "$parent" ]; then
    ok "destination with absent parent fails; no parents created"
  else
    fail "parents were created unexpectedly"
  fi
}

# --- Clone failure: retained container + reported location ---
t_clone_failure() {
  local d="$sandbox/clone-fail-dest"
  local out
  if out=$(git clone-for-worktrees "$sandbox/does-not-exist" "$d" 2>&1); then
    fail "clone failure returns nonzero"
  elif echo "$out" | grep -q "Created Worktree container"; then
    fail "clone failure reported success"
  elif [ ! -d "$d" ]; then
    fail "clone failure did not retain container"
  elif ! echo "$out" | grep -qF "$d"; then
    fail "clone failure did not report container location"
  else
    ok "clone failure nonzero, no success, container retained and located"
  fi
}

# --- Fetch failure via deterministic git shim ---
# git prepends its exec path to PATH when running `!` aliases, so a PATH shim
# cannot intercept the helper's inner git calls through the alias; drive the
# helper directly (the same script the alias shells out to) for injection.
t_fetch_failure() {
  local real_git
  real_git="$(command -v git)"
  local shim_dir="$sandbox/git-fail-fetch"
  mkdir -p "$shim_dir"
  cat > "$shim_dir/git" <<EOF
#!/bin/sh
for a in "\$@"; do
  [ "\$a" = fetch ] && { echo "injected fetch failure" >&2; exit 128; }
done
exec "$real_git" "\$@"
EOF
  chmod +x "$shim_dir/git"

  local d="$sandbox/fetch-fail-dest"
  local out
  if out=$(PATH="$shim_dir:$PATH" bash "$helper" "$fixture" "$d" 2>&1); then
    fail "fetch failure returns nonzero"
  elif echo "$out" | grep -q "Created Worktree container"; then
    fail "fetch failure reported success"
  elif [ ! -d "$d/.git" ]; then
    fail "fetch failure did not retain container"
  elif ! echo "$out" | grep -qF "$d"; then
    fail "fetch failure did not report container location"
  else
    ok "fetch failure nonzero, no success, container retained and located"
  fi
}

# --- Full behavior through the installed alias ---
t_full() {
  local out

  if ! out=$(git clone-for-worktrees "$fixture" "$dest" 2>&1); then
    fail "alias invocation creates container (output: $out)"
    return
  fi

  # bare layout: .git dir, no pointer file, no .bare, no worktree
  if [ -d "$dest/.git" ] && [ ! -e "$dest/.bare" ] && [ "$(ls -A "$dest")" = ".git" ]; then
    ok "container holds only a bare .git directory"
  else
    fail "container layout wrong: $(ls -A "$dest" | tr '\n' ' '), .bare=$([ -e "$dest/.bare" ] && echo yes || echo no)"
  fi

  local bare
  bare=$(git -C "$dest" rev-parse --is-bare-repository 2>/dev/null || true)
  if [ "$bare" = "true" ]; then
    ok "git recognizes the bare repository from the container"
  else
    fail "git does not recognize bare repository from container (got '$bare')"
  fi

  local gd
  gd=$(git -C "$dest/.git" rev-parse --git-dir 2>/dev/null || true)
  [ "$gd" = "." ] && ok "inside .git the repository directory is itself" || fail "git-dir inside .git is '$gd'"

  local url
  url=$(git -C "$dest" remote get-url origin 2>/dev/null || true)
  [ "$url" = "$fixture" ] && ok "origin identifies the intended source" || fail "origin url is '$url'"

  local mapping
  mapping=$(git -C "$dest" config remote.origin.fetch 2>/dev/null || true)
  [ "$mapping" = '+refs/heads/*:refs/remotes/origin/*' ] \
    && ok "fetch mapping force-updates all origin branches" \
    || fail "fetch mapping is '$mapping'"

  local refs
  refs=$(git -C "$dest" for-each-ref --format='%(refname:short)' refs/remotes/origin || true)
  { echo "$refs" | grep -qx "origin/main" \
    && echo "$refs" | grep -qx "origin/feature" \
    && echo "$refs" | grep -qx "origin/topic"; } \
    && ok "remote-tracking refs exist for every fixture branch" \
    || fail "remote-tracking refs missing: $(echo "$refs" | tr '\n' ' ')"

  local wl
  wl=$(git -C "$dest" worktree list 2>/dev/null | wc -l | tr -d ' ')
  [ "$wl" = 1 ] && ok "helper created no worktree" || fail "helper created worktrees (count $wl)"

  # subsequent normal fetch discovers a new branch
  git -C "$fixture" checkout -qb later
  echo "later content" > "$fixture/later.txt"
  git -C "$fixture" add later.txt
  git -C "$fixture" commit -qm "later commit"
  git -C "$fixture" checkout -q main
  if git -C "$dest" fetch origin >/dev/null 2>&1 \
     && git -C "$dest" show-ref --verify -q refs/remotes/origin/later; then
    ok "subsequent origin fetch discovers a new branch"
  else
    fail "subsequent origin fetch did not discover new branch"
  fi

  # manual worktree beside the bare repository
  if git -C "$dest" worktree add -b fwt-feature "$dest/wt-feature" origin/feature >/dev/null 2>&1 \
     && [ -f "$dest/wt-feature/feature.txt" ] \
     && [ -z "$(git -C "$dest/wt-feature" status --porcelain)" ] \
     && [ "$(git -C "$dest/wt-feature" rev-parse --abbrev-ref HEAD)" = fwt-feature ]; then
    ok "manual worktree beside the bare repository is a usable checkout"
  else
    fail "manual worktree addition failed"
  fi
}

t_config_link
t_register_absent
t_register_idempotent
t_register_conflict
t_register_preserves
t_usage
t_reject_dest
t_missing_parent
t_clone_failure
t_fetch_failure
t_full

if [ "$fail_count" -eq 0 ]; then
  echo "PASS: all clone-for-worktrees integration checks green"
else
  echo "FAIL: $fail_count check(s) failed" >&2
  exit 1
fi