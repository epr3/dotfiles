-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  defaults = {
    version = '*',
  },
  spec = {
    -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
    { 'tpope/vim-repeat', event = "VeryLazy" },
    require 'nvim/plugins/treesitter',
    require 'nvim/plugins/treesitter-context',
    {
      "gbprod/yanky.nvim",
      opts = {}

    },
    {
      'ggandor/flit.nvim',
      dependencies = { 'ggandor/leap.nvim', 'tpope/vim-repeat' },
      opts = {}
    },

    {
      'ggandor/leap.nvim',
      dependencies = { 'tpope/vim-repeat' },
      config = function()
        require('leap').create_default_mappings()
      end
    },
    {
      'echasnovski/mini.move',
      opts = {}
    },
    {
      'echasnovski/mini.comment',
      opts = {}
    },
    {
      'echasnovski/mini.pairs',
      opts = {}
    },
    {
      'echasnovski/mini.surround',
      opts = {
        mappings = {
          add = "gza",              -- Add surrounding in Normal and Visual modes
          delete = "gzd",           -- Delete surrounding
          find = "gzf",             -- Find surrounding (to the right)
          find_left = "gzF",        -- Find surrounding (to the left)
          highlight = "gzh",        -- Highlight surrounding
          replace = "gzr",          -- Replace surrounding
          update_n_lines = "gzn",   -- Update `n_lines`
        },
      }
    },
    {
      'echasnovski/mini.ai',
      opts = {
        n_lines = 500
      }
    },
  },
}, {
  ui = {
    -- If you have a Nerd Font, set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons otherwise define a unicodes icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})