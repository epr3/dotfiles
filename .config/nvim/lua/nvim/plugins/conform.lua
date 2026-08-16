-- Autoformat on save.
-- Prettier owns the web filetypes also served by cssls, jsonls, ts_ls, eslint,
-- tailwindcss, emmet_ls, vue_ls, and astro; keep their LSP fallback disabled.
local util = require 'conform.util'
require('conform').setup {
  formatters = {
    prettier = {
      require_cwd = true,
      cwd = util.root_file {
        '.prettierrc',
        '.prettierrc.json',
        '.prettierrc.yml',
        '.prettierrc.yaml',
        '.prettierrc.json5',
        '.prettierrc.js',
        '.prettierrc.cjs',
        '.prettierrc.mjs',
        '.prettierrc.toml',
        'prettier.config.js',
        'prettier.config.cjs',
        'prettier.config.mjs',
      },
    },
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    css = { 'prettier' },
    html = { 'prettier' },
    javascript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
    vue = { 'prettier' },
    astro = { 'prettier' },
    json = { 'prettier' },
    jsonc = { 'prettier' },
    markdown = { 'prettier' },
    ['markdown.mdx'] = { 'prettier' },
    sh = { 'shfmt' },
    go = { 'gofumpt', 'goimports', 'golines' },
  },
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- Keep Conform, rather than the enabled LSP servers, as formatter authority.
    local disable_filetypes = {
      c = true,
      cpp = true,
      css = true,
      html = true,
      vue = true,
      astro = true,
      typescript = true,
      typescriptreact = true,
      javascript = true,
      javascriptreact = true,
      json = true,
      jsonc = true,
      markdown = true,
      ['markdown.mdx'] = true,
    }
    return {
      timeout_ms = 500,
      lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
    }
  end,
}
-- vim: ts=2 sts=2 sw=2 et
