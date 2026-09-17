-- init.lua
vim.g.mapleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- Load core configuration first
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.user_commands")
require("config.abbreviations")
require("config.line_completion")

-- Add lazy to the `runtimepath`, this allows us to `require` it.
vim.opt.rtp:prepend(lazypath)

-- Setup plugin manager; imports every lua/plugins/*.lua (and lua/plugins/*/init.lua)
require("lazy").setup("plugins", {
  change_detection = {
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "netrwPlugin", -- oil.nvim is the file explorer
        "tarPlugin",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
