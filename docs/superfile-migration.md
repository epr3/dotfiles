# Superfile migration

## Launch and configuration

Launch directly with `spf` from Zsh. The repository's `.zshenv` exports
`XDG_CONFIG_HOME="$HOME/.config"`; `spf pl` reports configuration and hotkeys
under `$XDG_CONFIG_HOME/superfile`, including on macOS. No alias, launcher, or
change-directory integration is needed. Use upstream default hotkeys, not Yazi
bindings.

Dotbot links only `config.toml` into a real local `~/.config/superfile` directory.
Unlike the other wildcard-linked tool directories, Superfile generates upstream
hotkeys and themes beside its config. File-only linking keeps those assets out
of the repository; logs/data also remain local. Do not use `--fix-config-file`
without reviewing changes to the tracked config.

The settings select Neovim (`editor` and `dir_editor` are `'nvim'`), natural
case-insensitive sorting, previews, and `cd_on_quit = false`. Superfile supplies
the selected directory argument to Neovim. Zoxide support is enabled at the
owner's request and requires the existing `zoxide` package. Natural sorting
already puts directories first. `file_panel_extra_columns = 1` enables the size
column when the panel is wide enough; `file_size_use_si` controls its units.
Superfile 1.6.0 does not expose persistent hidden-file visibility in its config
schema; toggle hidden files with the upstream default hotkey. These preferences
do not imply full Yazi parity.

Release-source evidence: [natural sorting](https://github.com/yorukot/superfile/blob/v1.6.0/src/internal/ui/filepanel/sort.go),
[size columns](https://github.com/yorukot/superfile/blob/v1.6.0/src/internal/ui/filepanel/columns.go),
and [directory editor arguments](https://github.com/yorukot/superfile/blob/v1.6.0/src/internal/handle_file_operations.go).

### Existing Superfile directory symlink

If a previous install linked the entire `~/.config/superfile` directory, convert
it before launching again. Bootstrap deliberately skips the config-file link
when its parent is a symlink; it does not remove that directory link or its target.

Inspect `ls -ld "$HOME/.config/superfile"` and
`readlink "$HOME/.config/superfile"`. Only if it is a verified symlink to this
repository's `.config/superfile`, optionally run
`unlink "$HOME/.config/superfile"`, then `./install --only link`. The latter
creates a real local directory and links the config file. Verify with `ls -ld`
and `spf pl`. The unlink removes only the link, not its target. Preserve any
customized assets before conversion; do not delete files generated into the old
target automatically. Leave unrelated symlinks, real directories, and user files
alone. If ownership is uncertain or Dotbot reports a conflict, stop and inspect.

## CLI validation outcome

Tested installed Homebrew Superfile **v1.6.0**, using disposable homes and
repository copies under the OS temporary directory. The fixture copied the
root install/link config, Zsh files, `.fvmrc`, Superfile config, and the linked
clone helper, and reused the initialized Dotbot submodule via a symlink.
`HOME` and `ZDOTDIR` selected the empty temporary home; `./install --only link`
created its links before Zsh validation. No real file operations, package
uninstallation, or local cleanup were performed.

| Check | Outcome |
|---|---|
| Config discovery | **Pass:** Zsh loaded the repository `.zshenv`; `spf pl` reported config and hotkeys beneath the isolated home's `.config/superfile`, not macOS Application Support. Data/log paths remained outside the repository. |
| Repeatable linking | **Pass:** the existing `./install --only link` entrypoint exited 0 twice in an isolated home and repository fixture containing its link targets. The config file was linked inside a real local directory. No package stages ran. A separate legacy-directory-symlink fixture was preserved and the file-link action skipped safely. |
| Accepted settings | **Pass (parsing only):** with the owner's completed v1.6.0 config, startup produced no missing-field or unknown-setting warning. Both startup attempts reached the terminal initialization error below; full interactive behavior was not verified. Neovim, natural case-insensitive sorting, the size column, previews, disabled cwd integration, and requested Zoxide settings were retained. |
| First/repeated startup cleanliness | **Pass:** the fixture repository retained exactly one unchanged `config.toml`; 22 generated files (upstream hotkeys and themes) appeared only in the local config directory. Repeated startup retained these counts. Logs/data were outside the fixture repository. The real repository's pre-existing settings and untracked scratch files were preserved; no generated assets were introduced by these isolated checks. |
| Shell cwd after launch/quit | **Not run:** no interactive terminal was available. `cd_on_quit = false` is configured, but launch/quit behavior was not verified. |
| Safe copy/move | **Not run:** no interactive terminal was available. No headless terminal-UI automation or substitute shell copy/move test is claimed. |

Both startup attempts exited 1 solely with Bubble Tea's `/dev/tty` error in this
environment. The initial directory-link check had generated 22 repository files;
file-only linking resolved that blocker. The initial incomplete config had
reported missing fields; the owner's config update resolved that warning.

Repository shell regression suites (`scripts/test-artifact-locations.sh`,
`scripts/test-check-parity.sh`, and `scripts/test-git-clone-for-worktrees.sh`) passed. No new test
framework, Yazi hotkey translation, or visual-preview gate was introduced.

## Optional local Yazi cleanup — only after validation

Tracked Yazi configuration has been retired and `Brewfile` selects Superfile.
Removing a Homebrew manifest entry does **not** uninstall the existing package.
Bootstrap does not uninstall Yazi or delete local Yazi configuration.

1. Validate discovery with `spf --version` and `spf pl`, repeat config-only
   linking safely, and confirm successful settings loading and clean first and
   repeated startup. In an interactive terminal, compare shell `pwd` before and
   after launching/quitting. Exercise copy and move only on disposable fixture
   files; verify their contents and resulting locations before removing them.
2. After validation, inspect the old link with
   `ls -ld "$HOME/.config/yazi"` and `readlink "$HOME/.config/yazi"`.
   Confirm it is a symlink whose target is this repository's retired
   `.config/yazi` directory. A relative target is resolved from the link's parent,
   not the shell's cwd; a dangling link still requires this verification.
   If it points elsewhere, is a real directory, or ownership is uncertain, leave
   it alone. Preserve unrelated user files and any desired local customizations.
3. **Only for that verified obsolete repository-managed symlink**, optionally
   run `unlink "$HOME/.config/yazi"`. Do not append a slash, recursively remove
   the path, or delete its target. No cleanup command is run by bootstrap.
4. Optionally uninstall the old package explicitly with `brew uninstall yazi`.
   This is separate from repository linking and manifest changes; it is not
   required to use Superfile. No broad Homebrew cleanup is needed.
