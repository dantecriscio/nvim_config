local folding = require("core.myModules.folding")
local find_project_root = require("utils.paths").find_project_root
local lsp = require("lsp.serverCommon")

folding.setup_syntax_folding()

local root_dir, is_single_file = find_project_root()
lsp.start_or_attach("cspellServer", root_dir, is_single_file)

-- Use 2 spaces instead of tabs (jq cli command defaults to this)
vim.bo[0].tabstop = 2
vim.bo[0].shiftwidth = 2
vim.bo[0].expandtab = true
