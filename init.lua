vim.g.mapleader = "\\"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

-- Load core configuration first
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.user_commands")

-- Add lazy to the `runtimepath`, this allows us to `require` it.
---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- Setup plugin manager
require("lazy").setup("plugins", {
  -- Lazy options here
  change_detection = {
    notify = false,
  },
})
