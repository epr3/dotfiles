-- Minimal init for headless tests. Sets runtime path so `require` finds our modules
-- without loading plugins, LSP, or Mason.
vim.opt.rtp:prepend(vim.fn.fnamemodify('..', ':p'))

-- Stub vim.lsp.protocol so capabilities merge doesn't blow up
vim.lsp = vim.lsp or {}
vim.lsp.protocol = vim.lsp.protocol or {}
vim.lsp.protocol.make_client_capabilities = vim.lsp.protocol.make_client_capabilities or function()
  return {}
end
