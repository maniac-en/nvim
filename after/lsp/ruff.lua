-- after/lsp/ruff.lua
-- Linting, formatting and organize-imports for Python. Rule selection comes
-- from the project's pyproject.toml/ruff.toml (ruff defaults otherwise).
return {
  on_attach = function(client, _)
    -- Disable hover in favor of basedpyright
    client.server_capabilities.hoverProvider = false
  end,
  capabilities = {
    general = {
      -- match basedpyright (utf-16 only) to avoid mixed offset encodings
      positionEncodings = { "utf-16" },
    },
  },
}
