return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- defaults
        "vim",
        "lua",

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
        "eslint-lsp",
        "eslint_d",
        "json-lsp",
        "stylua",
        "tailwindcss-language-server",
        "unocss-language-server",
        "js-debug-adapter",
        "node-debug2-adapter",
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
  --{
  --	"stevearc/conform.nvim",
  --  for users those who want auto-save conform + lazyloading!
  --	event = "BufWritePre",
  --	config = function()
  --		require("custom.configs.conform")
  --	end,
  --	},
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
}
