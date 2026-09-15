-- lua/plugins/lsp/config.lua

-- diagnostics config
vim.diagnostic.config({
  virtual_text = {
    format = function(diagnostic)
      local message = diagnostic.message
      -- Truncate long messages for performance
      if #message > 60 then
        return message:sub(1, 60) .. "..."
      end
      if diagnostic.severity == vim.diagnostic.severity.ERROR then
        return "E: " .. message
      end
      return message
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
      return (diagnostic.source or "?") .. "> "
    end,
    scope = "line",
    source = "if_many",
    -- border comes from 'winborder' (lua/config/options.lua)
  },
})
