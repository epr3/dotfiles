# dotfiles

Personal dotfiles — Shell, Zellij, Neovim, VS Code, pi (coding agent), and macOS dev tools.

Managed with [Dotbot](https://github.com/anishathalye/dotbot).

## Quick start

```bash
git clone https://github.com/epr3/dotfiles.git
cd dotfiles
git submodule update --init dotbot
./install           # link configs + run bootstrap scripts, including pi
```

> To install only the config links (skip Homebrew, VS Code extensions, etc.):
> `./install --only link`

## What's inside

| Directory | What |
|---|---|
| `.config/` | worktrunk, gh-dash, oh-my-posh, lazygit, nvim, zellij, ghostty, btop, Superfile, yazi (pending retirement) |
| `.pi/` | pi coding agent config, skills, themes, extensions |
| `vscode/` | VS Code settings, keybindings, snippets |
| `scripts/` | Idempotent bootstrap scripts (Homebrew, pnpm, Node, git identity) |
| `dotbot/` | Dotbot submodule for symlink management |

> **Terminal migration**: This repository previously managed Alacritty. It now manages Ghostty. The repository changes do not uninstall Alacritty or remove any live home-directory symlinks; those remain until you choose to migrate locally.
>
> **File manager migration**: Launch Superfile directly with `spf`. Its curated configuration is linked at `~/.config/superfile/config.toml`; upstream hotkeys remain unchanged. Repository changes do not uninstall Yazi or remove its existing configuration. After validating Superfile, remove only an obsolete Yazi config symlink (if present) and uninstall Yazi explicitly with `brew uninstall yazi` if desired. Natural sorting, case-insensitive comparison, Neovim, previews, and no change-directory-on-quit are configured. Persistent hidden-file and directories-first preferences and explicit file-size display are not exposed by Superfile 1.6.0's configuration schema; hidden files can be toggled with its upstream default hotkey.

## Zellij tips

Zellij uses the built-in **Catppuccin Macchiato** dark theme and starts in
normal mode with stock keybindings. The status bar shows Ctrl/Alt shortcuts.

- `Ctrl-o`, then `w`: open the session manager to create, attach, or resurrect a session.
- `Ctrl-o`, then `d`: detach without terminating the session.
- `Ctrl-g`: toggle locked mode to pass application shortcuts through.

Inside Zellij, `wt switch <branch>` opens or reuses a branch tab with pi above
lazygit and a shell. Worktrunk loads `.config/zellij/layouts/worktree.kdl`
directly; no helper scripts are needed.

## Post-clone steps

- [Generate SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and add to GitHub
- Update submodules: `git submodule update --recursive --remote`
- Run `pi` and `/login` (or set provider API keys) after the first install
- Open Neovim + VS Code to let extension managers finish setup

## License

MIT