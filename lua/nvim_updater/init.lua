-- lua/nvim_updater/init.lua

local M = {}

-- Default values for plugin options
local default_config = {
	source_dir = vim.fn.expand("~/.local/src/neovim"),
	build_type = "RelWithDebInfo",
	branch = "master", -- default branch
	keys = nil, -- No default custom keys provided
}

---@function setup_default_keymaps
---Conditionally set keymaps based on user config
---Set up default keymaps for updating Neovim
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

	-- Adding keybinding to update with the `release-0.10` branch as an example
	vim.keymap.set("n", "<Leader>uB", function()
		M.update_neovim({ branch = "release-0.10" })
	end, { desc = "Update Neovim with development branch", noremap = true, silent = true })
end

---@function directory_exists
---Check if a directory exists
---@param path string The directory path to check
---@return boolean exists True if the directory exists, false otherwise
local function directory_exists(path)
	local expanded_path = vim.fn.expand(path) -- Ensures the home directory tilde (~) is expanded correctly
	return vim.fn.isdirectory(expanded_path) == 1
end

---@function notify
---Helper to display a notification
---@param message string The message to display in the notification
---@param level number The severity level of the notification
local function notify(message, level)
	vim.notify(message, level, { title = "Neovim Updater" })
end

---@function M.update_neovim
---Update Neovim according to user-configurable options
---@param opts table|nil Options table that can optionally include 'source_dir', 'build_type', and 'branch'
function M.update_neovim(opts)
	opts = opts or {}
	local source_dir = opts.source_dir or default_config.source_dir
	local build_type = opts.build_type or default_config.build_type
	local branch = opts.branch or default_config.branch

	-- Use a more explicit notification for debugging
	notify("Using source directory: " .. vim.inspect(source_dir), vim.log.levels.INFO)

	-- Ensure path is properly expanded
	local dir_exists = directory_exists(source_dir)

	-- Prepare the shell commands based on the directory check
	local git_commands = ""

	if not dir_exists then
		notify("Cloning Neovim repository to source: " .. source_dir .. " on branch " .. branch, vim.log.levels.INFO)
		git_commands = "git clone -b " .. branch .. " https://github.com/neovim/neovim " .. source_dir
	else
		notify("Checking out and pulling latest changes in branch: " .. branch, vim.log.levels.INFO)
		git_commands = "cd " .. source_dir .. " && git fetch origin && git checkout " .. branch .. " && git pull"
	end

	local build_commands = "cd "
		.. source_dir
		.. " && make clean && make CMAKE_BUILD_TYPE="
		.. build_type
		.. " && sudo make install"

	M.open_floating_terminal(git_commands .. " && " .. build_commands)
end

---@function M.open_floating_terminal
---Open a terminal inside a floating window to run shell commands
---@param command string The shell command to be executed in the terminal
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
		notify("Failed to create floating window", vim.log.levels.ERROR)
		return
	end

	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	vim.api.nvim_set_option_value("winblend", 10, { win = win })

	vim.fn.termopen(command, {
		on_exit = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
			notify("Neovim update completed!", vim.log.levels.INFO)
		end,
	})

	vim.treesitter.stop(buf)
	vim.api.nvim_set_current_win(win)
	vim.cmd("startinsert!")
end

---@function M.setup
---Setup function that initializes user configuration
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

---@function M.setup_usercmd
---Create a custom user command to update Neovim from source
function M.setup_usercmd()
	vim.api.nvim_create_user_command("UpdateNeovim", function()
		M.update_neovim()
	end, { desc = "Update Neovim from source" })
end

return M
