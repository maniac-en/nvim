-- lua/config/line_completion.lua
-- Whole-line completion (replaces tjdevries/complextras.nvim):
--   <C-x><C-m>  lines in the current buffer that contain the text on your line
--   <C-x><C-w>  same, across every file under the working directory (ripgrep;
--               respects .gitignore, skips hidden/binary files; files don't
--               need to be open)
-- Unlike built-in <C-x><C-l>, matches anywhere in a line, not just the start.

local max_items = 200
local max_line_length = 300 -- skip minified/generated lines

-- Replace the whole line (from column 1) with the chosen match
local function offer(lines)
  vim.fn.complete(1, lines)
end

local function add_unique(list, seen, line)
  if not seen[line] and #line <= max_line_length and #list < max_items then
    seen[line] = true
    list[#list + 1] = line
  end
end

local function complete_from_buffer()
  local text = vim.trim(vim.api.nvim_get_current_line())
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local matches, seen = {}, {}
  for row, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if row ~= cursor_row and line:find(text, 1, true) then
      add_unique(matches, seen, line)
    end
  end
  offer(matches)
end

local function complete_from_workspace()
  local text = vim.trim(vim.api.nvim_get_current_line())
  if text == "" then return end -- would match every line of every file
  if vim.fn.executable("rg") == 0 then
    vim.notify("<C-x><C-w> needs ripgrep (rg)", vim.log.levels.WARN)
    return
  end
  local res = vim.system({
    "rg", "--fixed-strings", "--no-filename", "--no-line-number", "--no-heading",
    "--color=never", "--max-count=50", "--", text,
  }, { text = true, cwd = vim.fn.getcwd() }):wait(3000)
  local current = vim.api.nvim_get_current_line()
  local matches, seen = {}, { [current] = true }
  for line in vim.gsplit(res.stdout or "", "\n", { plain = true, trimempty = true }) do
    add_unique(matches, seen, line)
  end
  offer(matches)
end

vim.keymap.set("i", "<C-x><C-m>", complete_from_buffer,
  { desc = "MANIAC_COMPLETION: [<C-x><C-m>] Complete line containing this text (buffer)" })
vim.keymap.set("i", "<C-x><C-w>", complete_from_workspace,
  { desc = "MANIAC_COMPLETION: [<C-x><C-w>] Complete line containing this text (workspace)" })
