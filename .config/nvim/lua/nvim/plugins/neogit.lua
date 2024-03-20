return {
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
    opts = {},
    init = function()
      local neogit = require 'neogit'

      vim.keymap.set('n', '<leader>gg', neogit.open, { desc = 'Open Neo[g]it' })
      vim.keymap.set('n', '<leader>gc', function()
        neogit.open { 'commit' }
      end, { desc = 'Open Neo[g]it [c]ommit' })
      vim.keymap.set('n', '<leader>gs', function()
        neogit.open { kind = 'split' }
      end, { desc = 'Open Neo[g]it [s]plit' })
      vim.keymap.set('n', '<leader>gw', function()
        neogit.open { cwd = '~' }
      end, { desc = 'Open Neo[g]it current [w]orking directory' })
    end,
  },
}
