-- Preserve each Neovim pane independently when Zellij resurrects its session.
local M = {}

function M.setup()
  if not vim.env.ZELLIJ or not vim.env.ZELLIJ_PANE_ID or vim.fn.executable 'zellij' == 0 then
    return
  end

  local dir = vim.fn.stdpath 'state' .. '/zellij-sessions'
  if vim.fn.mkdir(dir, 'p', 448) == 0 and vim.fn.isdirectory(dir) == 0 then
    vim.notify('Cannot create Zellij session directory: ' .. dir, vim.log.levels.ERROR)
    return
  end

  local session = vim.g.zellij_session_file
    or ('%s/%d-%s.vim'):format(dir, vim.fn.getpid(), tostring(vim.uv.hrtime()))
  local enabled = false

  local function save()
    local ok, err = pcall(vim.cmd, 'mksession! ' .. vim.fn.fnameescape(session))
    if not ok then
      vim.notify('Cannot save Zellij Neovim session: ' .. tostring(err), vim.log.levels.ERROR)
    end
    return ok
  end

  local function zellij(args)
    local command = { 'zellij', 'action', 'set-resurrect-command' }
    vim.list_extend(command, args)
    return vim.system(command, { text = true }):wait()
  end

  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
      -- Defer until a session passed with -S has finished loading.
      vim.schedule(function()
        if not save() then
          return
        end
        local result = zellij {
          '--',
          vim.v.progpath,
          '--cmd',
          'let g:zellij_session_file = ' .. vim.fn.string(session),
          '-S',
          session,
        }
        if result.code ~= 0 then
          vim.notify('Cannot set Zellij resurrection command: ' .. (result.stderr or ''), vim.log.levels.ERROR)
          return
        end
        enabled = true
      end)
    end,
  })

  local timer = vim.uv.new_timer()
  timer:start(15000, 15000, vim.schedule_wrap(function()
    if enabled then
      save()
    end
  end))

  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      timer:stop()
      timer:close()
      if not enabled then
        return
      end
      if vim.v.dying ~= 0 then
        save()
      else
        -- A normal editor exit should not resurrect a program that was closed.
        local result = zellij { '--clear' }
        if result.code == 0 then
          vim.fn.delete(session)
        end
      end
    end,
  })
end

return M
