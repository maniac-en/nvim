-- after/ftplugin/lua.lua
vim.opt_local.formatoptions = "jcroql"
require("config.runner").setup("lua %")
