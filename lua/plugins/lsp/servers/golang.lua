-- lua/plugins/lsp/servers/golang.lua

local M = {}

function M.setup()
  local lspconfig = require("lspconfig")
  lspconfig.gopls.setup({
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
        usePlaceholders = true,
        completeUnimported = true,
        experimentalPostfixCompletions = true,
      },
    }
  })
  lspconfig.golangci_lint_ls.setup {}
end

M.setup()
return M
