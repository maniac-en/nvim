-- lua/plugins/init.lua
return {
	-- Core functionality (load first for better startup experience)
	require("plugins.editor"), -- Editor enhancements (sleuth, undotree, cloak)

	-- UI and appearance (load early to provide consistent appearance)
	require("plugins.paint"), -- Must be high priority

	-- Git integration
	require("plugins.git"), -- Git integration (fugitive, gitsigns)

	-- File navigation and search
	require("plugins.oil"), -- File manager
	require("plugins.telescope"), -- Fuzzy finder

	-- Language and syntax handling
	require("plugins.treeshitter"), -- Syntax highlighting (load before LSP)
	require("plugins.lsp"),     -- Language server configurations (load before telescope)
	require("plugins.completion"), -- Completion (nvim-cmp)
	require("plugins.langtools"), -- Language-specific tools and runners

	-- Database tools
	require("plugins.squeel"),

	-- Other plugins with no specific dependencies
	require("plugins.plugins_with_no_config"),
}
