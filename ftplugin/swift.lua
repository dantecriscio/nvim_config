local treesitter = require("utils.treesitter")
local folding = require("core.myModules.folding")
local find_project_root = require("utils.paths").find_project_root
local lsp = require("lsp.serverCommon")

treesitter.setup_highlighting()
treesitter.setup_indentation()
folding.setup_treesitter_folding()

local root_dir, is_single_file = find_project_root()
lsp.start_or_attach("swiftServer", root_dir, is_single_file)
lsp.start_or_attach("cspellServer", root_dir, is_single_file)

-- Run command
vim.b.run_command = 'swift "' .. vim.fn.expand("%:p") .. '"'
