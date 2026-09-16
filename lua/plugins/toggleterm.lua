-- lua/plugins/toggleterm.lua
local key = require("config.map").lazy

return {
  {
    'akinsho/toggleterm.nvim',
    -- no rhs: toggleterm maps <C-\> itself (open_mapping) once loaded
    keys = { key([[<C-\>]], nil, "Terminal", "toggle floating terminal", { mode = { "n", "i" } }) },
    cmd = { "ToggleTerm", "TermExec", "TermSelect", "ToggleTermToggleAll", "ToggleTermSendCurrentLine",
      "ToggleTermSendVisualLines", "ToggleTermSendVisualSelection", "ToggleTermSetName" },
    version = "*",
    config = true,
    opts = {
      open_mapping = [[]],
      start_in_insert = true,
      direction = 'float',
    },
  }
}
