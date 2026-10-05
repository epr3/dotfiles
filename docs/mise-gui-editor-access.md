# Managed tools in GUI-launched editors

This slice (issue 06 of the [Managed tools migration](../.scratch/mise-managed-tools/spec.md)) makes **desktop-launched editors** (and their zsh subprocesses) resolve Managed tools through mise's stable shims without a terminal launch. It adds no launchctl changes, no editor-settings changes, and no per-version paths: the integration is the already-tracked `.zshenv`, plus this document's verification procedure. Governing decisions: [Managed tool ownership](adr/2026-10-04-mise-managed-tool-boundary.md), [guarded Bootstrap](adr/2026-07-18-curated-tool-config-bootstrap.md).

## Mechanism

Desktop processes do **not** inherit Zsh startup configuration — macOS launchd spawns Dock/Spotlight/Finder apps with launchd's own environment (system PATH, no `brew`, no shims). The integration therefore targets the shells the editor spawns, not the editor process itself:

| Context | Spawns | Startup files | Result |
| --- | --- | --- | --- |
| VS Code integrated terminal | `/bin/zsh` (the account's `UserShell`) | `~/.zshenv` → `~/.zshrc` | shims on PATH via `.zshenv`; interactive activation via `.zshrc` |
| VS Code tasks / integrated-debug shells | `/bin/zsh -c …` | `~/.zshenv` only | shims on PATH; no activation needed |
| Other zsh-spawning editors (JetBrains, etc.) | user shell or explicit zsh | `~/.zshenv` | shims on PATH |
| The editor process itself (extension host) | — | none | sees launchd PATH only; see Known limits |

Why `.zshenv` is sufficient and safe for every editor-spawned zsh:

- zsh sources `~/.zshenv` for **all** invocation modes — login, interactive, and `zsh -c` scripts — even when the environment starts empty. `.zshenv` prepends mise's shim directory ahead of `PNPM_HOME`, so mise owns Node selection everywhere; Python, Ruby, and Go resolve through the same shim directory.
- VS Code shell integration does not bypass it: VS Code rewrites `ZDOTDIR` for its injected rc scripts, and its generated `shellIntegration-env.zsh` sources `$USER_ZDOTDIR/.zshenv` (the real `~/.zshenv`) before restoring `ZDOTDIR`. Verified against the installed VS Code 1.140.0 bundle; nothing in this repository's config participates in that trick — it is stock VS Code behavior.
- Shims are **stable**: `~/.local/share/mise/shims/<tool>` dispatches by re-resolving versions on each invocation (global config, trusted project config, or pure-data version files by cwd). Tools added in later migrations appear as new shims via `mise reshim` — no per-version path edits anywhere.

Bootstrap link: `.zshenv` is linked by the existing Dotbot `install` (issue 02); nothing new is linked.

**Owner decision 2026-10-05:** the launchctl `setenv`/LaunchAgent route was considered and **declined** — only tracked Zsh configuration is used. Consequence (accepted): the editor process's own non-zsh subprocesses (e.g. extension-host code exec'ing `node` directly, or a task configured with `shell: false` and a bare command name) see launchd's PATH and will not find mise shims. Editor-managed tooling (VS Code extensions, Mason/language servers) is intentionally untouched — see Known limits.

## Trust, missing versions, and project selection from editor shells

