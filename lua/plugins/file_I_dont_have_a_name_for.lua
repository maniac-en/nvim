-- lua/plugins/file_I_dont_have_a_name_for.lua
-- Small plugins that don't need a file of their own

return {
  -- recall the last cursor position (must be loaded before files are read)
  { "farmergreg/vim-lastplace" },
  -- add/delete/update surroundings in pairs
  { "tpope/vim-surround",          event = "VeryLazy" },
  -- better dot repeats
  { "tpope/vim-repeat",            event = "VeryLazy" },
  -- some handy maps
  { "tpope/vim-unimpaired",        event = "VeryLazy" },
  -- flow state reading
  { "nullchilly/fsread.nvim",      cmd = { "FSRead", "FSClear", "FSToggle" } },
  -- devicons (loaded by the plugins that use it)
  { "nvim-tree/nvim-web-devicons", lazy = true },
}
