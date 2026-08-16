-- Optional Vue adapter: declared as pure data and applied only at registry
-- setup time, when the optional vue-language-server package is installed.
-- The `location` is relative and resolved by the registry against the Mason
-- install path, so this module never touches Mason state while loading.
return {
  mason = 'typescript-language-server',
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'javascript.jsx', 'typescript.tsx' },
  optional = {
    {
      package = 'vue-language-server',
      filetypes = { 'vue' },
      init_options = {
        plugins = {
          {
            name = '@vue/typescript-plugin',
            languages = { 'vue' },
            location = 'node_modules/@vue/language-server',
          },
        },
      },
      on_attach = function(client)
        -- Volar (vue_ls) owns semantic tokens for .vue; keep ts_ls tokens off to avoid duplication.
        local semantic_tokens = client.server_capabilities.semanticTokensProvider
        if semantic_tokens then
          semantic_tokens.full = vim.bo.filetype ~= 'vue'
        end
      end,
    },
  },
}
