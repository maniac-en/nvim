-- after/ftplugin/c.lua
vim.cmd("compiler gcc") -- errorformat for gcc/make output; it sets no makeprg
vim.opt_local.makeprg = "gcc -Wall -Wextra -o %:r %"

-- :Run builds into a temporary file (Neovim removes it on exit), then runs it,
-- so nothing is left in, or overwritten in, the current folder
local bin = vim.fn.shellescape(vim.fn.tempname())
require("config.runner").setup("gcc -Wall -Wextra -o " .. bin .. " % && " .. bin)
