-- Treesitter: syntax highlighting, parsing, indentation
require('nvim-treesitter.configs').setup {
  ensure_installed = {
    'bash', 'c', 'html', 'lua', 'markdown', 'markdown_inline', 'vim', 'vimdoc',
    'css', 'javascript', 'typescript', 'tsx', 'json', 'jsonc', 'vue', 'svelte', 'astro',
    'go', 'templ',
  },
  auto_install = true,
  highlight = {
    enable = not vim.g.vscode,
    additional_vim_regex_highlighting = { 'ruby', 'markdown' },
  },
  indent = { enable = true, disable = { 'ruby' } },
  autotag = { enable = true },
}
-- vim: ts=2 sts=2 sw=2 et
