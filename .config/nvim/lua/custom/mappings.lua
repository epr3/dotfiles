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
    ["<leader>gg"] = {
      function()
        local nvterm = require("nvterm.terminal")
        nvterm.send("lazygit && exit", "float")
        nvterm.toggle("float")
        nvterm.toggle("float")
      end,
      "Toggle lazygit",
    },
  },
}

M.trouble = {
  plugin = true,
  n = {
    ["<leader>xx"] = {
      function()
        require("trouble").toggle()
      end,
      "Toggle Trouble",
    },
    ["<leader>xw"] = {
      function()
        require("trouble").toggle("workspace_diagnostics")
      end,
      "Toggle workspace diagnostics",
    },
    ["<leader>xd"] = {
      function()
        require("trouble").toggle("document_diagnostics")
      end,
      "Toggle document diagnostics",
    },
    ["<leader>xq"] = {
      function()
        require("trouble").toggle("quickfix")
      end,
      "Toggle quickfix",
    },
    ["<leader>xl"] = {
      function()
        require("trouble").toggle("loclist")
      end,
      "Toggle loclist",
    },
    ["gR"] = {
      function()
        require("trouble").toggle("lsp_references")
      end,
      "Toggle LSP references",
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
    ["<leader>dr"] = {
      "<cmd> DapContinue <CR>",
      "Run or continue debugger",
    },
    ["<leader>dus"] = {
      function()
        local widgets = require("dap.ui.widgets")
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
        require("neotest").run.run(vim.fn.expand("%"))
      end,
      "Run the current file",
    },
    ["<leader>td"] = {
      function()
        require("neotest").run.run({ strategy = "dap" })
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
        require("neotest").output.open({ enter = true, auto_close = true })
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
