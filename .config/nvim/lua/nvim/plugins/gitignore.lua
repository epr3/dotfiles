-- Generate .gitignore from templates
local gitignore = require 'gitignore'
vim.keymap.set('n', '<leader>gi', gitignore.generate, { desc = '[G]enerate .g[i]tignore' })
-- vim: ts=2 sts=2 sw=2 et
