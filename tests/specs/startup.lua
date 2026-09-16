-- tests/specs/startup.lua
-- Clean startup, startup time, and which plugins load before any file/key/command.
return function(T)
  local check = T.check

  check("no messages/errors during startup", T.startup_messages == "", T.startup_messages)

  local res = vim.system({ "nvim", "--headless", "-i", "NONE", "+qa" }):wait(30000)
  check("clean nested start (no stderr)", res.code == 0 and vim.trim(res.stderr or "") == "", res.stderr)

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
  check(("median %.1fms (informational)"):format(times[2]), true)

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
  check("only " .. table.concat(expected, ", ") .. " load without a file",
    vim.deep_equal(loaded, expected), "loaded: " .. table.concat(loaded, ", "))

  -- Opening a Go file loads the LSP stack but not Lua-only lazydev
  local go_probe = T.write("probe/p.go", { "package main" })
  local res3 = vim.system({ "nvim", "--headless", "-i", "NONE", go_probe, "+" .. probe, "+qa!" }, { text = true }):wait(30000)
  local go_loaded = vim.split(vim.trim(res3.stdout or ""), ",", { trimempty = true })
  check("a Go file loads nvim-lspconfig but not lazydev",
    vim.tbl_contains(go_loaded, "nvim-lspconfig") and not vim.tbl_contains(go_loaded, "lazydev.nvim"),
    "loaded: " .. table.concat(go_loaded, ", "))

  -- The first vim.ui.select call (e.g. code actions) loads telescope and uses its picker
  local select_probe = [[lua vim.ui.select({ "a" }, {}, function() end)
    io.stdout:write(debug.getinfo(vim.ui.select, "S").source)]]
  local res4 = vim.system({ "nvim", "--headless", "-i", "NONE", "+" .. select_probe, "+qa!" }, { text = true }):wait(30000)
  check("first vim.ui.select loads telescope's ui-select",
    (res4.stdout or ""):find("telescope%-ui%-select") ~= nil, (res4.stdout or "") .. (res4.stderr or ""))
end
