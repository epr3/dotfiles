-- plugins-vscode.lua -- VS Code Neovim profile
-- Only embedded-safe editing helpers, no standalone UI/LSP/plugin-manager.

local pack = require 'pack'

-- ---------------------------------------------------------------------------
-- Plugin declarations
-- ---------------------------------------------------------------------------

pack.use 'tpope/vim-repeat'
pack.use 'gbprod/yanky.nvim'
pack.use 'ggandor/leap.nvim'
pack.use 'ggandor/flit.nvim'
pack.use 'echasnovski/mini.move'
pack.use 'echasnovski/mini.comment'
pack.use 'echasnovski/mini.pairs'
pack.use 'echasnovski/mini.surround'
pack.use 'echasnovski/mini.ai'

-- Treesitter works in VS Code for syntax, but highlight is off.
pack.use 'nvim-treesitter/nvim-treesitter'
pack.use 'nvim-treesitter/nvim-treesitter-context'

-- ---------------------------------------------------------------------------
-- Ensure plugins are installed
-- ---------------------------------------------------------------------------

pack.ensure()

-- ---------------------------------------------------------------------------
-- Plugin configuration
-- ---------------------------------------------------------------------------

require('leap').create_default_mappings()

require('mini.move').setup {}
require('mini.comment').setup {}
require('mini.pairs').setup {}
require('mini.surround').setup {
  mappings = {
    add = 'gza',
    delete = 'gzd',
    find = 'gzf',
    find_left = 'gzF',
    highlight = 'gzh',
    replace = 'gzr',
    update_n_lines = 'gzn',
  },
}
require('mini.ai').setup { n_lines = 500 }

-- Treesitter: syntax highlighting off inside VS Code; keep parsing for context.
require('nvim-treesitter.configs').setup {
  highlight = { enable = false },
  context_commentstring = { enable = true },
}

-- yanky.nvim defaults (no further opts needed)
require('yanky').setup {}

-- vim-repeat, flit (leap-based motions) need no explicit setup.

-- vim: ts=2 sts=2 sw=2 et
