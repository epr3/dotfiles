-- Mini profile adapter -- shared Mini configuration for the standalone Neovim
-- configuration and the VS Code Neovim profile. Both profiles use the single
-- echasnovski/mini.nvim package identity; each selects only the Mini modules
-- it intends to load.

local M = {}

--- Shared options applied to mini.ai in both profiles.
M.ai_options = { n_lines = 500 }

--- Configure Mini modules for the given profile.
---@param profile 'standalone'|'vscode'
function M.setup(profile)
  require('mini.ai').setup(M.ai_options)

  if profile == 'standalone' then
    local starter = require 'mini.starter'
    starter.setup {
      items = {
        starter.sections.builtin_actions(),
        starter.sections.recent_files(5, false),
        starter.sections.recent_files(5, true),
      },
      silent = true,
    }
  elseif profile == 'vscode' then
    require('mini.move').setup {}
    require('mini.comment').setup {}
    require('mini.pairs').setup {}
    require('mini.surround').setup {
      mappings = {
        add = 'gza',
        delete = 'gzd',
        find = 'gzf',
        find_left = 'gzF',
        highlight = 'gzh',
        replace = 'gzr',
        update_n_lines = 'gzn',
      },
    }
  else
    error('Unknown Mini profile: ' .. tostring(profile))
  end
end

return M
-- vim: ts=2 sts=2 sw=2 et
