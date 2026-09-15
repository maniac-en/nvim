return {
  {
    'akinsho/toggleterm.nvim',
    keys = { { [[<C-\>]], mode = { "n", "i" } } },
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
