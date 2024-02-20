local M = {}

M.general = {
  n = {
    --  format with conform
    ["<leader>fm"] = {
      function()
        require("conform").format()
      end,
      "formatting",
    },
    ["<leader>vc"] = {
      function()
        local nvterm = require "nvterm.terminal"
        local terminal = nvterm.new "float"
        local id = terminal.job_id

        -- The previous id was not always right for some reason so I made a fallback,
        -- as you can only have one floating terminal
        for _, term in pairs(nvterm.list_terms()) do
          if term.type == "float" then
            id = term.job_id
          end
        end

        if vim.api.nvim_buf_is_valid(id) then
          vim.api.nvim_chan_send(id, "lazygit && exit\n")
        end
      end,
      "Toggle lazygit",
    },
  },
}

M.neogit = {
  plugin = true,
  n = {
    ["<leader>gn"] = {
      function()
        require("neogit").open()
      end,
      "Open Neogit",
    },
    ["<leader>gc"] = {
      function()
        require("neogit").open { "commit" }
      end,
      "Open Neogit Commit",
    },
    ["<leader>gs"] = {
      function()
        require("neogit").open { kind = "split" }
      end,
      "Open Neogit Split",
    },
  },
}

M.dap = {
  plugin = true,
  n = {
    ["<leader>db"] = {
      function()
        require("dap").toggle_breakpoint()
      end,
      "Add breakpoint at line",
    },
    ["<leader>dus"] = {
      function()
        local widgets = require "dap.ui.widgets"
        local sidebar = widgets.sidebar(widgets.scopes)
        sidebar.open()
      end,
      "Open debugging sidebar",
    },
  },
}

M.neotest = {
  plugin = true,
  n = {
    ["<leader>tr"] = {
      function()
        require("neotest").run.run()
      end,
      "Run the nearest test",
    },
    ["<leader>tt"] = {
      function()
        require("neotest").run.run(vim.fn.expand "%")
      end,
      "Run the current file",
    },
    ["<leader>td"] = {
      function()
        require("neotest").run.run { strategy = "dap" }
      end,
      "Debug the nearest test",
    },
    ["<leader>tl"] = {
      function()
        require("neotest").run.run_last()
      end,
      "Run Last",
    },
    ["<leader>ts"] = {
      function()
        require("neotest").summary.toggle()
      end,
      "Toggle Summary",
    },
    ["<leader>to"] = {
      function()
        require("neotest").output.open { enter = true, auto_close = true }
      end,
      "Show Output",
    },
    ["<leader>tO"] = {
      function()
        require("neotest").output_panel.toggle()
      end,
      "Toggle Output Panel",
    },
  },
}

return M
