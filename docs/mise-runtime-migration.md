# Python, Ruby, and Go under mise: install, trust, and upgrade workflow

This slice (issue 03 of the [Managed tools migration](../.scratch/mise-managed-tools/spec.md)) moves **Python**, **Ruby**, and **Go** ownership to **mise**, extending the Node migration from [mise-node-migration.md](mise-node-migration.md). The shared resolution model, trust workflow, and upgrade workflow are identical; this page records the runtime-specific decisions, exceptions, and acceptance evidence.

Nothing was uninstalled or deleted: pyenv, rbenv, Homebrew's `go` and `ruby`, and all runtime state remain on disk until separately approved cleanup (checklist at the bottom).

## Ownership after this slice

| Tool | Version(s) | Owner | Notes |
| --- | --- | --- | --- |
| python | 3.12.4 | **mise** (`core:python`) | The sole pyenv-managed version; the pyenv copy had no user site-packages (only pip), so the runtime moved cleanly. `python.github_attestations = false` — see below. |
| ruby | 3.3.0 (default), 3.2.2 | **mise** (`core:ruby`) | Both rbenv versions preserved; first declared entry is the default (matching rbenv's old global). |
| CocoaPods (`pod`) | 1.15.2 | **mise ruby** (explicit gem install) | Human decision 2026-10-05: gems do not move with the runtime, so CocoaPods is reinstalled deliberately into mise ruby 3.3.0 by `scripts/install-cocoapods.sh`. rbenv hooks were retired instead of being kept for pod. |
| go | 1.27.1 | **mise** (`core:go`) | Homebrew-installed version preserved. `GOROOT`/`GOPATH` exports retired; `~/go/bin` stays on PATH. |
| rust | x86_64 1.70.0 | **decision point D2 (unchanged)** | Blocked on a human decision; `~/.cargo/bin` stays on PATH so the existing toolchain keeps resolving. |
| bun, standalone CLIs | — | **Homebrew (owner decision 2026-10-05)** | Issue 04 resolved by decision: no CLI migrates; mise manages language runtimes only. See [mise-cli-ownership.md](mise-cli-ownership.md). |

> **Update 2026-10-05 (issue 05):** Flutter and FVM were removed from the machine entirely by owner decision — the fork exception (D6) was retired rather than confirmed, and the official-stable cask went with it. The flutter row above is deleted accordingly; nothing installs Dart/Flutter anymore.

Retained as-is: pnpm (and its global packages), poetry, uv, LM Studio CLI, the OpenCode copies, zinit, and all Homebrew foundation tools.

## What is tracked

- `.config/mise/config.toml` — declares `python = "3.12.4"`, `ruby = ["3.3.0", "3.2.2"]`, `go = "1.27.1"` alongside the existing node default; comments explain each version's inventory evidence and the explicit exceptions (rust D2; the bun/CLI ownership question resolved to Homebrew retention in [mise-cli-ownership.md](mise-cli-ownership.md)).
- `.config/mise/mise.lock` — regenerated once with `mise lock --global`; records per-platform URLs and SHA-256 checksums for all five tools, so installs verify the same bytes.
- `scripts/install-mise-tools.sh` — verifies every declared tool generically: each declared version installed, the active resolution equals the first declared version, and the install lives in mise's data directory. Bash-3.2-compatible so it works with macOS's stock bash on fresh machines.
- `scripts/install-cocoapods.sh` — guarded stage: installs CocoaPods **1.15.2** (the reviewed baseline version) into the mise ruby via `mise x -- gem install`, then verifies `pod` resolves inside mise's install directory at the reviewed version — on every run, including the skip path. Skips only when `mise which pod` already resolves there at the pinned version.
- `scripts/mise-stage-helpers.sh` — shared preamble (resolve Homebrew/mise, resolve from `$HOME`, ownership guard) sourced by the mise-driving stages, including `install-pi.sh`.
- `.zshrc` — `eval "$(rbenv init -)"` and `eval "$(pyenv init -)"` removed (competing runtime selection; mise activate remains).
- `.zshenv` — `GOROOT`, `GOPATH`, `PYENV_ROOT` exports and their PATH entries retired; `~/go/bin` added so existing `go install`-ed tools (gopls, dlv, wails, …) keep resolving; `~/.rbenv/bin` retired with its hooks.
- `Brewfile` — `rbenv`, `pyenv`, and `go` dropped. Fresh machines install the runtimes through mise; existing local installs are untouched.

## Why `python.github_attestations = false`

mise verifies GitHub artifact attestations for its python builds by default, but the python-build-standalone release for 3.12.4 publishes none — `mise lock --global` recorded zero platform entries and locked installation would fail. The setting falls back to the SHA-256 checksums recorded in `mise.lock`. Revisit only together with a reviewed python version bump (a newer release may publish attestations).

## Go environment

- `GOROOT` had to be retired, not just left unused: mise's `go` binary on PATH with `GOROOT` still exported to Homebrew's libexec would resolve the wrong toolchain.
- `GOPATH` keeps its default of `~/go` under mise, and `~/go/bin` stays on PATH explicitly. The ~25 tools previously installed there (`gopls`, `dlv`, `templ`, `wails`, …) are self-contained binaries and keep working; `go install` continues to place new tools there.

## Ruby environment

- `ruby = ["3.3.0", "3.2.2"]` installs both; the first entry is the default, matching rbenv's old global. Non-default selection happens per-project via trusted config or `.ruby-version` / `.tool-versions`.
- CocoaPods 1.15.2 is installed with pinned version into mise ruby 3.3.0. Transitive gems resolve to current versions at install time (unavoidable for a fresh gem install; the pinned top-level version is the reviewed baseline).
- rbenv (formula + `~/.rbenv` state, including its rubies and gems) is a **cleanup candidate**, not deleted — see below.

## Trust and version files

Same model as Node: unfamiliar project `mise.toml` is not trusted implicitly; pure-data runtime-version files (`.python-version`, `.ruby-version`, `.go-version`, `.tool-versions`, …) are honored for version selection in trusted projects; missing versions error with `mise install` guidance instead of downloading on directory entry. See [mise-node-migration.md](mise-node-migration.md#trust-workflow) for the detailed workflow.

## Manual acceptance checklist

Observed on this machine (2026-10-05, macOS 26.5.1, mise 2026.10.2):

- [x] `mise ls` shows node 22.22.3, python 3.12.4, ruby 3.3.0 + 3.2.2, go 1.27.1 — all sourced from `~/.config/mise/config.toml`.
- [x] Interactive Zsh outside this repository resolves `python3`, `ruby`, and `go` to mise-managed installs at the declared versions; noninteractive Zsh resolves the same through the shims (verified with `env -i` fresh shells in both modes, plus `gem`, `bundle`, `pod`).
- [x] `pod --version` → 1.15.2 resolving inside `~/.local/share/mise/installs/ruby/3.3.0`; `gem`, `bundle` work (Bundler 2.5.3).
- [x] `~/go/bin` tools (e.g. `gopls`) still resolve and run.
- [x] Repeat stage run reports the locked tools already installed with unchanged install directories and an unmodified `mise.lock` (no opportunistic upgrades; "installed 0 tools · 5 already installed in 0ms").
- [x] A `.tool-versions` file selects ruby 3.2.2 inside a project and leaving the project restores the global 3.3.0 default; an uninstalled requested version (`.python-version` 3.12.2) errors with `mise install` guidance without downloading; 3.12.2 was not installed afterwards.
- [x] Unfamiliar project `mise.toml` is not trusted: its env is not applied and tool invocations error with `mise trust` guidance; no download, no silent fallback.
- [x] Retained tooling unaffected: pnpm 10.17.1, pi, opencode, gemini, poetry 2.0.0, uv 0.12.21, lms, rtk, gh 2.102.0, zinit, fvm, flutter, brew git/zsh. *(fvm and flutter were still installed when this issue-03 checklist ran; both were removed later the same day — issue 05.)*
- [x] pyenv 3.12.4, rbenv 3.2.2/3.3.0 (with the original CocoaPods gems), brew go 1.27.1, brew ruby 4.0.7 still present — nothing uninstalled or deleted.
- [ ] GUI-launched editors: covered by issue 06 — integration and verification procedure in [mise-gui-editor-access.md](mise-gui-editor-access.md).

Environment note: CocoaPods prints its standard UTF-8 warning when `LANG` is unset (e.g. a minimal `env -i` shell); normal terminal sessions are unaffected. Out-of-scope observation recorded for D4 accuracy: in a minimal environment the standalone `~/.opencode/bin/opencode` copy wins on PATH in both shell modes; the inventory's "brew wins interactively" was measured in an inherited-shell environment. Neither copy was touched.

## Post-verification cleanup checklist (human-approved, not executed)

Run only after the acceptance above has held for a while:

1. `brew uninstall rbenv pyenv go ruby` — the migrated/competing managers and runtimes (Homebrew `ruby` 4.0.7 was a competing install, inventory D5).
2. Remove `~/.pyenv` (its 3.12.4 install is superseded by mise python 3.12.4; it held only pip).
3. Remove `~/.rbenv` (its rubies and gems — including the original CocoaPods gems — are superseded; confirm no project depends on the rbenv-local gem set first).
4. Keep `~/.cargo` until D2 (rust) is decided.

Each step is a separate deliberate action; the mise migration does not perform them.
