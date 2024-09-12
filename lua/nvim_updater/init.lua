-- lua/nvim_updater/init.lua

local M = {}

-- Default values for plugin options
local default_config = {
	source_dir = vim.fn.expand("~/.local/src/neovim"),
	build_type = "RelWithDebInfo",
	keys = nil, -- No default custom keys provided
}

-- Conditionally set keymaps based on user config
local function setup_default_keymaps()
	vim.keymap.set("n", "<Leader>uU", function()
		M.update_neovim()
	end, { desc = "Update Neovim", noremap = true, silent = true })

	vim.keymap.set("n", "<Leader>uD", function()
		M.update_neovim({ build_type = "Debug" })
	end, { desc = "Update Neovim with Debug build", noremap = true, silent = true })

	vim.keymap.set("n", "<Leader>uR", function()
		M.update_neovim({ build_type = "Release" })
	end, { desc = "Update Neovim with Release build", noremap = true, silent = true })
end

-- Function to check if a directory exists
local function directory_exists(path)
	local expanded_path = vim.fn.expand(path) -- Ensures the home directory tilde (~) is expanded correctly
	if vim.fn.isdirectory(expanded_path) == 1 then
		return true
	else
		return false
	end
end

-- Function to update Neovim according to user-configurable options
---@param opts table|nil Options table accepting 'source_dir' and 'build_type'
function M.update_neovim(opts)
	opts = opts or {}
	local source_dir = opts.source_dir or default_config.source_dir
	local build_type = opts.build_type or default_config.build_type

	-- Use a more explicit notification for debugging
	vim.notify("Using source directory: " .. vim.inspect(source_dir), vim.log.levels.INFO)

	-- Ensure path is properly expanded
	local dir_exists = directory_exists(source_dir)

	-- Prepare the shell commands based on the directory check
	local git_commands = ""

	if not dir_exists then
		vim.notify("Cloning Neovim repository to the source: " .. source_dir, vim.log.levels.INFO)
		git_commands = "git clone https://github.com/neovim/neovim " .. source_dir
	else
		vim.notify("Pulling the latest changes in Neovim source from: " .. source_dir, vim.log.levels.INFO)
		git_commands = "cd " .. source_dir .. " && git pull"
	end

	local build_commands = "cd "
		.. source_dir
		.. " && make clean && make CMAKE_BUILD_TYPE="
		.. build_type
		.. " && sudo make install"

	M.open_floating_terminal(git_commands .. " && " .. build_commands)
end

-- Function that opens a terminal inside a floating window to run shell commands
---@param command string
function M.open_floating_terminal(command)
	local buf = vim.api.nvim_create_buf(false, true)
	if not buf or buf == 0 then
		vim.notify("Failed to create terminal buffer", vim.log.levels.ERROR)
		return
	end

	local ui = vim.api.nvim_list_uis()[1]
	local width = ui.width
	local height = ui.height
	local win_width = math.floor(width * 0.8)
	local win_height = math.floor(height * 0.8)

	local win_opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = math.floor((height - win_height) / 2),
		col = math.floor((width - win_width) / 2),
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, win_opts)
	if not win or win == 0 then
		vim.notify("Failed to create floating window", vim.log.levels.ERROR)
		return
	end

	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	vim.api.nvim_set_option_value("winblend", 10, { win = win })

	vim.fn.termopen(command, {
		on_exit = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
			vim.notify("Neovim update completed!", vim.log.levels.INFO)
		end,
	})

	vim.treesitter.stop(buf)
	vim.api.nvim_set_current_win(win)
	vim.cmd("startinsert!")
end
-- Setup function that initializes user configuration
---@param user_config table|nil User-provided config that overrides default values
function M.setup(user_config)
	-- Merge user config with default config
	default_config = vim.tbl_deep_extend("force", default_config, user_config or {})

	-- If the user doesn't specify `keys`, set default key mappings
	if default_config.keys == nil then
		setup_default_keymaps()
	end

	-- Setup user commands
	M.setup_usercmd()
end

-- Create a custom user command to update Neovim
function M.setup_usercmd()
	vim.api.nvim_create_user_command("UpdateNeovim", function()
		M.update_neovim()
	end, { desc = "Update Neovim from source" })
end

return M
