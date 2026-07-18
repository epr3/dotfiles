# dotfiles

Personal dotfiles — Shell, tmux, Neovim, VS Code, pi (coding agent), and macOS dev tools.

Managed with [Dotbot](https://github.com/anishathalye/dotbot).

## Quick start

```bash
git clone https://github.com/epr3/dotfiles.git
cd dotfiles
git submodule update --init dotbot
./install           # link configs + run bootstrap scripts
```

> To install only the config links (skip Homebrew, VS Code extensions, etc.):
> `./install --only link`

## What's inside

| Directory | What |
|---|---|
| `.config/` | worktrunk, gh-dash, oh-my-posh, lazygit, nvim, tmux, alacritty |
| `.pi/` | pi coding agent config, skills, themes, extensions |
| `vscode/` | VS Code settings, keybindings, snippets |
| `scripts/` | Idempotent bootstrap scripts (Homebrew, pnpm, Node, git identity) |
| `dotbot/` | Dotbot submodule for symlink management |

## Post-clone steps

- [Generate SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and add to GitHub
- Update submodules: `git submodule update --recursive --remote`
- Open Neovim + VS Code to let extension managers finish setup

## License

MIT