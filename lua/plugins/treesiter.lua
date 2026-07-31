return {
	{
		"nvim-treesitter/nvim-treesitter",
		-- Important to use a commit which is on the branch "main" rather than "master"
		-- Currently no tags point to that branch
		commit = "7248feaca45e4d944591497964bc19afa89ad1c6",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").install({
				-- Lua is automatically installed by neovim without this plugin
				-- Can view the currently installed parsers by running:
				-- `vim.api.nvim_get_runtime_file('parser/*', true)`
				"python",
				"java",
				"html",
				"css",
				"javascript",
				"typescript",
				"rust",
				"swift",
			})
		end,
	},
}
