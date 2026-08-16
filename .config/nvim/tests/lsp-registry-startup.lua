-- Headless startup check: standalone Neovim exits cleanly.
-- Run: XDG_DATA_HOME=$(mktemp -d) nvim --headless '+luafile tests/lsp-registry-startup.lua'
--
-- Verifies that the full Neovim config (with registry) loads without error
-- in headless mode. Catches module-load, registration, and config-composition
-- failures without requiring a UI or live language-server processes.
-- Use an isolated XDG_DATA_HOME so vim.pack does not merge local plugin state
-- into the repository lockfiles.

local errors = {}

local function assert(condition, message)
  if not condition then
    errors[#errors + 1] = message
  end
end

-- Confirm init.lua reached registry setup rather than merely leaving Neovim alive
-- after an earlier configuration error.
local lua_ls = vim.lsp.config.lua_ls
local marksman = vim.lsp.config.marksman
assert(type(lua_ls) == 'table', 'startup must register lua_ls')
assert(type(marksman) == 'table', 'startup must register marksman')
assert(marksman and marksman.cmd and marksman.cmd[1] == 'marksman', 'startup must keep the Marksman command')
assert(vim.lsp.is_enabled 'lua_ls', 'startup must enable lua_ls')
assert(vim.lsp.is_enabled 'marksman', 'startup must enable marksman')

if #errors > 0 then
  print 'HEADLESS STARTUP FAILURES:'
  for _, error in ipairs(errors) do
    print('  FAIL: ' .. error)
  end
  vim.cmd 'cq'
else
  print 'Headless startup check passes.'
  vim.cmd 'q'
end
