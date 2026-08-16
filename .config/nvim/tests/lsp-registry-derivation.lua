-- Headless registry-derivation check.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/lsp-registry-derivation.lua
--
-- Asserts that the registry:
--   1. Collects all server declarations
--   2. Derives Mason installation set from `.mason` fields
--   3. Strips `.mason` from configs passed to vim.lsp.config
--   4. Includes Marksman in the installation list
--   5. All 13 current servers are present

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

local function assert_contains(tbl, value, msg)
  for _, v in ipairs(tbl) do
    if v == value then
      return
    end
  end
  errors[#errors + 1] = msg .. ': ' .. tostring(value) .. ' not found in list'
end

local function assert_not_contains(tbl, value, msg)
  for _, v in ipairs(tbl) do
    if v == value then
      errors[#errors + 1] = msg .. ': ' .. tostring(value) .. ' should not be in list'
      return
    end
  end
end

-- Load the registry (doesn't exist yet — this is the RED step)
local ok, registry = pcall(require, 'nvim.plugins.lsp-registry')
if not ok then
  print('REGISTRY LOAD FAILURE: ' .. tostring(registry))
  vim.cmd 'cq'
  return
end

-- 1. Registry collects all servers
local servers = registry.servers()
assert(type(servers) == 'table', 'servers() must return a table')
assert_eq(#vim.tbl_keys(servers), 13, 'servers() must contain 13 servers')

-- 2. Registry derives Mason packages
local packages = registry.mason_packages()
assert(type(packages) == 'table', 'mason_packages() must return a table')
assert_eq(#packages, 13, 'mason_packages() must contain 13 packages')

-- 3. Marksman is in the installation list
assert_contains(packages, 'marksman', 'mason_packages() must include marksman')

-- 4. Every expected package is present
local expected_packages = {
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
  'marksman',
}
for _, pkg in ipairs(expected_packages) do
  assert_contains(packages, pkg, 'mason_packages() missing ' .. pkg)
end

-- 5. Server configs strip the mason field
local configs = registry.server_configs {}
assert(type(configs) == 'table', 'server_configs() must return a table')
for name, config in pairs(configs) do
  assert(config.mason == nil, name .. ': config must not contain mason field')
  assert(type(config) == 'table', name .. ': config must be a table')
end

-- 6. Every expected server is present
local expected_servers = {
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
for _, name in ipairs(expected_servers) do
  assert(servers[name] ~= nil, 'servers() missing ' .. name)
  assert(configs[name] ~= nil, 'server_configs() missing ' .. name)
end

-- Report
if #errors > 0 then
  print 'REGISTRY DERIVATION FAILURES:'
  for _, e in ipairs(errors) do
    print('  FAIL: ' .. e)
  end
  vim.cmd 'cq'
else
  print 'Registry derivation checks pass.'
  vim.cmd 'q'
end
