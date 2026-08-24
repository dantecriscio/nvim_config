local paths = require("utils.paths")

local lazy_path = paths.Data_Path .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazy_path) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=v11.17.5",
		lazy_path,
	})
end
vim.opt.rtp:prepend(lazy_path)

require("lazy").setup({
	{ import = "plugins" },
})
