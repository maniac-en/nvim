-- lua/config/keymaps.lua
local map = require("config.map").set

-- Disabled on purpose
map("x", "<Space>", "<Nop>", "Disabled", "<Space> in visual mode (leader)", { silent = true })
for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
  map("n", key, "<Nop>", "Disabled", "arrow keys (use hjkl)", { silent = true })
end
map("n", "Q", "<Nop>", "Disabled", "Q", { silent = true })

-- Jumps, search and scrolling keep the cursor centered
map("n", "<C-o>", "<C-o>zz", "Jump", "older jumplist position, centered")
map("n", "<Tab>", "<Tab>zz", "Jump", "newer jumplist position, centered")
map("n", "n", "nzzzv", "Search", "next match, centered")
map("n", "N", "Nzzzv", "Search", "previous match, centered")
map("n", "<C-d>", "<C-d>zz", "Motion", "half page down, cursor centered")
map("n", "<C-u>", "<C-u>zz", "Motion", "half page up, cursor centered")

-- Windows and tabs (these type the command and wait for a file name)
map("n", "ts", ":split<Space>", "Window", "[S]plit horizontally (type a file)")
map("n", "tv", ":vsplit<Space>", "Window", "[V]ertical split (type a file)")
map("n", "tn", ":tabe<Space>", "Tab", "[N]ew tab (type a file)")
map("n", "tc", vim.cmd.tabclose, "Tab", "[C]lose tab", { silent = true })

map("t", "<Esc>", "<C-\\><C-n>", "Terminal", "[Esc]ape to normal mode")

map("n", "<leader>ev", function() vim.cmd.tabedit(vim.fn.stdpath("config")) end, "Config",
  "[E]dit neo[V]im config in a new tab", { silent = true })
map("n", "<leader>cd", ":cd %:p:h<CR>:pwd<CR>", "Dir", "[C]hange [D]irectory to current file's folder")

-- Editing
map("n", "J", "mzJ`z", "Edit", "[J]oin lines, keep cursor in place")
map("x", "<leader>p", '"_dP', "Edit", "[P]aste over selection, keep register")
map("x", "<leader>s", ":sort u<CR>", "Edit", "[S]ort selection (unique)", { silent = true })
map("x", "J", ":m '>+1<CR>gv=gv", "Edit", "move selection down (re-indented)")
map("x", "K", ":m '<-2<CR>gv=gv", "Edit", "move selection up (re-indented)")
map("x", "<C-y>", '"+y', "Clipboard", "[Y]ank selection to system clipboard", { silent = true })

-- Wrapped lines: move by display line, unless a count is given
map({ "n", "x" }, "j", 'v:count == 0 ? "gj" : "j"', "Motion", "down by display line (counts use real lines)",
  { silent = true, expr = true })
map({ "n", "x" }, "k", 'v:count == 0 ? "gk" : "k"', "Motion", "up by display line (counts use real lines)",
  { silent = true, expr = true })
map({ "n", "x" }, "0", 'v:count == 0 ? "g0" : "0"', "Motion", "start of display line (counts use real lines)",
  { silent = true, expr = true })
map({ "n", "x" }, "$", 'v:count == 0 ? "g$" : "$"', "Motion", "end of display line (counts use real lines)",
  { silent = true, expr = true })

-- Quickfix / location list navigation is built in (Neovim 0.11+):
--   ]q [q next/prev, ]Q [Q last/first, ]<C-q> [<C-q> next/prev file; same with l for location lists
