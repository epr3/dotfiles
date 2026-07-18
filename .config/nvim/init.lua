-- Leader must be set before plugins load
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true

-- [[ Core settings ]]
require 'options'

-- [[ Basic keymaps and autocmds ]]
require 'keymaps'

-- [[ Plugin management via vim.pack ]]
require 'pack'

-- Branch: VS Code Neovim vs standalone Neovim
if vim.g.vscode then
  require 'plugins-vscode'
else
  require 'plugins'
end

-- vim: ts=2 sts=2 sw=2 et