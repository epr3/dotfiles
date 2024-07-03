return {
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'tokyonight-night'
    end,
    opts = {
      style = 'night',
      plugins = {
        auto = true,
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
