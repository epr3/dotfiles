# Tool Configuration

Application and developer-tool configuration managed under `.config/`.

## Language

**Neovim configuration**: The tracked Lua editor setup under `.config/nvim/` used by standalone Neovim and, in constrained form, by VS Code Neovim.
_Avoid_: nvim setup, editor config.

**VS Code Neovim profile**: The Neovim plugin subset and VS Code user files that make VS Code use the same modal-editing vocabulary without loading standalone-only UI, LSP, or terminal integrations.
_Avoid_: vscode configs, VSCode mode.

**Kickstart alignment**: Following kickstart.nvim's current readable, explicit Neovim-0.12-oriented patterns rather than treating Kickstart as a full distribution to vendor unchanged.
_Avoid_: best practices.

**Personal plugin set**: The current non-Kickstart plugins that encode existing workflows and should be ported unless they duplicate or conflict with Kickstart-aligned behavior.
_Avoid_: extras, kitchen sink.

## Relationships

- **Neovim configuration** has a **VS Code Neovim profile** for embedded editing.
- **Kickstart alignment** shapes the **Neovim configuration** without replacing the **Personal plugin set**.
- A **Mini profile adapter** serves both the **Neovim configuration** and its **VS Code Neovim profile**.
- **Core-first Treesitter configuration** is part of the **Neovim configuration**.

## Glossary

**Per-server declaration**: A pure, complete Neovim LSP configuration plus Mason package identity for one enabled language server, owned by one module under `.config/nvim/lua/nvim/servers/`.
_Avoid_: server configs, LSP setup files.

**Optional adapter**: A declarative extension inside a per-server declaration that activates only when the Mason package it names is installed — currently the Vue adapter for TypeScript on `ts_ls`.
_Avoid_: plugin wiring, vue plugin.

**Deferred resolution**: Resolving optional adapters at registry setup rather than while declarations load; declarations never query Mason state at load time.
_Avoid_: load-time lookup, eager resolution.

**Repair command**: The concrete command the health interface prints so missing optional tooling can be restored (for example `:MasonInstall vue-language-server`).
_Avoid_: repair steps, install hint.

**Keystroke interface**: A Neovim mapping's mode and key sequence, which must resolve to one action in every buffer where it is available.
_Avoid_: keybind, shortcut.

**Mini profile adapter**: The shared Mini configuration that gives the standalone **Neovim configuration** and **VS Code Neovim profile** one package identity while allowing each to select its own Mini modules.
_Avoid_: duplicated mini config, mini split.

**Core-first Treesitter configuration**: Neovim-0.12 Treesitter behavior implemented with Neovim core APIs, using a plugin adapter only for behavior core does not provide.
_Avoid_: legacy Treesitter setup, configs.setup.

**Plugin declaration interface**: A plugin declaration and its configuration module considered as one truthful interface, with no inert declarations or comment-only wrapper modules.
_Avoid_: plugin list, plugin stub.

## Example dialogue

> **Dev:** "Should we copy Kickstart's `init.lua` wholesale?"
> **Domain expert:** "No — this repo wants **Kickstart alignment**, preserving its **Personal plugin set** and explicit **VS Code Neovim profile**."

## Flagged ambiguities

- "best practices" resolved to **Kickstart alignment**: use current Kickstart patterns and `vim.pack`, not vendor Kickstart unchanged.
- "vscode configs" resolved to **VS Code Neovim profile**: create the missing tracked VS Code user files and keep the embedded Neovim plugin subset updated.
- Supermaven is outside the preserved **Personal plugin set** for this refresh; the refreshed Neovim configuration should not include a Neovim AI completion plugin.
