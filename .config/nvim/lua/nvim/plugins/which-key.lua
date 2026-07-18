-- Keybinding popup
require('which-key').setup()

require('which-key').add {
  { '<leader>c',  group = '[C]ode' },
  { '<leader>c_', hidden = true },
  { '<leader>d',  group = '[D]ocument' },
  { '<leader>d_', hidden = true },
  { '<leader>r',  group = '[R]ename' },
  { '<leader>r_', hidden = true },
  { '<leader>s',  group = '[S]earch' },
  { '<leader>s_', hidden = true },
  { '<leader>w',  group = '[W]orkspace' },
  { '<leader>w_', hidden = true },
}
-- vim: ts=2 sts=2 sw=2 et
