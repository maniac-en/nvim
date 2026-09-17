-- lua/config/autocmds.lua
local augroup = vim.api.nvim_create_augroup
local maniac_aug = augroup("maniac_aug", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- highlight the yanked text post yanking
autocmd("TextYankPost", {
  group = maniac_aug,
  pattern = "*",
  callback = function()
    vim.hl.on_yank({
      higroup = "IncSearch",
      timeout = 40,
    })
  end,
})

-- clear out trailing spaces on buffer write (without moving the cursor or
-- clobbering the last search pattern), except:
-- - filetypes where trailing spaces mean something (markdown: two = hard line break)
-- - when the project's .editorconfig sets trim_trailing_whitespace (true or
--   false): Neovim's built-in EditorConfig support decides
local keep_trailing_whitespace = { markdown = true }
autocmd("BufWritePre", {
  group = maniac_aug,
  pattern = "*",
  callback = function(args)
    if keep_trailing_whitespace[vim.bo[args.buf].filetype] then return end
    local editorconfig = vim.b[args.buf].editorconfig
    if type(editorconfig) == "table" and editorconfig.trim_trailing_whitespace ~= nil then return end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- disable line numbers and spell in terminal windows (window-local, so other
-- windows keep them)
autocmd("TermOpen", {
  group = maniac_aug,
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.spell = false
  end,
})
