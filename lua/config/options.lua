-- lua/config/options.lua
-- Core Neovim options organized by category for better maintainability

-- Use shorthand variables for conciseness
local opt = vim.opt
local o = vim.o
local wo = vim.wo
local g = vim.g
local fn = vim.fn
local api = vim.api
local HOME = fn.expand("$HOME")

------------------
-- Editor Basics --
------------------

-- Line numbers
opt.number = false
opt.relativenumber = true
opt.ruler = false -- Disable cursor position (using winbar instead)

-- Indentation (Use vim-sleuth)
opt.breakindent = true -- Enable break indent

-- Searching
opt.hlsearch = false  -- Don't highlight all search matches
opt.incsearch = true  -- Incremental search
opt.ignorecase = true -- Case-insensitive searching UNLESS...
opt.smartcase = true  -- ...a capital letter is used

-- Mouse and clipboard
opt.mouse = "a" -- Enable mouse mode
-- opt.clipboard = "unnamedplus"  -- Uncomment to sync clipboard with system

-- File handling
opt.directory = HOME .. "/.cache/nvim"    -- Swap file directory
opt.undofile = true                       -- Save undo history
opt.undodir = HOME .. "/.cache/nvim/undo" -- Undo file directory
opt.encoding = "utf-8"                    -- File encoding
-- opt.fileencodings = "utf-8,iso-2022-jp,sjis,euc-jp" -- Fallback file encodings

----------------
-- UI Settings --
----------------

-- Status display
vim.o.laststatus = 0 -- Hide statusline, using winbar instead

-- -- Custom winbar
-- -- o.winbar = "%=%m %y %F (%l/%L:%v) (%b 0x%B)%="
-- o.winbar = "%=%m %y %F (%l/%L:%v)%="

-- Custom winbar function for better control
local function get_winbar()
  local parts = {}

  -- Modified flag
  if vim.bo.modified then
    table.insert(parts, '[+]')
  elseif vim.bo.readonly then
    table.insert(parts, '[RO]')
  end

  -- File type (only if not empty)
  if vim.bo.filetype ~= '' then
    table.insert(parts, '[' .. vim.bo.filetype .. ']')
  end

  -- Relative file path (more useful than full path, less cluttered than just filename)
  local filepath = vim.fn.expand('%:~:.')
  if filepath == '' then
    filepath = '[No Name]'
  end
  table.insert(parts, filepath)

  -- Line/column info
  table.insert(parts, '(' .. vim.fn.line('.') .. '/' .. vim.fn.line('$') .. ':' .. vim.fn.col('.') .. ')')

  return '%=' .. table.concat(parts, ' ') .. '%='
end
-- Set winbar using the custom function
vim.o.winbar = '%!v:lua.get_winbar()'

-- Make the function globally accessible
_G.get_winbar = get_winbar

-- Window management
opt.splitbelow = true -- Open horizontal splits below
opt.splitright = true -- Open vertical splits to the right

-- Appearance
opt.cursorline = true                    -- Highlight the current line
-- opt.colorcolumn = "80"                   -- Show column guide
opt.signcolumn = "yes"                   -- Always show sign column
opt.termguicolors = true                 -- True color support
opt.display = "lastline,uhex"            -- Show as much as possible of last line
opt.listchars = "tab:»·,space:.,trail:·" -- Show special characters

-- Scrolling and motion
opt.scrolloff = 8      -- Keep 8 lines above/below cursor
opt.sidescroll = 8     -- Horizontal scrolloff
opt.sidescrolloff = 8  -- Keep 8 columns left/right of cursor
opt.startofline = true -- Move cursor to 1st non-blank while navigation

-- Colors and highlighting
api.nvim_set_var("t_co", 256)          -- Terminal colors support
api.nvim_set_var("background", "dark") -- Dark background
api.nvim_set_var("syntax", "on")       -- Enable syntax highlighting

-- Create highlight groups for winbar components
api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    -- Make winbar more visible
    local normal_bg = api.nvim_get_hl(0, { name = "Normal" }).bg or 0
    local normal_fg = api.nvim_get_hl(0, { name = "Normal" }).fg or 0xFFFFFF
    api.nvim_set_hl(0, "WinBar", { fg = normal_fg, bg = normal_bg, bold = true })
  end,
})
vim.cmd("doautocmd ColorScheme") -- Apply the highlights on startup

------------------
-- Text Handling --
------------------

-- Text wrapping and formatting
opt.linebreak = true               -- Avoid wrapping in the middle of words
opt.textwidth = 80                 -- Text width
opt.wrap = true                    -- Wrap lines
opt.formatoptions = "jcroqlnt"     -- Text formatting options
opt.backspace = "indent,eol,start" -- Backspace behavior

-- Spelling
opt.spelllang = "en"                                       -- Spellcheck language
opt.spellfile = HOME .. "/.config/nvim/spell/en.utf-8.add" -- Custom spell file
opt.spell = true                                           -- Enable spellcheck
opt.spellcapcheck = ""                                     -- Disable first word capitalization spellchecks

-- Folding
opt.foldmethod = "manual"                        -- Manual folding
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- Use treesitter for folds
opt.foldcolumn = "0"                             -- Don't show fold column
opt.foldtext = ""                                -- No custom fold text
opt.foldlevel = 99                               -- Start unfolded by default
opt.foldlevelstart = 1                           -- Start with some folds
opt.foldnestmax = 4                              -- Maximum nesting of folds

------------------
-- Performance --
------------------

-- Responsiveness
opt.updatetime = 150 -- Faster completion and swap file writes
opt.timeoutlen = 300 -- Time to wait for mapped sequences
opt.report = 0       -- Always report changed lines

-- Autocomplete
opt.completeopt = "menuone,noselect" -- Better completion experience

-- Preview
opt.inccommand = "split" -- Show preview for substitutions

-- Script encoding
api.nvim_set_var("scriptencoding", "utf-8")
