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
}
