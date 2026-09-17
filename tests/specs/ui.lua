-- tests/specs/ui.lua
-- Winbar/statusline look, indentation guessing, config paths.
return function(T)
  local check = T.check

  -- Winbar (used as the statusline) is bold, in the editor's colors, in every window
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  for _, group in ipairs({ "WinBar", "WinBarNC" }) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    check(group .. " is bold with the editor's colors", hl.bold == true and hl.fg == normal.fg and hl.bg == normal.bg,
      vim.inspect(hl))
  end
  -- Statusline (only the separator row between stacked windows) blends into the editor
  for _, group in ipairs({ "StatusLine", "StatusLineNC" }) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    check(group .. " is hidden in the editor background", hl.bg == normal.bg, vim.inspect(hl))
  end
  -- ...and has no text (e.g. the file name) that a transparent background would reveal
  T.write("notes.txt", { "hello" })
  T.open("notes.txt")
  vim.cmd("split | redraw!")
  local top = vim.fn.win_getid(1) -- the upper window (splitbelow puts the new one below)
  local row = vim.fn.win_screenpos(top)[1] + vim.api.nvim_win_get_height(top)
  local text = {}
  for col = 1, vim.o.columns do text[#text + 1] = vim.fn.screenstring(row, col) end
  text = table.concat(text)
  check("separator row between stacked windows is empty", vim.trim(text) == "", ("row %d: %q"):format(row, text))
  vim.cmd("only")

  -- Config paths come from stdpath("config"), not a hard-coded ~/.config/nvim
  local config = vim.fn.stdpath("config")
  check("spellfile lives in the config dir", vim.o.spellfile == config .. "/spell/en.utf-8.add", vim.o.spellfile)
  local tabs = #vim.api.nvim_list_tabpages()
  T.run_keys("<leader>ev")
  local ev = T.await(function() return vim.bo.filetype == "oil" end)
  local dir = ev and require("oil").get_current_dir() or vim.api.nvim_buf_get_name(0)
  check("<leader>ev opens the config dir in a new tab",
    ev and #vim.api.nvim_list_tabpages() == tabs + 1 and vim.fs.normalize(dir) == vim.fs.normalize(config),
    ("filetype=%s dir=%s tabs=%d"):format(vim.bo.filetype, dir, #vim.api.nvim_list_tabpages()))
  vim.cmd("silent! tabonly")
  -- Indentation is guessed per file by vim-sleuth (sibling files for new/unindented
  -- ones); it beats ftplugin defaults, and modelines/.editorconfig beat it
  local function indent_of(path, lines)
    if lines then T.write(path, lines) end
    local b = T.open(path)
    vim.wait(300)
    return { sw = vim.fn.shiftwidth(), et = vim.bo[b].expandtab }
  end
  local two_js = { "function f() {", "  if (x) {", "    return 1;", "  }", "}" }
  local py = indent_of("indent/two.py", { "def f():", "  if x:", "    return 1" })
  check("indent: 2-space Python stays 2 (beats the ftplugin's 4)", py.sw == 2 and py.et, vim.inspect(py))
  for _, n in ipairs({ "a", "b", "c" }) do T.write("neighbors/" .. n .. ".js", two_js) end
  local new_file = indent_of("neighbors/new.js")
  check("indent: new file takes 2-space style from sibling files", new_file.sw == 2 and new_file.et,
    vim.inspect(new_file))
  T.write("indent_ec/.editorconfig", { "root = true", "", "[*]", "indent_style = space", "indent_size = 8" })
  local ec = indent_of("indent_ec/two.js", { "function f() {", "  return 1;", "}" })
  check("indent: .editorconfig indent_size wins over guessing", ec.sw == 8 and ec.et, vim.inspect(ec))
end
