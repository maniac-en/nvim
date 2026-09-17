-- after/ftplugin/typescript.lua
vim.opt_local.formatoptions = "jcroql"
require("config.runner").setup("ts-node %")
