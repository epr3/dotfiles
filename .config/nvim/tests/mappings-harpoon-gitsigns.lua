-- Headless mapping-contract check: Harpoon removal lives at <leader>hx and
-- <leader>hd stays Gitsigns' buffer-local diff-against-index in attached buffers.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/mappings-harpoon-gitsigns.lua
--
-- Stubs the Harpoon and Gitsigns plugin dependencies, loads both mapping
-- modules, and reads observable mapping resolution through Neovim's mapping
-- API. No network access, plugin manager, Mason state, or live plugins.

-- Pin the leader so stored lhs strings are deterministic.
vim.g.mapleader = ' '
local KEYS = {
  hx = ' hx',
  hd = ' hd',
  ha = ' ha',
  h1 = ' h1',
  h2 = ' h2',
  h3 = ' h3',
  h4 = ' h4',
  ctrl_a = '<C-A>',
  ctrl_p = '<C-P>',
  ctrl_n = '<C-N>',
}

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

-- Stub Harpoon: only `setup` runs at load time; list operations run inside
-- keymap callbacks and stay observable through the mapping's raw callback.
local harpoon_remove_called = false
package.preload['harpoon'] = function()
  local noop = function() end
  local list = {
    add = noop,
    remove = function()
      harpoon_remove_called = true
    end,
    select = noop,
    prev = noop,
    next = noop,
    items = {},
  }
  return {
    setup = noop,
    list = function()
      return list
    end,
  }
end

-- Stub Gitsigns: capture the setup config so the test can attach to a scratch
-- buffer and register the buffer-local mapping surface.
local gitsigns_config
local gitsigns_stub
package.preload['gitsigns'] = function()
  local noop = function() end
  gitsigns_stub = {
    setup = function(config)
      gitsigns_config = config
    end,
    nav_hunk = noop,
    stage_hunk = noop,
    reset_hunk = noop,
    stage_buffer = noop,
    undo_stage_hunk = noop,
    reset_buffer = noop,
    preview_hunk = noop,
    blame_line = noop,
    diffthis = noop,
    toggle_current_line_blame = noop,
    toggle_deleted = noop,
  }
  return gitsigns_stub
end

-- Load both mapping surfaces through their real modules.
require 'nvim.plugins.harpoon'
require 'nvim.plugins.gitsigns'

-- A plain buffer and a Gitsigns-attached buffer.
local plain_buf = vim.api.nvim_create_buf(true, false)
local git_buf = vim.api.nvim_create_buf(true, false)
gitsigns_config.on_attach(git_buf)

local function global_map(lhs)
  for _, m in ipairs(vim.api.nvim_get_keymap 'n') do
    if m.lhs == lhs then
      return m
    end
  end
end

local function buf_map(buf, lhs)
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, 'n')) do
    if m.lhs == lhs then
      return m
    end
  end
end

-- 1. Harpoon removal resolves through <leader>hx with its deletion description.
local hx = global_map(KEYS.hx)
assert(hx ~= nil, '<leader>hx must be a normal-mode mapping')
if hx then
  assert_eq(hx.desc, '[D]elete from Harpoon', '<leader>hx description')
  assert(hx.callback ~= nil, '<leader>hx must be callable')
  if hx.callback then
    hx.callback()
    assert(harpoon_remove_called, '<leader>hx must run Harpoon removal')
  end
end

-- 2. No global <leader>hd remains: outside a Gitsigns-attached buffer it must
-- not resolve, so no normal-mode mapping collision is left.
assert(global_map(KEYS.hd) == nil, '<leader>hd must not be a global normal-mode mapping')

-- 3. In the attached buffer <leader>hd resolves to Gitsigns diff-against-index,
-- as a buffer-local mapping.
local hd_git = buf_map(git_buf, KEYS.hd)
assert(hd_git ~= nil, 'in a Gitsigns-attached buffer <leader>hd must resolve')
if hd_git then
  assert_eq(hd_git.desc, 'git [d]iff against index', '<leader>hd description in attached buffer')
  assert(hd_git.callback == gitsigns_stub.diffthis, '<leader>hd must resolve to the Gitsigns diff action')
  assert(buf_map(plain_buf, KEYS.hd) == nil, '<leader>hd must be buffer-local to the attached buffer')
end

-- 4. Harpoon removal stays available in the attached buffer: no buffer-local
-- <leader>hx shadows the global removal mapping.
assert(buf_map(git_buf, KEYS.hx) == nil, '<leader>hx must not be shadowed in an attached buffer')
local hx_git = global_map(KEYS.hx)
assert(hx_git ~= nil and hx_git.desc == '[D]elete from Harpoon', '<leader>hx must remain available in an attached buffer')

-- 5. Harpoon add, selection, and navigation mappings remain unchanged.
local unchanged_mappings = {
  [KEYS.ha] = '[A]ppend to Harpoon',
  [KEYS.h1] = '[H]arpoon window [1]',
  [KEYS.h2] = '[H]arpoon window [2]',
  [KEYS.h3] = '[H]arpoon window [3]',
  [KEYS.h4] = '[H]arpoon window [4]',
}
for lhs, desc in pairs(unchanged_mappings) do
  local m = global_map(lhs)
  assert(m ~= nil, lhs .. ' must remain a normal-mode mapping')
  if m then
    assert_eq(m.desc, desc, lhs .. ' description')
  end
end
for _, lhs in ipairs { KEYS.ctrl_a, KEYS.ctrl_p, KEYS.ctrl_n } do
  assert(global_map(lhs) ~= nil, lhs .. ' must remain a normal-mode mapping')
end

-- Report
if #errors > 0 then
  print 'MAPPING CONTRACT FAILURES:'
  for _, e in ipairs(errors) do
    print('  FAIL: ' .. e)
  end
  vim.cmd 'cq'
else
  print 'Harpoon/Gitsigns mapping contract passes.'
  vim.cmd 'q'
end
