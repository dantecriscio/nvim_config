local default_key_map_modes = require("utils.map").default_key_map_modes

return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "v0.2.2",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-fzy-native.nvim",
		},
		keys = {
			{ "<leader>f", "<Cmd>Telescope find_files<CR>", mode = default_key_map_modes },
			{ "<leader>F", "<Cmd>Telescope live_grep<CR>", mode = default_key_map_modes },
		},
		config = function()
			--[[
			We have a problem where if we open files through telescope,
			it doesn't remember the folds. It misses the autocmd.
			This is known about, as a flaw with telescope itself: 
				https://github.com/nvim-telescope/telescope.nvim/issues/1277
			There are 2 fixes:
				1: When using telescope, exit its insertion mode first
				(go to normal mode), and then choose the file.
					For some reason this works
					The bug does not happen from telescope's normal mode
				2: Automate solution 1, such that certain keymappings
				will first go to normal mode first and then execute.
					First, make use of :stopinsert
					Then execute a command that opens the file

			I found a solution online that does this
				Scroll down really far to see this answer
				https://github.com/nvim-telescope/telescope.nvim/issues/1048
				Also implements multi_open after selecting with TAB

			Below is a modified version of that online solution]]

			local actions = require("telescope.actions")
			local transform_mod = require("telescope.actions.mt").transform_mod
			local action_state = require("telescope.actions.state")

			-- Helper functions from github issues page
			local function multi_open(prompt_bufnr, method)
				local cmd_map = {
					vertical = "vsplit",
					horizontal = "split",
					default = "edit",
				}
				local picker = action_state.get_current_picker(prompt_bufnr)
				local multi_selection = picker:get_multi_selection()

				if #multi_selection >= 1 then
					require("telescope.pickers").on_close_prompt(prompt_bufnr)
					pcall(vim.api.nvim_set_current_win, picker.original_win_id)

					local cmd = cmd_map[method]
					for _, entry in ipairs(multi_selection) do
						local section = vim.fn.split(entry.value, ":")

						local filename = section[1]

						-- Will be nil if they don't exist
						local row = tonumber(section[2])
						local col = tonumber(section[3])

						vim.cmd(string.format("%s %s", cmd, filename))

						if row and col then
							pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
						end
					end
				else
					actions["select_" .. method](prompt_bufnr)
				end
			end

			local custom_actions = transform_mod({
				multi_selection_open_vertical = function(prompt_bufnr)
					multi_open(prompt_bufnr, "vertical")
				end,
				multi_selection_open_horizontal = function(prompt_bufnr)
					multi_open(prompt_bufnr, "horizontal")
				end,
				multi_selection_open = function(prompt_bufnr)
					multi_open(prompt_bufnr, "default")
				end,
			})

			local function stop_insert(callback)
				return function(prompt_bufnr)
					vim.cmd.stopinsert()
					vim.schedule(function()
						callback(prompt_bufnr)
					end)
				end
			end
			local my_telescope_keymaps = {
				i = {
					["<C-v>"] = stop_insert(
						custom_actions.multi_selection_open_vertical
					),
					["<C-h>"] = stop_insert(
						custom_actions.multi_selection_open_horizontal
					),
					["<CR>"] = stop_insert(custom_actions.multi_selection_open),

					["<Tab>"] = actions.toggle_selection
						+ actions.move_selection_worse,
					["<S-Tab>"] = actions.toggle_selection
						+ actions.move_selection_better,

					["<C-j>"] = actions.move_selection_next,
					["<C-k>"] = actions.move_selection_previous,
				},

				n = {
					["q"] = actions.close,
					[";"] = actions.close,

					["v"] = custom_actions.multi_selection_open_vertical,
					["h"] = custom_actions.multi_selection_open_horizontal,
					["<CR>"] = custom_actions.multi_selection_open,

					["<Tab>"] = actions.toggle_selection
						+ actions.move_selection_worse,
					["<S-Tab>"] = actions.toggle_selection
						+ actions.move_selection_better,

					["j"] = actions.move_selection_next,
					["k"] = actions.move_selection_previous,
					["J"] = actions.results_scrolling_up,
					["K"] = actions.results_scrolling_down,
					["M"] = actions.move_to_middle,
					["gg"] = actions.move_to_top,
					["G"] = actions.move_to_bottom,

					["n"] = actions.cycle_history_next,
					["p"] = actions.cycle_history_prev,

					["u"] = actions.preview_scrolling_up,
					["d"] = actions.preview_scrolling_down,

					["l"] = actions.open_qflist,
					["f"] = actions.send_to_qflist + actions.open_qflist,

					["?"] = actions.which_key,
				},
			}

			require("telescope").setup({
				extensions = {
					fzy_native = {
						override_generic_sorter = false,
						override_file_sorter = true,
					},
				},
				pickers = {
					find_files = {
						theme = "dropdown",
					},
					live_grep = {

						-- The preview is useful for grep
						preview = "true",
					},
				},
				defaults = {

					-- The preview is not really useful for file finding imo
					preview = false,
					sorting_strategy = "ascending",
					layout_config = {
						prompt_position = "top",
					},
					prompt_prefix = " ",
					selection_caret = " ",
					path_display = { "smart" },

					mappings = my_telescope_keymaps,
				},
			})
			require("telescope").load_extension("fzy_native")
		end,
	},
	{
		"nvim-lua/plenary.nvim",
		commit = "37604d95d8a212478063c40df4b7c48313453d52",
		lazy = true,
	},
	{
		"nvim-telescope/telescope-fzy-native.nvim",
		commit = "282f069504515eec762ab6d6c89903377252bf5b",
		lazy = true,
	},
}
