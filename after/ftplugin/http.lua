-- after/ftplugin/http.lua
require("config.map").set("n", "<leader>r", "<cmd>Rest run<CR>", "HTTP", "[R]un request under cursor",
  { buffer = true, silent = true })
