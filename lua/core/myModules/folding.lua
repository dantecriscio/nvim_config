local map = require("utils.map").map
local alpabetical_key_map_modes = require("utils.map").alpabetical_key_map_modes
local is_normal_file_buffer = require("utils.buffers").is_normal_file_buffer

local function open_all_folds()
	vim.opt.foldlevel = 99
end
local function close_all_folds()
	vim.opt.foldlevel = 0
end

-- Start with folds completely open for all files
open_all_folds()

map(alpabetical_key_map_modes, "ze", "]z")
map(alpabetical_key_map_modes, "zb", "[z")
map(alpabetical_key_map_modes, "zR", open_all_folds)
map(alpabetical_key_map_modes, "zM", close_all_folds)

-- Set custom text which appears whenever we have a fold
function _G.MyFoldText()
	local first_line = vim.fn.getline(vim.v.foldstart)

	-- Removes leading whitespaces
	local last_line = vim.fn.getline(vim.v.foldend):gsub("^%s*", "")
	local line_count = vim.v.foldend - vim.v.foldstart

	local fold_message = " +--- " .. line_count .. " lines ---+ "
	if line_count == 1 then
		fold_message = fold_message:gsub("lines", "line")
	end

	-- Edge case, where a language parser decides that a single line is a fold
	if line_count == 0 or

		-- Specific languages can define this method
		-- For example, python will check if the first line ends with ":"
		-- If it does, then don't include the last line in the fold
		vim.b.fold_last_line and
		vim.b.fold_last_line(vim.v.foldstart, vim.v.foldend) == false
	then
		last_line = ""
	end

	local fold_text = first_line .. fold_message .. last_line

	-- Turn tabs into appropriate number of spaces
	-- If we don't do this, the foldtext turns 1 tab into 1 space
	local tab_spaces = string.rep(" ", vim.o.ts)
	return fold_text:gsub("\t", tab_spaces)
end

vim.opt.foldtext = "v:lua.MyFoldText()"

-- Get rid of trailing dots that vim automatically adds in
vim.opt.fillchars:append({ fold = " " })

-- Automatically remembers folds after closing and reopening
local remember = vim.api.nvim_create_augroup("remember", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
  group = remember,
  callback = function (args)
  	if is_normal_file_buffer(args.buf) then
		vim.cmd("mkview")
	end
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  group = remember,
  callback = function (args)
  	if is_normal_file_buffer(args.buf) then
		-- `silent!`
		-- If first time ever opening buffer and view file doesn't exist

		-- `noautocmd`
		-- For some dumb reason, view-files end with `doautoall SessionLoadPost`
		-- This breaks the barbar plugin, since it will then reset the tab order
		-- It also makes no sense, as View and Sessions are different conceptually
		vim.cmd("silent! noautocmd loadview")
	end
  end,
})

local M = {}

function M.setup_syntax_folding()
	vim.wo[0][0].foldmethod = "syntax"
end

function M.setup_treesitter_folding()
	-- These options come from Treesitter's README on how to set up folding
	vim.wo[0][0].foldmethod = "expr"
	vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"

	--[[
	TODO: Investigate multiple strange bugs from the `foldexpr` line which only seems to apply on Amazon Linux.
	I blame the foldexpr because the bugs only started once I migrated to Neovim 0.12 and changed the foldexpr.

	When restoring folds from a view-file - with or without a session - syntax folds work (JSON files) but treesitter don't:
		- With a session:
			- The treesitter file types ignore the view and begin with all the folds open.
			- Subsequent folding works.
		- Without a session:
			- The treesitter file types ignore the view and begin with all the folds open.
			- Subsequent folding does not work. It complains with `E490: No fold found`.

	Some debugging work (which went nowhere) was to look at an example view-file which gets generated:
	````
	setlocal foldmethod=expr
	setlocal foldexpr=v:lua.vim.treesitter.foldexpr()
	setlocal foldmarker={{{,}}}
	setlocal foldignore=#
	setlocal foldlevel=99
	setlocal foldminlines=1
	setlocal foldnestmax=20
	setlocal foldenable
	10
	sil! normal! zc
	````

	Note that `foldlevel=99` is also set prior in this lua file, which gets sourced by init.lua.
	Also the foldmethod and foldexpr are set in this lua file, which gets sourced by ftplugin.
	So there is some redundant behavior here.
	However, none of that helps to explain why the `zc` line isn't working.
	It also doesn't explain why no folds are found in the case without a session.

	All of this is mysterious, and applies on Amazon Linux but not on Fedora 44 or Mac.
	]]
end

return M
