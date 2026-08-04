local refresh_diagnostics = require('lsp.serverCommon').refresh_diagnostics

--- @class HudElement
---
--- Function which returns whether or not the element is currently visible.
--- Returns nil if the element is part of a plugin it is not loaded yet.
--- Function should use `pcall(require("plugin"))` when dealing with plugins.
--- @field is_shown fun():boolean?
---
--- Function which makes the element become visible.
--- Function should use `pcall(require("plugin"))` when dealing with plugins.
--- @field show fun(self: HudElement):nil
---
--- Function which hides the element, so it is not visible.
--- Function should use `pcall(require("plugin"))` when dealing with plugins.
--- @field hide fun(self: HudElement):nil
---
--- In Neovim, some options are local to the current buffer and window.
--- See https://neovim.io/doc/user/options.html#local-options for more info.
--- The goal of the HUD is to create the illusion of these being global.
--- Autocommands on "BufEnter" are used to create this illusion.
--- This can be used to delete the existing the autocmd and create a new one.
--- @field _autocmd_id integer?

---@param hud_element HudElement
---@param option_name string
---@param value any
local function handle_local_option(hud_element, option_name, value)
	for _, window_id in ipairs(vim.api.nvim_list_wins()) do
		vim.wo[window_id][option_name] = value
	end

	if hud_element._autocmd_id ~= nil then
		vim.api.nvim_del_autocmd(hud_element._autocmd_id)
	end

	hud_element._autocmd_id = vim.api.nvim_create_autocmd({ "BufEnter" }, {
		callback = function(event_args)
			if vim.fn.buflisted(event_args.buf) == 1 then
				vim.opt[option_name] = value
			end
		end,
	})
end

--- @type table<string, HudElement>
local M = {
	tabs = {
		is_shown = function() return vim.o.showtabline ~= 0 end,
		show = function(_) vim.opt.showtabline = 2 end,
		hide = function(_) vim.opt.showtabline = 0 end,
	},

	line_numbers = {
		is_shown = function() return vim.o.number end,
		show = function(self)
			handle_local_option(self, "number", true)
		end,
		hide = function(self)
			handle_local_option(self, "number", false)
		end,
	},

	relative_line_numbers = {
		is_shown = function() return vim.o.relativenumber end,
		show = function(self)
			handle_local_option(self, "relativenumber", true)
		end,
		hide = function(self)
			handle_local_option(self, "relativenumber", false)
		end,
	},

	color_column = {
		is_shown = function() return vim.o.colorcolumn == "80" end,
		show = function(self)
			handle_local_option(self, "colorcolumn", "80")
		end,
		hide = function(self)
			handle_local_option(self, "colorcolumn", "0")
		end,
	},

	git_signs = {
		is_shown = function()
			local gitsigns_ok, _ = pcall(require, "gitsigns")
			if not gitsigns_ok then
				return nil
			end

			return require("gitsigns.config").config.signcolumn
		end,
		show = function(self)
			if self.is_shown() == false then
				vim.cmd("silent! Gitsigns toggle_signs")
			end
		end,
		hide = function(self)
			if self.is_shown() == true then
				vim.cmd("silent! Gitsigns toggle_signs")
			end
		end,
	},

	-- Use this as a vertical buffer for my neck
	-- In case line numbers and git_signs are disabled
	buffer_sign_column = {
		is_shown = function() return vim.o.signcolumn == "yes" end,
		show = function(self)
			handle_local_option(self, "signcolumn", "yes")
		end,
		hide = function(self)
			handle_local_option(self, "signcolumn", "auto")
		end,
	},

	diagnostics = {
		is_shown = function() return vim.diagnostic.is_enabled() end,
		show = function(_) vim.diagnostic.enable(true) end,
		hide = function(_) vim.diagnostic.enable(false) end,
	},

	strict = {
		is_shown = function()
			return vim.g.ignore_strict_diagnostics ~= true
		end,
		show = function(_)
			vim.g.ignore_strict_diagnostics = false
			refresh_diagnostics()
		end,
		hide = function(_)
			vim.g.ignore_strict_diagnostics = true
			refresh_diagnostics()
		end,
	},
}

return M
