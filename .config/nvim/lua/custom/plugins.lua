return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				-- defaults
				"vim",
				"lua",
				"markdown",

				-- web dev
				"html",
				"css",
				"javascript",
				"typescript",
				"tsx",
				"json",
				"jsonc",
				"vue",
				"svelte",
				"astro",

				"go",
			},
		},
	},
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("custom.configs.dap")
			require("core.utils").load_mappings("dap")
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = "mfussenegger/nvim-dap",
		init = function()
			require("core.utils").load_mappings("harpoon")
		end,
		config = function()
			require("custom.configs.dap-ui")
		end,
	},
	{
		"leoluz/nvim-dap-go",
		ft = "go",
		dependencies = {
			"mfussenegger/nvim-dap",
			"rcarriga/nvim-dap-ui",
		},
		config = function(_, opts)
			require("dap-go").setup(opts)
			require("core.utils").load_mappings("dap_go")
		end,
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"marilari88/neotest-vitest",
		},
		init = function()
			require("core.utils").load_mappings("neotest")
		end,
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-vitest"),
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"folke/neodev.nvim",
			"folke/neoconf.nvim",
		},
		config = function()
			require("neodev").setup({
				lspconfig = false,
				plugins = { "neotest" },
				types = true,
			})
			require("neoconf").setup({})
			require("plugins.configs.lspconfig")
			require("custom.configs.lspconfig")
		end,
	},
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"astro-language-server",
				"vue-language-server",
				"typescript-language-server",
				"lua-language-server",
				"emmet-ls",
				"eslint_d",
				"json-lsp",
				"stylua",
				"tailwindcss-language-server",
				"unocss-language-server",
				"js-debug-adapter",
				"marksman",
				"markdownlint",
				"gopls",
				"gofumpt",
				"golines",
				"goimports",
				"delve",
			},
		},
	},
	{
		"nvimtools/none-ls.nvim",
		event = "VeryLazy",
		opts = function()
			return require("custom.configs.null-ls")
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		ft = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"vue",
			"astro",
		},
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	{
		"folke/trouble.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		init = function()
			require("core.utils").load_mappings("trouble")
		end,
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		init = function()
			require("core.utils").load_mappings("harpoon")
		end,
		config = function()
			require("custom.configs.harpoon")
		end,
	},
	{
		"christoomey/vim-tmux-navigator",
		lazy = false,
	},
}
