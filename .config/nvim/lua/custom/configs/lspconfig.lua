local configs = require("plugins.configs.lspconfig")
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require("lspconfig")

local server_settings = {
  emmet_ls = require("custom.configs.servers.emmet_ls"),
  volar = require("custom.configs.servers.volar"),
  lua_ls = require("custom.configs.servers.lua_ls"),
  jsonls = require("custom.configs.servers.jsonls"),
  tsserver = require("custom.configs.servers.tsserver"),
  eslint = {},
  tailwindcss = {},
  unocss = {},
  astro = {},
}

local conf = require("neoconf")

local is_disabled = function(client)
  return conf.get(client .. ".disable")
end

local get_server_settings = function(server_name)
  -- return standard server settings in all other cases
  return server_settings[server_name] or {}
end

local get_config = function(server_name)
  return vim.tbl_extend("keep", get_server_settings(server_name), {
    on_attach = on_attach,
    capabilities = capabilities,
  })
end

for key, _ in pairs(server_settings) do
  if not is_disabled(key) then
    lspconfig[key].setup(get_config(key))
  end
end
