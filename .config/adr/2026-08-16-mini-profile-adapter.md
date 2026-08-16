# Use one Mini package identity behind a profile adapter

The standalone **Neovim configuration** and **VS Code Neovim profile** will declare the `mini.nvim` monorepo from one source and share Mini options through a **Mini profile adapter**, while each profile selects its own Mini modules. Each profile will keep its own lockfile, so updating one intentionally distinct plugin set cannot leave the other profile's pins stale.
