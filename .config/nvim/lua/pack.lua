-- Native Neovim 0.12 plugin management via vim.pack.
--
-- Usage:
--   local pack = require 'pack'
--   pack.use('author/repo', { name = 'custom-name', version = 'branch', build = 'make' })
--   pack.ensure()

local M = { plugins = {}, builds = {} }

local function source(repo)
  if repo:match '^[%w+.-]+://' or repo:match '^git@' then
    return repo
  end
  return 'https://github.com/' .. repo .. '.git'
end

--- Declare a plugin for vim.pack.
---@param repo string GitHub "owner/repo" identifier or clone URL.
---@param opts? {name?:string, version?:string|table, build?:string|fun(path:string)}
function M.use(repo, opts)
  opts = opts or {}
  local name = opts.name or repo:match '([^/]+)$'
  local spec = { src = source(repo), name = name }
  if opts.version then
    spec.version = opts.version
  end

  table.insert(M.plugins, spec)
  if opts.build then
    M.builds[name] = opts.build
  end
end

local function run_build(event)
  if event.data.kind ~= 'install' and event.data.kind ~= 'update' then
    return
  end

  local build = M.builds[event.data.spec.name]
  if not build then
    return
  end

  if type(build) == 'function' then
    build(event.data.path)
    return
  end

  vim.system({ 'sh', '-c', build }, { cwd = event.data.path }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify(
          ('pack: build failed for %s\n%s'):format(event.data.spec.name, result.stderr),
          vim.log.levels.ERROR
        )
      end)
    end
  end)
end

vim.api.nvim_create_autocmd('PackChanged', { callback = run_build })

--- Install and load all declared plugins for this session.
function M.ensure()
  vim.pack.add(M.plugins)
end

--- Interactively review and apply plugin updates.
function M.update()
  vim.pack.update()
end

vim.api.nvim_create_user_command('PackUpdate', M.update, {})

return M
-- vim: ts=2 sts=2 sw=2 et
