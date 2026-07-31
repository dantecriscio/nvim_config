local treesitter = require("utils.treesitter")
local folding = require("core.myModules.folding")
local find_project_root = require("utils.paths").find_project_root
local lsp = require("lsp.serverCommon")

treesitter.setup_highlighting()
treesitter.setup_indentation()
folding.setup_treesitter_folding()

--- Lua is strange, it likes to start its root directory at a lua/ dir
--- However, the init.lua file lives outside of this lua/ dir
--- So, we cannot just find the root by looking upwards for "lua/"
--- If we did this, and started at init.lua, we would never find the root
---
--- The solution is to find the project root by looking upwards for ".git"
--- Then, we check if a ./lua/ dir exists, and if so that becomes our root
--- @param starting_dir string directory to start looking for "lua/"
--- @return string lua_root_dir "lua/" directory if found, otherwise the starting_dir
local function resolve_lua_root_dir(starting_dir)
	for name, type in vim.fs.dir(starting_dir) do
		if name == "lua" and type == "directory" then
			return starting_dir .. "lua/"
		end
	end

	return starting_dir
end

local project_root_dir, is_single_file = find_project_root()
local lua_root_dir = resolve_lua_root_dir(project_root_dir)

lsp.start_or_attach("luaServer", lua_root_dir, is_single_file)
lsp.start_or_attach("cspellServer", project_root_dir, is_single_file)
