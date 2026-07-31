local default_key_map_modes = require("utils.map").default_key_map_modes

return {
	{
		-- This author doesn't seem to use tags, so use the commits instead
		"windwp/nvim-autopairs",
		commit = "de4f7138a68d5d5063170f2182fd27faf06b0b54",
		event = "InsertEnter",
		opts = {},
	},
	{
		"windwp/nvim-ts-autotag",
		commit = "88c1453db4ba7dd24131086fe51fdf74e587d275",
		event = "InsertEnter",
		opts = {
			enable_rename = false,
			enable_close = true,
			enable_close_on_slash = true,
			filetypes = { "html", "xml" },
		},
	},
	{
		"numToStr/Comment.nvim",
		tag = "v0.8.0",
		opts = {},
		keys = {
			{
				"C",
				function()
					require("Comment.api").toggle.linewise.current()
				end,
				mode = { "n", "o" },
			},
			{
				"C",
				"<Plug>(comment_toggle_linewise_visual)gv",
				mode = "x"
			},

			-- "cm" is supposed to be short for "comment multi-line"
			{
				"<leader>cm",
				function()
					require("Comment.api").toggle.blockwise.current()
				end,
				mode = { "n", "o" },
			},
			{
				"<leader>cm",
				"<Plug>(comment_toggle_blockwise_visual)gv",
				mode = { "x", "s" },
			},

			{
				"<leader>ck",
				function()
					require("Comment.api").insert.linewise.above()
				end,
				mode = default_key_map_modes,
			},
			{
				"<leader>cj",
				function()
					require("Comment.api").insert.linewise.below()
				end,
				mode = default_key_map_modes,
			},
			{
				"<leader>cl",
				function()
					require("Comment.api").insert.linewise.eol()
				end,
				mode = default_key_map_modes,
			},
		},
	},
}
