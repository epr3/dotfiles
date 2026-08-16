# Adopt a core-first Treesitter configuration

The Neovim configuration will replace the legacy `nvim-treesitter.configs` interface and its `master`-branch lock-in with **Core-first Treesitter configuration** on the Neovim 0.12 line. The migration preserves current user-visible grammar coverage, MDX support, standalone highlighting/indent/autotag, and the VS Code profile's no-double-highlight behavior; a plugin adapter remains only for behavior Neovim core does not provide.
