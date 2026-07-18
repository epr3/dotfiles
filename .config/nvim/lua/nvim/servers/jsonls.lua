vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = { 'tsconfig.json' },
  callback = function()
    vim.bo.filetype = 'jsonc'
  end,
})

return {}
