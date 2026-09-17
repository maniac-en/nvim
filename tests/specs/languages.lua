-- tests/specs/languages.lua
-- The other languages: server attaches, linters, format-on-save rules.
return function(T)
  local check = T.check

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
    T.write("misc/" .. case.file, case.content)
    local buf = T.open("misc/" .. case.file)
    check(("%s: %s attaches"):format(case.file, case.server), T.wait_client(buf, case.server),
      vim.inspect(T.client_names(buf)))
    if case.linter then
      local got = vim.wait(10000, function() return T.diag_sources(buf)[case.linter] end, 100)
      check(("%s: %s reports"):format(case.file, case.linter), got, vim.inspect(T.diag_sources(buf)))
    end
    if case.format ~= nil then
      if case.format then T.wait_formatter(buf) else vim.wait(2000) end
      local before = T.text(buf)
      vim.cmd("silent write")
      local changed = T.text(buf) ~= before
      check(("%s: %s on save"):format(case.file, case.format and "formatted" or "not formatted"),
        changed == case.format, T.text(buf))
    end
  end

  -- :make fills the quickfix list (compiler plugins set makeprg + errorformat)
  T.write("mk/go/go.mod", { "module example.com/mk", "", "go 1.21" })
  local makes = {
    {
      file = "mk/go/main.go",
      ft = "go",
      content = { "package main", "", "func main() { undefinedFn() }" },
      first = { lnum = 3, text = "undefined: undefinedFn" }
    },
    {
      file = "mk/py/a.py",
      ft = "python",
      content = { "import os" },
      first = { lnum = 1, text = "`os` imported but unused" }
    },
    {
      file = "mk/sh/b.sh",
      ft = "sh",
      content = { "if true; then" },
      first = { lnum = 2, text = "syntax error" }
    },
    {
      file = "mk/c/c.c",
      ft = "c",
      content = { "int main(){ return x; }" },
      first = { lnum = 1, text = "undeclared" }
    },
  }
  for _, case in ipairs(makes) do
    T.write(case.file, case.content)
    T.open(case.file)
    vim.cmd.lcd(vim.fn.expand("%:p:h"))
    vim.fn.setqflist({}, "r")
    local ok = pcall(function() vim.cmd("silent make!") end)
    local entries = vim.tbl_filter(function(e) return e.valid == 1 end, vim.fn.getqflist())
    local first = entries[1]
    check((":make on a broken %s file fills the quickfix list"):format(case.ft),
      ok and first ~= nil and first.lnum == case.first.lnum and first.text:find(case.first.text, 1, true) ~= nil,
      ("makeprg=%s entries=%d first=%s"):format(vim.o.makeprg, #entries,
        first and first.lnum .. ": " .. first.text or "-"))
  end
  vim.cmd.lcd(T.root)
end
