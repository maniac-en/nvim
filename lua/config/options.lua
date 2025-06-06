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
o.laststatus = 0 -- Hide statusline, using winbar instead

-- Custom winbar with conditional display
local function get_tailored_winbar()
  -- Don't show for certain file types
  local excluded_filetypes = {
    "help",
    "NvimTree",
    "TelescopePrompt",
    "qf",
    "fugitive",
    "lazy",
    "mason",
    "oil",
  }

  local buf_ft = vim.bo.filetype
  for _, ft in ipairs(excluded_filetypes) do
    if ft == buf_ft then
      return "" -- No winbar for excluded filetypes
    end
  end

  -- return "%=%m %y %F (%l/%L:%v) (%b 0x%B)%="
  return "%=%m %y %F (%l/%L:%v)%="
end
o.winbar = get_tailored_winbar()

-- Window management
opt.splitbelow = true -- Open horizontal splits below
opt.splitright = true -- Open vertical splits to the right

-- Appearance
opt.cursorline = true                    -- Highlight the current line
opt.colorcolumn = "80"                   -- Show column guide
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
