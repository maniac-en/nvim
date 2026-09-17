-- lua/plugins/rest.lua
return {
  {
    "rest-nvim/rest.nvim",
    ft = "http",
    cmd = "Rest",
    -- ships its own http parser (luarocks: tree-sitter-http)
  }
}
