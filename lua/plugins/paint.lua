-- lua/plugins/paint.lua
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      local colors = require("catppuccin.palettes").get_palette("macchiato")
      require("catppuccin").setup({
        flavour = "macchiato",
        styles = {
          strings = { "italic" },
          comments = { "italic" },
          functions = { "bold" },
        },
        custom_highlights = {
          -- using winbar as my statusline, hide statusline for horizontal splits
          StatusLine = { bg = colors.base, fg = colors.base },
          StatusLineNC = { bg = colors.base, fg = colors.base },
        },
        -- Integration with new plugins
        integrations = {
          treesitter = true,
          cmp = true,
          mason = true,
          dadbod_ui = true,
          gitsigns = {
            enabled = true,
            -- Set to true if you're using transparent background
            transparent = false,
          },
          telescope = {
            enabled = true,
            -- Enable style for telescope prompt
            -- style = "nvchad",
          },
          native_lsp = {
            enabled = true,
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
        },
      })
      -- Set colorscheme
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
