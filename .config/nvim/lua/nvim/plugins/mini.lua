-- Mini modules: ai, surround, starter
require('mini.ai').setup { n_lines = 500 }
require('mini.surround').setup()

local starter = require 'mini.starter'
starter.setup {
  items = {
    starter.sections.builtin_actions(),
    starter.sections.recent_files(5, false),
    starter.sections.recent_files(5, true),
  },
  silent = true,
}
-- vim: ts=2 sts=2 sw=2 et
