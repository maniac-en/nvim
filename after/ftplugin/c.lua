-- after/ftplugin/c.lua
vim.cmd("compiler gcc") -- errorformat for gcc/make output; it sets no makeprg
vim.opt_local.makeprg = "gcc -Wall -Wextra -o %:r %"
require("config.runner").setup("gcc -o out % && ./out && rm out")
