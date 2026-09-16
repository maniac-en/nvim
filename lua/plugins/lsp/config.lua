-- lua/plugins/lsp/config.lua

-- diagnostics config
vim.diagnostic.config({
  virtual_text = {
    format = function(diagnostic)
      local message = diagnostic.message
      -- Truncate long messages (by characters, so multi-byte text isn't cut mid-character)
      if vim.fn.strchars(message) > 60 then
        message = vim.fn.strcharpart(message, 0, 60) .. "..."
      end
      if diagnostic.severity == vim.diagnostic.severity.ERROR then
        message = "E: " .. message
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
    source = false, -- the prefix above already names the source
    -- border comes from 'winborder' (lua/config/options.lua)
  },
})
