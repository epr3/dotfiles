-- Headless behavior check: declarations install only scoped server behavior.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/lsp-registry-behaviors.lua

local errors = {}

local function assert(condition, message)
  if not condition then
    errors[#errors + 1] = message
  end
end

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    errors[#errors + 1] = message .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual)
  end
end

package.preload['mason'] = function()
  return { setup = function() end }
end
package.preload['mason-tool-installer'] = function()
  return { setup = function() end }
end
package.preload['cmp_nvim_lsp'] = function()
  return {
    default_capabilities = function()
      return {}
    end,
  }
end
package.preload['lazydev'] = function()
  return { setup = function() end }
end

local autocmds = {}
local groups = {}
local original_create_autocmd = vim.api.nvim_create_autocmd
local original_create_augroup = vim.api.nvim_create_augroup
vim.api.nvim_create_augroup = function(name, options)
  groups[name] = options
  return name
end
vim.api.nvim_create_autocmd = function(events, options)
  autocmds[#autocmds + 1] = { events = events, options = options }
end

local original_config = vim.lsp.config
local original_enable = vim.lsp.enable
vim.lsp.config = {}
vim.lsp.enable = function() end

local registry = require 'nvim.plugins.lsp-registry'
registry.setup()

vim.api.nvim_create_autocmd = original_create_autocmd
vim.api.nvim_create_augroup = original_create_augroup
vim.lsp.config = original_config
vim.lsp.enable = original_enable

local function includes(events, expected)
  if type(events) == 'string' then
    return events == expected
  end
  return vim.tbl_contains(events, expected)
end

local jsonc_autocmd
local eslint_attach_autocmd
for _, autocmd in ipairs(autocmds) do
  if includes(autocmd.events, 'BufRead') and autocmd.options.pattern == 'tsconfig.json' then
    jsonc_autocmd = autocmd
  end
  if autocmd.events == 'LspAttach' then
    eslint_attach_autocmd = autocmd
  end
end

assert(jsonc_autocmd ~= nil, 'registry must install tsconfig JSONC detection')
assert(jsonc_autocmd and jsonc_autocmd.options.group ~= nil, 'JSONC detection must belong to a scoped augroup')
assert(eslint_attach_autocmd ~= nil, 'registry must install enabled-server attach behavior')
assert(eslint_attach_autocmd and eslint_attach_autocmd.options.group ~= nil, 'server attach behavior must belong to a scoped augroup')

if jsonc_autocmd then
  local original_filetype = vim.bo.filetype
  jsonc_autocmd.options.callback()
  assert_eq(vim.bo.filetype, 'jsonc', 'opening tsconfig.json must set JSONC filetype')
  vim.bo.filetype = original_filetype
end

if eslint_attach_autocmd then
  local fixes = {}
  vim.api.nvim_create_autocmd = function(events, options)
    fixes[#fixes + 1] = { events = events, options = options }
  end
  local original_client = vim.lsp.get_client_by_id
  local buffer = vim.api.nvim_get_current_buf()
  vim.lsp.get_client_by_id = function()
    return { name = 'eslint' }
  end
  eslint_attach_autocmd.options.callback { buf = buffer, data = { client_id = 1 } }
  vim.lsp.get_client_by_id = original_client
  vim.api.nvim_create_autocmd = original_create_autocmd

  assert_eq(#fixes, 1, 'ESLint attach must install one save fix')
  if fixes[1] then
    assert_eq(fixes[1].events, 'BufWritePre', 'ESLint fix must run before save')
    assert_eq(fixes[1].options.buffer, buffer, 'ESLint fix must be buffer-local')
    assert(fixes[1].options.group ~= nil, 'ESLint fix must belong to a scoped augroup')
    assert_eq(fixes[1].options.command, 'EslintFixAll', 'ESLint save behavior must fix all')
  end
end

if #errors > 0 then
  print 'REGISTRY BEHAVIOR FAILURES:'
  for _, error in ipairs(errors) do
    print('  FAIL: ' .. error)
  end
  vim.cmd 'cq'
else
  print 'Registry behavior checks pass.'
  vim.cmd 'q'
end
