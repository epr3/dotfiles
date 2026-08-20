# Headless checks

From `.config/nvim`, run the offline LSP declaration and behavior checks:

```sh
for test in \
  lsp-registry-contract.lua \
  lsp-registry-derivation.lua \
  lsp-registry-behaviors.lua \
  lsp-registry-integration.lua \
  lsp-registry-vue-adapter.lua \
  lsp-registry-formatting.lua \
  mappings-harpoon-gitsigns.lua \
  plugin-declarations-contract.lua \
  mini-profile-adapter.lua \
  profile-lockfiles.lua \
  treesitter-core-first.lua; do
  nvim --headless -u tests/minimal-init.lua -l "tests/$test"
done
```

These checks stub plugin dependencies. They neither access the network nor start language-server processes.

Run the standalone startup smoke check separately, after normal Neovim startup:

```sh
nvim --headless '+luafile tests/lsp-registry-startup.lua'
```

It uses installed plugins and local Mason state, so it is deliberately not part of the offline contract suite.

Once Stylua is available, verify Lua formatting with the tracked `.stylua.toml` settings:

```sh
stylua --check lua tests
```
