-- lua/config/runner.lua
-- Buffer-local :Run (and <leader>r) for filetypes that have a run command;
-- used by the after/ftplugin files. The command runs in a terminal split, so
-- program output, colors and prompts work as they would in a shell.

local M = {}

-- `command` is a shell command; % and friends are expanded as usual (:h cmdline-special)
function M.setup(command)
  vim.api.nvim_buf_create_user_command(0, "Run", function()
    vim.cmd("write")
    vim.cmd("vsplit term://" .. command)
    vim.cmd("startinsert")
  end, { desc = "Run the current file (" .. command .. ")" })

  require("config.map").set("n", "<leader>r", "<cmd>Run<CR>", "Run", "[R]un current file",
    { buffer = true, silent = true })
end

return M
