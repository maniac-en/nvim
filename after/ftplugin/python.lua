-- after/ftplugin/python.lua
vim.opt_local.formatoptions = "jcroql"
-- ruff colors its output even through a pipe, and the compiler's default
-- --preview adds rules the ruff LSP doesn't apply
vim.b.ruff_makeprg_params = "--color=never"
vim.cmd("compiler ruff") -- :make checks the project with ruff
require("config.runner").setup("python3 %")
