-- Headless profile lockfile contract check.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/profile-lockfiles.lua
--
-- Verifies the split lockfile boundary:
--   1. Each profile selects its own lockfile via the plugin-management path.
--   2. Each lock contains exactly that profile's declared plugin set.
--   3. Removed and superseded package identities are absent from both locks.

local errors = {}

local function assert(condition, msg)
  if not condition then
    errors[#errors + 1] = msg
  end
end

local function config_root()
  local source = debug.getinfo(1, 'S').source:sub(2)
  return vim.fn.fnamemodify(source, ':p:h:h')
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

local function lockfile_path(decl, default)
  local single = decl:match 'pack%.lockfile%s*[\'"]([^\'"]+)[\'"]' or decl:match 'pack%.lockfile%(["\']([^"\']+)["\']%)'
  return single or default
end

local function parse_declared_names(decl)
  local names = {}
  -- pack.use 'repo' or pack.use "repo"
  for repo in decl:gmatch 'pack%.use%s*[\'"]([^\'"]+)[\'"]' do
    local name = repo:match '([^/]+)$'
    names[name] = true
  end
  -- pack.use('repo', { ... }) with optional name override
  for repo, opts in decl:gmatch 'pack%.use%s*%(%s*[\'"]([^\'"]+)[\'"]%s*,%s*(%b{})' do
    local name = opts:match 'name%s*=%s*[\'"]([^\'"]+)[\'"]'
    if not name then
      name = repo:match '([^/]+)$'
    end
    names[name] = true
  end
  return names
end

local root = config_root()
local standalone_decl = read_file(root .. '/lua/plugins.lua')
local vscode_decl = read_file(root .. '/lua/plugins-vscode.lua')

-- 1. Each profile selects its own lockfile via the plugin-management path.
local standalone_lock = lockfile_path(standalone_decl, 'nvim-pack-lock.json')
local vscode_lock = lockfile_path(vscode_decl, 'vscode-pack-lock.json')

assert(standalone_lock == 'nvim-pack-lock.json', 'standalone lockfile must be nvim-pack-lock.json (got ' .. tostring(standalone_lock) .. ')')
assert(vscode_lock == 'vscode-pack-lock.json', 'vscode lockfile must be vscode-pack-lock.json (got ' .. tostring(vscode_lock) .. ')')

local standalone_lock_text = read_file(root .. '/' .. standalone_lock)
local vscode_lock_text = read_file(root .. '/' .. vscode_lock)

assert(standalone_lock_text ~= nil, 'standalone lockfile must exist: ' .. standalone_lock)
assert(vscode_lock_text ~= nil, 'vscode lockfile must exist: ' .. vscode_lock)

local standalone_data = standalone_lock_text and vim.json.decode(standalone_lock_text) or nil
local vscode_data = vscode_lock_text and vim.json.decode(vscode_lock_text) or nil

assert(standalone_data ~= nil and standalone_data.plugins ~= nil, 'standalone lock must decode to { plugins = {...} }')
assert(vscode_data ~= nil and vscode_data.plugins ~= nil, 'vscode lock must decode to { plugins = {...} }')

local standalone_declared = parse_declared_names(standalone_decl)
local vscode_declared = parse_declared_names(vscode_decl)

local function lock_keys(lock)
  local keys = {}
  for k in pairs(lock.plugins or {}) do
    keys[k] = true
  end
  return keys
end

local standalone_locked = standalone_data and lock_keys(standalone_data) or {}
local vscode_locked = vscode_data and lock_keys(vscode_data) or {}

-- 2. Each lock contains exactly that profile's declared plugin set.
for name in pairs(standalone_declared) do
  assert(standalone_locked[name] ~= nil, 'standalone lock must contain ' .. name)
end
for name in pairs(standalone_locked) do
  assert(standalone_declared[name] ~= nil, 'standalone lock must not contain undeclared ' .. name)
end

for name in pairs(vscode_declared) do
  assert(vscode_locked[name] ~= nil, 'vscode lock must contain ' .. name)
end
for name in pairs(vscode_locked) do
  assert(vscode_declared[name] ~= nil, 'vscode lock must not contain undeclared ' .. name)
end

-- 3. Removed and superseded package identities are absent from both locks.
local forbidden = {
  'fidget.nvim',
  'nvim-treesitter-context',
  'mini.ai',
  'mini.comment',
  'mini.move',
  'mini.pairs',
  'mini.surround',
}

for _, name in ipairs(forbidden) do
  assert(standalone_locked[name] == nil, 'standalone lock must not contain ' .. name)
  assert(vscode_locked[name] == nil, 'vscode lock must not contain ' .. name)
end

if #errors > 0 then
  print 'PROFILE LOCKFILE CONTRACT FAILURES:'
  for _, err in ipairs(errors) do
    print('  FAIL: ' .. err)
  end
  vim.cmd 'cq'
else
  print 'Profile lockfile contract check passes.'
  vim.cmd 'q'
end
-- vim: ts=2 sts=2 sw=2 et
