return {

	init_options = {
		plugins = {
			{
				name = "@vue/typescript-plugin",
				location = (function()
					if os.getenv("PNPM_HOME") then
						return os.getenv("PNPM_HOME") .. "/global/5/node_modules/@vue/typescript-plugin"
					end
					return ""
				end)(),
				languages = { "javascript", "typescript", "vue" },
			},
		},
	},
	filetypes = {
		"typescript",
		"typescript.tsx",
		"javascript.tsx",
		"typescriptreact",
		"javascript",
		"javascriptreact",
		"vue",
	},
}
