-- lua/plugins/lsp/servers/python.lua

local M = {}

function M.setup()
  local lspconfig = require("lspconfig")
  lspconfig.pyright.setup({
    handlers = {
    },
    settings = {
      pyright = {
        disableOrganizeImports = false,
      },
      python = {
        analysis = {
          ignore = { "*" },
          logLevel = "Information",
          autoImportCompletions = true,
          autoSearchPaths = true,
          diagnosticMode = "off",
          typeCheckingMode = "on",
          useLibraryCodeForTypes = true,
        },
      },
    },
  })
  lspconfig.ruff.setup({
    on_attach = function(client, _)
      if client.name == "ruff_lsp" then
        -- Disable hover in favor of Pyright
        client.server_capabilities.hoverProvider = false
      end
    end,
    init_options = {
      settings = {
        args = {
          "--select=F6,F7,F8",
        },
      },
    },
  })
end

M.setup()
return M
