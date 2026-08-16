-- Headless Mini profile adapter contract check.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/mini-profile-adapter.lua
--
-- Verifies the Mini profile adapter seam:
--   1. Both profiles declare the Mini monorepo as the sole Mini package identity.
--   2. Both profiles receive identical shared mini.ai options through the adapter.
--   3. Each profile retains its intended Mini module selection.

local errors = {}

local function assert(condition, msg)
  if not condition then
    errors[#errors + 1] = msg
  end
end

local config_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local content = f:read '*a'
  f:close()
  return content
end

local standalone_decl = read_file(config_root .. '/lua/plugins.lua')
local vscode_decl = read_file(config_root .. '/lua/plugins-vscode.lua')

-- 1. Both profiles use the Mini monorepo as the sole Mini package identity.
assert(standalone_decl:find("pack.use 'echasnovski/mini.nvim'", 1, true), 'standalone must declare echasnovski/mini.nvim')
assert(vscode_decl:find("pack.use 'echasnovski/mini.nvim'", 1, true), 'vscode must declare echasnovski/mini.nvim')

local function count_mini_identities(text, label)
  local count = 0
  for _ in text:gmatch 'echasnovski/mini%.([%w_]+)' do
    count = count + 1
  end
  return count
end

assert(count_mini_identities(standalone_decl, 'standalone') == 1, 'standalone must have exactly one Mini package identity')
assert(count_mini_identities(vscode_decl, 'vscode') == 1, 'vscode must have exactly one Mini package identity')

-- Stub Mini modules and capture setup calls.
local captured = {}

local function stub(name, extra)
  local mod = {
    setup = function(opts)
      captured[name] = opts or true
    end,
  }
  if extra then
    for k, v in pairs(extra) do
      mod[k] = v
    end
  end
  package.loaded['mini.' .. name] = mod
end

stub 'ai'
stub('starter', {
  sections = {
    builtin_actions = function()
      return { name = 'builtin_actions' }
    end,
    recent_files = function(n, bool)
      return { name = 'recent_files', n = n, bool = bool }
    end,
  },
})
stub 'move'
stub 'comment'
stub 'pairs'
stub 'surround'

local adapter = require 'nvim.plugins.mini-profile'

-- 2. Both profiles receive identical shared mini.ai options.
adapter.setup 'standalone'
local standalone_ai_opts = captured.ai
local standalone_selection = vim.deepcopy(captured)
standalone_selection.ai = nil

captured = {}

adapter.setup 'vscode'
local vscode_ai_opts = captured.ai
local vscode_selection = vim.deepcopy(captured)
vscode_selection.ai = nil

assert(standalone_ai_opts and standalone_ai_opts.n_lines == 500, 'standalone mini.ai must receive n_lines = 500')
assert(vscode_ai_opts and vscode_ai_opts.n_lines == 500, 'vscode mini.ai must receive n_lines = 500')
assert(vim.deep_equal(standalone_ai_opts, vscode_ai_opts), 'mini.ai options must be identical across profiles')

-- 3. Each profile retains its intended Mini module selection.
assert(standalone_selection.starter ~= nil, 'standalone must configure mini.starter')
assert(standalone_selection.move == nil, 'standalone must not configure mini.move')
assert(standalone_selection.comment == nil, 'standalone must not configure mini.comment')
assert(standalone_selection.pairs == nil, 'standalone must not configure mini.pairs')
assert(standalone_selection.surround == nil, 'standalone must not configure mini.surround')

assert(vscode_selection.move ~= nil, 'vscode must configure mini.move')
assert(vscode_selection.comment ~= nil, 'vscode must configure mini.comment')
assert(vscode_selection.pairs ~= nil, 'vscode must configure mini.pairs')
assert(vscode_selection.surround ~= nil, 'vscode must configure mini.surround')
assert(vscode_selection.starter == nil, 'vscode must not configure mini.starter')

if #errors > 0 then
  print 'MINI PROFILE ADAPTER CONTRACT FAILURES:'
  for _, err in ipairs(errors) do
    print('  FAIL: ' .. err)
  end
  vim.cmd 'cq'
else
  print 'Mini profile adapter contract check passes.'
  vim.cmd 'q'
end
-- vim: ts=2 sts=2 sw=2 et
