return {
  mason = 'eslint-lsp',
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
    'vue',
    'svelte',
    'astro',
    'markdown',
    'markdown.mdx',
  },
  settings = {
    useFlatConfig = true,
  },
  behavior = {
    on_attach = function(event)
      local group = vim.api.nvim_create_augroup('nvim-lsp-eslint-fix', { clear = false })
      vim.api.nvim_clear_autocmds { group = group, buffer = event.buf }
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = group,
        buffer = event.buf,
        command = 'EslintFixAll',
      })
    end,
    on_detach = function(event)
      vim.api.nvim_clear_autocmds { group = 'nvim-lsp-eslint-fix', buffer = event.buf }
    end,
  },
}
