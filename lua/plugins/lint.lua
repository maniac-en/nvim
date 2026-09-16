-- lua/plugins/lint.lua
-- Linters that don't come from a language server (ruff/gopls report via LSP)
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "quick-lint-js" },
      typescript = { "quick-lint-js" },
      go = { "golangcilint" },
    }

    -- golangci-lint reports compile errors as "typecheck" issues, pinned to
    -- line 1; gopls already shows them on the right line, so drop them.
    -- Built on first use: loading the linter runs blocking version checks.
    local golangcilint
    lint.linters.golangcilint = function()
      if not golangcilint then
        local base = require("lint.linters.golangcilint")
        golangcilint = vim.tbl_extend("force", base, {
          parser = function(output, bufnr, cwd)
            return vim.tbl_filter(function(d)
              return d.source ~= "typecheck"
            end, base.parser(output, bufnr, cwd))
          end,
        })
      end
      return golangcilint
    end

    -- golangci-lint lints the whole package on disk and blocks briefly while
    -- starting, so it runs on save only; quick-lint-js is fast enough to run
    -- as you edit
    local save_only = { go = true }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd("BufWritePost", {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
      group = lint_augroup,
      callback = function(args)
        if not save_only[vim.bo[args.buf].filetype] then
          lint.try_lint()
        end
      end,
    })

    require("config.map").set("n", "<leader>li", function()
      lint.try_lint()
    end, "Lint", "[L]int current file now")
  end,
}
