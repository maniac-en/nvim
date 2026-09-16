-- tests/specs/keymaps.lua
-- Every mapping the config defines has an "Area: [M]nemonic action" description
-- (including lazy-loaded plugins' stubs, before they load); <leader>sk searches them.
return function(T)
  local check, await, keys = T.check, T.await, T.keys
  local pattern = "^%u[%w/ ]*: %S" -- e.g. "Git: [G]it [S]tatus", "LSP: hover documentation"

  -- Inventory in a separate Neovim started with -V1, so each mapping records the
  -- script that defined it; includes Go/LSP buffer-local maps
  T.go_module("go")
  T.write("go/main.go", { "package main", "", "func main() {}" })
  local out = T.root .. "/inventory.json"
  T.write("inventory.lua", {
    "local cfg = vim.fn.stdpath('config')",
    "local rows, seen = {}, {}",
    "local function scan(maps)",
    "  for _, m in ipairs(maps) do",
    "    local src = ''",
    "    if m.sid and m.sid > 0 then local i = vim.fn.getscriptinfo({ sid = m.sid })[1]; src = i and i.name or '' end",
    "    local stub = src:find('/lazy.nvim/', 1, true) ~= nil",
    "    if (src:find(cfg, 1, true) == 1 or stub) and not seen[m.mode .. m.lhs .. (m.buffer or 0)] then",
    "      seen[m.mode .. m.lhs .. (m.buffer or 0)] = true",
    "      rows[#rows + 1] = { mode = m.mode, lhs = m.lhs, desc = m.desc or '', stub = stub }",
    "    end",
    "  end",
    "end",
    "vim.cmd('edit go/main.go')",
    "vim.wait(20000, function() return #vim.lsp.get_clients({ bufnr = 0, name = 'gopls' }) > 0 end, 100)",
    "for _, mode in ipairs({ 'n', 'x', 'o', 'i', 't' }) do scan(vim.api.nvim_get_keymap(mode)) scan(vim.api.nvim_buf_get_keymap(0, mode)) end",
    "local fugitive = require('lazy.core.config').plugins['vim-fugitive']._.loaded ~= nil",
    "vim.fn.writefile({ vim.json.encode({ rows = rows, fugitive_loaded = fugitive }) }, '" .. out .. "')",
    "vim.cmd('qa!')",
  })
  vim.system({ "nvim", "--headless", "-V1", "-i", "NONE", "-c", "luafile " .. T.root .. "/inventory.lua" },
    { cwd = T.root }):wait(60000)
  local ok, data = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(out), "\n")) end)
  check("inventory of config mappings collected", ok and #data.rows > 100, ok and #data.rows or data)
  if ok then
    local bad, stubs, gs = {}, 0, nil
    for _, r in ipairs(data.rows) do
      if not r.desc:match(pattern) then bad[#bad + 1] = ("%s %s %q"):format(r.mode, r.lhs, r.desc) end
      if r.stub then stubs = stubs + 1 end
      if r.lhs == " gs" and r.mode == "n" then gs = r end
    end
    check(("all %d config mappings use \"Area: action\" descriptions"):format(#data.rows), #bad == 0,
      table.concat(bad, "\n"))
    check(("lazy-loaded plugins' keys are described before loading (%d stubs)"):format(stubs), stubs >= 15)
    check("<leader>gs is described before fugitive loads",
      gs ~= nil and gs.desc == "Git: [G]it [S]tatus" and gs.stub and not data.fugitive_loaded, vim.inspect(gs))
  end

  -- <leader>sk opens telescope's keymaps picker
  T.write("notes.txt", { "hello world" })
  T.open("notes.txt")
  keys("<leader>sk")
  local picker
  await(function()
    local okp, p = pcall(function() return require("telescope.actions.state").get_current_picker(vim.api.nvim_get_current_buf()) end)
    picker = okp and p or nil
    return picker ~= nil
  end)
  check("<leader>sk opens the keymaps picker", picker ~= nil and picker.prompt_title == "Key Maps",
    picker and picker.prompt_title or vim.bo.filetype)
  if picker then require("telescope.actions").close(picker.prompt_bufnr) end
  await(function() return vim.bo.filetype ~= "TelescopePrompt" end)

  -- Once telescope has loaded, its real mappings keep their descriptions
  check("<C-p> keeps its description after telescope loads",
    T.plugin_loaded("telescope.nvim") and vim.fn.maparg("<C-p>", "n", false, true).desc == "Search: [P]roject files",
    vim.fn.maparg("<C-p>", "n", false, true).desc)

  -- Ctrl+/ opens the current-buffer search, however the terminal encodes it
  for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
    keys(lhs)
    local cbs = await(function()
      local okp, p = pcall(function() return require("telescope.actions.state").get_current_picker(vim.api.nvim_get_current_buf()) end)
      return okp and p ~= nil and p.prompt_title == "Current Buffer Fuzzy"
    end)
    check(lhs .. " opens current buffer search", cbs, vim.bo.filetype)
    keys("<Esc><Esc>")
    await(function() return vim.bo.filetype ~= "TelescopePrompt" end)
  end
end
