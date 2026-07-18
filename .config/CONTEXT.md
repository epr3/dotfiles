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

## Example dialogue

> **Dev:** "Should we copy Kickstart's `init.lua` wholesale?"
> **Domain expert:** "No — this repo wants **Kickstart alignment**, preserving its **Personal plugin set** and explicit **VS Code Neovim profile**."

## Flagged ambiguities

- "best practices" resolved to **Kickstart alignment**: use current Kickstart patterns and `vim.pack`, not vendor Kickstart unchanged.
- "vscode configs" resolved to **VS Code Neovim profile**: create the missing tracked VS Code user files and keep the embedded Neovim plugin subset updated.
- Supermaven is outside the preserved **Personal plugin set** for this refresh; the refreshed Neovim configuration should not include a Neovim AI completion plugin.
