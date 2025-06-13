-- lua/plugins/lsp/servers/golang.lua

local M = {}

function M.setup()
  local lspconfig = require("lspconfig")
  lspconfig.gopls.setup({
    settings = {
      gopls = {
        gofumpt = true,
        codelenses = {
          gc_details = false,
          generate = true,
          regenerate_cgo = true,
          run_govulncheck = true,
          test = true,
          tidy = true,
          upgrade_dependency = true,
          vendor = true,
        },
        hints = {
          assignVariableTypes = false,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        analyses = {
          nilness = true,
          unusedparams = true,
          unusedwrite = true,
          useany = true,
        },
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck = true,
        directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
        semanticTokens = true,
      },
    },
    -- settings = {
    --   gopls = {
    --     analyses = {
    --       unusedparams = true,
    --       shadow = true,
    --     },
    --     staticcheck = true,
    --     usePlaceholders = true,
    --     completeUnimported = true,
    --     experimentalPostfixCompletions = true,
    --   },
    -- }
  })
end

M.setup()
return M
