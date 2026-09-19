-- tests/specs/dap.lua
-- Debugging: real sessions with debugpy (Python) and Delve (Go) stop at a
-- breakpoint, the UI opens and closes with the session, keys load nvim-dap lazily.
return function(T)
  local check, await = T.check, T.await

  check("nvim-dap not loaded before a debug key", not T.plugin_loaded("nvim-dap"))

  local function ui_open()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "dapui_scopes" then return true end
    end
    return false
  end

  -- Start `name` from the filetype's configurations, stop at the breakpoint on
  -- `line`, then continue to the end
  local function session(ft, file, name, line, timeout)
    local buf = T.open(file)
    vim.api.nvim_win_set_cursor(0, { line, 0 })
    T.run_keys("<leader>db")
    local set = await(function()
      if not T.plugin_loaded("nvim-dap") then return false end
      local bps = require("dap.breakpoints").get(buf)[buf] or {}
      return #bps == 1 and bps[1].line == line
    end, 5000)
    check(("%s: <leader>db sets a breakpoint (and loads nvim-dap)"):format(ft), set)
    local signs = vim.fn.sign_getplaced(buf, { group = "dap_breakpoints" })[1].signs
    check(("%s: breakpoint sign shown"):format(ft), #signs == 1 and signs[1].name == "DapBreakpoint",
      vim.inspect(signs))

    local dap = require("dap")
    local config
    for _, c in ipairs(dap.configurations[ft] or {}) do
      if c.name == name then config = c end
    end
    check(("%s: %q configuration registered"):format(ft, name), config ~= nil)
    if not config then return end

    dap.run(config)
    local stopped = await(function()
      local s = dap.session()
      return s ~= nil and s.current_frame ~= nil and s.current_frame.line == line
    end, timeout)
    local s = dap.session()
    check(("%s: session stops at the breakpoint"):format(ft), stopped,
      s and vim.inspect(s.current_frame and s.current_frame.line) or "no session")
    check(("%s: debug UI opens with the session"):format(ft), ui_open())

    dap.continue()
    local ended = await(function() return dap.session() == nil end, timeout)
    check(("%s: session runs to the end"):format(ft), ended)
    check(("%s: debug UI closes with the session"):format(ft), await(function() return not ui_open() end, 3000))
    dap.clear_breakpoints()
    vim.cmd("silent! only")
  end

  T.write("dbg/app.py", { "def add(a, b):", "    total = a + b", "    return total", "", "print(add(2, 3))" })
  session("python", "dbg/app.py", "file", 2, 20000)

  -- Stepping into json.dumps: "file" stays in our code (debugpy's justMyCode),
  -- "file (library code too)" lands in the standard library's json module
  do
    local dap = require("dap")
    T.write("dbg/lib.py", { "import json", "", 'payload = json.dumps({"a": 1})', "print(payload)" })
    local buf = T.open("dbg/lib.py")
    require("dap.breakpoints").set({}, buf, 3)
    local function step_into_with(name)
      local config
      for _, c in ipairs(dap.configurations.python) do
        if c.name == name then config = c end
      end
      if not config then return "no config " .. name end
      dap.run(config)
      await(function()
        local s = dap.session()
        return s ~= nil and s.current_frame ~= nil and s.current_frame.line == 3
      end, 20000)
      local before = dap.session() and dap.session().current_frame
      dap.step_into()
      await(function()
        local s = dap.session()
        return s ~= nil and s.current_frame ~= nil and s.current_frame ~= before
      end, 10000)
      local frame = dap.session() and dap.session().current_frame
      local where = frame and ((frame.source and frame.source.path or "?") .. ":" .. frame.line) or "?"
      dap.continue()
      await(function() return dap.session() == nil end, 10000)
      return where
    end
    local mine = step_into_with("file")
    check("python: \"file\" steps over library code (justMyCode)", mine:find("lib%.py:4$") ~= nil, mine)
    local all = step_into_with("file (library code too)")
    check("python: \"file (library code too)\" steps into the json module", all:find("/json/") ~= nil, all)
    dap.clear_breakpoints()
    vim.cmd("silent! only")
  end

  T.go_module("dbg_go")
  T.write("dbg_go/main.go", {
    "package main", "", 'import "fmt"', "",
    "func add(a, b int) int {", "\ttotal := a + b", "\treturn total", "}", "",
    "func main() {", "\tfmt.Println(add(2, 3))", "}",
  })
  session("go", "dbg_go/main.go", "Debug", 6, 60000)

  -- <leader>dt exists only in Python and Go buffers
  T.write("dbg/notes.txt", { "x" })
  local plain = T.open("dbg/notes.txt")
  local py = T.open("dbg/app.py")
  check("<leader>dT (library code too) in Python buffers", T.has_buf_map(py, "n", "<leader>dT"))
  check("<leader>dt only in Python/Go buffers",
    T.has_buf_map(py, "n", "<leader>dt") and vim.fn.maparg("<leader>dt", "n") ~= ""
      and vim.api.nvim_buf_call(plain, function() return vim.fn.maparg("<leader>dt", "n") == "" end))
end
