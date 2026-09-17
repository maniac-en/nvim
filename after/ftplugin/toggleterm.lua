-- after/ftplugin/toggleterm.lua
-- Turn write commands (:w, :wq, ...) into a quit, so muscle memory doesn't error
-- https://github.com/akinsho/toggleterm.nvim/issues/155
vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd", "FileAppendCmd" }, {
  group = vim.api.nvim_create_augroup("maniac_toggleterm_write", { clear = false }),
  buffer = 0,
  command = "q!",
})
