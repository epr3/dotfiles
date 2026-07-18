return {
  {
    'davidmh/mdx.nvim',
    cond = (function()
      return not vim.g.vscode
    end),
    config = true,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
}