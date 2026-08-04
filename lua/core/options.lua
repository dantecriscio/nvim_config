-- Many of these options get overwritten by
-- editorconfig.lua (a lua file built in to neovim)
-- Useful to read the file, but I don't like it overwriting my values
vim.g.editorconfig = false

vim.opt.background = "dark"

-- Don't automatically make the next line a comment if the current line is
vim.api.nvim_create_autocmd({ "BufEnter" }, {
	callback = function()
		vim.opt.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- Opens new buffers to the right and below
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Make the cursor always be a block (a is for all modes)
vim.api.nvim_create_autocmd({ "BufEnter" }, {
	callback = function()
		vim.opt.guicursor = "a:block"
	end,
})

local function disable_features_in_large_file()
	-- Apply buffer-local options (e.g., disable spell check, set foldmethod)
	vim.opt_local.spell = false
	vim.opt_local.foldmethod = "manual"
	vim.cmd("setlocal syntax=off") -- Disable syntax highlighting
end
local large_file_group = vim.api.nvim_create_augroup("LargeFileActions", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
	group = large_file_group,
	callback = function(args)
		local buf_id = args.buf
		local file_path = vim.api.nvim_buf_get_name(buf_id)
		-- Check file size: vim.fn.getfsize() returns size in bytes, -1 on error
		-- 100 * 1024 bytes = 100 KB
		local file_size = vim.fn.getfsize(file_path)
		if file_size > 100 * 1024 then
			print("Disabling features due to large file with " .. file_size .. " bytes")
			disable_features_in_large_file()
		end
	end,
})

-- Controls how many spaces a tab (indent) turns into
-- These 3 are all buffer local options
-- They can be overwritten within an ftplugin file
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false

-- When a line is wrapped, we continue indent the wrapping to match
vim.opt.breakindent = true

-- All lowercase searches are case insensitive
-- But searches with any uppercase characters are case sensitive
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Neovim 0.11.0 now defaults this option to the string:
-- internal,filler,closeoff,linematch:40
-- linematch:40 breaks gitsigns plugin. Specifically git_signs.preview_hunk()
-- https://github.com/lewis6991/gitsigns.nvim/issues/1278
vim.opt.diffopt = "internal,filler,closeoff"

-- Encountered an issue with Wezterm domains and Neovim
-- Temporarily can fix by disabling this feature
-- The real fix should be upstream in Wezterm
-- https://github.com/wezterm/wezterm/issues/4607
vim.o.termsync = false

-- Default is "folds,cursor,curdir"
-- Remove curdir, this way view files do not update the working directory
-- https://neovim.io/doc/user/options.html#'viewoptions'
vim.opt.viewoptions = "folds,cursor"

-- Default is "blank,buffers,curdir,folds,help,tabpages,winsize,terminal"
-- Remove many things, and add globals
-- https://neovim.io/doc/user/options.html#'sessionoptions'
vim.opt.sessionoptions = "buffers,folds,globals"

-- I always want my statusline to be global
-- laststatus = 0 lies, it shows the statusline with horizontally split windows
-- https://github.com/neovim/neovim/issues/5626#issuecomment-186720136
-- I want to toggle it off globally with laststatus = 4, but that doesn't exist
vim.opt.laststatus = 3

-- The rest of the options (like line numbers and color column) are in:
-- require("core.myModules.hudKeymaps").default_display_preferences() ->
-- require("core.myModules.headsUpDisplay")
