local M = {}

-- Methods for setting up treesitter once when a language file is opened
function M.setup_highlighting()
	vim.treesitter.start()
end

function M.setup_indentation()
	vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end


-- Methods for traversing the tree to find specific tokens (like function names) in the buffer
---@alias ResultStatusCode
---| 0 # SUCCESS
---| 1 # ROOT_NODE_REACHED
---| 2 # CHILD_NOT_FOUND

 function M.go_up_until(node, up_until_type)
	local root_most_node = node

	while root_most_node:type() ~= up_until_type do
		local parent = root_most_node:parent()
		if parent == nil then
			return 1, root_most_node
		end
		root_most_node = parent
	end

	return 0, root_most_node
end

function M.get_child_with_type(node, child_type)
	local desired_child_node = nil
	for child in node:iter_children() do
		if child:type() == child_type then
			desired_child_node = child
			break
		end
	end
	if desired_child_node == nil then
		return 2, desired_child_node
	end
	return 0, desired_child_node
end

function M.node_to_buffer_text(node)
	local start_row, start_col, end_row, end_col = node:range()
	local read_lines = vim.api.nvim_buf_get_text(
		0,
		start_row,
		start_col,
		end_row,
		end_col,
		{}
	)
	local result = ""
	for _, text in ipairs(read_lines) do
		result = result .. text:gsub("%s", "")
	end
	return result
end



--- A helper function for finding text by walking a parsed tree
---
--- A common way to use treesitter's tree is to answer a question like
--- "what function is my cursor currently in?"
--- 
--- Answering this question involves 4 steps:
---   1. Get the node where the cursor currently is
---   2. Navigate up until some node represents the entire function
---   3. Go to a specific child of that node, which is the function's name
---   4. Use that node's range to get the function's name from the buffer
--- 
--- function acts as a framework for this common use case.
---
--- @param start_node TSNode starting point
--- @param up_until_type string node type to move upwards until finding
--- @param child_type string node type to look for in the immediate children
--- @return ResultStatusCode status indicating success or failure
--- @return string result of the navigation. Empty String if result_code ~= 0.
--- @return TSNode root_most_node the closest to root the navigation reached
function M.treesitter_navigate(start_node, up_until_type, child_type)
	local move_up_status, root_most_node = M.go_up_until(
		start_node,
		up_until_type
	)
	if move_up_status ~= 0 then
		return move_up_status, "", root_most_node
	end

	local get_child_status, desired_child_node = M.get_child_with_type(
		root_most_node,
		child_type
	)
	if get_child_status ~= 0 then
		return get_child_status, "", root_most_node
	end

	local buffer_text = M.node_to_buffer_text(desired_child_node)
	return 0, buffer_text, root_most_node
end


return M
