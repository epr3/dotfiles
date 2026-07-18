return {
  {
    'nvim-tree/nvim-web-devicons',
    cond = (function()
      return not vim.g.vscode
    end),
    opts = {
      strict = true,
      override_by_extension = {
        astro = {
          icon = '',
          color = '#EF8547',
          name = 'astro',
        },
      },
    },
  },
}