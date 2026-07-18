# Move Neovim plugins to vim.pack

The Neovim configuration will follow current kickstart.nvim more literally by using Neovim's built-in `vim.pack` plugin manager instead of `lazy.nvim`, while preserving the repository's personal plugin capabilities and the separate VS Code Neovim profile. This trades lazy.nvim's mature lazy-loading/spec ecosystem for fewer external bootstrap assumptions and closer alignment with upstream Kickstart on the installed Neovim 0.12 line.
