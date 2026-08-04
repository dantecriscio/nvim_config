local is_normal_file_buffer = require("utils.buffers").is_normal_file_buffer
local get_buffer_ids = require("utils.buffers").get_buffer_ids
local set_default_display = require("core.myModules.hudKeymaps").set_default_display

local session_group = vim.api.nvim_create_augroup("sessions", { clear = true })

-- If vim was called with any arguments, set the default hud and then return
if vim.v.argv[3] ~= nil then
	vim.api.nvim_create_autocmd({ "VimEnter" }, {
		group = session_group,
		callback = set_default_display
	})

	return
end

local hud = require("core.myModules.headsUpDisplay")
local paths = require("utils.paths")

-- Make sure the the desired directory exists
vim.fn.mkdir(paths.Sessions, "p")

-- Session loads and restores should only depend on the initial cwd
local initial_directory = vim.fn.getcwd()

local session_path = paths.Sessions .. paths.serialize_path(initial_directory)
    .. "_session.vim"
local hud_path = paths.Sessions .. paths.serialize_path(initial_directory)
    .. "_hud.lua"

local function unlist_undesired_buffers()
	local undesired_buffer_filer = function(bufnr)
		return not is_normal_file_buffer(bufnr)
	end
	for _, bufnr in ipairs(get_buffer_ids(undesired_buffer_filer)) do
		vim.bo[bufnr].buflisted = false
	end


end

local function save_hud()
    local hud_file = io.open(hud_path, "w")
    if hud_file ~= nil then
        for display_name, display in pairs(hud) do
            hud_file:write(display_name .. "=" ..
                tostring(display.is_shown()) .. "\n")
        end
        hud_file:flush()
        hud_file:close()
    end
end

local function save_session()
    -- Save barbar order of buffers
    vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" })

    -- Actually save the session file
    vim.cmd("mks! " .. vim.fn.fnameescape(session_path))
end

local function restore_hud()
    if vim.fn.filereadable(hud_path) == 0 then
        set_default_display()
        return
    end

    local hud_file = io.open(hud_path, "r")
    if hud_file ~= nil then
        for line in hud_file:lines() do
            local equal_index = string.find(line, "=")
            local display_name = line:sub(0, equal_index - 1)
            local display_shown = line:sub(equal_index+1)

            if display_shown == "true" then
                hud[display_name]:show()
            end
            if display_shown == "false" then
                hud[display_name]:hide()
            end
        end

        hud_file:close()
    end
end

local function restore_session()
    if vim.fn.filereadable(session_path) == 0 then
        return
    end

    -- Actually restore the session file
    vim.cmd("silent! source " .. vim.fn.fnameescape(session_path))
end


vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
	group = session_group,
	callback = function()
		-- Prevents scratch buffers and de-compiled buffers from being saved
		unlist_undesired_buffers()

        save_hud()
        save_session()
	end,
})

vim.api.nvim_create_autocmd({ "VimEnter" }, {
	group = session_group,
	callback = function()
        restore_hud()
        restore_session()
	end,

    -- Need this because the barbar plugin waits for the SessionLoadPost event
    -- to restore the buffer order
	nested = true,
})

