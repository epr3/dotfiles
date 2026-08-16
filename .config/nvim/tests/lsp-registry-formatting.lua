-- Headless formatting-authority check for LSP-served web filetypes.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/lsp-registry-formatting.lua

local errors = {}

local function assert(condition, message)
  if not condition then
    errors[#errors + 1] = message
  end
end

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    errors[#errors + 1] = message .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual)
  end
end

local setup_options
package.preload['conform.util'] = function()
  return {
    root_file = function()
      return function() end
    end,
  }
end
package.preload['conform'] = function()
  return {
    setup = function(options)
      setup_options = options
    end,
  }
end

require 'nvim.plugins.conform'

assert(type(setup_options) == 'table', 'Conform must be configured')
if type(setup_options) == 'table' then
  local web_filetypes = {
    'css',
    'html',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'vue',
    'astro',
    'json',
    'jsonc',
    'markdown',
    'markdown.mdx',
  }
  for _, filetype in ipairs(web_filetypes) do
    local formatters = setup_options.formatters_by_ft[filetype]
    assert_eq(type(formatters), 'table', filetype .. ' must have a Conform formatter')
    assert_eq(formatters and formatters[1], 'prettier', filetype .. ' must be owned by Prettier')

    local bufnr = vim.api.nvim_get_current_buf()
    vim.bo[bufnr].filetype = filetype
    local format_options = setup_options.format_on_save(bufnr)
    assert_eq(format_options.lsp_fallback, false, filetype .. ' must not fall back to LSP formatting')
  end

  assert_eq(setup_options.formatters_by_ft.lua[1], 'stylua', 'Lua must use Stylua')
end

if #errors > 0 then
  print 'FORMATTING AUTHORITY FAILURES:'
  for _, error in ipairs(errors) do
    print('  FAIL: ' .. error)
  end
  vim.cmd 'cq'
else
  print 'Formatting authority check passes.'
  vim.cmd 'q'
end
