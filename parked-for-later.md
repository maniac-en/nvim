# Parked for later

Things deliberately postponed. Pick one up when it becomes a real need.

## HTML format on save
- **Now:** `html` is excluded from format-on-save (`no_format_on_save` in
  `lua/plugins/lsp/autocmds.lua`). The html language server still gives
  completion and diagnostics.
- **Why parked:** HTML often embeds other languages (JS, CSS, template syntax),
  so formatting it well is a separate task.
- **To revisit:** decide how to format HTML with its embedded languages, then
  remove `html` from `no_format_on_save`.

## Fork rest.nvim to fix deprecated `vim.validate` usage
- **Now:** rest.nvim (upstream `714d551`, Dec 2025, no activity since) calls
  `vim.validate` with the old table form in `lua/rest-nvim/config/check.lua`.
  It works today; `:checkhealth vim.deprecated` reports it. The smoke test
  tolerates this one known warning (`known_deprecations` in `tests/lib.lua`).
- **Why parked:** nothing breaks until Neovim 1.0 removes the old form.
- **To revisit:** fork rest.nvim, switch to `vim.validate(name, value, type)`
  calls, point `lua/plugins/rest.lua` at the fork, then remove the rest.nvim
  entry from `known_deprecations` in `tests/lib.lua`.

## Switch the AI commit script from Gemini to Claude
- **Now:** `:AiCommit` (`ftplugin/gitcommit.lua`) runs `~/.local/bin/ai-commit-msg.sh`
  (outside this repo). That script calls the Gemini API (`gemini-2.0-flash`, via
  `curl`, with `GEMINI_API_KEY`) and writes the message into the commit file.
- **Why parked:** it's a change to an external script, separate from the
  Neovim config work.
- **To revisit:** point the script at Claude (e.g. the Anthropic Messages API
  with `ANTHROPIC_API_KEY`, or the `claude` CLI), keeping the same contract:
  takes the commit file path, writes the message into it, exits non-zero on
  failure. `:AiCommit` itself shouldn't need changes.

## Revisit plugins that Neovim 0.12 partly covers (after a few weeks of use)
Kept during the 0.12 refresh because they have extras you may rely on without
remembering. If you never reach for the extras, swap to the built-in and drop
the plugin.
- **undotree** (`<leader>u`): built-in `:Undotree` (`packadd nvim.undotree`)
  covers browsing undo history; you'd lose the diff panel
  (`undotree_DiffAutoOpen`).
- **vim-unimpaired**: 0.11+ built-ins cover `[q ]q [b ]b [l ]l [a ]a [t ]t
  [<Space> ]<Space>`; you'd lose `yo*` option toggles, `[e ]e` line exchange,
  `[x ]x` encoding.
- **workspace-diagnostics.nvim**: pre-opens git-tracked files so servers report
  project-wide diagnostics (skipped for basedpyright). Built-in alternative:
  `:lua vim.lsp.buf.workspace_diagnostics()` on demand, where the server
  supports it.
