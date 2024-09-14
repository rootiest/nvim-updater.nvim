-- lua/nvim_updater/init.lua

local M = {}

-- Default values for plugin options
local default_config = {
	source_dir = vim.fn.expand("~/.local/src/neovim"),
	build_type = "RelWithDebInfo",
	branch = "master",
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

	vim.keymap.set("n", "<Leader>uC", function()
		M.remove_source_dir()
	end, { desc = "Remove Neovim source directory", noremap = true, silent = true })
end

---@function directory_exists
---Check if a directory exists
---@param path string The directory path to check
---@return boolean exists True if the directory exists, false otherwise
local function directory_exists(path)
	local expanded_path = vim.fn.expand(path)
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
---Update Neovim from source based on provided or default configuration options.
---If the directory does not exist, it will first clone the repository, then checkout the specified branch.
---@param opts table|nil Optional parameters 'source_dir', 'build_type', and 'branch'
function M.update_neovim(opts)
	opts = opts or {}
	local source_dir = opts.source_dir or ""
	if source_dir == "" then
		source_dir = default_config.source_dir
	end
	local build_type = opts.build_type or ""
	if build_type == "" then
		build_type = default_config.build_type
	end
	local branch = opts.branch or ""
	if branch == "" then
		branch = default_config.branch
	end

	notify("Using source directory: " .. vim.inspect(source_dir), vim.log.levels.INFO)

	local dir_exists = directory_exists(source_dir)
	local git_commands = ""

	if not dir_exists then
		notify("Cloning Neovim repository to: " .. source_dir, vim.log.levels.INFO)
		-- First, clone without specifying a branch
		git_commands = "git clone https://github.com/neovim/neovim " .. source_dir
	end

	-- Checkout the branch and pull updates
	notify("Checking out branch: " .. branch, vim.log.levels.INFO)
	git_commands = git_commands
		.. " && cd "
		.. source_dir
		.. " && git fetch origin && git checkout "
		.. branch
		.. " && git pull"

	notify("Building Neovim with build type: " .. build_type, vim.log.levels.INFO)
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
		notify("Failed to create terminal buffer", vim.log.levels.ERROR)
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
		on_exit = function(_, exit_code)
			if exit_code == 0 then
				notify("Neovim update completed successfully!", vim.log.levels.INFO)
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
			else
				notify("Neovim update failed with exit code: " .. exit_code, vim.log.levels.ERROR)
			end
		end,
	})

	vim.treesitter.stop(buf)
	vim.api.nvim_set_current_win(win)
	vim.cmd("startinsert!")
end

---@function M.remove_source_dir
---Remove the Neovim source directory, or a user-specified one
---@param opts table|nil Optional table for 'source_dir'
function M.remove_source_dir(opts)
	opts = opts or {}
	local source_dir = opts.source_dir or ""
	if source_dir == "" then
		source_dir = default_config.source_dir
	end

	if directory_exists(source_dir) then
		local success = vim.fn.delete(source_dir, "rf")
		if success == 0 then
			notify("Successfully removed Neovim source directory: " .. source_dir, vim.log.levels.INFO)
		else
			notify("Error removing Neovim source directory: " .. source_dir, vim.log.levels.ERROR)
		end
	else
		notify("Source directory does not exist: " .. source_dir, vim.log.levels.WARN)
	end
end

---@function M.setup
---Setup function initializing user configuration
---@param user_config table|nil User-provided config that overrides default values
function M.setup(user_config)
	default_config = vim.tbl_deep_extend("force", default_config, user_config or {})

	if default_config.keys == nil then
		setup_default_keymaps()
	end

	M.setup_usercmd()
end

---@function M.setup_usercmd
---Create user commands for both updating and removing Neovim source
function M.setup_usercmd()
	-- User command for updating Neovim with optional arguments for branch, build type, and source directory
	vim.api.nvim_create_user_command("UpdateNeovim", function(opts)
		local args = vim.split(opts.args, " ")
		local branch = args[1] or default_config.branch
		local build_type = args[2] or default_config.build_type
		local source_dir = args[3] or default_config.source_dir

		-- Update Neovim using the parsed arguments
		M.update_neovim({ branch = branch, build_type = build_type, source_dir = source_dir })
	end, {
		desc = "Update Neovim with optional branch, build_type, and source_dir",
		nargs = "*", -- Allows a flexible number of arguments
	})

	-- User command for removing the Neovim source directory, with an optional source_dir argument
	vim.api.nvim_create_user_command("RemoveNeovimSource", function(opts)
		local args = vim.split(opts.args, " ")
		M.remove_source_dir({ source_dir = #args > 0 and args[1] or nil })
	end, {
		desc = "Remove Neovim source directory (can specify custom path)",
		nargs = "?", -- Optional, single argument
	})
end

return M
