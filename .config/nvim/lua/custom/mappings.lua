local M = {}

M.general = {
	n = {
		["<C-h>"] = {
			"<cmd> TmuxNavigateLeft<CR>",
			"window left",
		},

		["<C-j>"] = {
			"<cmd> TmuxNavigateDown<CR>",
			"window down",
		},

		["<C-l>"] = {
			"<cmd> TmuxNavigateRight<CR>",
			"window right",
		},

		["<C-k>"] = {
			"<cmd> TmuxNavigateUp<CR>",
			"window up",
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

M.harpoon = {
	plugin = true,
	n = {
		["<leader>aa"] = {
			function()
				require("harpoon"):list():append()
			end,
			"Append to list harpoon",
		},
		["<leader>ae"] = {
			function()
				require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
			end,
			"Toggle harpoon list",
		},
		["<leader>ah"] = {
			function()
				require("harpoon"):list():select(1)
			end,
			"Select first file harpoon",
		},

		["<leader>aj"] = {
			function()
				require("harpoon"):list():select(2)
			end,
			"Select second file harpoon",
		},

		["<leader>ak"] = {
			function()
				require("harpoon"):list():select(3)
			end,
			"Select third file harpoon",
		},

		["<leader>al"] = {
			function()
				require("harpoon"):list():select(4)
			end,
			"Select fourth file harpoon",
		},
		["<leader>ap"] = {
			function()
				require("harpoon"):list():prev()
			end,
			"Previous buffer harpoon",
		},
		["<leader>an"] = {
			function()
				require("harpoon"):list():next()
			end,
			"Next buffer harpoon",
		},
	},
}

M.dap_go = {
	plugin = true,
	n = {
		["<leader>dgt"] = {
			function()
				require("dap-go").debug_test()
			end,
			"Debug go test",
		},
		["<leader>dgl"] = {
			function()
				require("dap-go").debug_last()
			end,
			"Debug last go test",
		},
	},
}

M.trouble = {
	plugin = true,
	n = {
		["<leader>yx"] = {
			function()
				require("trouble").toggle()
			end,
			"Toggle Trouble",
		},
		["<leader>yw"] = {
			function()
				require("trouble").toggle("workspace_diagnostics")
			end,
			"Toggle workspace diagnostics",
		},
		["<leader>yd"] = {
			function()
				require("trouble").toggle("document_diagnostics")
			end,
			"Toggle document diagnostics",
		},
		["<leader>yq"] = {
			function()
				require("trouble").toggle("quickfix")
			end,
			"Toggle quickfix",
		},
		["<leader>yl"] = {
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
