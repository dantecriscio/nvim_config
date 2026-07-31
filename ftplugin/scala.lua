local folding = require("core.myModules.folding")
local find_project_root = require("utils.paths").find_project_root
local lsp = require("lsp.serverCommon")

-- Treesitter has a parser for this, but it doesn't support folding
-- So I didn't install it, and prefer to use syntax for everything
folding.setup_syntax_folding()

local root_dir, is_single_file = find_project_root()
lsp.start_or_attach("scalaServer", root_dir, is_single_file)
lsp.start_or_attach("cspellServer", root_dir, is_single_file)
