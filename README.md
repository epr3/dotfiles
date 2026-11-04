# dotfiles

Personal dotfiles — Shell, Zellij, Neovim (standalone and the VS Code Neovim profile), pi (coding agent), and macOS dev tools.

Managed with [Dotbot](https://github.com/anishathalye/dotbot).

## Quick start

```bash
git clone https://github.com/epr3/dotfiles.git
cd dotfiles
git submodule update --init dotbot
./install           # link configs + run bootstrap scripts, including Pi-Bolt + Pi extensions
```

> To install only the config links (skip Homebrew, package installs, git identity, etc.):
> `./install --only link`

## What's inside

| Directory | What |
|---|---|
| `.config/` | Dotfile-managed tool config: worktrunk, gh-dash, oh-my-posh, lazygit, nvim (standalone + VS Code Neovim profile), zellij, ghostty, btop, Superfile, OpenCode, mise |
| `skills/` | Shared agent skills (one neutral source) — linked at `~/.agents/skills`, discovered natively by both Pi and OpenCode |
| `.pi/` | pi coding agent config, themes, extensions |
| `scripts/` | Idempotent bootstrap scripts (Homebrew, mise + locked tools, pnpm, CocoaPods, pi-bolt install/activate + pi extensions, git identity) |
| `dotbot/` | Dotbot submodule for symlink management |

> **Pi runtime migration**: Pi-Bolt — the compiled distribution of Pi — is now the `pi` runtime: Homebrew owns installation and upgrades (`brew upgrade pi-bolt`; declared in the Brewfile), and after activation the PATH-visible entry point makes `pi` launch Pi-Bolt in interactive shells, noninteractive `zsh -c`, and direct executable calls alike (`pi-bolt` also invokes it directly). Bootstrap (`scripts/install-pi-bolt.sh`) activates the entry point automatically on a machine with no existing `pi`; on a machine that already has one it leaves resolution unchanged and prints the validate → activate → rollback steps.
>
> **Rollback**: `scripts/pi-entrypoint.sh deactivate` removes only the entry
> point's `pi` symlink — new shells resolve `pi` to the retained pnpm Pi
> (`~/Library/pnpm/pi`, version 1.5.0) again. Local state — settings, sessions,
> credentials, packages under `~/.pi/agent`, and the agent context store — is
> untouched either way; `brew uninstall pi-bolt` is optional. Re-activate with
> `scripts/pi-entrypoint.sh activate`.
>
> Note: Zellij worktree tabs still launch the agent with `zsh -c "exec pi"`, so
> they now start Pi-Bolt too.
>
> **Terminal migration**: This repository previously managed Alacritty. It now manages Ghostty. The repository changes do not uninstall Alacritty or remove any live home-directory symlinks; those remain until you choose to migrate locally.
>
> **File manager migration**: Launch Superfile directly with `spf`. Its curated configuration is linked at `~/.config/superfile/config.toml`; upstream hotkeys remain unchanged. Repository changes do not uninstall Yazi or remove its existing configuration. See [validation results and safe optional cleanup](docs/superfile-migration.md), including conversion of any old whole-directory Superfile symlink. After those checks pass, remove only a verified obsolete repository-managed Yazi config symlink and uninstall Yazi explicitly with `brew uninstall yazi` if desired. Natural case-insensitive sorting (directories first), file sizes where panel width permits, Neovim, previews, and no change-directory-on-quit are configured. Persistent hidden-file visibility is not exposed by Superfile 1.6.0's configuration schema; hidden files can be toggled with its upstream default hotkey.

## Zellij tips

Zellij uses the built-in **Catppuccin Macchiato** dark theme and starts in
normal mode with stock keybindings. The status bar shows Ctrl/Alt shortcuts.

- `Ctrl-o`, then `w`: open the session manager to create, attach, or resurrect a session.
- `Ctrl-o`, then `d`: detach without terminating the session.
- `Ctrl-g`: toggle locked mode to pass application shortcuts through.

Inside Zellij, `wt switch <branch>` opens or reuses a branch tab with Pi above
lazygit and a shell. Worktrunk loads `.config/zellij/layouts/worktree.kdl`
directly; no helper scripts are needed. New tabs require `pi` on PATH.
Reused tabs keep their existing agent process.

## OpenCode scratch files

`~/.ignore` is linked to this repo's `.ignore`, making `.scratch/` searchable in
projects under your home directory even when Git ignores it. This also applies
to other ripgrep-based tools; Git's ignore rules are unchanged.

OpenCode v2.0.26's `@` file picker needs the exception in each project's root
`.ignore` too. Add these lines to that file, preserving any existing rules:

```gitignore
!.scratch/
!**/.scratch/**
```

Reopen OpenCode in that project to refresh its file index. Projects outside your
home directory also need this local exception for agent searches.

## Post-clone steps

- [Generate SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and add to GitHub
- Update submodules: `git submodule update --recursive --remote`
- Run Pi (`pi`; equivalently `pi-bolt`) and `/login` (or set provider API keys) after the first install
- Open Neovim + VS Code to let extension managers finish setup

## License

MIT
