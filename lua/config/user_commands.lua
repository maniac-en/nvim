-- lua/config/user_commands.lua
-- :Browse <url> opens a URL in the browser (fugitive's :GBrowse uses it)
vim.api.nvim_create_user_command("Browse", function(opts)
  local _, err = vim.ui.open(opts.fargs[1])
  if err then vim.notify(err, vim.log.levels.ERROR) end
end, { nargs = 1, desc = "Open a URL in the browser" })

-- https://www.reddit.com/r/neovim/comments/zhweuc/comment/izo9br1/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
vim.api.nvim_create_user_command("Redir", function(ctx)
  local lines = vim.split(vim.api.nvim_exec2(ctx.args, { output = true })["output"], "\n", { plain = true })
  vim.cmd("new")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.opt_local.modified = false
end, { nargs = "+", complete = "command" })
