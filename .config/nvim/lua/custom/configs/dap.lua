local dap = require("dap")

dap.adapters["pwa-node"] = {
	type = "server",
	host = "localhost",
	port = "${port}",
	executable = {
		-- command = "node",
		-- -- 💀 Make sure to update this path to point to your installation
		-- args = { "/path/to/js-debug/src/dapDebugServer.js", "${port}" },
		command = "js-debug-adapter",
		args = { "${port}" },
	},
}

for _, language in ipairs({ "typescript", "javascript" }) do
	dap.configurations[language] = {
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch Current File (pwa-node)",
			cwd = vim.fn.getcwd(),
			args = { "${file}" },
			sourceMaps = true,
			protocol = "inspector",
		},
		{
			type = "pwa-node",
			request = "attach",
			name = "Attach Program (pwa-node)",
			cwd = vim.fn.getcwd(),
			processId = require("dap.utils").pick_process,
			skipFiles = { "<node_internals>/**" },
		},
	}
end
