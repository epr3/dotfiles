-- Headless integration check: registry setup registers and enables all servers.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/lsp-registry-integration.lua
--
-- Stubs plugin dependencies (mason, cmp-nvim-lsp, lazydev) so we can verify
-- the registry's own logic without network or UI.

local errors = {}

local function assert(condition, msg)
  if not condition then
    errors[#errors + 1] = msg
  end
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    errors[#errors + 1] = msg .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual)
  end
end

-- Stub plugin modules so registry.setup() runs without real plugins
package.preload['mason'] = package.preload['mason'] or function()
  package.loaded['mason'] = { setup = function() end }
end
package.preload['mason-tool-installer'] = package.preload['mason-tool-installer']
  or function()
    local installed = {}
    package.loaded['mason-tool-installer'] = {
      setup = function(opts)
        installed = opts.ensure_installed or {}
      end,
      get_installed = function()
        return installed
      end,
    }
  end
package.preload['cmp_nvim_lsp'] = package.preload['cmp_nvim_lsp']
  or function()
    package.loaded['cmp_nvim_lsp'] = {
      default_capabilities = function()
        return {}
      end,
    }
  end
package.preload['lazydev'] = package.preload['lazydev'] or function()
  package.loaded['lazydev'] = { setup = function() end }
end

-- Stub vim.lsp.config and vim.lsp.enable to track calls
vim.lsp.config = vim.lsp.config or {}
vim.lsp.enable = vim.lsp.enable or function() end

-- Track what gets registered
local registered = {}
local enabled = {}
local original_config = vim.lsp.config
local original_enable = vim.lsp.enable

vim.lsp.config = setmetatable({}, {
  __newindex = function(_, name, config)
    registered[name] = config
    rawset(original_config, name, config)
  end,
  __index = function(_, name)
    return registered[name] or rawget(original_config, name)
  end,
})
vim.lsp.enable = function(name)
  enabled[name] = true
end

-- Load and run the registry
local registry = require 'nvim.plugins.lsp-registry'
registry.setup()

-- 1. All 13 servers registered
local expected = {
  'lua_ls',
  'jsonls',
  'ts_ls',
  'vue_ls',
  'eslint',
  'tailwindcss',
  'cssls',
  'astro',
  'marksman',
  'svelte',
  'templ',
  'emmet_ls',
  'gopls',
}
for _, name in ipairs(expected) do
  assert(registered[name] ~= nil, 'server not registered: ' .. name)
  assert(enabled[name], 'server not enabled: ' .. name)
end
assert_eq(vim.tbl_count(registered), 13, 'expected exactly 13 registered servers')

-- 2. Marksman is registered
assert(registered['marksman'] ~= nil, 'marksman not registered')
assert(registered['marksman'].cmd[1] == 'marksman', 'marksman cmd wrong')

-- 3. No server config contains the mason field
for name, config in pairs(registered) do
  assert(config.mason == nil, name .. ': mason field leaked into vim.lsp.config')
end

-- 4. Capabilities were merged (our stub returns {}, so capabilities should be {})
for name, config in pairs(registered) do
  assert(type(config.capabilities) == 'table', name .. ': capabilities not set')
end

-- 5. mason-tool-installer was called with marksman in the list
local installer = package.loaded['mason-tool-installer']
assert(type(installer) == 'table', 'mason-tool-installer not loaded')
local installed = installer.get_installed()
assert(#installed > 0, 'ensure_installed list is empty')
local has_marksman = false
for _, pkg in ipairs(installed) do
  if pkg == 'marksman' then
    has_marksman = true
  end
end
assert(has_marksman, 'marksman not in ensure_installed list')

-- Report
if #errors > 0 then
  print 'REGISTRY INTEGRATION FAILURES:'
  for _, e in ipairs(errors) do
    print('  FAIL: ' .. e)
  end
  vim.cmd 'cq'
else
  print 'Registry integration checks pass.'
  vim.cmd 'q'
end
