local find_project_root = require("utils.paths").find_project_root
local lsp = require("lsp.serverCommon")

local root_dir, is_single_file = find_project_root()
lsp.start_or_attach("cspellServer", root_dir, is_single_file)
