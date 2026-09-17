-- lua/plugins/paint.lua

-- Transparent editor background and floating windows (let the terminal show through)
local transparent = false
-- Solid floating windows: borders blend into the float background, colored title
-- bars (telescope: red prompt, lavender results, green preview)
local solid_floats = false

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        transparent_background = transparent,
        float = {
          transparent = transparent,
          solid = solid_floats,
        },
        flavour = "macchiato",
        styles = {
          strings = { "italic" },
          comments = { "italic" },
          functions = { "bold" },
        },
        -- `colors` is the flavour's palette (plus `none`)
        custom_highlights = function(colors)
          return {
            -- using winbar as my statusline, hide statusline for horizontal splits
            -- (the separator row between stacked windows is still drawn with it)
            StatusLine = { bg = transparent and colors.none or colors.base, fg = colors.base },
            StatusLineNC = { bg = transparent and colors.none or colors.base, fg = colors.base },
            -- winbar is my statusline: same colors as the editor, bold
            WinBar = { fg = colors.text, bg = transparent and colors.none or colors.base, style = { "bold" } },
            WinBarNC = { fg = colors.text, bg = transparent and colors.none or colors.base, style = { "bold" } },
          }
        end,
        -- Styles for LSP diagnostics virtual text, underlines and inlay hints
        lsp_styles = {
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
            ok = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
            ok = { "underline" },
          },
          inlay_hints = {
            background = true,
          },
        },
        -- Integration with new plugins
        integrations = {
          treesitter = true,
          blink_cmp = true,
          mason = true,
          dadbod_ui = true,
          gitsigns = {
            enabled = true,
            -- hunk previews: colored text without diff backgrounds (independent of `transparent`)
            transparent = true,
          },
          telescope = {
            enabled = true,
          },
        },
      })
      -- Set colorscheme
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
