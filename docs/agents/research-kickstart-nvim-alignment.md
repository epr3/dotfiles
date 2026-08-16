# Research: kickstart.nvim vs. this repo's Neovim configuration

**Date:** 2026-08-16 · **Question:** what does current kickstart.nvim actually do, and where does `.config/nvim/` diverge from it under Neovim 0.12?
**Scope:** read-only. No configs were modified.

## Sources

- `nvim-lua/kickstart.nvim`, default branch `master`, at commit `626c660f5` (2026-08-07), 31.2k stars — [repo](https://github.com/nvim-lua/kickstart.nvim), [`init.lua`](https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/master/init.lua) (986 lines), [`README.md`](https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/master/README.md), [`lua/kickstart/health.lua`](https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/master/lua/kickstart/health.lua).
- Neovim 0.12.4 bundled docs (locally installed runtime, `/opt/homebrew/Cellar/neovim/0.12.4/share/nvim/runtime/doc/`): `pack.txt` (`:help vim.pack`), `lsp.txt`, `deprecated.txt`, `news.txt`.
- GitHub REST API for upstream repo identity/default branches (`api.github.com/repos/...`).
- This repo: `.config/nvim/**` at `4ce098e` plus one uncommitted edit to `lua/plugins.lua`; local runtime state under `~/.local/share/nvim/site/pack/plugins/start/`; `nvim --version` = **v0.12.4**.

## What kickstart is now (primary-source facts)

1. **Single-file, `vim.pack`-based.** `init.lua` is one 986-line file organised into ten numbered `do ... end` sections (OPTIONS, KEYMAPS & AUTOCMDS, PLUGIN MANAGER INTRO, UI/CORE UX, SEARCH & NAVIGATION, LSP, FORMATTING, AUTOCOMPLETE & SNIPPETS, TREESITTER, OPTIONAL EXAMPLES). lazy.nvim is gone; every plugin arrives via `vim.pack.add { gh 'owner/repo' }` with a local `gh()` helper (`init.lua:326`, `:346`).
2. **Config immediately follows `add`.** Kickstart calls `require('plugin').setup{}` on the line after `vim.pack.add` in the same session — `vim.pack.add()` installs into `site/pack/core/opt` and runs `:packadd` per plugin, so "plugin's code can be used directly after `add()`" (`:help vim.pack`, `vim.pack.add()`). No restart dance.
3. **Build steps via `PackChanged`.** One autocmd handles `install`/`update` kinds: `make` for telescope-fzf-native, `make install_jsregexp` for LuaSnip, `packadd` + `:TSUpdate` for nvim-treesitter (`init.lua:256-326`, `:help vim.pack-events`).
4. **Version pinning is first-class.** `{ src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' }`, `{ src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' }`, `{ src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' }` — `version` accepts a branch, tag, commit, or `vim.version.range()` (`:help vim.pack.Spec`).
5. **Lockfile is `nvim-pack-lock.json` at `$XDG_CONFIG_HOME/nvim/`,** and the README explicitly recommends *tracking it in version control*; updates run through `:lua vim.pack.update()` (`:write` confirms, `:quit` discards) and `:lua vim.pack.update(nil, { offline = true })` inspects state (README "Post Installation"; `:help vim.pack-lockfile`).
6. **Neovim floor is 0.12.** README: "targets *only* the latest stable and latest nightly". `lua/kickstart/health.lua` errors below `vim.version.ge(vim.version(), '0.12')`.
7. **Component choices as of `master`:** `blink.cmp` (not nvim-cmp) for completion, `mini.icons` + `MiniIcons.mock_nvim_web_devicons()` (not nvim-web-devicons, switched in `ec3f4489c`), `nvim-mini/mini.nvim` (org rename), `mason-org/mason.nvim` + `mason-org/mason-lspconfig.nvim` (`automatic_enable = false`) + `mason-tool-installer`, `guess-indent.nvim` (not vim-sleuth), `mini.statusline`, tokyonight, telescope with `make`-gated fzf-native, conform.nvim, fidget.nvim, nvim-treesitter pinned to `main` with the new `require('nvim-treesitter').install(...)` + `vim.treesitter.start()` + `FileType`-autocmd model.
8. **0.12-era API style throughout:** `vim.loader.enable()`, `vim.o.*` (with `vim.opt` only for list-like options), `vim.hl.on_yank()`, a central `vim.diagnostic.config{ jump = { on_jump = ... } }`, `client:supports_method(method, buf)` (colon call), `vim.lsp.config(name, server)` + `vim.lsp.enable(name)`, LSP keymaps on the 0.11+ `grn`/`gra`/`grD` defaults, and `mini.ai` remapped to `aa`/`ii` to avoid clashing with built-in treesitter incremental selection.

## Where this repo stands

The repo's stated posture is **Kickstart alignment** — "current Kickstart patterns and `vim.pack`, not vendor Kickstart unchanged" (`.config/CONTEXT.md`). Structure is multi-file (`init.lua` → `options`/`keymaps`/`pack`/`plugins` | `plugins-vscode`, plus `lua/nvim/plugins/*` and `lua/nvim/servers/*`), which is a deliberate divergence and fine.

### The core gap: `pack.lua` is not `vim.pack`

`.config/nvim/lua/pack.lua` is a hand-rolled manager despite the "`vim.pack` plugin manager" header comment. It shells out to `git clone --filter=blob:none` into `site/pack/plugins/{start,opt}` and never calls `vim.pack.add`/`update`/`get`. Consequences, all measured against `:help vim.pack`:

| Concern | `pack.lua` today | `vim.pack` (0.12.4) |
| --- | --- | --- |
| Load timing | `start/` dirs only enter the runtime path at startup, so `plugins.lua` must `return` early after a fresh install (the uncommitted edit) and ask for a restart | `add()` runs `:packadd` per plugin; code is usable on the next line |
| Version pinning | none — always default branch | `version` = branch/tag/commit/`vim.version.range()` |
| Non-GitHub sources | impossible — `M.use` takes `owner/repo` and hardcodes `https://github.com/` | `src` is any `git clone`-able URI |
| Name collisions | name derived from repo basename | explicit `name` field |
| Lockfile | none (`lazy-lock.json` still on disk, git-ignored via `.gitignore:4`, referencing the dead lazy.nvim era) | `nvim-pack-lock.json`, recommended to be tracked |
| Build hooks | run only on clone/update; `':' `-prefixed commands (e.g. `:TSUpdate`) are silently skipped | `PackChanged` autocmd with `install`/`update` kinds |
| Removal / inspection | none | `vim.pack.del()`, `vim.pack.get()`, update confirmation buffer |
| Dead code | `M.setup()` iterates `spec.setup`, a field `M.use` never sets | n/a |

### Concrete breakage found while grounding

- **Startup currently fails.** `nvim --headless -c 'qall!'` errors at `lua/nvim/plugins/treesitter.lua:2`: `module 'nvim-treesitter.configs' not found`. Cause: nvim-treesitter's **default branch is now `main`** (API check), so a branch-less clone gets the rewrite — the installed copy at `~/.local/share/nvim/site/pack/plugins/start/nvim-treesitter` is on `main` and has no `configs.lua`. Because `plugins.lua` requires modules unguarded, the error aborts everything after treesitter (harpoon, debug, indent-line, neotest, trouble, lualine, tmux, surround, treesitter-context, gitignore, oil, mdx). Kickstart avoids this exactly by pinning `version = 'main'` *and* using the `main`-branch API.
- **harpoon version drift.** `lua/nvim/plugins/harpoon.lua` uses the harpoon2 API (`harpoon:setup()`), but `ThePrimeagen/harpoon`'s default branch is `master` (harpoon1) and the installed copy is on `master` — latent failure once treesitter is fixed. Needs `version = 'harpoon2'`, which `pack.lua` cannot express.
- **Colourscheme installs as a directory literally named `nvim`.** `pack.use 'catppuccin/nvim'` derives the basename → `.../start/nvim` (confirmed on disk). Needs an explicit `name`.
- **`leap.nvim` moved to Codeberg** (`https://codeberg.org/andyg/leap.nvim`; the plugin itself prints this warning at startup). The VS Code profile declares `ggandor/leap.nvim` and `ggandor/flit.nvim`, and `pack.lua`'s GitHub-only URL construction cannot follow it; `vim.pack`'s `src` can.
- **Deprecated/removed APIs still in use** (all per 0.12.4 `deprecated.txt`): `vim.highlight.on_yank()` → `vim.hl` (`keymaps.lua:47`); `vim.diagnostic.goto_prev/goto_next` → `vim.diagnostic.jump{count=±1, float=true}` (`keymaps.lua:9-10`); `client.supports_method(...)` dot-called with a single argument in `lspconfig.lua` — 0.12 signature is `Client:supports_method(method, bufnr)`, so the method name is being passed as `self`.
- **Health check floor is stale.** `lua/nvim/health.lua` accepts ≥ 0.9.4; kickstart now demands ≥ 0.12, and this config's own patterns (`vim.lsp.config`, `vim.lsp.enable`) are 0.11+/0.12 anyway.

### Divergences that are choices, not bugs

Preserved **Personal plugin set** items with no kickstart counterpart: harpoon, oil, trouble, lualine, neotest (+vitest/go), nvim-dap stack, indent-blankline, nvim-surround, treesitter-context, gitignore, mdx, vim-tmux-navigator, catppuccin, and the per-server modules under `lua/nvim/servers/`. Keeping nvim-cmp instead of blink.cmp and nvim-web-devicons instead of mini.icons are also choices — but note the upstream org renames the repo is still pointing at: `williamboman/mason.nvim` → **`mason-org/mason.nvim`** and `echasnovski/mini.nvim` → **`nvim-mini/mini.nvim`** (both API-confirmed HTTP 301 redirects; git still follows them, so this is drift rather than breakage). The repo also skips `mason-lspconfig`, hand-maintaining a `server_defaults` table of `cmd`/`filetypes` that nvim-lspconfig already ships — kickstart uses `mason-lspconfig` purely for the name translation and lets lspconfig supply `cmd`/`filetypes`.

## Conclusions

1. **The alignment gap is one module, not the layout.** Replacing `pack.lua`'s bespoke clone/restart cycle with `vim.pack.add` (plus a `PackChanged` build autocmd) removes the restart dance, the dead `M.setup()`, and the GitHub-only limitation in a single change, while the multi-file structure stays.
2. **Un-pinned default branches are actively breaking this config.** nvim-treesitter (now `main`) breaks startup today; harpoon (needs `harpoon2`) breaks next. Both are `version` fields under `vim.pack` — the highest-value reason to migrate.
3. **Adopt the lockfile.** Track `.config/nvim/nvim-pack-lock.json` and drop the stale `lazy-lock.json` (and its `.gitignore` entry), matching kickstart's README recommendation and this repo's "declarative, non-secret, tracked config" stance.
4. **Guard per-plugin config requires.** `plugins.lua`'s unguarded `require` chain turns one broken plugin into a dead config; kickstart's per-section `do ... end` blocks are more forgiving.
5. **Two small hygiene passes:** retire the deprecated API calls (`vim.hl.on_yank`, `vim.diagnostic.jump`, `client:supports_method`) and raise `lua/nvim/health.lua` to a 0.12 floor.
6. **Optional, revisit deliberately:** blink.cmp vs nvim-cmp, mini.icons vs nvim-web-devicons, `mason-lspconfig` vs the hand-written `server_defaults`, and the `mason-org`/`nvim-mini` renames.

## Caveats

- `.config/nvim/lua/plugins.lua` has a pre-existing uncommitted edit (the `if pack.ensure() then return end` early-return); findings account for it.
- Running `nvim --headless` to reproduce startup behaviour caused `pack.lua` to clone missing plugins into `~/.local/share/nvim/site/pack/plugins/` (machine-local plugin data, outside this repo). No tracked file was changed.
- Kickstart's `master` moves quickly (lazy.nvim → `vim.pack` landed recently); re-check against a fresh commit before acting on component-level choices.
