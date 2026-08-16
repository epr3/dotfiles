-- LSP registry: collects server declarations, derives installation and enablement.
--
-- Each server module in nvim/servers/ returns a pure declaration:
--   { mason = 'pkg-name', cmd = ..., filetypes = ..., settings = ..., ... }
--
-- This registry:
--   1. Collects all declarations
--   2. Derives Mason installation list from .mason fields
--   3. Strips .mason and registers each config with vim.lsp.config / vim.lsp.enable
--   4. Applies shared capabilities and LspAttach behavior

local M = {}

-- Complete server map: module name -> server key used by vim.lsp.config
local server_modules = {
  lua_ls = 'nvim.servers.lua_ls',
  jsonls = 'nvim.servers.jsonls',
  ts_ls = 'nvim.servers.ts_ls',
  vue_ls = 'nvim.servers.vue_ls',
  eslint = 'nvim.servers.eslint',
  tailwindcss = 'nvim.servers.tailwind',
  cssls = 'nvim.servers.cssls',
  astro = 'nvim.servers.astro',
  marksman = 'nvim.servers.marksman',
  svelte = 'nvim.servers.svelte',
  templ = 'nvim.servers.templ',
  emmet_ls = 'nvim.servers.emmet_ls',
  gopls = 'nvim.servers.gopls',
}

-- Cache loaded declarations
local _declarations = nil

local function load_declarations()
  if _declarations then
    return _declarations
  end
  _declarations = {}
  for server_name, module_name in pairs(server_modules) do
    local ok, decl = pcall(require, module_name)
    if ok and type(decl) == 'table' then
      _declarations[server_name] = decl
    end
  end
  return _declarations
end

--- Returns all server declarations keyed by server name.
function M.servers()
  return load_declarations()
end

--- Returns the list of Mason package identifiers derived from declarations.
function M.mason_packages()
  local decls = load_declarations()
  local packages = {}
  for _, decl in pairs(decls) do
    if type(decl.mason) == 'string' then
      packages[#packages + 1] = decl.mason
    end
  end
  table.sort(packages)
  return packages
end

--- Returns server configs suitable for vim.lsp.config (mason field stripped).
--- @param capabilities table Client capabilities to merge into each config.
function M.server_configs(capabilities)
  local decls = load_declarations()
  local configs = {}
  for server_name, decl in pairs(decls) do
    -- Shallow copy, strip registry-only fields.
    local config = vim.tbl_extend('force', {}, decl)
    config.mason = nil
    config.behavior = nil
    -- Merge capabilities
    config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})
    configs[server_name] = config
  end
  return configs
end

-- Optional adapters: declarative extensions to a server, applied only when the
-- optional Mason package they need is installed. Resolution is deferred to
-- setup(); declarations never query Mason state while loading.
--
-- Adapter shape (declared in a server module):
--   optional = { { package = 'mason-pkg', filetypes = {...}, init_options = {...}, on_attach = fn } }
-- Relative `location` string values inside init_options are resolved against the
-- installed package's path before the config is registered.

--- Expands a table, resolving `location` keys that are relative paths.
--- @param value any
--- @param install_path string Mason install path for the optional package
local function resolve_locations(value, install_path)
  if type(value) ~= 'table' then
    return value
  end
  local resolved = {}
  for key, sub in pairs(value) do
    if key == 'location' and type(sub) == 'string' and not vim.startswith(sub, '/') then
      resolved[key] = install_path .. '/' .. sub
    else
      resolved[key] = resolve_locations(sub, install_path)
    end
  end
  return resolved
end

