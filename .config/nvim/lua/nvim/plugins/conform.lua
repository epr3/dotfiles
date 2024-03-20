return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },

        css = { "prettier" },
        html = { "prettier" },

        sh = { "shfmt" },

        go = { "gofumpt", "goimports", "golines" },
      },
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = {
          c = true,
          cpp = true,
          vue = true,
          typescript = true,
          typescriptreact = true,
          javascript = true,
          javascriptreact = true
        }
        return {
          timeout_ms = 500,
          lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
        }
      end,
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
