-- Headless plugin-declaration contract check.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/plugin-declarations-contract.lua
--
-- Verifies the truthful Plugin declaration interfaces:
--   1. Fidget and Treesitter Context are not declared in either profile
--      and have no resolved lock entries.
--   2. MDX remains declared (supplying the `markdown.mdx` filetype contract
--      consumed by formatting and language-server selection).
--   3. Cross-pane tmux navigation (vim-tmux-navigator) remains declared.
--   4. Comment-only wrapper modules and stale implicit-configuration claims
--      are absent.
--
-- Declarations and lock contents are validated as data; nothing is installed.

local function config_root()
  local source = debug.getinfo(1, 'S').source:sub(2) -- strip '@'
  return vim.fn.fnamemodify(source, ':p:h:h') -- tests/ -> .config/nvim
end

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local content = f:read '*a'
  f:close()
  return content
end

local errors = {}

local function assert(condition, msg)
  if not condition then
    errors[#errors + 1] = msg
  end
end

local function assert_absent(text, needle, what)
  if text == nil then
    errors[#errors + 1] = what .. ': file unreadable'
    return
  end
  if text:find(needle, 1, true) then
    errors[#errors + 1] = what .. ': must not contain ' .. needle
  end
end

local function assert_present(text, needle, what)
  if text == nil then
    errors[#errors + 1] = what .. ': file unreadable'
    return
  end
  if not text:find(needle, 1, true) then
    errors[#errors + 1] = what .. ': must contain ' .. needle
  end
end

local root = config_root()
local standalone = read_file(root .. '/lua/plugins.lua')
local vscode = read_file(root .. '/lua/plugins-vscode.lua')
local lock_text = read_file(root .. '/nvim-pack-lock.json')
local lock = lock_text and vim.json.decode(lock_text) or nil

-- 1. Fidget and Treesitter Context are not declared in either profile.
assert_absent(standalone, 'j-hui/fidget.nvim', 'standalone profile')
assert_absent(vscode, 'j-hui/fidget.nvim', 'vscode profile')
assert_absent(standalone, 'nvim-treesitter/nvim-treesitter-context', 'standalone profile')
assert_absent(vscode, 'nvim-treesitter/nvim-treesitter-context', 'vscode profile')
assert_absent(standalone, 'nvim.plugins.treesitter-context', 'standalone profile')

-- ... and have no resolved lock entries.
assert(lock ~= nil, 'nvim-pack-lock.json must decode as JSON')
if lock then
  assert(lock.plugins['fidget.nvim'] == nil, 'lock must not contain fidget.nvim')
  assert(lock.plugins['nvim-treesitter-context'] == nil, 'lock must not contain nvim-treesitter-context')
end

-- 2. MDX remains declared (the `markdown.mdx` contract).
assert_present(standalone, "pack.use 'davidmh/mdx.nvim'", 'standalone profile')
if lock then
  assert(lock.plugins['mdx.nvim'] ~= nil, 'lock must retain mdx.nvim')
end

-- 3. Cross-pane tmux navigation remains declared.
assert_present(standalone, "pack.use 'christoomey/vim-tmux-navigator'", 'standalone profile')
if lock then
  assert(lock.plugins['vim-tmux-navigator'] ~= nil, 'lock must retain vim-tmux-navigator')
end

-- 4. Comment-only wrapper modules and stale configuration claims are absent.
local removed_wrappers = { 'nvim.plugins.mdx', 'nvim.plugins.tmux' }
for _, mod in ipairs(removed_wrappers) do
  local ok = pcall(require, mod)
  assert(not ok, mod .. ' must not be loadable (wrapper removed)')
end
assert_absent(standalone, 'configured implicitly', 'standalone profile')

if #errors > 0 then
  print 'PLUGIN DECLARATION CONTRACT FAILURES:'
  for _, error in ipairs(errors) do
    print('  FAIL: ' .. error)
  end
  vim.cmd 'cq'
else
  print 'Plugin declaration contract check passes.'
  vim.cmd 'q'
end
