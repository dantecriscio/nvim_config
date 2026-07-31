local map = require("utils.map").map
local dap_utils = require("utils.dapUtils")
local java_utils = require("utils.javaUtils")
local treesitter = require("utils.treesitter")
local folding = require("core.myModules.folding")
local lsp = require("lsp.serverCommon")

-- Begin this file with some low-hanging fruit
-- Setup auto-commands and buffer-local preferences
-- These work the same for either source java files or class files
treesitter.setup_highlighting()
treesitter.setup_indentation()
folding.setup_treesitter_folding()

-- Use 4 spaces instead of tabs (Java Checkstyle linter prefers spaces)
vim.bo[0].tabstop = 4
vim.bo[0].shiftwidth = 4
vim.bo[0].expandtab = true

-- Helper function for highlighting semantic_tokens
local function set_highlight(token, args, highlight_group)
	vim.lsp.semantic_tokens.highlight_token(
		token, args.buf, args.data.client_id, highlight_group
	)
end

local custom_static_non_final = "StaticNonFinal"
vim.cmd.highlight(custom_static_non_final, "guifg=#f7768e")

local custom_non_static_non_final = "NonStaticNonFinal"
vim.cmd.highlight(custom_non_static_non_final, "guifg=#1abc9c")

vim.api.nvim_create_autocmd('LspTokenUpdate', {
	buffer = 0,
	callback = function(args)
		local token = args.data.token

		if token.type == "namespace" and token.modifiers.importDeclaration then
			set_highlight(token, args, "@variable")
			return
		end

		if token.type ~= "property" then
			return
		end

		local final = token.modifiers.readonly
		local static = token.modifiers.static

		if static then
			if final then
				set_highlight(token, args, "Constant")
			else
				set_highlight(token, args, custom_static_non_final)
			end

		else
			if final then
				set_highlight(token, args, custom_non_static_non_final)
			else
				set_highlight(token, args, "@property")
			end
		end
	end,
})

-- Now, worry about starting-up or attaching to a JDTLS instance
-- Also worry about de-compiling class files
local jdtls_root_dir, is_single_file = java_utils.get_jdtls_root_dir()
local bufnr = vim.api.nvim_get_current_buf()
local bufname = vim.api.nvim_buf_get_name(bufnr)

-- Made-up jdt URI
local is_jdt_uri_class_file = vim.startswith(bufname, "jdt://")
-- Normal file path on the filesystem, ending with .class
local is_normal_class_file = vim.endswith(bufname, ".class") and
	not is_jdt_uri_class_file

local function jdtls_start_or_attach()
	return lsp.start_or_attach(
		java_utils.server_config_name,
		jdtls_root_dir,
		is_single_file
	)
end


local function decompile(jdtls_client)
	vim.bo[bufnr].modifiable = true
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].buftype = 'nofile'
	vim.bo[bufnr].buflisted = true

	local content
	local function handler(_, result)
		content = result
		local normalized = string.gsub(result, '\r\n', '\n')
		local source_lines = vim.split(normalized, "\n", { plain = true })
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, source_lines)
	end

	if (is_jdt_uri_class_file) then
		local params = { uri = bufname }
		-- Custom extension of the Language Server Protocol
		-- https://github.com/eclipse-jdtls/eclipse.jdt.ls/wiki/Language-Server-Protocol-Extensions
		jdtls_client:request("java/classFileContents", params, handler, bufnr)
	elseif (is_normal_class_file) then
		local cmd = {
		  command = "java.decompile",
		  arguments = { vim.uri_from_bufnr(bufnr) }
		}
		jdtls_client:request('workspace/executeCommand', cmd, handler, bufnr)
	else
		print("Illegal state in java.lua, decompile() function")
		return
	end

	-- Need to block. Otherwise logic could run that sets the cursor
	-- to a position that's still missing.
	vim.wait(5000, function() return content ~= nil end)

	vim.bo[bufnr].modifiable = false
end

