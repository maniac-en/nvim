-- after/ftplugin/go.lua
local map = require("config.map").set

vim.opt_local.formatoptions = "jcroql"
vim.cmd("compiler go") -- :make builds the module, errors go to the quickfix list
require("config.runner").setup("go run %")

-- The <leader>tt choices. The label is also what the picker filters on, so
-- "normal", "verbose" and "go test" all narrow it down.
local test_modes = {
  { label = "normal", flags = "" },
  { label = "verbose", flags = "-v " },
}

-- Runs the package in `dir`: a list of files would skip the tests of an
-- external test package (package foo_test)
local function test_package(dir, flags)
  vim.cmd("write")
  vim.cmd("vsplit term://cd " .. vim.fn.shellescape(dir) .. " && go test " .. flags .. ".")
  vim.cmd("startinsert")
end

map("n", "<leader>tt", function()
  local dir = vim.fn.expand("%:p:h") -- while this buffer is still the current one
  vim.ui.select(test_modes, {
    prompt = "Test the package with",
    format_item = function(mode) return ("%-7s go test %s."):format(mode.label, mode.flags) end,
  }, function(mode)
    if mode then test_package(dir, mode.flags) end
  end)
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
