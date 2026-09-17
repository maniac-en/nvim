-- lua/plugins/squeel.lua
local key = require("config.map").lazy

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    dependencies = {
      {
        "tpope/vim-dadbod",
        lazy = true,
      },
      {
        "kristijanhusak/vim-dadbod-completion",
        ft = { "sql", "mysql", "plsql" },
        lazy = true,
      },
    },
    keys = {
      key("<leader>D", "<cmd>DBUIToggle<cr>", "DB", "toggle [D]atabase UI"),
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
    config = function()
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_force_echo_notifications = 1
      vim.g.db_ui_win_position = "left"
      vim.g.db_ui_winwidth = 40
      -- SQL completion comes from blink.cmp (lua/plugins/completion.lua)
    end,
  },
}
