-- LSP configuration, Mason tooling, and LSP-attach keymaps

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
    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
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

    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

require('mason').setup()

local servers = {
  emmet_ls = require 'nvim.servers.emmet_ls',
  lua_ls = require 'nvim.servers.lua_ls',
  jsonls = require 'nvim.servers.jsonls',
  volar = require 'nvim.servers.volar',
  ts_ls = require 'nvim.servers.ts_ls',
  eslint = require 'nvim.servers.eslint',
  tailwindcss = require 'nvim.servers.tailwind',
  cssls = {},
  astro = {},
  marksman = {},
  svelte = {},
  templ = {},
  gopls = require 'nvim.servers.gopls',
}

local ensure_installed = vim.tbl_keys(servers)
vim.list_extend(ensure_installed, {
  'stylua',
  'astro-language-server',
  'css-lsp',
  'vue-language-server',
  'typescript-language-server',
  'svelte-language-server',
  'lua-language-server',
  'emmet-ls',
  'eslint-lsp',
  'json-lsp',
  'tailwindcss-language-server',
  'markdownlint',
  'gopls',
  'gofumpt',
  'goimports',
  'golines',
  'templ',
})

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

require('mason-lspconfig').setup {
  handlers = {
    function(server_name)
      local server = servers[server_name] or {}
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      require('lspconfig')[server_name].setup(server)
    end,
  },
}

-- lazydev.nvim configures Lua LSP for Neovim config files
require('lazydev').setup {
  library = {
    { path = 'luvit-meta/library', words = { 'vim%.uv' } },
  },
}
-- vim: ts=2 sts=2 sw=2 et
