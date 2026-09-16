-- lua/config/map.lua
-- One way to define keymaps across the config. Descriptions always read
-- "Area: [M]nemonic action" (e.g. "Git: [G]it [S]tatus"), so they look the same
-- in :map and in the telescope keymaps picker (<leader>sk).
local M = {}

---@param area string what the mapping is about, e.g. "Search", "LSP", "Git"
---@param text string the action, with [M]nemonic letters, e.g. "[S]earch [H]elp"
---@return string
function M.desc(area, text)
  return area .. ": " .. text
end

--- vim.keymap.set with an "Area: action" description
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param area string
---@param text string
---@param opts? vim.keymap.set.Opts
function M.set(mode, lhs, rhs, area, text, opts)
  opts = vim.tbl_extend("force", {}, opts or {})
  opts.desc = M.desc(area, text)
  vim.keymap.set(mode, lhs, rhs, opts)
end

--- A lazy.nvim `keys` entry with an "Area: action" description. Declaring
--- plugin keymaps this way (instead of inside `config`) means the stub mapping
--- lazy.nvim creates at startup is already described before the plugin loads.
---@param lhs string
---@param rhs? string|function nil: only load the plugin, which maps the key itself
---@param area string
---@param text string
---@param opts? table extra lazy keys fields (mode, silent, expr, ...)
---@return table
function M.lazy(lhs, rhs, area, text, opts)
  return vim.tbl_extend("force", { lhs, rhs, desc = M.desc(area, text) }, opts or {})
end

return M
