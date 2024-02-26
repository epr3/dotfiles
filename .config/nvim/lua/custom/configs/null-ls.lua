local lsp_formatting = function(bufnr)
	vim.lsp.buf.format({
		filter = function(c)
			return c.name == "null-ls"
		end,
		bufnr = bufnr,
	})
end

local null_ls = require("null-ls")
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local opts = {
	sources = {
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.diagnostics.markdownlint,
		null_ls.builtins.formatting.markdownlint,
		null_ls.builtins.formatting.gofumpt,
		null_ls.builtins.formatting.goimports_reviser,
		null_ls.builtins.formatting.golines,
	},
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") and client.name ~= "eslint" then
			vim.api.nvim_clear_autocmds({
				group = augroup,
				buffer = bufnr,
			})
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					lsp_formatting(bufnr)
				end,
			})
		end
	end,
}
return opts
