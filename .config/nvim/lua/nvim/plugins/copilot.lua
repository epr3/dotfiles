return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      suggestion = {
        keymap = {
          accept = '<TAB>',
        },
        auto_trigger = true,
      },
    },
  },
}
