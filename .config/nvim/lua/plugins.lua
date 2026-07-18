-- plugins.lua -- standalone Neovim plugin declarations
-- Declare repos for pack to install, ensure they're cloned, then configure.

local pack = require 'pack'

-- ---------------------------------------------------------------------------
-- Plugin declarations (installed into pack/plugins/start/)
-- ---------------------------------------------------------------------------

pack.use 'tpope/vim-sleuth'
pack.use 'numToStr/Comment.nvim'
pack.use 'catppuccin/nvim'
pack.use 'nvim-tree/nvim-web-devicons'
pack.use 'lewis6991/gitsigns.nvim'
pack.use 'folke/which-key.nvim'
pack.use 'nvim-telescope/telescope.nvim'
pack.use 'nvim-lua/plenary.nvim'
pack.use('nvim-telescope/telescope-fzf-native.nvim', { build = 'make' })
pack.use 'nvim-telescope/telescope-ui-select.nvim'
pack.use 'folke/lazydev.nvim'
pack.use 'Bilal2453/luvit-meta'
-- neovim/nvim-lspconfig kept for utility functions (root_pattern, etc.) used by
-- some server configs; registration uses the built-in vim.lsp.enable.
pack.use 'neovim/nvim-lspconfig'
pack.use 'williamboman/mason.nvim'
pack.use 'WhoIsSethDaniel/mason-tool-installer.nvim'
pack.use 'j-hui/fidget.nvim'
pack.use 'hrsh7th/cmp-nvim-lsp'
pack.use 'stevearc/conform.nvim'
pack.use 'windwp/nvim-autopairs'
pack.use 'hrsh7th/nvim-cmp'
pack.use 'L3MON4D3/LuaSnip'
pack.use 'saadparwaiz1/cmp_luasnip'
pack.use 'hrsh7th/cmp-path'
pack.use 'folke/todo-comments.nvim'
pack.use 'echasnovski/mini.nvim'
pack.use 'nvim-treesitter/nvim-treesitter'
pack.use 'ThePrimeagen/harpoon'
pack.use 'mfussenegger/nvim-dap'
pack.use 'rcarriga/nvim-dap-ui'
pack.use 'nvim-neotest/nvim-nio'
pack.use 'jay-babu/mason-nvim-dap.nvim'
pack.use 'leoluz/nvim-dap-go'
pack.use 'lukas-reineke/indent-blankline.nvim'
pack.use 'nvim-neotest/neotest'
pack.use 'antoinemadec/FixCursorHold.nvim'
pack.use 'marilari88/neotest-vitest'
pack.use 'nvim-neotest/neotest-go'
pack.use 'folke/trouble.nvim'
pack.use 'nvim-lualine/lualine.nvim'
pack.use 'christoomey/vim-tmux-navigator'
pack.use 'kylechui/nvim-surround'
pack.use 'nvim-treesitter/nvim-treesitter-context'
pack.use 'wintermute-cell/gitignore.nvim'
pack.use 'stevearc/oil.nvim'
pack.use 'davidmh/mdx.nvim'

-- ---------------------------------------------------------------------------
-- Ensure plugins are installed
-- ---------------------------------------------------------------------------

pack.ensure()

-- ---------------------------------------------------------------------------
-- Plugin configuration
-- ---------------------------------------------------------------------------

require 'nvim.plugins.theme'
require 'nvim.plugins.web-devicons'
require 'nvim.plugins.gitsigns'
require 'nvim.plugins.which-key'
require 'nvim.plugins.telescope'
require 'nvim.plugins.lspconfig'
require 'nvim.plugins.conform'
require 'nvim.plugins.autopairs'
require 'nvim.plugins.cmp'
require 'nvim.plugins.todo-comments'
require 'nvim.plugins.mini'
require 'nvim.plugins.treesitter'
require 'nvim.plugins.harpoon'
require 'nvim.plugins.debug'
require 'nvim.plugins.indent-line'
require 'nvim.plugins.neotest'
require 'nvim.plugins.trouble'
require 'nvim.plugins.lualine'
require 'nvim.plugins.tmux'
require 'nvim.plugins.surround'
require 'nvim.plugins.treesitter-context'
require 'nvim.plugins.gitignore'
require 'nvim.plugins.oil'
require 'nvim.plugins.mdx'

-- Note: vim-sleuth, Comment.nvim, and LuaSnip (for snippets) are
-- configured implicitly via built-in defaults or init.lua inline config.

-- vim: ts=2 sts=2 sw=2 et
