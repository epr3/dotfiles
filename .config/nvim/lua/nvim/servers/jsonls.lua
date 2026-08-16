return {
  mason = 'json-lsp',
  cmd = { 'vscode-json-language-server', '--stdio' },
  filetypes = { 'json', 'jsonc' },
  behavior = {
    autocmds = {
      {
        events = { 'BufNewFile', 'BufRead' },
        pattern = 'tsconfig.json',
        callback = function()
          vim.bo.filetype = 'jsonc'
        end,
      },
    },
  },
}
