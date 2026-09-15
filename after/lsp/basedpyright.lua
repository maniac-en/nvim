-- after/lsp/basedpyright.lua
-- Type checker for completion/hover/navigation; its diagnostics are silenced
-- (ruff handles linting)
return {
  settings = {
    basedpyright = {
      -- ruff provides the organize-imports code action
      disableOrganizeImports = true,
      analysis = {
        ignore = { "*" }, -- suppress basedpyright diagnostics for all files
        logLevel = "Information",
        autoImportCompletions = true,
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "standard",
        useLibraryCodeForTypes = true,
      },
    },
  },
}
