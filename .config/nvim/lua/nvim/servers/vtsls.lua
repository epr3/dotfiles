local mason_registry = require 'mason-registry'
local vue_language_server_path = mason_registry.get_package('vue-language-server'):get_install_path() .. '/node_modules/@vue/language-server'
return {
  settings = {
    vtsls = {
      autoUseWorkspaceTsdk = true,
      tsserver = {
        globalPlugins = {
          {
            name = '@vue/typescript-plugin',
            location = vue_language_server_path,
            languages = { 'vue' },
            configNamespace = 'typescript',
            enableForWorkspaceTypeScriptVersions = true,
          },
        },
      },
    },
  },
  filetypes = {
    'typescript',
    'typescript.tsx',
    'javascript.tsx',
    'typescriptreact',
    'javascript',
    'javascriptreact',
    'vue',
  },
}
