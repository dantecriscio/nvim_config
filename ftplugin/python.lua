local treesitter = require("utils.treesitter")
local folding = require("core.myModules.folding")
local find_project_root = require("utils.paths").find_project_root
local lsp = require("lsp.serverCommon")

treesitter.setup_highlighting()
treesitter.setup_indentation()
folding.setup_treesitter_folding()

local root_dir, is_single_file = find_project_root()

lsp.start_or_attach("pythonServer", root_dir, is_single_file)
lsp.start_or_attach("cspellServer", root_dir, is_single_file)

-- Check if the first line of a fold ends with ":"
-- If it does, then don't include the last line in the fold text
vim.b.fold_last_line = function(fold_start_number, _)
	return vim.fn.getline(fold_start_number):sub(-1, -1) ~= ":"
end

-- Run command
vim.b.run_command = 'python "' .. vim.fn.expand("%:p") .. '"'