local client
if is_jdt_uri_class_file or is_normal_class_file then
	client = java_utils.get_chosen_lsp_client()
	if client == nil then
		if is_jdt_uri_class_file  then
			print("Error: trying to open a jdt:// URI but no jdtls clients")
			return
		end

		-- Opening a .class file before any .java file is valid
		-- Will start new jdtls client, attach, and use to decompile
		local client_id = jdtls_start_or_attach()

		client = vim.lsp.get_client_by_id(client_id)
		decompile(client)
	else
		decompile(client)
		vim.lsp.buf_attach_client(bufnr, client.id)
	end

-- Handle normal .java files
else
	local client_id = jdtls_start_or_attach()
	client = vim.lsp.get_client_by_id(client_id)

	-- Only normal .java files should have spellchecking
	lsp.start_or_attach(
		"cspellServer",
		jdtls_root_dir,
		is_single_file
	)
end

-- Everything from this point on, assumes that a jdtls client is attached
if client == nil then
	return
end


local full_file_path = vim.fn.expand("%:p")
local java_class_name = vim.fn.expand("%:p:t:r")

-- Setup the run_command for running either a single file or unit test
vim.b.run_command = function()
	if is_single_file then
		local build_cmd = 'javac "' .. full_file_path .. '"'
		local exec_cmd = 'java -cp "' .. jdtls_root_dir .. '" ' .. java_class_name

		if is_jdt_uri_class_file then
			return 'echo "Cannot run jdt:// files"'
		elseif is_normal_class_file then
			return exec_cmd
		else
			return build_cmd .. " && " .. exec_cmd
		end

	else
		local project_root_dir, _ = java_utils.get_project_root_dir()
		local cd_cmd = 'cd "' .. project_root_dir .. '"'

		local run_ut_cmd = "gradle --rerun-tasks test --tests " .. java_utils.get_full_method_path()

		local path_to_html_ut_results = project_root_dir .. "build/reports/tests/test/index.html"
		local echo_html_cmd = 'echo "Unit Test Results are available at: ' .. path_to_html_ut_results .. '"'

		return "( " .. cd_cmd .. " && " .. run_ut_cmd .. " && " .. echo_html_cmd .. " )"
	end
end

local function custom_debug_run()
	local dap = require("dap")
	if dap.session() ~= nil then
		dap.continue()
		return
	end

	java_utils.start_debug(client)
end



-- TODO: Move most of these to a common place
-- Just the first two might need to be language-specific
-- Do this once there is a second language I want to debug
map("", "<leader>dr", custom_debug_run)
-- x for execution (where the debugee is being executed)
map("", "<leader>dx", function()
	local terminal_plugin = require("toggleterm.terminal")
	local found_debugee_terminal = terminal_plugin.find(function(term)
		return term.display_name == java_utils.terminal_display_name
	end)
	if found_debugee_terminal == nil then
		print("Could not find terminal with display name", java_utils.terminal_display_name)
		return
	end
	found_debugee_terminal:open()
end)

map("", "<leader>dt", function()
	dap_utils.terminate_and_cleanup()
end)
map("", "<leader>db", function() require("dap").toggle_breakpoint() end)
map("", "<leader>dg", function()
	require("dap").list_breakpoints()
	vim.cmd("copen")
end)
map("", "<leader>dn", function() require("dap").clear_breakpoints() end)

map("", "<leader>dj", function() require("dap").step_over() end)
map("", "<leader>dk", function() require("dap").step_back() end)
map("", "<leader>dh", function() require("dap").step_out() end)
map("", "<leader>dl", function() require("dap").step_into() end)

map("", "<leader>df", function() require("dap").focus_frame() end)
map("", "<leader>da", function() require("dap").run_to_cursor() end)

-- v for "variables in scope"
map("", "<leader>dv", function()
	dap_utils.open_or_create_widget("sidebar", "scopes", "40 vsplit")
end)
-- s for "stacktrace"
map("", "<leader>ds", function()
	dap_utils.open_or_create_widget("sidebar", "frames", "15 split")
end)
-- m for "multi-threading"
map("", "<leader>dm", function()
	dap_utils.open_or_create_widget("sidebar", "threads", "15 split")
end)
-- c for "console (interactive)"
map("", "<leader>dc", function()
	local _, win_id = require("dap").repl.open()
	vim.api.nvim_set_current_win(win_id)
end)

