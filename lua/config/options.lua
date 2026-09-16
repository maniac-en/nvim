-- lua/config/options.lua
-- Core Neovim options organized by category for better maintainability

-- Use shorthand variables for conciseness
local opt = vim.opt
local o = vim.o
local fn = vim.fn
local api = vim.api
local HOME = fn.expand("$HOME")

------------------
-- Editor Basics --
------------------

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.ruler = false -- Disable cursor position (using winbar instead)

-- Indentation (defaults; vim-sleuth adapts them to each file, .editorconfig overrides)
opt.tabstop = 4        -- Width of a tab character
opt.softtabstop = 4    -- Spaces per <Tab>/<BS> while editing
opt.shiftwidth = 4     -- Spaces per indent level (>>, <<, auto-indent)
opt.expandtab = true   -- Indent with spaces
opt.breakindent = true -- Enable break indent

-- Searching
opt.hlsearch = false  -- Don't highlight all search matches
opt.incsearch = true  -- Incremental search
opt.ignorecase = true -- Case-insensitive searching UNLESS...
opt.smartcase = true  -- ...a capital letter is used

-- Mouse and clipboard
opt.mouse = "a" -- Enable mouse mode
-- system clipboard stays explicit: visual <C-y> copies to it, "+p pastes (lua/config/keymaps.lua)

-- File handling
opt.directory = fn.stdpath("state") .. "/swap//"   -- Swap files (~/.local/state/nvim/swap); // names them by full path
opt.undofile = true                                 -- Save undo history
opt.undodir = fn.stdpath("state") .. "/undo//"      -- Undo files (~/.local/state/nvim/undo)
opt.undolevels = 10000                              -- Maximum number of changes that can be undone

----------------
-- UI Settings --
----------------

-- Status display
vim.o.laststatus = 0 -- Hide statusline, using winbar instead

-- Custom winbar
-- o.winbar = "%=%m %y %F (%l/%L:%v) (%b 0x%B)%="
o.winbar = "%=%m %y %F (%l/%L:%v)%="

-- Window management
opt.splitbelow = true -- Open horizontal splits below
opt.splitright = true -- Open vertical splits to the right

-- Appearance
opt.cursorline = true                    -- Highlight the current line
opt.signcolumn = "yes"                   -- Always show sign column
opt.termguicolors = true                 -- True color support
opt.display = "lastline,uhex"            -- Show as much as possible of last line
opt.listchars = "tab:»·,space:.,trail:·" -- Show special characters
opt.winborder = "rounded"                -- Default border for floating windows (hover, signature, etc.)

-- Scrolling and motion
opt.scrolloff = 8      -- Keep 8 lines above/below cursor
opt.sidescroll = 8     -- Horizontal scrolloff
opt.sidescrolloff = 8  -- Keep 8 columns left/right of cursor
opt.startofline = true -- Move cursor to 1st non-blank while navigation

-- Colors and highlighting
-- Make winbar more visible; runs whenever a colorscheme is (re)applied
api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    local normal_bg = api.nvim_get_hl(0, { name = "Normal" }).bg or 0
    local normal_fg = api.nvim_get_hl(0, { name = "Normal" }).fg or 0xFFFFFF
    api.nvim_set_hl(0, "WinBar", { fg = normal_fg, bg = normal_bg, bold = true })
  end,
})

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
opt.foldmethod = "manual" -- Manual folding (zf to create)
opt.foldcolumn = "0"      -- Don't show fold column
opt.foldtext = ""         -- No custom fold text
opt.foldlevel = 99        -- Folds open by default
opt.foldlevelstart = 99   -- Every buffer starts unfolded

------------------
-- Performance --
------------------

-- Responsiveness
opt.updatetime = 150 -- Faster completion and swap file writes
opt.timeoutlen = 300 -- Time to wait for mapped sequences
opt.report = 0       -- Always report changed lines

-- Autocomplete
opt.completeopt = "menuone,noselect" -- Better completion experience
opt.shortmess:append("c")           -- No "match 1 of 2" style ins-completion messages

-- Preview
opt.inccommand = "split" -- Show preview for substitutions
