-- Headless core-first treesitter contract check.
-- Run: nvim --headless -u tests/minimal-init.lua -l tests/treesitter-core-first.lua
--
-- Verifies the core-first Treesitter configuration seam:
--   1. Neither profile calls the legacy nvim-treesitter.configs interface.
--   2. Both profiles declare nvim-treesitter without the legacy master pin.
--   3. The standalone profile alone declares the nvim-ts-autotag gap adapter.
--   4. The standalone profile preserves the grammar set, MDX registration,
--      highlighting (with regex fallback), indentation (with Ruby disabled),
--      and autotag behavior.
--   5. The VS Code profile keeps parsers available without enabling Neovim
--      highlight, indent, or autotag.

local errors = {}

local function assert(condition, msg)
  if not condition then
    errors[#errors + 1] = msg
  end
end

local config_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local content = f:read '*a'
  f:close()
  return content
end

local standalone_decl = read_file(config_root .. '/lua/plugins.lua')
local vscode_decl = read_file(config_root .. '/lua/plugins-vscode.lua')

-- 1. No legacy nvim-treesitter.configs invocation remains.
assert(standalone_decl and not standalone_decl:find('nvim%-treesitter%.configs', 1, true), 'standalone must not call nvim-treesitter.configs')
assert(vscode_decl and not vscode_decl:find('nvim%-treesitter%.configs', 1, true), 'vscode must not call nvim-treesitter.configs')

-- 2. Both profiles declare nvim-treesitter without the legacy master pin.
assert(standalone_decl:find("'nvim-treesitter/nvim-treesitter'", 1, true), 'standalone must declare nvim-treesitter')
assert(vscode_decl:find("'nvim-treesitter/nvim-treesitter'", 1, true), 'vscode must declare nvim-treesitter')
assert(not standalone_decl:find('version%s*=%s*[\'"]master[\'"]', 1), 'standalone must not pin nvim-treesitter to master')
assert(not vscode_decl:find('version%s*=%s*[\'"]master[\'"]', 1), 'vscode must not pin nvim-treesitter to master')

-- 3. Standalone alone declares the autotag gap adapter.
assert(standalone_decl:find("pack.use 'windwp/nvim-ts-autotag'", 1, true), 'standalone must declare nvim-ts-autotag')
assert(not vscode_decl:find('windwp/nvim%-ts%-autotag', 1, true), 'vscode must not declare nvim-ts-autotag')

local expected_grammars = {
  'bash',
  'c',
  'html',
  'lua',
  'markdown',
  'markdown_inline',
  'vim',
  'vimdoc',
  'css',
  'javascript',
  'typescript',
  'tsx',
  'json',
  'vue',
  'svelte',
  'astro',
  'go',
  'templ',
}

-- Stub treesitter plugin and core APIs so the test runs without a real install.
local captured = {
  install_calls = {},
  starts = {},
}

package.loaded['nvim-treesitter'] = {
  install = function(grammars)
    table.insert(captured.install_calls, vim.deepcopy(grammars))
  end,
  indentexpr = function()
    return 42
  end,
}

package.loaded['nvim-treesitter.parsers'] = setmetatable({}, {
  __index = function()
    return { install_info = {} }
  end,
})

package.loaded['nvim-ts-autotag'] = {
  setup = function(opts)
    captured.autotag_setup = opts or true
  end,
}

local original_lang = vim.treesitter.language
vim.treesitter.language = {
  register = function(lang, filetype)
    if filetype == 'jsonc' then
      captured.jsonc_register = { lang = lang, filetype = filetype }
    else
      captured.register = { lang = lang, filetype = filetype }
    end
  end,
  get_lang = function(filetype)
    if filetype == 'markdown.mdx' then
      return 'markdown'
    end
    return filetype
  end,
  add = function(lang)
    captured.add = captured.add or {}
    captured.add[lang] = true
    return true
  end,
}

local original_start = vim.treesitter.start
vim.treesitter.start = function(buf, lang)
  table.insert(captured.starts, { buf = buf, lang = lang })
end

package.loaded['nvim.plugins.treesitter'] = nil
local treesitter = require 'nvim.plugins.treesitter'

-- Module-level contract.
assert(vim.deep_equal(treesitter.grammars, expected_grammars), 'grammar set must match the preserved list')
assert(treesitter.regex_highlight_filetypes.ruby and treesitter.regex_highlight_filetypes.markdown, 'ruby and markdown must use regex highlighting')
assert(treesitter.no_indent_filetypes.ruby, 'ruby indent must be disabled')

-- Standalone profile.
treesitter.setup 'standalone'
assert(
  captured.register and captured.register.lang == 'markdown' and captured.register.filetype == 'markdown.mdx',
  'markdown parser must be registered for markdown.mdx'
)
assert(
  captured.jsonc_register and captured.jsonc_register.lang == 'json' and captured.jsonc_register.filetype == 'jsonc',
  'json parser must be registered for jsonc'
)
assert(#captured.install_calls >= 1 and vim.deep_equal(captured.install_calls[1], expected_grammars), 'standalone must install the grammar set')

local function find_start(buf)
  for _, s in ipairs(captured.starts) do
    if s.buf == buf then
      return s
    end
  end
  return nil
end

local html_buf = vim.api.nvim_create_buf(false, true)
vim.bo[html_buf].filetype = 'html'
local html_start = find_start(html_buf)
assert(html_start and html_start.lang == 'html', 'html must start treesitter highlight')
assert(vim.bo[html_buf].indentexpr == "v:lua.require'nvim-treesitter'.indentexpr()", 'html must use treesitter indentexpr')

captured.starts = {}
local ruby_buf = vim.api.nvim_create_buf(false, true)
vim.bo[ruby_buf].filetype = 'ruby'
local ruby_start = find_start(ruby_buf)
assert(ruby_start and ruby_start.lang == 'ruby', 'ruby must start treesitter highlight')
assert(vim.bo[ruby_buf].indentexpr ~= "v:lua.require'nvim-treesitter'.indentexpr()", 'ruby must not use treesitter indentexpr')

captured.starts = {}
local md_buf = vim.api.nvim_create_buf(false, true)
vim.bo[md_buf].filetype = 'markdown'
local md_start = find_start(md_buf)
assert(md_start and md_start.lang == 'markdown', 'markdown must start treesitter highlight')
assert(vim.bo[md_buf].syntax == 'ON', 'markdown must enable legacy syntax highlighting')

captured.starts = {}
local mdx_buf = vim.api.nvim_create_buf(false, true)
vim.bo[mdx_buf].filetype = 'markdown.mdx'
local mdx_start = find_start(mdx_buf)
assert(mdx_start and mdx_start.lang == 'markdown', 'markdown.mdx must start markdown treesitter highlight')

assert(captured.autotag_setup ~= nil, 'standalone must setup nvim-ts-autotag')

-- VS Code profile: clear standalone FileType autocommands first.
vim.cmd 'autocmd! FileType'
captured = {
  install_calls = {},
  starts = {},
}
captured.autotag_setup = nil
package.loaded['nvim.plugins.treesitter'] = nil
package.loaded['nvim-ts-autotag'] = {
  setup = function(opts)
    captured.autotag_setup = opts or true
  end,
}
treesitter = require 'nvim.plugins.treesitter'

treesitter.setup 'vscode'
assert(
  captured.register and captured.register.lang == 'markdown' and captured.register.filetype == 'markdown.mdx',
  'vscode must register markdown for markdown.mdx'
)
assert(#captured.install_calls >= 1 and vim.deep_equal(captured.install_calls[1], expected_grammars), 'vscode must install the grammar set')
assert(captured.autotag_setup == nil, 'vscode must not setup nvim-ts-autotag')

local vscode_html_buf = vim.api.nvim_create_buf(false, true)
vim.bo[vscode_html_buf].filetype = 'html'
local vscode_html_start = find_start(vscode_html_buf)
assert(vscode_html_start == nil, 'vscode must not start treesitter highlight')

-- Restore stubs.
vim.treesitter.language = original_lang
vim.treesitter.start = original_start

if #errors > 0 then
  print 'TREESITTER CORE-FIRST CONTRACT FAILURES:'
  for _, err in ipairs(errors) do
    print('  FAIL: ' .. err)
  end
  vim.cmd 'cq'
else
  print 'Treesitter core-first contract check passes.'
  vim.cmd 'q'
end
-- vim: ts=2 sts=2 sw=2 et
