-- Debug adapter protocol (DAP) configuration
local dap = require 'dap'
local dapui = require 'dapui'

require('mason-nvim-dap').setup {
  automatic_setup = true,
  handlers = {},
  ensure_installed = { 'delve', 'js-debug-adapter' },
}

vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function()
  dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
end, { desc = 'Debug: Set Breakpoint' })

dapui.setup {
  icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
  controls = {
    icons = {
      pause = '⏸', play = '▶', step_into = '⏎', step_over = '⏭',
      step_out = '⏮', step_back = 'b', run_last = '▶▶',
      terminate = '⏹', disconnect = '⏏',
    },
  },
}

vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

dap.listeners.after.event_initialized['dapui_config'] = dapui.open
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close

require('dap-go').setup()

dap.adapters['pwa-node'] = {
  type = 'server',
  host = 'localhost',
  port = '${port}',
  executable = {
    command = 'js-debug-adapter',
    args = { '${port}' },
  },
}

for _, language in ipairs { 'typescript', 'javascript' } do
  dap.configurations[language] = {
    {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch Current File (pwa-node)',
      cwd = vim.fn.getcwd(),
      args = { '${file}' },
      sourceMaps = true,
      protocol = 'inspector',
    },
    {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach Program (pwa-node)',
      cwd = vim.fn.getcwd(),
      processId = require('dap.utils').pick_process,
      skipFiles = { '<node_internals>/**' },
    },
    {
      type = 'pwa-node',
      request = 'launch',
      name = 'Debug Current Test File',
      autoAttachChildProcesses = true,
      skipFiles = { '<node_internals>/**', '**/node_modules/**' },
      program = '${workspaceFolder}/node_modules/vitest/vitest.mjs',
      runtimeExecutable = 'node',
      rootPath = '${workspaceFolder}',
      cwd = '${workspaceFolder}',
      args = { 'run', '--no-file-parallelism', '${relativeFile}' },
      smartStep = true,
      console = 'integratedTerminal',
      internalConsoleOptions = 'neverOpen',
    },
  }
end
-- vim: ts=2 sts=2 sw=2 et