Same model as every other zsh context (see [mise-node-migration.md](mise-node-migration.md#trust-workflow)); all of it flows through the shims, so it behaves identically in an editor terminal:

- **Untrusted project `mise.toml`** — tool invocations error with `mise trust` guidance; its `[env]` is not applied; no download, no silent fallback.
- **Trusted project** (after explicit `mise trust`) — its tool versions select through the shims; pure-data files (`.nvmrc`, `.python-version`, `.tool-versions`, …) need no trust. Leaving the directory restores the global defaults.
- **Missing requested version** — the shim fails with `Tool not installed for shim: <tool> … Install all missing tools with: mise install`; no download on directory entry; explicit `mise install` in the project restores intended resolution.

## Real GUI-launch verification procedure

Run once per migration slice (and after any future ownership change). Steps use VS Code, the installed GUI editor. Do **not** launch the editor from an activated terminal — a terminal-launched editor inherits the shell's PATH and proves nothing about the desktop path.

1. Quit VS Code completely (`Cmd+Q`). Relaunch from the **Dock or Spotlight** (a launchd GUI launch, not `open`/`code` from a terminal).
2. In VS Code, open a folder **outside the dotfiles repository** (e.g. any project under `~/`) and open an integrated terminal.
3. Ownership and versions — every `command -v` must print a path under `~/.local/share/mise/shims`, and `mise which` must print inside `~/.local/share/mise/installs`:
   ```sh
   command -v node python3 ruby go
   node --version; python3 --version; ruby -v; go version
   mise which node python3 ruby go
   ```
   Expected: node 22.22.3, python 3.12.4, ruby 3.3.0, go 1.27.1.
4. Subprocess command success from the editor context (a real child process, not a builtin):
   ```sh
   node -e 'console.log("ok", process.version)'
   python3 -c 'import sys; print("ok", sys.version.split()[0])'
   go version; ruby -e 'puts "ok #{RUBY_VERSION}"'
   ```
5. Untrusted project (launchd-like clean shell + editor terminal agreement):
   ```sh
   TDIR=$(mktemp -d); mkdir -p "$TDIR/proj"; printf '[tools]\nruby = "3.2.2"\n[env]\nPROBE = "leaked"\n' > "$TDIR/proj/mise.toml"
   cd "$TDIR/proj" && ruby -v; echo "probe=${PROBE:-unset}"   # → mise trust error; probe=unset; no download
   ```
6. Trusted selection and restoration (continue in the same directory):
   ```sh
   mise trust && ruby -v     # → 3.2.2
   cd "$TDIR" && ruby -v     # → 3.3.0 (global default restored)
   mise untrust "$TDIR/proj"; rm -rf "$TDIR"
   ```
7. Missing version, actionable failure, no download:
   ```sh
   TDIR2=$(mktemp -d); mkdir -p "$TDIR2/proj"; printf '3.12.2\n' > "$TDIR2/proj/.python-version"
   cd "$TDIR2/proj" && python3 --version    # → 'Tool not installed for shim' + 'mise install' guidance; 3.12.2 not installed afterwards
   cd "$HOME"; rm -rf "$TDIR2"
   ```
8. Retained tooling still usable from the editor terminal: `pnpm --version`, `pi --version` (or the pi entry point), `opencode --version`, `gh --version`, `pod --version` resolve and run; Mason-installed language servers in Neovim and VS Code extensions untouched.

## Manual acceptance checklist

Observed where noted (2026-10-05, macOS 26.5.1, VS Code 1.140.0, mise 2026.10.2):

- [x] VS Code shell integration sources the real `~/.zshenv` after `ZDOTDIR` rewriting (bundle inspection: `shellIntegration-env.zsh` + `ptyHostMain.js` `USER_ZDOTDIR`), so integrated terminals and task shells run `.zshenv`'s shim prepend regardless of how VS Code itself was launched.
- [x] Editor-shell-path probes (clean `env -i` zsh, the same startup-file path a desktop-spawned editor shell takes): untrusted `mise.toml` errors with `mise trust` guidance, env not applied; after explicit trust, project ruby 3.2.2 selects via shim and leaving restores global 3.3.0; missing `.python-version` 3.12.2 fails with `mise install` guidance, exit code 1, nothing downloaded, 3.12.2 not installed afterwards.
- [ ] GUI-launch observation (steps 1–8 above): **pending human step** — launch VS Code from Dock/Spotlight and record the outputs here.
- [ ] Retained editor-managed tooling spot-check from the editor terminal (step 8): **pending human step**.
- Editor-managed plugins/language servers, agent CLIs (pi, OpenCode), their credentials and update ownership: untouched — no editor settings, extension, or agent config was read or modified by this slice; `.zshenv`'s PNPM_HOME, `~/go/bin`, `~/.opencode/bin`, and cargo/lmstudio path entries remain intact for anything spawned through zsh.

## Known limits (accepted by the owner decision above)

- The editor process itself and shellless subprocesses it execs directly (extension host, `shell: false` tasks with bare command names) see launchd's PATH — mise shims, Homebrew, and `PNPM_HOME` are absent there. This is why editor-managed tooling (which brings its own runtimes or resolves through terminals) is preserved rather than migrated.
- If a future need arises (e.g. an extension that must exec `node` without a shell), the fix is a login-time `launchctl setenv PATH` LaunchAgent — deliberately not adopted. Revisit as a new issue, not silently.
