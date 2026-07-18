return {
  {
    'supermaven-inc/supermaven-nvim',
    cond = (function()
      return not vim.g.vscode
    end),
    config = function()
      require('supermaven-nvim').setup {}
    end,
  },
}