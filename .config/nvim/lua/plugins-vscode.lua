-- plugins-vscode.lua -- VS Code Neovim profile
-- Only embedded-safe editing helpers, no standalone UI/LSP/plugin-manager.

local pack = require 'pack'

-- ---------------------------------------------------------------------------
-- Plugin declarations
-- ---------------------------------------------------------------------------

pack.use 'tpope/vim-repeat'
pack.use 'gbprod/yanky.nvim'
pack.use 'https://codeberg.org/andyg/leap.nvim'
pack.use 'ggandor/flit.nvim'
pack.use 'echasnovski/mini.nvim'

-- Core-first treesitter: keep nvim-treesitter (main branch) for parser
-- installation, which is not provided by Neovim core.
pack.use('nvim-treesitter/nvim-treesitter', { version = 'main' })

-- ---------------------------------------------------------------------------
-- Ensure plugins are installed
-- ---------------------------------------------------------------------------

pack.lockfile 'vscode-pack-lock.json'
pack.ensure()

-- ---------------------------------------------------------------------------
-- Plugin configuration
-- ---------------------------------------------------------------------------

require('leap').add_default_mappings()

require('nvim.plugins.mini-profile').setup 'vscode'

-- Treesitter: syntax highlighting off inside VS Code; keep parsing for context.
require('nvim.plugins.treesitter').setup 'vscode'

-- yanky.nvim defaults (no further opts needed)
require('yanky').setup {}

-- vim-repeat, flit (leap-based motions) need no explicit setup.

-- vim: ts=2 sts=2 sw=2 et
