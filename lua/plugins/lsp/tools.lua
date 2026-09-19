-- lua/plugins/lsp/tools.lua
-- The language servers the config enables, and the Mason packages it expects.
-- Used by lua/plugins/lsp/init.lua and the smoke test.
local M = {}

M.servers = {
  -- Go
  "gopls",
  -- Python
  "basedpyright",
  "ruff",
  -- Lua
  "lua_ls",
  -- Shell
  "bashls",
  -- C/C++
  "clangd",
  -- JSON
  "jsonls",
  -- Web
  "html",
  "cssls",
  "tailwindcss",
  "ts_ls",
}

-- Everything the config expects from Mason (package names as in :Mason). Missing
-- ones install in the background when Mason loads; updates stay manual (:Mason).
-- tests/specs/startup.lua checks each server above has its package here.
M.mason = {
  -- Go: language server, linter, debugger
  "gopls", "golangci-lint", "delve",
  -- Python: language server, lint + format, debugger
  "basedpyright", "ruff", "debugpy",
  -- Lua, shell, C
  "lua-language-server", "bash-language-server", "clangd",
  -- Web: JSON, HTML, CSS, Tailwind, JS/TS (+ JS/TS linter)
  "json-lsp", "html-lsp", "css-lsp", "tailwindcss-language-server", "typescript-language-server", "quick-lint-js",
  -- nvim-treesitter (main) builds parsers with it
  "tree-sitter-cli",
}

return M
