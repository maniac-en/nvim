-- tests/smoke.lua
-- Headless smoke test for this config: startup, LSP, format-on-save, linting,
-- keymaps. Checks behavior, not exact formatter output. Needs the Mason tools
-- (and go, git) installed. Takes ~30-60s.
--
-- Run: tests/run.sh   (or directly:)
--   nvim --headless -i NONE -c 'lua dofile(vim.fn.stdpath("config") .. "/tests/smoke.lua")'
-- Exit code is 0 when every check passes, 1 otherwise.

-- Don't leave undo files for the throwaway sample files
vim.o.undofile = false
-- Keep "-- INSERT --", "N lines yanked" and similar text out of the output
vim.o.showmode = false
vim.o.report = 9999

-- Results are printed as each check runs; a summary follows at the end
local function print_line(line)
  io.stdout:write(line .. "\n")
  io.stdout:flush()
end
local results = {}
local function check(name, ok, detail)
  ok = ok and true or false
  results[#results + 1] = { name = name, ok = ok }
  print_line(("%s  %s"):format(ok and "PASS" or "FAIL", name))
  if not ok and detail then
    print_line("      " .. tostring(detail):gsub("\n", "\n      "))
  end
end

-- Sections are registered here and run in order inside a coroutine at the end,
-- so checks that type keys can wait without blocking Neovim's main loop.
-- An error inside a section counts as a failed check.
local sections = {}
local function section(name, fn)
  sections[#sections + 1] = { name = name, fn = fn }
end

-- Wait for cond() without blocking the main loop (queued keys get processed).
-- Only usable inside a section. Returns whether cond() became true.
local function await(cond, timeout)
  local co = assert(coroutine.running(), "await() must run inside a section")
  local start = vim.uv.now()
  local function tick()
    local ok = cond()
    if ok or vim.uv.now() - start > (timeout or 5000) then
      coroutine.resume(co, ok and true or false)
    else
      vim.defer_fn(tick, 30)
    end
  end
  vim.defer_fn(tick, 0)
  return coroutine.yield()
end
-- Queue keys as if typed (processed by the main loop during await)
local function keys(k) vim.api.nvim_feedkeys(vim.keycode(k), "t", false) end

local root = vim.fn.tempname()
local function write(path, lines)
  local full = root .. "/" .. path
  vim.fn.mkdir(vim.fs.dirname(full), "p")
  vim.fn.writefile(lines, full)
  return full
end

local function open(path)
  vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. path))
  return vim.api.nvim_get_current_buf()
end
local function lines(buf) return vim.api.nvim_buf_get_lines(buf, 0, -1, false) end
local function text(buf) return table.concat(lines(buf), "\n") end
local function client_names(buf)
  return vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = buf }))
end
local function wait_client(buf, name, timeout)
  return vim.wait(timeout or 20000, function()
    return #vim.lsp.get_clients({ bufnr = buf, name = name }) > 0
  end, 100)
end
local function wait_formatter(buf, timeout)
  return vim.wait(timeout or 10000, function()
    return #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) > 0
  end, 100)
end
local function diag_sources(buf)
  local seen = {}
  for _, d in ipairs(vim.diagnostic.get(buf)) do seen[d.source or "?"] = true end
  return seen
end
local function has_buf_map(buf, mode, lhs)
  return vim.fn.maparg(lhs, mode, false, true).buffer == 1 and vim.api.nvim_get_current_buf() == buf
end

-- Count vim.lsp.buf.format calls (format-on-save should call it once per save)
local format_calls = 0
local real_format = vim.lsp.buf.format
vim.lsp.buf.format = function(...)
  format_calls = format_calls + 1
  return real_format(...)
end

local startup_messages = vim.trim(vim.fn.execute("messages"))

-- Headless Neovim has no UI, so lazy.nvim's VeryLazy event (fired after the
-- first redraw) never happens; fire it so VeryLazy plugins load as they would
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })

local function plugin_loaded(name)
  local plugin = require("lazy.core.config").plugins[name]
  return plugin ~= nil and plugin._.loaded ~= nil
end

-- One git repo for all sample files, used as the working directory like a real
-- project (workspace-diagnostics lists files via `git ls-files` from the cwd,
-- once per session, at the first LSP attach)
vim.fn.mkdir(root, "p")
vim.system({ "git", "init", "-q", root }):wait()
write("py/scripts/other.py", { "x = 1" })
vim.system({ "git", "add", "-A" }, { cwd = root }):wait()
vim.cmd.cd(vim.fn.fnameescape(root))

