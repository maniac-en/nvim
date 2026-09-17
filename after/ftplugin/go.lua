-- after/ftplugin/go.lua
local map = require("config.map").set

vim.opt_local.formatoptions = "jcroql"
vim.cmd("compiler go") -- :make builds the module, errors go to the quickfix list
require("config.runner").setup("go run %")

map("n", "<leader>tt", function()
  vim.cmd("write")
  vim.cmd("vsplit term://go test -v %:p:h/*.go")
  vim.cmd("startinsert")
end, "Test", "[T]est package", { buffer = true, silent = true })

map("n", "<leader>tm", function()
  vim.cmd("write")
  local main_go_file = vim.fn.input("Main GO file > ")
  if main_go_file == "" then
    main_go_file = "dummy_main.go"
  elseif not main_go_file:match("%.go$") then
    main_go_file = main_go_file .. ".go"
  end
  vim.cmd(("vsplit term://go test -v %%:h/%s %%"):format(main_go_file))
  vim.cmd("startinsert")
end, "Test", "[T]est with a [M]ain file", { buffer = true, silent = true })
