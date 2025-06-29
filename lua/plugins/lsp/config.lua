-- lua/plugins/lsp/config.lua

-- LSP and diagnostics configuration
local M = {}

function M.setup()
  -- diagnostics config
  vim.diagnostic.config({
    virtual_text = {
      format = function(diagnostic)
        if diagnostic.severity == vim.diagnostic.severity.ERROR then
          return string.format("E: %s", diagnostic.message)
        end
        return diagnostic.message
      end,
    },
    virtual_lines = false,
    underline = false,
    severity_sort = true,
    update_in_insert = false,
    float = {
      show_header = true,
      header = "",
      prefix = function(diagnostic)
        return diagnostic.source .. "> "
      end,
      scope = "line",
      source = "if_many",
      border = "rounded",
      focusable = true,
    },
  })

  local lsp_hover_opts = {
    max_width = 100,
    max_height = 14,
    border = 'rounded',
  }

  local hover = vim.lsp.buf.hover
  ---@diagnostic disable: duplicate-set-field
  vim.lsp.buf.hover = function()
    ---@diagnostic disable-next-line: redundant-parameter
    return hover(lsp_hover_opts)
  end

  -- @@@(self): don't really need this because signature_help completion pretty much
  -- covers this!!!
  local signature_help = vim.lsp.buf.signature_help
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf.signature_help = function()
    ---@diagnostic disable-next-line: redundant-parameter
    return signature_help(lsp_hover_opts)
  end
end

M.setup() -- auto-execute on require
return M
