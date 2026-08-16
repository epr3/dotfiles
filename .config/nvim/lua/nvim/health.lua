--
-- This file is not required for your own configuration,
-- but helps people determine if their system is setup correctly.
--
--

local check_version = function()
  local verstr = string.format('%s.%s.%s', vim.version().major, vim.version().minor, vim.version().patch)
  if not vim.version.cmp then
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
    return
  end

  if vim.version.cmp(vim.version(), { 0, 12, 0 }) >= 0 then
    vim.health.ok(string.format("Neovim version is: '%s'", verstr))
  else
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
  end
end

local check_external_reqs = function()
  -- Basic utils: `git`, `make`, `unzip`
  for _, exe in ipairs { 'git', 'make', 'unzip', 'rg' } do
    local is_executable = vim.fn.executable(exe) == 1
    if is_executable then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s'", exe))
    end
  end

  return true
end

-- Reports the deferred optional Vue/TypeScript adapter declared by ts_ls.
-- The adapter only activates when the optional tooling is installed; a missing
-- package must not break TypeScript, so this makes it visible with a concrete
-- repair command instead.
local function check_optional_vue_adapter()
  local ok, declaration = pcall(require, 'nvim.servers.ts_ls')
  if not ok or type(declaration) ~= 'table' or type(declaration.optional) ~= 'table' then
    return
  end
  for _, adapter in ipairs(declaration.optional) do
    local package = adapter.package
    if type(package) ~= 'string' then
      goto continue
    end
    local registry_ok, mason_registry = pcall(require, 'mason-registry')
    if not registry_ok then
      vim.health.warn(string.format("Optional Vue/TypeScript integration: status unknown ('%s' cannot be checked)", package))
    elseif mason_registry.is_installed(package) then
      vim.health.ok(string.format("Optional Vue/TypeScript integration active (uses installed '%s')", package))
    else
      vim.health.warn(string.format(
        [[
Optional Vue/TypeScript integration inactive: '%s' is not installed.
  TypeScript editing still works; the Vue adapter is skipped. To restore it:
  Repair: run `:MasonInstall %s`]],
        package,
        package
      ))
    end
    ::continue::
  end
end

return {
  check = function()
    vim.health.start 'nvim'

    vim.health.info [[NOTE: Not every warning is a 'must-fix' in `:checkhealth`

  Fix only warnings for plugins and languages you intend to use.
    Mason will give warnings for languages that are not installed.
    You do not need to install, unless you want to use those languages!]]

    local uv = vim.uv or vim.loop
    vim.health.info('System Information: ' .. vim.inspect(uv.os_uname()))

    check_version()
    check_external_reqs()
    check_optional_vue_adapter()
  end,
}
