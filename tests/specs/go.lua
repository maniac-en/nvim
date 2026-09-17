-- tests/specs/go.lua
-- gopls, organize imports + format on save, golangci-lint, Go buffer keymaps.
return function(T)
  local check = T.check

  T.go_module("go")
  T.write("go/main.go", {
    "package main",
    "",
    "func main() {",
    '  os.Remove("a")', -- missing import + bad indent + unchecked error
    '\tfmt.Println("hi")',
    "}",
  })
  local buf = T.open("go/main.go")
  check("gopls attaches", T.wait_client(buf, "gopls"), vim.inspect(T.client_names(buf)))

  T.formats = 0
  vim.cmd("silent write")
  local src = T.text(buf)
  check("save adds missing imports", src:find('"fmt"', 1, true) and src:find('"os"', 1, true), src)
  check("save formats (gofumpt indent)", src:find("\n\tos.Remove", 1, true) ~= nil, src)
  check("formatted exactly once per save", T.formats == 1, "format calls: " .. T.formats)

  local got_errcheck = vim.wait(60000, function() return T.diag_sources(buf).errcheck end, 250)
  check("golangci-lint reports issues after save", got_errcheck, vim.inspect(T.diag_sources(buf)))

  -- Compile error: gopls reports it; golangci-lint's "typecheck" copy is filtered
  local l = T.lines(buf)
  table.insert(l, #l, "\tx := 1")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, l)
  vim.cmd("silent write")
  vim.wait(60000, function() return T.diag_sources(buf).compiler end, 250)
  vim.wait(5000, function() return #require("lint").get_running(buf) == 0 end, 100)
  vim.wait(1000)
  local sources = T.diag_sources(buf)
  check("gopls reports compile error", sources.compiler, vim.inspect(sources))
  check("golangci-lint typecheck duplicates filtered", not sources.typecheck, vim.inspect(sources))

  for _, lhs in ipairs({ "<leader>r", "<leader>tt", "<leader>tm", "grd", "grr", "grs", "K" }) do
    check("buffer keymap " .. lhs, T.has_buf_map(buf, "n", lhs))
  end
end
