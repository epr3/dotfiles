-- Core-first Treesitter configuration.
--
-- Neovim 0.12 provides treesitter highlighting via vim.treesitter.start() and
-- parser registration via vim.treesitter.language. This module keeps the
-- nvim-treesitter plugin only as an adapter for parser installation and
-- indentation, which are not provided by core. Autotag is handled by the
-- dedicated nvim-ts-autotag adapter because core has no tag auto-rename/close
-- feature.

local M = {}

--- Parsers to keep installed for both profiles.
M.grammars = {
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

--- Filetypes where legacy regex highlighting should run alongside treesitter.
M.regex_highlight_filetypes = { ruby = true, markdown = true }

--- Filetypes where treesitter indentation must stay disabled.
M.no_indent_filetypes = { ruby = true }

---@param lang string
---@return boolean
local function is_supported(lang)
  local ok, parsers = pcall(require, 'nvim-treesitter.parsers')
  return ok and parsers[lang] ~= nil
end

--- Install a parser if nvim-treesitter supports it. This replicates the legacy
--- auto_install behavior on buffer enter.
---@param lang string
local function maybe_install(lang)
  if is_supported(lang) then
    require('nvim-treesitter').install { lang }
  end
end

---@param buf integer
local function enable_highlight(buf)
  local ft = vim.bo[buf].filetype
  if ft == '' then
    return
  end

  local ok, lang = pcall(vim.treesitter.language.get_lang, ft)
  if not ok or not lang then
    return
  end

  maybe_install(lang)

  if not vim.treesitter.language.add(lang) then
    return
  end

  vim.treesitter.start(buf, lang)

  if M.regex_highlight_filetypes[ft] then
    vim.bo[buf].syntax = 'ON'
  end
end

---@param buf integer
local function enable_indent(buf)
  local ft = vim.bo[buf].filetype
  if ft == '' or M.no_indent_filetypes[ft] then
    return
  end

  local ok, lang = pcall(vim.treesitter.language.get_lang, ft)
  if not ok or not lang then
    return
  end

  if not vim.treesitter.language.add(lang) then
    return
  end

  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

--- Configure treesitter for the given profile.
---@param profile 'standalone'|'vscode'
function M.setup(profile)
  -- davidmh/mdx.nvim sets the mdx filetype to markdown.mdx; register the
  -- markdown parser so core highlighting and indentation apply. The jsonc
  -- filetype is handled by the json parser on the supported nvim-treesitter
  -- main branch.
  vim.treesitter.language.register('markdown', 'markdown.mdx')
  vim.treesitter.language.register('json', 'jsonc')

  -- Ensure the declared grammar set is installed asynchronously.
  require('nvim-treesitter').install(M.grammars)

  if profile == 'standalone' then
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(ev)
        enable_highlight(ev.buf)
      end,
    })

    vim.api.nvim_create_autocmd('FileType', {
      callback = function(ev)
        enable_indent(ev.buf)
      end,
    })

    require('nvim-ts-autotag').setup {}
  elseif profile == 'vscode' then
    -- VS Code owns highlighting. Keep parsers available for parsing/context
    -- behavior but do not start Neovim treesitter highlight.
  else
    error('Unknown treesitter profile: ' .. tostring(profile))
  end
end

return M
-- vim: ts=2 sts=2 sw=2 et
