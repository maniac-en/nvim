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
