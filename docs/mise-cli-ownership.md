# Standalone CLIs stay in Homebrew: ownership and upgrade workflow

This slice (issue 04 of the [Managed tools migration](../.scratch/mise-managed-tools/spec.md)) resolved **by decision, without migration**. Asked to approve the live provisioning the planned CLI migration required, the owner decided on 2026-10-05 that **mise manages language runtimes only** — the Node, Python, Ruby, and Go installs that issues 02 and 03 already migrated ([mise-node-migration.md](mise-node-migration.md), [mise-runtime-migration.md](mise-runtime-migration.md)). Every standalone CLI keeps Homebrew as its installation and upgrade owner. Nothing was installed, upgraded, uninstalled, or deleted for this decision: the tracked `[tools]` section and `mise.lock` are byte-for-byte unchanged, no Brewfile entry moved, and the shell-resolution model is untouched. Recorded as a dated amendment to [the managed-tool-boundary ADR](adr/2026-10-04-mise-managed-tool-boundary.md).

## Ownership after this decision

| Tool group | Owner | Upgrade path |
| --- | --- | --- |
| node, python, ruby (+ CocoaPods 1.15.2 gem), go | **mise** (locked, tracked global config + `mise.lock`) | Reviewed bump → `mise lock --global` → diff → `mise install --locked` (see [mise-node-migration.md](mise-node-migration.md#upgrade-workflow)) |
| fzf, zoxide, eza, ripgrep, btop, superfile, oh-my-posh, worktrunk, lazygit, zellij, neovim (binary) | **Homebrew** (Brewfile) | Deliberate `brew upgrade <tool>`; fresh machines install them via `brew bundle` |
| bat, fd, yazi, tmux, bun, uv | **Homebrew** (ad-hoc installs — present on this machine, absent from the Brewfile per inventory §1/D3) | Deliberate `brew upgrade <tool>`; a fresh machine gets none of these until they are added to the `Brewfile` or installed explicitly |
| rtk | **Homebrew** (Brewfile) | `brew upgrade rtk` — it powers Pi's RTK integration (Pi is an excluded agent CLI) and the guarded `scripts/init-rtk-pi.sh` stage |
| jq | **Homebrew** (Brewfile) | `brew upgrade jq` — the verification dependency of `scripts/install-mise-tools.sh`, so it must stay brew-owned ahead of the mise-tools stage |
| git-delta, diffnav | **Homebrew** (Brewfile) | `brew upgrade` — no mise registry backend exists for either; git-delta is lazygit's configured pager, diffnav renders gh-dash diffs |
| git, zsh, bash, gh (+ gh-dash extension) | **Homebrew** (foundation) | `brew upgrade` |
| poetry, pnpm (+ Pi/gemini globals), LM Studio CLI, zinit, opencode | standalone / shell / agent-owned (unchanged) | Their own update mechanisms |

> Same-day follow-up (2026-10-05, issue 05): the owner then removed **Flutter entirely** — the Flutter-Foundation fork, FVM, and the official-stable brew cask are all retired, so the two Flutter rows that were here are gone. Nothing installs Dart/Flutter anymore; reinstalling is a deliberate future decision (a plain `brew install --cask flutter` if it's ever wanted again). See the ADR amendment.

The inventory's registry-eligibility table (issue 01, §1) remains valid evidence that these CLIs *could* have migrated; it was never exercised into installs. The 2026-10-05 decision closes the deferral note that issues 02 and 03 carried in `.config/mise/config.toml` — no per-tool mise verification is owed for CLIs anymore, because nothing installs them through mise.

## Upgrade workflow for the Homebrew-owned CLIs

Upgrades remain deliberate, as with the runtimes — just through Homebrew:

1. `brew upgrade <tool>` (or `brew upgrade` for a reviewed batch) — never a Bootstrap side effect you didn't choose.
2. Fresh machines keep getting the Brewfile-listed CLIs through `brew bundle`; add or remove formulae in the `Brewfile` explicitly. Note the split recorded in the ownership table: bat, fd, yazi, tmux, bun, and uv are ad-hoc Homebrew installs absent from the `Brewfile` (inventory §1), so fresh machines do not receive them today — a deliberate Brewfile change is required if they should.

Known Homebrew-owned behavior (recorded in issue 02's comments, unchanged here): a Bootstrap `brew bundle` run may upgrade already-outdated formulae it manages. That predates this migration and stays outside mise's scope.

## What is tracked (issue-04 state, same-day updates from the Flutter retirement noted inline)

- `Brewfile` — all retained CLIs stay listed (the flutter cask left the Brewfile with the 2026-10-05 Flutter retirement, issue 05).
- `.config/mise/config.toml` — comment-only update resolving the "deferred to issue 04" note; `[tools]` still declares exactly the four runtimes. The Flutter exception bullet left the comments with the same retirement.
- `.config/mise/mise.lock` — untouched.
- `install.conf.yaml`, all `scripts/` stages — untouched by this decision (the `.fvmrc` link left `install.conf.yaml` with the Flutter retirement; the bootstrap itself never touched Flutter).
- `.zshenv` / `.zshrc` — untouched by this decision: mise shims + activate keep owning runtime resolution, and every CLI integration (`fzf --zsh`, `zoxide init`, `oh-my-posh init`, `wt config shell init`) keeps executing its Homebrew binary. (`.zshrc` lost only the Dart CLI completion hook with the Flutter retirement.)

## Manual acceptance checklist

Observed on this machine (2026-10-05, macOS 26.5.1, mise 2026.10.2, read-only — no installs):

- [x] `mise ls` unchanged: go 1.27.1, node 22.22.3, python 3.12.4, ruby 3.3.0 + 3.2.2 — all sourced from `~/.config/mise/config.toml` (the linked tracked config); no CLI appears.
- [x] Interactive Zsh outside this repository resolves `node/python3/ruby/go/pod` to mise installs at the locked versions, and every retained CLI (fzf, zoxide, eza, rg, bat, fd, btop, spf, oh-my-posh, wt, lazygit, zellij, yazi, tmux, jq, nvim, bun, uv) to `/opt/homebrew/bin`.
- [x] Noninteractive Zsh outside this repository resolves the runtimes through the mise shim directory (shims sit first on PATH ahead of `PNPM_HOME` and Homebrew) and the CLIs through `/opt/homebrew/bin`.
- [x] Shell integrations still emit under the retained owners: `fzf --zsh`, `zoxide init --cmd cd zsh`, `oh-my-posh init zsh`, `wt config shell init zsh`.
- [x] Retained tooling unaffected: pnpm 10.17.1, pi, opencode, gemini, poetry, uv, lms, rtk 0.51.0, gh, `~/go/bin` tools. (fvm and flutter were still installed when this checklist ran; both were removed later the same day — see the same-day follow-up note above.)
- [ ] GUI-launched editors: covered by issue 06 (launch-environment integration).

## Post-verification cleanup checklist (human-approved, not executed)

Separate from the runtime cleanup list in [mise-runtime-migration.md](mise-runtime-migration.md). Unchanged here — this decision uninstalls nothing and adds no cleanup candidates.
