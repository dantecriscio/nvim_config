local mason_bin = require("utils.paths").Mason_Bin

--- @return ServerConfig
local function get_server_config(_)

	--- @type ServerConfig
	local server_config = {
		cmd = { mason_bin .. "rust-analyzer" },

		single_file_support = true,

		-- https://rust-analyzer.github.io/book/configuration.html
		post_init_settings = {
			['rust-analyzer'] = {
				--[[
				As per rust-analyzer.github.io/book/diagnostics.html, the LSP server comes with 2 sources of diagnostics:
				1. Native Diagnostics
				    - Works how most LSP servers work
					- It gets updates about the contents of the buffer, processes the content in memory, and reports diagnostics
					- Doesn't require me to save the file for it it work
					- Very fast
				2. Integration with `cargo check`
					- Reaches out to an external process
					- Requires me to save the file for it to work
					- Slower

				I dislike 2, because I don't like things which require me to save the file.
				Also, if both are running, they sometimes report essentially the exact same diagnostic,
				so the diagnostic messages can feel redundant.
				--]]

				-- If true, runs "cargo check" on save for extra diagnostics
				-- Manually disable
				checkOnSave = false,

				-- Makes the Native Diagnostics own the work of catching more bugs.
				-- It is still experimental, but I like it so far.
				diagnostics = {
					experimental = {
						enable = true,
					}
				},
			},
		},
	}

	return server_config
end

return get_server_config
