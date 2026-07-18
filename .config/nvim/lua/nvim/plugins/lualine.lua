-- Statusline
require('lualine').setup {
  theme = 'tokyonight',
  sections = {
    lualine_c = { { 'filename', path = 1 } },
  },
}
-- vim: ts=2 sts=2 sw=2 et
