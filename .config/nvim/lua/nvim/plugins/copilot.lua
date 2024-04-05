return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'canary',
    dependencies = {
      'github/copilot.vim', -- or github/copilot.vim
      'nvim-lua/plenary.nvim', -- for curl, log wrapper
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('CopilotChat').setup {
        window = {
          layout = 'float',
          title = 'Copilot Chat',
        },
      }

      local chat = require 'CopilotChat'

      local actions = require 'CopilotChat.actions'
      vim.keymap.set('n', '<leader>cct', function()
        chat.toggle()
      end, { desc = '[T]oggle [C]opilot [C]hat' })

      vim.keymap.set('n', '<leader>cch', function()
        actions.pick(actions.help_actions())
      end, { desc = 'Toggle [C]opilot [C]hat [H]elp' })

      vim.keymap.set('n', '<leader>ccp', function()
        actions.pick(actions.prompt_actions {
          selection = require('CopilotChat.select').buffer,
        })
      end, { desc = 'Toggle [C]opilot [C]hat [P]rompt' })

      vim.keymap.set('n', '<leader>ccq', function()
        local input = vim.fn.input 'Quick Chat: '
        if input ~= '' then
          chat.ask(input, { selection = require('CopilotChat.select').buffer })
        end
      end, { desc = 'Toggle [C]opilot [Q]uick [C]hat' })
    end,
    -- See Commands section for default commands if you want to lazy load on them
  },
}

