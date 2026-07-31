local alpabetical_key_map_modes = require("utils.map").alpabetical_key_map_modes

--[[ Fixes a strange issue with neovim folding
Folds are computed initially, but not recomputed after the buffer is modified

For example, lets say we open a new buffer with the following lines:
	1  if true then
	2      x = 1
	3  end
Then vim will correctly compute that lines 1-3 should be folded,
assuming we are using the syntax or expr (treesitter) folding methods.

But, lets say we add a new line in the middle:
	1  if true then
	2      x = 1
	3      y = 2
	4  end
Still, vim will think that only lines 1-3 should be folded.
This leads to an incorrect and confusing fold:

One way to fix this is to save the buffer, and then reload with :e
But usually we do not want to save just because we are folding!

A strange solution is that updating the foldmethod with
vim.o.foldmethod = "method" will force vim to recompute folds.
This even works if we set the option to its current value!

We use this trick before all folding keybinds]]

-- Assume that lhs and rhs are both strings
-- We will wrap the rhs in a folding reset
local function fold_keymap(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, function()
		local method = vim.o.foldmethod
		vim.cmd("setlocal foldmethod="..method)

		-- The exclamation point means to not use remappings
		-- No exclamation point would be infinite recursion,
		-- and would which would crash vim
		vim.cmd("normal! " .. rhs)
	end, options)
end

fold_keymap(alpabetical_key_map_modes, "ze", "]z")
fold_keymap(alpabetical_key_map_modes, "zb", "[z")

fold_keymap(alpabetical_key_map_modes, "za", "za")
fold_keymap(alpabetical_key_map_modes, "zo", "zo")
fold_keymap(alpabetical_key_map_modes, "zO", "zO")
fold_keymap(alpabetical_key_map_modes, "zc", "zc")
fold_keymap(alpabetical_key_map_modes, "zC", "zC")
fold_keymap(alpabetical_key_map_modes, "zR", "zR")
fold_keymap(alpabetical_key_map_modes, "zM", "zM")

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
local function remember_folding_autocmds()
	vim.api.nvim_create_autocmd({ "BufWinLeave", "BufWritePost" }, {
		buffer = 0,
		group = remember,
		command = "noautocmd silent! mkview",
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
		buffer = 0,
		group = remember,
		callback = function()
			vim.cmd([[
				normal zR
				noautocmd silent! loadview
			]])
		end,
	})
end

local M = {}

function M.setup_syntax_folding()
	vim.wo[0][0].foldmethod = "syntax"
	vim.cmd("setlocal foldmethod=syntax")

	remember_folding_autocmds()
end

function M.setup_treesitter_folding()
	-- These options come from Treesitter's README on how to set up folding
	vim.wo[0][0].foldmethod = "expr"
	vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"

	remember_folding_autocmds()
end

return M
