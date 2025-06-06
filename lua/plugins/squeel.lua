-- lua/plugins/squeel.lua
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
      { "<leader>db", "<cmd>DBUIToggle<cr>", desc = "Toggle DB UI" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
    config = function()
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_force_echo_notifications = 1
      vim.g.db_ui_win_position = "left"
      vim.g.db_ui_winwidth = 40

      -- Set up SQL file type completion
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          require("cmp").setup.buffer({
            sources = {
              { name = "vim-dadbod-completion", priority = 1000 },
              { name = "buffer",                priority = 500 },
            },
          })
        end,
      })
    end,
  },
}
