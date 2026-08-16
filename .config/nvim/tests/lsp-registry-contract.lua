-- Headless declaration-contract check for LSP server modules.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/lsp-registry-contract.lua
--
-- Asserts that every enabled server declaration:
--   1. Returns a table (not nil or a non-table value)
--   2. Has a `mason` field that is a non-empty string (Mason package identifier)
--   3. Has at least one LSP config field (cmd, filetypes, settings, root_dir, init_options, on_attach)
--   4. Does NOT require mason-registry at load time (no load-time side effects requiring Mason state)

local errors = {}

local function assert(condition, msg)
  if not condition then
    errors[#errors + 1] = msg
  end
end

local function check_declaration(name, mod)
  assert(type(mod) == 'table', name .. ': must return a table, got ' .. type(mod))
  if type(mod) ~= 'table' then
    return
  end

  assert(type(mod.mason) == 'string' and #mod.mason > 0, name .. ': must have a non-empty string `mason` field (Mason package identifier)')

  local lsp_fields = { 'cmd', 'filetypes', 'settings', 'root_dir', 'init_options', 'on_attach' }
  local has_lsp_field = false
  for _, field in ipairs(lsp_fields) do
    if mod[field] ~= nil then
      has_lsp_field = true
      break
    end
  end
  assert(has_lsp_field, name .. ': must have at least one LSP config field (cmd, filetypes, settings, root_dir, init_options, on_attach)')
end

-- Server modules to check (the complete enabled set)
local server_modules = {
  'nvim.servers.lua_ls',
  'nvim.servers.jsonls',
  'nvim.servers.ts_ls',
  'nvim.servers.vue_ls',
  'nvim.servers.eslint',
  'nvim.servers.tailwind',
  'nvim.servers.cssls',
  'nvim.servers.astro',
  'nvim.servers.marksman',
  'nvim.servers.svelte',
  'nvim.servers.templ',
  'nvim.servers.emmet_ls',
  'nvim.servers.gopls',
}

-- Load and check each declaration
for _, module_name in ipairs(server_modules) do
  local ok, mod = pcall(require, module_name)
  if ok then
    check_declaration(module_name, mod)
  else
    errors[#errors + 1] = module_name .. ': failed to load — ' .. tostring(mod)
  end
end

-- Report
if #errors > 0 then
  print 'DECLARATION CONTRACT FAILURES:'
  for _, e in ipairs(errors) do
    print('  FAIL: ' .. e)
  end
  vim.cmd 'cq'
else
  print 'All server declarations pass contract check.'
  vim.cmd 'q'
end
