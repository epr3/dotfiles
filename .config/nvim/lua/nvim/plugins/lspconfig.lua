-- LSP configuration, Mason tooling, and LSP-attach keymaps

-- LspAttach autocommand: keymaps, document highlight, inlay hints, eslint fix
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
    map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
    map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    map('K', vim.lsp.buf.hover, 'Hover Documentation')
    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client then
      -- Document highlight on cursor hold
      if client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })
        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      -- Inlay hints toggle
      if client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
        map('<leader>th', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
        end, '[T]oggle Inlay [H]ints')
      end

      -- Eslint fix on save (moved from server-level on_attach to central LspAttach)
      if client.name == 'eslint' then
        vim.api.nvim_create_autocmd('BufWritePre', {
          buffer = event.buf,
          command = 'EslintFixAll',
        })
      end
    end
  end,
})

-- Client capabilities (merge LSP protocol defaults with cmp-nvim-lsp for completion)
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

-- Mason: LSP server / formatter / linter installer
require('mason').setup()

-- Tools to ensure are installed by Mason
local ensure_installed = {
  -- LSP servers
  'lua-language-server',
  'typescript-language-server',
  'vue-language-server',
  'json-lsp',
  'eslint-lsp',
  'tailwindcss-language-server',
  'css-lsp',
  'astro-language-server',
  'svelte-language-server',
  'gopls',
  'emmet-ls',
  'templ',
  'markdownlint',
  -- Formatters
  'stylua',
  'gofumpt',
  'goimports',
  'golines',
}

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

-- Server overrides (per-server config modules in nvim/servers/)
local servers = {
  lua_ls = require 'nvim.servers.lua_ls',
  jsonls = require 'nvim.servers.jsonls',
  ts_ls = require 'nvim.servers.ts_ls',
  volar = require 'nvim.servers.volar',
  eslint = require 'nvim.servers.eslint',
  tailwindcss = require 'nvim.servers.tailwind',
  emmet_ls = require 'nvim.servers.emmet_ls',
  gopls = require 'nvim.servers.gopls',
  cssls = {},
  astro = {},
  marksman = {},
  svelte = {},
  templ = {},
}

-- Register and enable each server via vim.lsp.config / vim.lsp.enable.
-- Minimal per-server defaults so vim.lsp.config can start each server.
-- The cmd binaries are on PATH because Mason adds its bin/ directory.
-- nvim-lspconfig is kept for utility functions (root_pattern used by
-- tailwindcss and gopls configs) but its deprecated framework index is not used.
local server_defaults = {
  lua_ls      = { cmd = { 'lua-language-server' },                        filetypes = { 'lua' } },
  jsonls      = { cmd = { 'vscode-json-language-server', '--stdio' },     filetypes = { 'json', 'jsonc' } },
  ts_ls       = { cmd = { 'typescript-language-server', '--stdio' },      filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'javascript.jsx', 'typescript.tsx' } },
  volar       = { cmd = { 'vue-language-server', '--stdio' },             filetypes = { 'vue' } },
  eslint      = { cmd = { 'vscode-eslint-language-server', '--stdio' },   filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'javascript.jsx', 'typescript.tsx', 'vue', 'svelte', 'astro' } },
  tailwindcss = { cmd = { 'tailwindcss-language-server', '--stdio' },     filetypes = { 'html', 'css', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'vue', 'svelte', 'astro' } },
  cssls       = { cmd = { 'vscode-css-language-server', '--stdio' },      filetypes = { 'css', 'scss', 'less' } },
  astro       = { cmd = { 'astro-language-server', '--stdio' },           filetypes = { 'astro' } },
  marksman    = { cmd = { 'marksman' },                                   filetypes = { 'markdown', 'markdown.mdx' } },
  svelte      = { cmd = { 'svelte-language-server', '--stdio' },          filetypes = { 'svelte' } },
  templ       = { cmd = { 'templ', 'lsp' },                               filetypes = { 'templ' } },
  emmet_ls    = { cmd = { 'emmet-language-server', '--stdio' },           filetypes = { 'html', 'css', 'typescriptreact', 'javascriptreact', 'svelte', 'vue' } },
  gopls       = { cmd = { 'gopls' },                                      filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' } },
}

for server_name, server_config in pairs(servers) do
  local defaults = server_defaults[server_name] or {}
  -- Merge: defaults first, our overrides second (override wins)
  local config = vim.tbl_deep_extend('force', {}, defaults, server_config)
  config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})
  vim.lsp.config[server_name] = config
  vim.lsp.enable(server_name)
end

-- lazydev.nvim: Lua LSP enhancement for Neovim config files
require('lazydev').setup {
  library = {
    { path = 'luvit-meta/library', words = { 'vim%.uv' } },
  },
}
-- vim: ts=2 sts=2 sw=2 et