--- Applies optional adapters to declarations and running configs at setup time.
--- @param declarations table server_name -> declaration
--- @param configs table server_name -> config to register with vim.lsp.config
local function apply_optional_adapters(declarations, configs)
  local ok, mason_registry = pcall(require, 'mason-registry')
  if not ok then
    return
  end
  for server_name, declaration in pairs(declarations) do
    for _, adapter in ipairs(declaration.optional or {}) do
      local package = adapter.package
      if type(package) ~= 'string' or not mason_registry.is_installed(package) then
        goto continue
      end
      local install_path = mason_registry.get_package(package):get_install_path()
      -- Attach behavior is active only when the adapter resolved.
      if type(adapter.on_attach) == 'function' then
        declaration.behavior = declaration.behavior or {}
        local previous = declaration.behavior.on_attach
        if previous then
          declaration.behavior.on_attach = function(event, client)
            previous(event, client)
            adapter.on_attach(event, client)
          end
        else
          declaration.behavior.on_attach = adapter.on_attach
        end
      end
      -- Config extension: union of filetypes, deep-merged init_options.
      -- Copy filetypes so the public declaration tables stay unmutated.
      local config = configs[server_name]
      if config and type(config) == 'table' then
        if type(adapter.filetypes) == 'table' then
          local merged = {}
          for _, filetype in ipairs(config.filetypes or {}) do
            merged[#merged + 1] = filetype
          end
          for _, filetype in ipairs(adapter.filetypes) do
            local seen = false
            for _, existing in ipairs(merged) do
              if existing == filetype then
                seen = true
                break
              end
            end
            if not seen then
              merged[#merged + 1] = filetype
            end
          end
          config.filetypes = merged
        end
        if type(adapter.init_options) == 'table' then
          config.init_options = vim.tbl_deep_extend('force', {}, config.init_options or {}, resolve_locations(adapter.init_options, install_path))
        end
      end
      ::continue::
    end
  end
end

local function install_behaviors(declarations)
  local attach_behaviors = {}

  for server_name, declaration in pairs(declarations) do
    local behavior = declaration.behavior
    if behavior then
      local autocmds = behavior.autocmds or {}
      local group
      if #autocmds > 0 then
        group = vim.api.nvim_create_augroup('nvim-lsp-' .. server_name .. '-behavior', { clear = true })
      end
      for _, autocmd in ipairs(autocmds) do
        vim.api.nvim_create_autocmd(autocmd.events, {
          group = group,
          pattern = autocmd.pattern,
          callback = autocmd.callback,
        })
      end
      if behavior.on_attach or behavior.on_detach then
        attach_behaviors[server_name] = behavior
      end
    end
  end

  if next(attach_behaviors) == nil then
    return
  end

  local group = vim.api.nvim_create_augroup('nvim-lsp-server-behaviors', { clear = true })
  local function with_behavior(event, method)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    local behavior = client and attach_behaviors[client.name]
    if behavior and behavior[method] then
      behavior[method](event, client)
    end
  end

  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(event)
      with_behavior(event, 'on_attach')
    end,
  })
  vim.api.nvim_create_autocmd('LspDetach', {
    group = group,
    callback = function(event)
      with_behavior(event, 'on_detach')
    end,
  })
end

--- Full setup: Mason, capabilities, server behavior, register + enable all servers.
function M.setup()
  -- Mason
  require('mason').setup()

  local ensure_installed = M.mason_packages()
  -- Add formatters and linters that live outside server declarations
  ensure_installed[#ensure_installed + 1] = 'stylua'
  ensure_installed[#ensure_installed + 1] = 'gofumpt'
  ensure_installed[#ensure_installed + 1] = 'goimports'
  ensure_installed[#ensure_installed + 1] = 'golines'
  ensure_installed[#ensure_installed + 1] = 'markdownlint'
  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  -- Capabilities (LSP protocol defaults + cmp-nvim-lsp completion)
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

  -- Install only behavior declared by enabled servers. Optional adapters are
  -- resolved first (deferred: only when their Mason package is installed).
  local declarations = M.servers()
  local configs = M.server_configs(capabilities)
  apply_optional_adapters(declarations, configs)
  install_behaviors(declarations)

  -- Register and enable each server.
  for server_name, config in pairs(configs) do
    vim.lsp.config[server_name] = config
    vim.lsp.enable(server_name)
  end

  -- lazydev: Lua LSP enhancement for Neovim config files
  require('lazydev').setup {
    library = {
      { path = 'luvit-meta/library', words = { 'vim%.uv' } },
    },
  }
end

return M
