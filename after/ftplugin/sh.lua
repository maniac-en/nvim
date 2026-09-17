-- after/ftplugin/sh.lua
vim.opt_local.formatoptions = "jcroql"
vim.cmd("compiler bash")            -- errorformat for bash -n
vim.opt_local.makeprg = "bash -n %" -- the compiler's makeprg has no file, so it would read stdin
