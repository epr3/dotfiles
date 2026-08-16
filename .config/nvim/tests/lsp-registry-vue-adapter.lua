-- Headless check for the deferred optional Vue/TypeScript adapter.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/lsp-registry-vue-adapter.lua
--
-- Asserts that the Vue adapter for TypeScript is optional and deferred:
--   1. Missing Vue tooling still registers ts_ls without .vue or the Vue plugin (AC1)
--   2. Present Vue tooling connects ts_ls to .vue editing via @vue/typescript-plugin (AC2)
--   3. Health names the missing optional package and gives a concrete repair command (AC3)
--   4. Declarations carry no resolved install path (no Mason-state lookup at load, AC4)

local errors = {}

local function assert(condition, msg)
  if not condition then
    errors[#errors + 1] = msg
  end
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    errors[#errors + 1] = string.format('%s: expected %s, got %s', msg, tostring(expected), tostring(actual))
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

-- Stub plugin dependencies so registry.setup() runs without real plugins.
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

-- Controllable Mason registry state: real runtime makes the adapter decision
-- here at setup time; tests flip installation to prove both sides.
local vue_installed = false
local VUE_INSTALL_PATH = '/fake/mason/packages/vue-language-server'
package.preload['mason-registry'] = function()
  return {
    is_installed = function(name)
      return name == 'vue-language-server' and vue_installed
    end,
    get_package = function(name)
      assert_eq(name, 'vue-language-server', 'adapter must look up the declared package')
      return {
        get_install_path = function()
          return VUE_INSTALL_PATH
        end,
      }
    end,
  }
end

-- Run registry.setup() and capture what gets registered as vim.lsp.config.
local function setup_and_capture()
  local registered = {}
  local original_config = vim.lsp.config
  local original_enable = vim.lsp.enable
  vim.lsp.config = setmetatable({}, {
    __newindex = function(_, name, config)
      registered[name] = config
    end,
    __index = function(_, name)
      return registered[name] or rawget(original_config, name)
    end,
  })
  vim.lsp.enable = function() end
  require('nvim.plugins.lsp-registry').setup()
  vim.lsp.config = original_config
  vim.lsp.enable = original_enable
  return registered
end

-- AC4: the declaration itself stays pure — relative location only, no resolved path.
local declarative_plugins = {}
local ts_ls_ok, ts_ls_decl = pcall(require, 'nvim.servers.ts_ls')
assert(ts_ls_ok, 'ts_ls declaration must load without Mason state: ' .. tostring(ts_ls_decl))
if ts_ls_ok then
  assert_eq(type(ts_ls_decl.optional), 'table', 'ts_ls must declare the optional Vue adapter')
  for _, adapter in ipairs(ts_ls_decl.optional or {}) do
    assert_eq(adapter.package, 'vue-language-server', 'optional adapter must name its Mason package')
    for _, plugin in ipairs((adapter.init_options or {}).plugins or {}) do
      declarative_plugins[#declarative_plugins + 1] = plugin
    end
  end
  assert_eq(#declarative_plugins, 1, 'ts_ls must declare exactly one Vue plugin')
  if declarative_plugins[1] then
    assert_eq(declarative_plugins[1].name, '@vue/typescript-plugin', 'adapter must declare the Vue TypeScript plugin')
    assert(
      type(declarative_plugins[1].location) == 'string' and not vim.startswith(declarative_plugins[1].location, '/'),
      'declaration must not embed an absolute install path (no Mason-state lookup at load)'
    )
  end
end

-- AC1: absent tooling — ts_ls registers untouched.
vue_installed = false
local absent = setup_and_capture()
assert(type(absent['ts_ls']) == 'table', 'ts_ls must be registered without Vue tooling')
assert_not_contains(absent['ts_ls'].filetypes or {}, 'vue', 'ts_ls without Vue tooling must not claim .vue files')
assert((absent['ts_ls'].init_options or {}).plugins == nil, 'ts_ls without Vue tooling must not load the @vue/typescript-plugin')

-- AC2: present tooling — ts_ls gains .vue and the resolved plugin.
vue_installed = true
local present = setup_and_capture()
assert(type(present['ts_ls']) == 'table', 'ts_ls must be registered with Vue tooling')
assert_contains(present['ts_ls'].filetypes or {}, 'vue', 'ts_ls with Vue tooling must service .vue files')
local plugins = (present['ts_ls'].init_options or {}).plugins or {}
assert_eq(#plugins, 1, 'ts_ls with Vue tooling must load exactly one TypeScript plugin')
if plugins[1] then
  assert_eq(plugins[1].name, '@vue/typescript-plugin', 'the adapter must load the Vue TypeScript plugin')
  assert_contains(plugins[1].languages or {}, 'vue', 'the plugin must declare vue language support')
  assert_eq(
    plugins[1].location,
    VUE_INSTALL_PATH .. '/node_modules/@vue/language-server',
    'plugin location must resolve against the Mason install path at setup time'
  )
end

-- AC3: health reports the missing optional package with a concrete repair command.
local function health_report()
  local messages = { ok = {}, warn = {}, error = {} }
  local original_health = vim.health
  vim.health = {
    start = function() end,
    info = function() end,
    ok = function(msg)
      messages.ok[#messages.ok + 1] = msg
    end,
    warn = function(msg)
      messages.warn[#messages.warn + 1] = msg
    end,
    error = function(msg)
      messages.error[#messages.error + 1] = msg
    end,
  }
  require('nvim.health').check()
  vim.health = original_health
  return messages
end

vue_installed = false
local absent_health = health_report()
local absent_warning = table.concat(absent_health.warn, '\n')
assert(absent_warning:find('vue-language-server', 1, true) ~= nil, 'health must name the missing optional package')
assert(absent_warning:find(':MasonInstall vue-language-server', 1, true) ~= nil, 'health must give the concrete repair command')

vue_installed = true
local present_health = health_report()
local present_ok = table.concat(present_health.ok, '\n')
assert(present_ok:find('vue-language-server', 1, true) ~= nil, 'health must confirm the integration is active when tooling is present')

-- Report
if #errors > 0 then
  print 'VUE ADAPTER FAILURES:'
  for _, e in ipairs(errors) do
    print('  FAIL: ' .. e)
  end
  vim.cmd 'cq'
else
  print 'Vue adapter checks pass.'
  vim.cmd 'q'
end
