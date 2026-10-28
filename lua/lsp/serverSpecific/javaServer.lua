local paths = require("utils.paths")
local os_type = require("utils.os_type")
local architecture = require("utils.architecture")

local jdtls_dir = paths.Mason_Path .. "packages/jdtls/"

local function get_base_os_config()
	if os_type.is_linux_os then
		return "config_linux"
	end
	if os_type.is_macos then
		return "config_mac"
	end
	if os_type.is_wsl then
		return "config_ss_linux"
	end
	if os_type.is_windows then
		return "config_win"
	end

	error("Could not determine os to use for JDTLS config")
end

local function get_os_config()
	-- For some reason, the distribution of jdtls through mason does not come with config_win_arm
	local base_os_config = get_base_os_config()

	if architecture.is_arm and not os_type.is_windows then
		return base_os_config .. "_arm"
	end

	return base_os_config
end

local os_config = get_os_config()

--- @return string
local function get_launcher_file()
	-- Essentially do a regex search on a directory to find this jar file
	-- Returns a non-empty string for success, empty string for failure
	local glob_result = vim.fn.globpath(jdtls_dir .. "plugins", "*launcher_*")

	if (glob_result == "") then
		error("Could not determine launcher file to use for JDTLS config")
	end

	return glob_result
end

local launcher_file = get_launcher_file()

--- Very proud of how I handled this.
--- Creates data directories under a new folder in the Data_Dir.
--- Makes a new, nicely named folder, for each different project.
--- Has a "catch-all" folder for files that are not part of a project.
--- @param server_config_params ServerConfigParams
--- @return string inferred_data_dir
local function resolve_data_dir(server_config_params)
	if server_config_params.is_single_file then
		return paths.Java_Workspaces .. "NonProjectDataDir"
	end

	return paths.Java_Workspaces .. paths.serialize_path(server_config_params.root_dir)
end

--- @param server_config_params ServerConfigParams
--- @return ServerConfig
local function get_server_config(server_config_params)

	--- @type ServerConfig
	local server_config = {
		cmd = {
			"java", -- or '/path/to/java21 (only version I've had success with)

			"-Declipse.application=org.eclipse.jdt.ls.core.id1",
			"-Dosgi.bundles.defaultStartLevel=4",
			"-Declipse.product=org.eclipse.jdt.ls.core.product",
			"-Dlog.protocol=true",
			"-Dlog.level=ALL",
			"-Xmx1g",
			"--add-modules=ALL-SYSTEM",
			"--add-opens",
			"java.base/java.util=ALL-UNNAMED",
			"--add-opens",
			"java.base/java.lang=ALL-UNNAMED",

			-- Add lombok support
			"-javaagent:" .. jdtls_dir .. "lombok.jar",

			-- This will depend on the version of jdtls installed
			"-jar",
			launcher_file,

			-- This will depend on the machine os
			"-configuration",
			jdtls_dir .. os_config,

			"-data",
			resolve_data_dir(server_config_params),
		},

		-- Having false allows single files to still run JDTLS with full capabilities
		-- Having true means that single files will always see the diagnostic:
		-- <FileName.java> is a non-project file, only syntax errors are reported
		single_file_support = false,

		-- Here you can configure eclipse.jdt.ls specific settings
		-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
		-- For some reason, `bundles` and `workspaceFolders` work for the init_options but `settings` does not.
		-- As such these `settings` only work if they are sent to the server after initialization.
		init_options = {
			-- https://github.com/microsoft/java-debug does not have a "public static void main()" method
			-- This means that it cannot easily be invoked as a standalone debugger from the commandline
			-- Instead, it is designed to get bundled with jdtls, and jdtls starts the process
			bundles = {
				paths.Mason_Path .. "share/java-debug-adapter/com.microsoft.java.debug.plugin.jar",
			},

			-- Add workspaceFolders here if working on multiple projects at once
			-- workspaceFolders = {
			--
			-- },

			-- Copied from nvim-jdtls, which has this capability and many more
			extendedClientCapabilities = {
				-- Gives extra code action capabilities, and ability to "gd" into class files
				classFileContentsSupport = true,
			},

			settings = {
				java = {
					autobuild = {
						-- Don't try to build the project automatically
						-- Let me decide when to run the build commands
						enabled = false,
					},

					-- Documentation above is outdated, it is `imports` rather than `import`
					imports = {
						gradle = {
							-- If true, will run run gradle buildship on startup (auto-generates .classpath file based on gradle config)
							-- Set to false if you don't want .classpath files being overwritten
							-- Set to true if making a simple gradle project, and this auto-generation is helpful
							-- A really great alternative is to force jdtls to import as an eclipse project before gradle:
							-- https://github.com/eclipse-jdtls/eclipse.jdt.ls/issues/257#issuecomment-350598939
							enabled = true,
						},
					},
				},
			},
		},

		-- For some reason, some portion of the documented settings above need to run after initialization
		post_init_settings = {
			java = {
				format = {
					-- By default will insert tabs by whenever the "create method" code action is used
					-- Instead use spaces, since Java Checkstyle linter prefers spaces
					insertSpaces = true,
				},
			},
		},
	}

	return server_config
end

return get_server_config
