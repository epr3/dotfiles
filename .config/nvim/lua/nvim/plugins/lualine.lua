return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cond = (function()
      return not vim.g.vscode
    end),
    opts = {
      theme = 'tokyonight',
      sections = {
        lualine_c = { { 'filename', path = 1 } },
      },
    },
  },
}