----------------------------------------------------------------------------
section("startup", function()
  check("startup: no messages/errors in this session", startup_messages == "", startup_messages)

  local res = vim.system({ "nvim", "--headless", "-i", "NONE", "+qa" }):wait(30000)
  check("startup: clean nested start (no stderr)", res.code == 0 and vim.trim(res.stderr or "") == "", res.stderr)

  local times = {}
  for i = 1, 3 do
    local log = vim.fn.tempname()
    vim.system({ "nvim", "--headless", "-i", "NONE", "--startuptime", log, "+qa" }):wait(30000)
    for _, line in ipairs(vim.fn.readfile(log)) do
      if line:find("NVIM STARTED", 1, true) then times[i] = tonumber(line:match("^(%d+%.%d+)")) end
    end
    times[i] = times[i] or -1
    vim.fn.delete(log)
  end
  table.sort(times)
  check(("startup: median %.1fms (informational)"):format(times[2]), true)

  -- Only these plugins load when starting without a file; everything else waits
  -- for a file, key, command or VeryLazy (lazy.nvim itself isn't in its plugin list)
  local expected = { "catppuccin", "nvim-treesitter", "oil.nvim", "vim-lastplace", "nvim-web-devicons" }
  local probe = [[lua local names = {}
    for name, p in pairs(require("lazy.core.config").plugins) do
      if p._.loaded and name ~= "lazy.nvim" then names[#names + 1] = name end
    end
    table.sort(names) io.stdout:write(table.concat(names, ","))]]
  local res2 = vim.system({ "nvim", "--headless", "-i", "NONE", "+" .. probe, "+qa!" }, { text = true }):wait(30000)
  local loaded = vim.split(vim.trim(res2.stdout or ""), ",", { trimempty = true })
  table.sort(expected)
  check("startup: only " .. table.concat(expected, ", ") .. " load without a file",
    vim.deep_equal(loaded, expected), "loaded: " .. table.concat(loaded, ", "))

  -- Opening a Go file loads the LSP stack but not Lua-only lazydev
  local go_probe = write("probe/p.go", { "package main" })
  local res3 = vim.system({ "nvim", "--headless", "-i", "NONE", go_probe, "+" .. probe, "+qa!" }, { text = true }):wait(30000)
  local go_loaded = vim.split(vim.trim(res3.stdout or ""), ",", { trimempty = true })
  -- The first vim.ui.select call (e.g. code actions) loads telescope and uses its picker
  local select_probe = [[lua vim.ui.select({ "a" }, {}, function() end)
    io.stdout:write(debug.getinfo(vim.ui.select, "S").source)]]
  local res4 = vim.system({ "nvim", "--headless", "-i", "NONE", "+" .. select_probe, "+qa!" }, { text = true }):wait(30000)
  check("lazy: first vim.ui.select loads telescope's ui-select",
    (res4.stdout or ""):find("telescope%-ui%-select") ~= nil, res4.stdout .. (res4.stderr or ""))

  check("startup: a Go file loads nvim-lspconfig but not lazydev",
    vim.tbl_contains(go_loaded, "nvim-lspconfig") and not vim.tbl_contains(go_loaded, "lazydev.nvim"),
    "loaded: " .. table.concat(go_loaded, ", "))
end)

----------------------------------------------------------------------------
section("go", function()
  vim.fn.mkdir(root .. "/go", "p")
  vim.system({ "go", "mod", "init", "example.com/smoke" }, { cwd = root .. "/go" }):wait()
  write("go/main.go", {
    "package main",
    "",
    "func main() {",
    '  os.Remove("a")', -- missing import + bad indent + unchecked error
    '\tfmt.Println("hi")',
    "}",
  })
  local buf = open("go/main.go")
  check("go: gopls attaches", wait_client(buf, "gopls"), vim.inspect(client_names(buf)))

  format_calls = 0
  vim.cmd("silent write")
  local src = text(buf)
  check("go: save adds missing imports", src:find('"fmt"', 1, true) and src:find('"os"', 1, true), src)
  check("go: save formats (gofumpt indent)", src:find('\n\tos.Remove', 1, true) ~= nil, src)
  check("go: formatted exactly once per save", format_calls == 1, "format calls: " .. format_calls)

  local got_errcheck = vim.wait(60000, function() return diag_sources(buf).errcheck end, 250)
  check("go: golangci-lint reports issues after save", got_errcheck, vim.inspect(diag_sources(buf)))

  -- Compile error: gopls reports it; golangci-lint's "typecheck" copy is filtered
  local l = lines(buf)
  table.insert(l, #l, "\tx := 1")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, l)
  vim.cmd("silent write")
  vim.wait(60000, function() return diag_sources(buf).compiler end, 250)
  vim.wait(5000, function() return #require("lint").get_running(buf) == 0 end, 100)
  vim.wait(1000)
  local sources = diag_sources(buf)
  check("go: gopls reports compile error", sources.compiler, vim.inspect(sources))
  check("go: golangci-lint typecheck duplicates filtered", not sources.typecheck, vim.inspect(sources))

  for _, lhs in ipairs({ "<leader>r", "<leader>t", "<leader>dt", "gd", "K" }) do
    check("go: buffer keymap " .. lhs, has_buf_map(buf, "n", lhs))
  end
  check("go: makeprg", vim.bo[buf].makeprg == "go build", vim.bo[buf].makeprg)
end)

----------------------------------------------------------------------------
section("python", function()
  write("py/t.py", {
    "import sys",
    "import os",
    "import json",
    "",
    "def f( a ):",
    '    x: int = "not an int"', -- type error: basedpyright diagnostics must stay silent
    '    return os.path.join(a,json.dumps(x))',
  })
  local buf = open("py/t.py")
  check("python: basedpyright attaches", wait_client(buf, "basedpyright"), vim.inspect(client_names(buf)))
  check("python: ruff attaches", wait_client(buf, "ruff"), vim.inspect(client_names(buf)))
  check("python: ruff provides formatting", wait_formatter(buf))

  vim.wait(20000, function() return diag_sources(buf).Ruff end, 200)
  vim.wait(2000)
  local sources = diag_sources(buf)
  check("python: ruff diagnostics (unused import)", sources.Ruff, vim.inspect(sources))
  check("python: basedpyright diagnostics silenced", not sources.basedpyright, vim.inspect(sources))

  vim.api.nvim_win_set_cursor(0, { 7, 12 }) -- on `os`
  local hovers = vim.lsp.buf_request_sync(buf, "textDocument/hover",
    vim.lsp.util.make_position_params(0, "utf-16"), 10000) or {}
  local hover_from = {}
  for id, r in pairs(hovers) do
    if r.result then hover_from[#hover_from + 1] = vim.lsp.get_client_by_id(id).name end
  end
  check("python: hover only from basedpyright", #hover_from == 1 and hover_from[1] == "basedpyright",
    vim.inspect(hover_from))

  format_calls = 0
  vim.cmd("silent write")
  local l = lines(buf)
  check("python: save sorts imports", l[1] == "import json" and l[2] == "import os" and l[3] == "import sys",
    text(buf))
  check("python: save formats", vim.tbl_contains(l, "def f(a):"), text(buf))
  check("python: formatted exactly once per save", format_calls == 1, "format calls: " .. format_calls)

  for _, lhs in ipairs({ "<leader>r", "gd", "K" }) do
    check("python: buffer keymap " .. lhs, has_buf_map(buf, "n", lhs))
  end

  -- Opening another git-tracked project file must not warn about a redundant
  -- didOpen (workspace-diagnostics pre-opens tracked files)
  local before = vim.fn.execute("messages")
  local other = open("py/scripts/other.py")
  wait_client(other, "basedpyright")
  vim.wait(3000)
  local new_msgs = vim.fn.execute("messages"):sub(#before + 1)
  check("python: no 'redundant open text document' warning",
    not new_msgs:find("redundant open text document", 1, true), new_msgs)
end)

----------------------------------------------------------------------------
section("other languages", function()
  -- format: true = must change on save, false = must stay untouched, nil = not checked
  local cases = {
    { file = "t.c",    server = "clangd", content = { "int main(){return 0;}" } },
    { file = "t.ts",   server = "ts_ls",  content = { "let x: number = 1;" } },
    { file = "t.js",   server = "ts_ls",  content = { "const a = 1;", "a = 2;" },                     linter = "quick-lint-js" },
    { file = "t.json", server = "jsonls", content = { '{"a":1,', '"b":[1,2]}' },                      format = true },
    { file = "t.css",  server = "cssls",  content = { "p{color:red;margin:0}" },                      format = true },
    { file = "t.html", server = "html",   content = { "<div><p>hi</p>", "      <p>there</p></div>" }, format = false },
    { file = "t.sh",   server = "bashls", content = { "echo hi" } },
    { file = "t.lua",  server = "lua_ls", content = { "local x = 1" } },
  }
  for _, case in ipairs(cases) do
    write("misc/" .. case.file, case.content)
    local buf = open("misc/" .. case.file)
    check(("%s: %s attaches"):format(case.file, case.server), wait_client(buf, case.server),
      vim.inspect(client_names(buf)))
    if case.linter then
      local got = vim.wait(10000, function() return diag_sources(buf)[case.linter] end, 100)
      check(("%s: %s reports"):format(case.file, case.linter), got, vim.inspect(diag_sources(buf)))
    end
    if case.format ~= nil then
      if case.format then wait_formatter(buf) else vim.wait(2000) end
      local before = text(buf)
      vim.cmd("silent write")
      local changed = text(buf) ~= before
      check(("%s: %s on save"):format(case.file, case.format and "formatted" or "not formatted"),
        changed == case.format, text(buf))
    end
  end
end)

----------------------------------------------------------------------------
section("completion", function()
  check("completion: nvim-cmp is gone", package.loaded.cmp == nil and not pcall(require, "cmp"))

  write("go/comp.go", { "package main", "", "func helper() {", "\t", "}" })
  local buf = open("go/comp.go")
  wait_client(buf, "gopls")
  await(function() return false end, 1500) -- let gopls load the package

  local blink = require("blink.cmp")
  check("completion: Rust fuzzy matcher active", require("blink.cmp.fuzzy").implementation_type == "rust",
    require("blink.cmp.fuzzy").implementation_type)
  local gopls = vim.lsp.get_clients({ bufnr = buf, name = "gopls" })[1]
  check("completion: LSP clients get blink.cmp capabilities", gopls and vim.deep_equal(
    gopls.config.capabilities.textDocument.completion, blink.get_lsp_capabilities().textDocument.completion))

  -- Typing shows LSP items; <C-y> accepts the selected (first) one
  vim.api.nvim_win_set_cursor(0, { 4, 1 })
  keys("A")
  await(function() return vim.fn.mode() == "i" end)
  keys("fmt.Prin")
  local shown = await(function()
    for _, item in ipairs(blink.get_items() or {}) do
      if item.source_id == "lsp" and item.label == "Println" then return blink.is_menu_visible() end
    end
  end, 10000)
  check("completion: menu shows LSP items while typing", shown,
    vim.inspect(vim.tbl_map(function(i) return i.label end, vim.list_slice(blink.get_items() or {}, 1, 5))))
  keys("<C-y>")
  local accepted = await(function() return vim.api.nvim_get_current_line():find("fmt%.Print%w*%(") ~= nil end)
  check("completion: <C-y> accepts an item", accepted, vim.api.nvim_get_current_line())
  keys("<Esc>")
  await(function() return vim.fn.mode() == "n" end)

  -- No completion inside comments
  vim.api.nvim_buf_set_lines(buf, 3, 4, false, { "\t// fmt.Prin" })
  vim.api.nvim_win_set_cursor(0, { 4, 11 })
  keys("a")
  await(function() return vim.fn.mode() == "i" end)
  keys("t")
  check("completion: no menu inside comments", not await(function() return blink.is_menu_visible() end, 2000))
  keys("<Esc>")
  await(function() return vim.fn.mode() == "n" end)
  vim.cmd("silent! bwipeout!")

  -- Filetype-specific sources
  local providers = function() return vim.tbl_keys(require("blink.cmp.sources.lib").get_enabled_providers("default")) end
  write("misc/t.sql", { "select 1;" })
  open("misc/t.sql")
  check("completion: SQL uses dadbod source", vim.tbl_contains(providers(), "dadbod"), vim.inspect(providers()))
  open("misc/t.lua")
  check("completion: Lua uses lazydev source", vim.tbl_contains(providers(), "lazydev"), vim.inspect(providers()))

  -- Command-line menu shows automatically (after 4 characters)
  keys(":checkhea")
  local cmd_menu = await(function() return vim.fn.mode() == "c" and blink.is_menu_visible() end)
  keys("<C-c>")
  await(function() return vim.fn.mode() == "n" end)
  io.stdout:write("\n") -- headless Neovim echoes the typed command line to stdout
  check("completion: cmdline menu shows while typing", cmd_menu)

  -- Whole-line completion: <C-x><C-m> (current buffer), <C-x><C-w> (workspace via rg)
  write("misc/lines_other.txt", { "unopened = smoke_marker_42 * 2" })
  write("misc/lines.txt", { "in buffer: smoke_marker_42 here", "" })
  local lbuf = open("misc/lines.txt")
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  local function pum_words()
    return vim.tbl_map(function(i) return i.word end, vim.fn.complete_info({ "items" }).items or {})
  end
  keys("A")
  await(function() return vim.fn.mode() == "i" end)
  keys("smoke_marker_42")
  await(function() return vim.api.nvim_get_current_line() == "smoke_marker_42" end)
  keys("<C-x><C-m>")
  await(function() return vim.fn.pumvisible() == 1 end)
  local words = pum_words()
  check("line completion: <C-x><C-m> offers matching buffer lines only",
    vim.deep_equal(words, { "in buffer: smoke_marker_42 here" }), vim.inspect(words))
  keys("<C-e>")
  await(function() return vim.fn.pumvisible() == 0 end)
  keys("<C-x><C-w>")
  await(function() return vim.fn.pumvisible() == 1 end)
  words = pum_words()
  check("line completion: <C-x><C-w> includes lines from unopened files",
    vim.tbl_contains(words, "unopened = smoke_marker_42 * 2"), vim.inspect(words))
  keys("<C-e><Esc>")
  await(function() return vim.fn.mode() == "n" end)
  vim.api.nvim_buf_delete(lbuf, { force = true })
end)

----------------------------------------------------------------------------
section("treesitter", function()
  check("treesitter: nvim-treesitter is on the main branch",
    type(require("nvim-treesitter").install) == "function" and not pcall(require, "nvim-treesitter.configs"))
  check("treesitter: exactly one go parser on runtimepath (no stale parsers)",
    #vim.api.nvim_get_runtime_file("parser/go.so", true) == 1,
    vim.inspect(vim.api.nvim_get_runtime_file("parser/go.so", true)))

  write("go/ts.go", {
    "package main",
    "",
    'import "fmt"',
    "",
    "func helper(a int, b string) {",
    "\tif a > 0 {",
    "\t\tfmt.Println(b)",
    "\t}",
    "}",
    "",
    "func caller() {",
    '\thelper(1, "x")',
    "}",
  })
  local buf = open("go/ts.go")
  check("treesitter: highlighting active in Go", vim.treesitter.highlighter.active[buf] ~= nil)
  check("treesitter: indentexpr set in Go", vim.bo[buf].indentexpr:find("nvim%-treesitter") ~= nil, vim.bo[buf].indentexpr)

  local function run(k) vim.api.nvim_feedkeys(vim.keycode(k), "mx", false) end
  local function yank_after(k, row, col)
    vim.api.nvim_win_set_cursor(0, { row, col })
    run(k .. "y")
    return vim.fn.getreg('"')
  end
  local got = yank_after("vam", 7, 3)
  check("textobjects: vam selects the function", got:match("^func helper") and got:match("}$"), got)
  got = yank_after("via", 12, 8)
  check("textobjects: via selects an argument", got == "1", got)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  run("]f")
  local after_move = vim.api.nvim_win_get_cursor(0)[1]
  run(";")
  check("textobjects: ]f moves to next function, ; repeats",
    after_move == 5 and vim.api.nvim_win_get_cursor(0)[1] == 11, vim.inspect(vim.api.nvim_win_get_cursor(0)))
  vim.api.nvim_win_set_cursor(0, { 12, 8 })
  run("<leader>sa")
  check("textobjects: <leader>sa swaps arguments", vim.api.nvim_buf_get_lines(buf, 11, 12, false)[1] == '\thelper("x", 1)',
    vim.api.nvim_buf_get_lines(buf, 11, 12, false)[1])
  vim.cmd("silent undo")

  -- <C-space> selects the node under the cursor, grows to parents, <C-backspace> shrinks back
  got = yank_after("<C-space>", 7, 14)
  local grown = yank_after("<C-space><C-space><C-space>", 7, 14)
  local shrunk = yank_after("<C-space><C-space><C-space><C-backspace><C-backspace>", 7, 14)
  check("selection: <C-space> starts at node, grows, <C-backspace> shrinks back",
    got == "b" and grown:find("fmt.Println(b)", 1, true) and shrunk == "b",
    vim.inspect({ start = got, grown = grown, shrunk = shrunk }))

  vim.api.nvim_win_set_cursor(0, { 12, 1 })
  run("gcc")
  check("comment: gcc comments the line", vim.api.nvim_buf_get_lines(buf, 11, 12, false)[1] == '\t// helper(1, "x")',
    vim.api.nvim_buf_get_lines(buf, 11, 12, false)[1])
  vim.cmd("silent undo")

  -- K hover with a code block: its markdown injections must parse (the old
  -- master branch crashed here and turned highlighting off)
  wait_client(buf, "gopls")
  await(function() return false end, 1500)
  vim.api.nvim_win_set_cursor(0, { 7, 7 }) -- on Println
  vim.lsp.buf.hover()
  local float
  await(function()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(w).relative ~= "" and vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "markdown" then
        float = w
        return true
      end
    end
  end, 10000)
  check("hover: K opens a markdown popup", float ~= nil)
  if float then
    local fbuf = vim.api.nvim_win_get_buf(float)
    local ok, err = pcall(function() vim.treesitter.get_parser(fbuf):parse(true) end)
    local langs = {}
    if ok then vim.treesitter.get_parser(fbuf):for_each_tree(function(_, t) langs[t:lang()] = true end) end
    check("hover: code blocks in the popup parse without errors", ok and langs.go, err or vim.inspect(langs))
    vim.api.nvim_win_close(float, true)
  end

  -- http requests as textobjects (queries/http/textobjects.scm)
  write("misc/t.http", { "GET https://example.com", "", "###", "", "POST https://example.com/x", "" })
  open("misc/t.http")
  check("lazy: opening a .http file loads rest.nvim (:Rest available)",
    plugin_loaded("rest.nvim") and vim.fn.exists(":Rest") == 2)
  got = yank_after("var", 5, 0)
  check("textobjects: var selects an HTTP request (custom query)", got:find("^POST https://example.com/x") ~= nil, got)
end)

----------------------------------------------------------------------------
section("lazy loading", function()
  local function close_floats()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_config(w).relative ~= "" then
        pcall(vim.api.nvim_win_close, w, true)
      end
    end
  end
  write("lazy/t.txt", { "word here" })
  open("lazy/t.txt")

  check("lazy: lazydev loaded once a Lua file was opened", plugin_loaded("lazydev.nvim"))

  -- keys
  keys("<C-p>")
  check("lazy: <C-p> loads telescope and opens a picker",
    await(function() return plugin_loaded("telescope.nvim") and vim.bo.filetype == "TelescopePrompt" end, 5000),
    vim.bo.filetype)
  keys("<Esc><Esc>")
  await(function() return vim.bo.filetype ~= "TelescopePrompt" end)
  close_floats()

  keys("<C-\\>")
  check("lazy: <C-\\> loads toggleterm and opens a terminal",
    await(function() return plugin_loaded("toggleterm.nvim") and vim.bo.filetype == "toggleterm" end, 5000),
    vim.bo.filetype)
  vim.cmd("stopinsert")
  close_floats()

  keys("<leader>gs")
  check("lazy: <leader>gs loads fugitive and opens :Git status",
    await(function() return plugin_loaded("vim-fugitive") and vim.bo.filetype == "fugitive" end, 5000),
    vim.bo.filetype)
  vim.cmd("silent! bwipeout")

  -- commands
  for _, case in ipairs({
    { cmd = "GV", plugin = "gv.vim" },
    { cmd = "ZenMode", plugin = "zen-mode.nvim", after = "ZenMode" },
    { cmd = "FSRead", plugin = "fsread.nvim", after = "FSClear" },
  }) do
    open("lazy/t.txt")
    local ok, err = pcall(vim.cmd, "silent " .. case.cmd)
    check(("lazy: :%s loads %s"):format(case.cmd, case.plugin), ok and plugin_loaded(case.plugin), err)
    if case.after then pcall(vim.cmd, case.after) end
    if case.cmd == "GV" then pcall(vim.cmd, "tabclose") end
  end

  -- VeryLazy plugins
  for _, name in ipairs({ "Comment.nvim", "vim-surround", "vim-repeat", "vim-unimpaired" }) do
    check("lazy: " .. name .. " loaded on VeryLazy", plugin_loaded(name))
  end
  local tbuf = open("lazy/t.txt")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_feedkeys(vim.keycode('ysiw"'), "mx", false)
  check("surround: ysiw\" surrounds a word", vim.api.nvim_buf_get_lines(tbuf, 0, 1, false)[1] == '"word" here',
    vim.api.nvim_buf_get_lines(tbuf, 0, 1, false)[1])
  vim.api.nvim_feedkeys(vim.keycode("]<Space>"), "mx", false)
  check("unimpaired: ]<Space> adds a blank line below", vim.api.nvim_buf_line_count(tbuf) == 2,
    vim.inspect(vim.api.nvim_buf_get_lines(tbuf, 0, -1, false)))
  vim.api.nvim_buf_delete(tbuf, { force = true })
end)

----------------------------------------------------------------------------
section("telescope", function()
  -- LSP pickers must not be filtered by file ignore patterns: a definition in a
  -- path like .../golang.org/... used to be dropped by an unanchored "%.o"
  check("telescope: no global file_ignore_patterns (LSP pickers unfiltered)",
    vim.tbl_isempty(require("telescope.config").values.file_ignore_patterns or {}),
    vim.inspect(require("telescope.config").values.file_ignore_patterns))

  -- gd (telescope lsp_definitions) into a dependency under a golang.org/ path; offline via replace
  write("tele_go/deps/golang.org/dep/go.mod", { "module example.org/dep", "", "go 1.22" })
  write("tele_go/deps/golang.org/dep/dep.go", { "package dep", "", "func Hello() string { return \"hi\" }" })
  write("tele_go/go.mod", { "module example.com/tele", "", "go 1.22", "",
    "require example.org/dep v0.0.0", "", "replace example.org/dep => ./deps/golang.org/dep" })
  write("tele_go/main.go", { "package main", "", 'import "example.org/dep"', "", "func main() {", "\t_ = dep.Hello()", "}" })
  local gbuf = open("tele_go/main.go")
  wait_client(gbuf, "gopls")
  await(function() return false end, 2500)
  vim.api.nvim_win_set_cursor(0, { 6, 9 }) -- on Hello
  vim.api.nvim_feedkeys("gd", "mx", false)
  local target = root .. "/tele_go/deps/golang.org/dep/dep.go"
  check("telescope: gd reaches a definition under a golang.org/ path",
    await(function() return vim.api.nvim_buf_get_name(0) == target end, 10000), vim.api.nvim_buf_get_name(0))

  -- <leader>sf (hidden + no_ignore) lists real files, hides .git/, node_modules/ and binaries
  local shown_files = { "tele/internal/auth.api.go", "tele/cmd/server.app/main.go", "tele/pkg/target/x.go",
    "tele/scripts/rebuild/run.sh", "tele/notes/todo.org", "tele/config.old.yaml", "tele/app/.air.toml" }
  local hidden_files = { "tele/.git/HEAD", "tele/sub/.git/config", "tele/node_modules/x/index.js",
    "tele/web/node_modules/y/a.js", "tele/bin/app.o", "tele/lib/libfoo.a", "tele/report.pdf", "tele/.DS_Store" }
  for _, f in ipairs(vim.list_extend(vim.deepcopy(shown_files), hidden_files)) do write(f, { "x" }) end
  open("tele/config.old.yaml")
  vim.api.nvim_feedkeys(vim.keycode("<leader>sf"), "mx", false)
  local picker
  await(function()
    local ok, pk = pcall(require("telescope.actions.state").get_current_picker, vim.api.nvim_get_current_buf())
    picker = ok and pk or nil
    return picker ~= nil
  end)
  await(function() return false end, 1500) -- let the finder finish
  local listed = {}
  if picker then
    for entry in picker.manager:iter() do listed[entry.value] = true end
    require("telescope.actions").close(picker.prompt_bufnr)
  end
  local missing, leaked = {}, {}
  for _, f in ipairs(shown_files) do if not listed[f] then missing[#missing + 1] = f end end
  for _, f in ipairs(hidden_files) do if listed[f] then leaked[#leaked + 1] = f end end
  check("telescope: <leader>sf shows real files like auth.api.go, server.app/, target/, rebuild/",
    picker ~= nil and #missing == 0, "missing: " .. table.concat(missing, ", "))
  check("telescope: <leader>sf hides .git/, node_modules/ and binaries", picker ~= nil and #leaked == 0,
    "leaked: " .. table.concat(leaked, ", "))
end)

----------------------------------------------------------------------------
section("editor", function()
  -- <CR> in quickfix and location list windows jumps to the entry under the cursor
  write("qf/target.txt", { "one", "two", "three" })
  local target = root .. "/qf/target.txt"
  for _, kind in ipairs({ "quickfix", "location" }) do
    vim.cmd("silent! only | enew")
    local entries = { { filename = target, lnum = 1, text = "first" }, { filename = target, lnum = 3, text = "third" } }
    if kind == "quickfix" then
      vim.fn.setqflist({}, "r")
      vim.fn.setqflist(entries, "r")
      vim.cmd("copen")
    else
      vim.fn.setqflist({}, "r") -- empty quickfix list: a quickfix-only command would fail here
      vim.fn.setloclist(0, entries, "r")
      vim.cmd("lopen")
    end
    vim.api.nvim_win_set_cursor(0, { 2, 0 }) -- second entry
    vim.v.errmsg = ""
    vim.api.nvim_feedkeys(vim.keycode("<CR>"), "mx", false)
    local jumped = vim.api.nvim_buf_get_name(0) == target and vim.api.nvim_win_get_cursor(0)[1] == 3
    check(("%s list: <CR> jumps to the entry"):format(kind), jumped and vim.v.errmsg == "",
      ("buf=%s line=%d errmsg=%s"):format(vim.api.nvim_buf_get_name(0), vim.api.nvim_win_get_cursor(0)[1], vim.v.errmsg))
    vim.cmd("silent! cclose | silent! lclose | silent! only")
  end

  for _, cmd in ipairs({ "RunGo", "RunPython", "RunC", "RunJavascript", "RunTypescript", "RunLua" }) do
    check("command :" .. cmd, vim.fn.exists(":" .. cmd) == 2)
  end

  -- Trailing whitespace is stripped on save without moving the cursor or the search
  write("ws/t.txt", { "x   ", "hello" })
  local buf = open("ws/t.txt")
  vim.fn.setreg("/", "hello")
  vim.api.nvim_win_set_cursor(0, { 2, 3 })
  vim.cmd("silent write")
  check("whitespace: stripped on save", lines(buf)[1] == "x", vim.inspect(lines(buf)))
  check("whitespace: cursor kept", vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 2, 3 }))
  check("whitespace: search pattern kept", vim.fn.getreg("/") == "hello", vim.fn.getreg("/"))

  vim.cmd("enew | setfiletype gitcommit")
  check("gitcommit: :AiCommit is buffer-local", vim.api.nvim_buf_get_commands(0, {}).AiCommit ~= nil
    and vim.api.nvim_get_commands({}).AiCommit == nil)
end)

----------------------------------------------------------------------------
-- Deprecation warnings from third-party plugins we've decided to live with for
-- now; each one must have an entry in parked-for-later.md. Matched against the
-- warning's stack trace. Anything else fails the health check.
local known_deprecations = {
  { stack = "/rest.nvim/", note = "rest.nvim vim.validate{} (parked: fork rest.nvim)" },
}

section("health", function()
  vim.cmd("silent checkhealth vim.deprecated")
  local report = text(0)
  vim.cmd("bwipeout!")
  if report:find("No deprecated functions detected", 1, true) then
    check("health: no deprecated functions", true)
  else
    -- one chunk per warning, each followed by its stack trace
    local unknown = {}
    for warning in (report .. "\n- "):gmatch("WARNING(.-)\n%- ") do
      local known
      for _, k in ipairs(known_deprecations) do
        if warning:find(k.stack, 1, true) then known = k end
      end
      if known then
        check("health: known deprecation tolerated: " .. known.note, true)
      else
        unknown[#unknown + 1] = "WARNING" .. warning
      end
    end
    check("health: no unexpected deprecated functions", #unknown == 0, table.concat(unknown, "\n"))
  end

  local msgs = vim.trim(vim.fn.execute("messages"))
  check("messages: empty after all checks", msgs == "", msgs)
end)

----------------------------------------------------------------------------
local finished = false
local function finish()
  if finished then return end
  finished = true
  vim.lsp.buf.format = real_format
  vim.cmd.cd("/")
  vim.fn.delete(root, "rf")

  local failed = vim.tbl_filter(function(r) return not r.ok end, results)
  print_line(("\n%d checks, %d failed"):format(#results, #failed))
  for _, r in ipairs(failed) do
    print_line("  FAIL  " .. r.name)
  end
  vim.cmd(#failed == 0 and "qa!" or "cquit! 1")
end

-- Never hang silently: report what ran so far and fail. Exits the process
-- directly, since :cquit may not get through while a section is blocked.
local limit_minutes = 4
vim.defer_fn(function()
  check(("finished within %d minutes"):format(limit_minutes), false, "timed out; results above are partial")
  pcall(finish)
  io.stdout:flush()
  os.exit(1)
end, limit_minutes * 60 * 1000)

coroutine.wrap(function()
  for _, sec in ipairs(sections) do
    print_line("\n== " .. sec.name)
    local ok, err = xpcall(sec.fn, debug.traceback)
    if not ok then check(sec.name .. ": no errors", false, err) end
  end
  finish()
end)()
