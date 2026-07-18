-- File explorer as a buffer
require('oil').setup {
  view_options = {
    show_hidden = true,
  },
}

vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
-- vim: ts=2 sts=2 sw=2 et
