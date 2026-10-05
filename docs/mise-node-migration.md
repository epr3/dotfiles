# Node under mise: install, trust, and upgrade workflow

This slice (issue 02 of the [Managed tools migration](../.scratch/mise-managed-tools/spec.md)) moves **Node.js** ownership from pnpm env to **mise**. pnpm, poetry, LM Studio, and the agent CLIs keep their existing owners; nothing was uninstalled or deleted. Governing decisions: [Managed tool ownership](adr/2026-10-04-mise-managed-tool-boundary.md), [guarded Bootstrap](adr/2026-07-18-curated-tool-config-bootstrap.md).

## What is tracked

- `.config/mise/config.toml` — the Dotfile-managed global mise configuration, linked by Bootstrap to `~/.config/mise/config.toml`. It declares the reviewed Node default (`22.22.3`, inventory D1) and the tool policy.
- `.config/mise/mise.lock` — the committed global lockfile (generated once with `mise lock --global`; Bootstrap writes next to the symlink target, inside this repository). Core node entries record the download URL and SHA-256 checksum per platform, so installs verify the same bytes.
- `scripts/install-mise.sh` — guarded stage: installs mise itself via Homebrew (the documented owner of mise).
- `scripts/install-mise-tools.sh` — guarded stage: runs `mise install --locked` from `$HOME` (outside this repository, so project config cannot participate), then verifies Node resolves to a mise-managed install.
- `scripts/setup-node-lts.sh` — removed; pnpm no longer selects Node (`pnpm env use` was the competing owner). pnpm's own node copies under `~/Library/pnpm/nodejs/` remain on disk.

## Resolution model

| Context | Mechanism | Result |
| --- | --- | --- |
| Interactive Zsh | `mise activate zsh` in `.zshrc` | mise-managed Node on PATH; entering a trusted project selects its version |
| Noninteractive Zsh | mise shim directory prepended in `.zshenv` | shims resolve the same versions without shell activation |
| Bootstrap dependent stages | scripts re-exec under `mise x` | locked Node available even with no previously activated shell |

The shim directory sits ahead of `PNPM_HOME` on PATH, so mise owns Node selection; `pnpm`, `pi`, and `gemini` still resolve from `PNPM_HOME` and pnpm's global packages keep working against their recorded node paths.

## Explicit install workflow

Fresh machines get the locked versions automatically through `./install`. For everything else, installation is explicit:

- **A trusted project requests a version that is missing** → running its tool errors with `Install all missing tools with: mise install`. Run `mise install` inside that project to install the requested version deliberately. No download ever happens on directory entry.
- **An untrusted project's `mise.toml`** → mise refuses to use it and errors with `Trust them with mise trust` guidance instead of silently falling back.
- **A new version as a personal default** → deliberate config change (below), never an opportunistic upgrade.

## Trust workflow

`mise.toml` (and other code-capable config) in a project is **not trusted implicitly**: entering the directory applies nothing, and tool invocations tell you to run `mise trust`. Review the file, then:

```sh
cd <project> && mise trust
```

Pure-data runtime-version files (`.nvmrc`, `.node-version`, `.tool-versions`) are honored for version selection and need no trust; they are enabled for node in the global config. Leaving the project restores the global default without writing to the project's repository.

## Upgrade workflow

Upgrades are deliberate reviewed changes, never a side effect of Bootstrap or `cd`:

1. Edit the version request in `.config/mise/config.toml`.
2. Run `mise lock --global` (refreshes `.config/mise/mise.lock`; nothing is installed).
3. Review the lockfile diff (versions, URLs, checksums), then `mise install --locked`.
4. Commit both files together.

`tool_config.locked = true` makes the committed lock authoritative: an ordinary `mise install` resolves the pinned versions and fails loudly if a lock entry is missing rather than re-resolving something newer.

## Manual acceptance checklist

Observed on this machine (2026-10-05, macOS 26.5.1, mise 2026.10.2):

- [x] `./install` installs the locked Node: `mise ls` shows `node 22.22.3` from `~/.config/mise/config.toml`.
- [x] Interactive Zsh resolves `node` to `~/.local/share/mise/installs/node/22.22.3/bin/node`; noninteractive Zsh resolves the same version through the shim.
- [x] Repeat `./install`: every stage reports "already installed", the install directory mtime is unchanged, and `mise.lock` is unmodified.
- [x] Untrusted project (`mise.toml` + env probe): env not applied, tool error names `mise trust`; no download, no silent fallback to global.
- [x] Missing requested version (`.nvmrc` with an uninstalled version): error with `Install all missing tools with: mise install`; no download on directory entry; explicit `mise install` activates the requested version in that project.
- [x] Leaving the project restores the global default; no files were written into the tested repositories.
- [x] pnpm 10.17.1, pi 1.0.0, opencode, rtk, and gh all still resolve and run.
- [ ] GUI-launched editors: covered by issue 06 — integration and verification procedure in [mise-gui-editor-access.md](mise-gui-editor-access.md).
