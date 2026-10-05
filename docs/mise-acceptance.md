# Managed tools migration: final acceptance and operations

This is the final acceptance record and operations index for the [Managed tools migration](../.scratch/mise-managed-tools/spec.md) (issue 07). It consolidates the per-slice evidence and the human-approved cleanup path; the slice-level detail lives in [mise-node-migration.md](mise-node-migration.md), [mise-runtime-migration.md](mise-runtime-migration.md), [mise-cli-ownership.md](mise-cli-ownership.md), and [mise-gui-editor-access.md](mise-gui-editor-access.md). Governing decisions: [Managed tool ownership](adr/2026-10-04-mise-managed-tool-boundary.md), [guarded Bootstrap](adr/2026-07-18-curated-tool-config-bootstrap.md), [no maintained test suite](adr/2026-10-04-no-maintained-dotfiles-test-suite.md).

**Verdict 2026-10-05:** existing-machine migration acceptance and the repeat-run acceptance are recorded below. Two acceptance items are **reported as gaps, not claimed**: the fresh-machine Bootstrap run (no clean Apple Silicon environment available) and the genuinely desktop-launched editor observation (a human GUI step — also issue 06's two open boxes). Everything that could be verified on this machine was verified against the [inventory baseline](../.scratch/mise-managed-tools/inventory.md).

## Verified on this machine (2026-10-05, macOS 26.5.1, Apple M1 Max, mise 2026.10.2)

All probes ran in fresh `env -i` Zsh shells outside this repository and in throwaway directories under the OS temp area; probe trust entries were revoked and the directories deleted afterwards. No install, uninstall, upgrade, or lock rewrite happened at any point.

- [x] **Linked global config and lock participate and are unmodified:** `~/.config/mise/config.toml` (whole-dir Dotbot link) and `mise.lock` are byte-identical to the tracked files (matching SHA-256); `mise ls` sources every tool from the linked config — node 22.22.3, python 3.12.4, ruby 3.3.0 + 3.2.2, go 1.27.1.
- [x] **Repeat run installs nothing:** `mise install --locked` from `$HOME` reports "installed 0 tools · 5 already installed in 2ms"; the lockfile hash is unchanged before/after; the `install-mise-tools.sh` and `install-cocoapods.sh` stages verify every declared version and the CocoaPods 1.15.2 pin on their skip paths. *(Scope note: the full `./install` entrypoint was not re-run for this record — its only non-deterministic part is the Homebrew-owned `brew bundle` upgrade behavior pre-dating this migration; issues 02 and 03 recorded clean full-repeat runs on this machine. This is also why the "installs reviewed versions" claim below is a no-op proof on a machine where the versions pre-exist — the first real locked install of a missing version is owed by the fresh-machine gap above.)*
- [x] **Interactive Zsh (fresh `env -i`):** `node`/`python3`/`ruby`/`go` resolve inside `~/.local/share/mise/installs/` (mise activate) at the declared versions and execute successfully (`node -e`, `python3 -c`, `ruby -e`, `go version`); `pod` 1.15.2, `gem`, `bundle` resolve in the mise ruby.
- [x] **Noninteractive Zsh (fresh `env -i`, plain `zsh -c`):** the same runtimes resolve through `~/.local/share/mise/shims` at the same versions and execute successfully; shims sit first on PATH. *(Probe note: `zsh -f` disables startup files entirely — a `-f`-flagged probe resolving `/usr/bin/python3` is a probe error, not a resolution failure.)*
- [x] **Global defaults outside the repository** hold in both shell modes (all probes ran in `$HOME` and temp dirs, never inside this repo).
- [x] **Unfamiliar projects are not implicitly trusted:** an untrusted `mise.toml` has its `[env]` not applied (`PROBE` unset) and tool invocations fail with `Trust them with mise trust` guidance (exit 1, no substitution, no download); interactive Zsh keeps the global default with a loud `is not trusted, run mise trust` warning.
- [x] **Explicit trust restores intended selection:** after `mise trust`, the project's `ruby = "3.2.2"` selects via shim; leaving the directory restores the global 3.3.0; `mise untrust` + probe cleanup leaves no residue.
- [x] **Compatible version files need no trust:** a `.tool-versions` file selects ruby 3.2.2 immediately; leaving restores 3.3.0. No files were written into the probe directories' repos (they were throwaway dirs; nothing outside temp was touched).
- [x] **Missing requested versions fail loudly, never download on directory entry:** `cd` into a `.python-version` 3.12.2 project exits 0 with no network activity and no install; invoking the tool errors with `Install all missing tools with: mise install` (exit 1); 3.12.2 is confirmed not installed afterwards.
- [x] **Previously existing installations and runtime state remain intact:** pyenv 3.12.4, rbenv 3.2.2/3.3.0, pnpm node 22.20.0 + 22.22.3 under `~/Library/pnpm/nodejs/`, Homebrew go 1.27.1 and ruby 4.0.7, rust 1.70.0 + cargo all still present and runnable.
- [x] **Retained tooling and excluded owners are usable:** pnpm 10.17.1, pi, opencode, gemini, poetry 2.0.0, uv, lms, rtk, gh, git/zsh foundations, and the Homebrew-owned CLIs (fzf, zoxide, eza, rg, bat, fd, btop, spf, oh-my-posh, wt, lazygit, zellij, yazi, tmux, jq, nvim, bun) all resolve to their intended owners and run. Claude Code remains absent by design (inventory D7). *(In interactive Zsh `wt` resolves to the tracked `.zshrc` shell function wrapping the brew binary — expected.)*
- [x] **Flutter absence holds (D6 closed by removal, issue 05):** no `flutter`, `dart`, or `fvm` resolves anywhere; no brew flutter/fvm, no `leoafarias` tap, no `~/.fvmrc`, no `~/fvm`. There is no retained exception to verify — the human decision points are documented in the inventory (D6) and the ADR amendment.
- [x] **Configuration validation and reference checks:** `zsh -n` passes on `.zshenv`/`.zshrc`; `bash -n` passes on all guarded stages; every `install.conf.yaml` script reference and every doc cross-reference in the mise docs resolves to an existing file.

## Gaps reported (acceptance not claimed)

1. **Fresh-machine Bootstrap run — not executed.** No clean Apple Silicon environment was available, and wiping this machine was not an option. The fresh-machine path is *structurally* verified — the guarded stage order, the Brewfile mise entry, the tracked config + committed lock, and the bash-3.2-compatible stages were all exercised by repeat runs on this machine — but a real `./install` on a clean machine is the only proof of the full path. Close by running `./install` on any new Apple Silicon Mac or clean macOS account and checking the stage output against [mise-node-migration.md](mise-node-migration.md) and [mise-runtime-migration.md](mise-runtime-migration.md).
2. **Genuinely desktop-launched editor observation — pending human step.** The editor integration is verified structurally (VS Code's shell integration sources the real `~/.zshenv`; clean `env -i` shells take the same startup-file path) and every probe passes in those shells, but only a human can launch VS Code from Dock/Spotlight and observe steps 1–8 of the procedure in [mise-gui-editor-access.md](mise-gui-editor-access.md). Those outputs also close issue 06's two open boxes. A terminal-launched editor does not satisfy this.

Both gaps are observation-only: no configuration, script, or documentation change is expected to follow from them unless an observation fails.

## Operations index

| Task | Workflow |
| --- | --- |
| Fresh setup | `./install` — Dotbot links the tracked config, then guarded stages install Homebrew, mise (Brewfile owner), pnpm, and the locked tools via `mise install --locked` from `$HOME`, then CocoaPods 1.15.2 and pi |
| Install a missing project tool | `cd <project> && mise install` — never triggered by directory entry (see [Trust workflow](mise-node-migration.md#trust-workflow)) |
| Trust an unfamiliar project | review the file, then `cd <project> && mise trust` (`mise untrust <path>` to revoke) |
| Reviewed version upgrade | edit `.config/mise/config.toml` → `mise lock --global` → review the lock diff → `mise install --locked` → commit config + lock together ([upgrade workflow](mise-node-migration.md#upgrade-workflow)) |
| Upgrade a standalone CLI | `brew upgrade <tool>` — Homebrew owns every CLI ([mise-cli-ownership.md](mise-cli-ownership.md)); `brew bundle` during Bootstrap may upgrade outdated formulae it manages (pre-existing behavior) |
| Regenerate shims after adding tools | `mise reshim` — stable shim dir, no per-version path edits |
| Shell resolution contexts | interactive = `mise activate` (`.zshrc`), noninteractive + editor zsh = shims (`.zshenv`), dependent Bootstrap stages = `mise x` — see the resolution table in [mise-node-migration.md](mise-node-migration.md) and the editor mechanics in [mise-gui-editor-access.md](mise-gui-editor-access.md) |

Ownership summary: mise owns the four language runtimes (+ CocoaPods as a pinned gem in mise ruby); Homebrew owns mise itself, foundations, GUI apps, OS deps, and every standalone CLI; pnpm/poetry/LM Studio/zinit keep their standalone owners; pi and OpenCode are excluded agent CLIs with untouched update ownership; rust stays at decision point D2 (`~/.cargo/bin` on PATH until decided); Flutter has no manager (removed 2026-10-05, issue 05).

## Post-verification cleanup path (human-approved, not executed)

Consolidates the checklists in [mise-runtime-migration.md](mise-runtime-migration.md#post-verification-cleanup-checklist-human-approved-not-executed) and [mise-cli-ownership.md](mise-cli-ownership.md#post-verification-cleanup-checklist-human-approved-not-executed). Nothing here has been run; every step needs separate explicit human approval and is a deliberate one-at-a-time action.

| Candidate | Why | Safeguard before removal |
| --- | --- | --- |
| `brew uninstall rbenv pyenv go ruby` | migrated/competing managers and runtimes (D5) | mise equivalents verified in daily use for a while |
| `~/.pyenv` (3.12.4, pip only) | superseded by mise python | none known; confirm no script references `~/.pyenv` |
| `~/.rbenv` (3.2.2/3.3.0 + original CocoaPods gems) | superseded by mise ruby + pinned pod | confirm no project depends on the rbenv-local gem set first |
| `~/.opencode/bin/opencode` standalone copy (131 MB, D4) | duplicate of the brew `opencode-v2` install | decide deliberately (D4); the `.zshenv` PATH entry must go with it or the fallback path dangles |
| `~/.cargo` + `~/.rustup` (x86_64 1.70.0) | only after D2 is decided | keep until then; removal is part of the D2 decision, not this checklist |
| owner-owned `~/flutter/bin` PATH entry in `~/.zprofile` | stale since the Flutter removal (issue 05) | outside dotfiles management; owner edits `~/.zprofile` directly |

Not candidates: pnpm's `~/Library/pnpm/nodejs/` copies — pnpm's global `package.json` records hard node paths into them (22.20.0 especially), so they stay while pnpm owns the excluded agent CLIs; zinit; LM Studio; poetry.
