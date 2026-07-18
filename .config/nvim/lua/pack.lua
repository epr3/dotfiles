-- pack.lua -- vim.pack plugin manager
-- Installs plugins from GitHub repos into pack/plugins/{start,opt}
-- so Neovim's built-in package mechanism loads them automatically.
--
-- Usage:
--   local pack = require 'pack'
--   pack.use('author/repo', { name = 'custom-name', opt = true, build = 'make' })
--   pack.ensure()
--   pack.setup()

local M = {}

local base = vim.fn.stdpath 'data' .. '/site/pack/plugins'
local start_dir = base .. '/start'
local opt_dir = base .. '/opt'

--- Registered plugin descriptors.
---@type table<string, {repo:string,name:string,opt:boolean,build:string|fun():nil}>
M.plugins = {}

--- Declare a plugin for installation.
---@param repo string  GitHub "owner/repo" identifier.
---@param opts? {name?:string, opt?:boolean, build?:string|fun()}
function M.use(repo, opts)
  opts = opts or {}
  local name = opts.name or repo:match '([^/]+)$'
  M.plugins[repo] = {
    repo = repo,
    name = name,
    opt = opts.opt or false,
    build = opts.build,
  }
end

local function plugin_dir(spec)
  return (spec.opt and opt_dir or start_dir) .. '/' .. spec.name
end

local function clone(spec)
  local dir = plugin_dir(spec)
  if vim.fn.isdirectory(dir) == 1 then
    return false
  end
  vim.fn.mkdir(vim.fn.fnamemodify(dir, ':h'), 'p')
  local url = 'https://github.com/' .. spec.repo .. '.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', url, dir }
  if vim.v.shell_error ~= 0 then
    vim.schedule(function()
      vim.notify('pack: failed to clone ' .. spec.repo, vim.log.levels.WARN)
    end)
    return false
  end
  return true
end

local function run_build(spec)
  if not spec.build then
    return
  end
  local dir = plugin_dir(spec)
  local build = spec.build
  if type(build) == 'string' then
    if build:match '^:' then
      -- Vim command (e.g. ':TSUpdate') – skip for initial install
    else
      vim.fn.system({ 'git', '-C', dir, 'config', 'core.hooksPath', '/dev/null' })
      vim.fn.system({ 'sh', '-c', 'cd ' .. vim.fn.shellescape(dir) .. ' && ' .. build })
    end
  elseif type(build) == 'function' then
    build(dir)
  end
end

--- Clone any missing plugins.  Returns true when at least one was cloned.
function M.ensure()
  local new = false
  for _, spec in pairs(M.plugins) do
    if clone(spec) then
      run_build(spec)
      new = true
    end
  end
  if new then
    -- Freshly cloned plugins need a restart to be picked up by packpath
    vim.schedule(function()
      vim.notify 'pack: new plugins cloned -- restart Neovim to load them'
    end)
  end
  return new
end

--- Update all installed plugins (git pull).
function M.update()
  local updated = false
  for _, spec in pairs(M.plugins) do
    local dir = plugin_dir(spec)
    if vim.fn.isdirectory(dir .. '/.git') == 1 then
      vim.fn.system { 'git', '-C', dir, 'pull', '--ff-only' }
      if vim.v.shell_error == 0 then
        local _, out = vim.fn.systemlist { 'git', '-C', dir, 'log', '-1', '--format=%h %s' }
        if out and #out > 0 then
          updated = true
        end
        run_build(spec)
      end
    end
  end
  if not updated then
    vim.notify 'pack: all plugins up-to-date'
  end
end

--- Set up all non-opt plugins that declare config functions.
function M.setup()
  for _, spec in pairs(M.plugins) do
    if spec.setup and not spec.opt then
      spec.setup()
    end
  end
end

vim.api.nvim_create_user_command('PackUpdate', M.update, {})

return M
-- vim: ts=2 sts=2 sw=2 et
