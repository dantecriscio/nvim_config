local map = require("utils.map").map
local default_key_map_modes = require("utils.map").default_key_map_modes
local alpabetical_key_map_modes = require("utils.map").alpabetical_key_map_modes
local all_key_map_modes = require("utils.map").all_key_map_modes

-- Maps leader to the space bar (pretty universal)
map(default_key_map_modes, "<Space>", "<Nop>")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Use control-(h,j,k,l) to move in any mode
map(all_key_map_modes, "<C-h>", "<Left>")
map(all_key_map_modes, "<C-j>", "<Down>")
map(all_key_map_modes, "<C-k>", "<Up>")
map(all_key_map_modes, "<C-l>", "<Right>")

-- My remappings for moving far vertically and horizontally
map(alpabetical_key_map_modes, "H", "^")
map(alpabetical_key_map_modes, "L", "$")
map(alpabetical_key_map_modes, "K", "<C-u>zz0")
map(alpabetical_key_map_modes, "J", "<C-d>zz0")

-- Only paste what we "yank", not the deleted text
map(alpabetical_key_map_modes, "p", '"0p')

-- Moves the cursor after pasting with shift
map(alpabetical_key_map_modes, "P", '"0gP')

-- Make x, only while in visual mode, cut text into register 0
map("x", "x", '"0x')

-- Use control to copy, cut, and paste from clipboard
map(default_key_map_modes, "<C-p>", '"+p')
map(default_key_map_modes, "<C-y>", '"+y')
map(default_key_map_modes, "<C-x>", '"+x')

-- Use Control to paste while in insertion mode.
-- p for default, v for clipboard
map("i", "<C-p>", '<Esc>"0pa')
map("i", "<C-v>", '<Esc>"+pa')

-- Intuitive tab indentation, only in visual mode
map("x", "<TAB>", ">gv")
map("x", "<S-TAB>", "<gv")

-- Removes the highlighting from the screen that comes with searching via "/"
map(default_key_map_modes, "<Leader>n", "<Cmd>noh<CR>")

-- Write buffers quickly
map(default_key_map_modes, "<leader>w", "<Cmd>w<CR>")
map(default_key_map_modes, "<leader>W", "<Cmd>wa<CR>")

-- Close a window quickly
map(default_key_map_modes, "<leader>q", "<Cmd>q<CR>")
map(default_key_map_modes, "<leader>Q", "<Cmd>q!<CR>")

-- Open and close the quickfix list easily
map(alpabetical_key_map_modes, "go", "<Cmd>copen<CR>")
map(alpabetical_key_map_modes, "gq", "<Cmd>cclose<CR>")

-- Switch between windows quickly
map(default_key_map_modes, "<Leader>h", "<C-w>h")
map(default_key_map_modes, "<Leader>j", "<C-w>j")
map(default_key_map_modes, "<Leader>k", "<C-w>k")
map(default_key_map_modes, "<Leader>l", "<C-w>l")

-- Resize windows quickly
map(default_key_map_modes, "<Up>", "<Cmd>resize -2<CR>")
map(default_key_map_modes, "<Down>", "<Cmd>resize +2<CR>")
map(default_key_map_modes, "<Left>", "<Cmd>vertical resize -2<CR>")
map(default_key_map_modes, "<Right>", "<Cmd>vertical resize +2<CR>")

-- Easier redo command
map(alpabetical_key_map_modes, "R", "<C-r>")

-- Control-A can be used to increment a number
-- But I prefer <leader> commands to <C-> commands, so remap this
map(default_key_map_modes, "<leader>i", "<C-a>")

-- Control-X similarly was originally for decrementing a number
map(default_key_map_modes, "<leader>I", "<C-x>")

-- Common to remap gd to LSP "Go to Definition
-- But the original gd is still useful. So map gn to this
map(alpabetical_key_map_modes, "gn", "gd")

-- Easier commenting
vim.keymap.set({"n"}, "C", "gcc", {remap = true})
vim.keymap.set({"v"}, "C", "gc", {remap = true})

