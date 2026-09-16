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

-- disable line numbers in terminal
autocmd("TermOpen", {
  group = maniac_aug,
  pattern = "*",
  callback = function()
    vim.o.number = false
    vim.o.relativenumber = false
    vim.o.spell = false
  end,
})

-- file-type buffer-specific format options

-- Auto-format paragraphs
autocmd("FileType", {
  group = maniac_aug,
  pattern = { "text" },
  callback = function()
    vim.opt_local.formatoptions = vim.opt_local.formatoptions + "a"
  end,
})

-- Preferred format options for coding
autocmd("FileType", {
  group = maniac_aug,
  pattern = { "sh", "go", "lua", "python", "javascript" },
  callback = function()
    vim.opt_local.formatoptions = "jcroql"
  end,
})

-- In toggleterm buffers, turn write commands (:w, :wq, ...) into a quit
-- https://github.com/akinsho/toggleterm.nvim/issues/155
autocmd("FileType", {
  group = maniac_aug,
  pattern = "toggleterm",
  callback = function(args)
    autocmd({ "BufWriteCmd", "FileWriteCmd", "FileAppendCmd" }, {
      group = maniac_aug,
      buffer = args.buf,
      command = "q!",
    })
  end,
})
