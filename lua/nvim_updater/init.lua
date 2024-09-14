-- lua/nvim_updater/init.lua
---@module "nvim_updater"
---Plugin for updating and building Neovim from source

local M = {}

-- Default values for plugin options
local default_config = {
	source_dir = vim.fn.expand("~/.local/src/neovim"),
	build_type = "RelWithDebInfo",
	branch = "master",
	keys = nil, -- No default custom keys provided
}

---@function setup_default_keymaps
--- Setup default keymaps for updating or removing Neovim
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
--- Check if a directory exists
---@param path string The directory path to check
---@return boolean exists True if the directory exists, false otherwise
local function directory_exists(path)
	local expanded_path = vim.fn.expand(path)
	return vim.fn.isdirectory(expanded_path) == 1
end

---@function notify
--- Helper to display a notification
---@param message string The message to display in the notification
---@param level number The severity level of the notification
local function notify(message, level)
	vim.notify(message, level, { title = "Neovim Updater" })
end

---@function open_floating_terminal
--- Open a terminal inside a floating window to run shell commands
--- Map 'q' to close the window on an error
---@param command string The shell command to be executed in the terminal
function M.open_floating_terminal(command)
	local buf = vim.api.nvim_create_buf(false, true)
	if not buf or buf == 0 then
		notify("Failed to create terminal buffer", vim.log.levels.ERROR)
		return
	end

	local ui = vim.api.nvim_list_uis()[1]
	local win_opts = {
		style = "minimal",
		relative = "editor",
		width = math.floor(ui.width * 0.8),
		height = math.floor(ui.height * 0.8),
		row = math.floor((ui.height - math.floor(ui.height * 0.8)) / 2),
		col = math.floor((ui.width - math.floor(ui.width * 0.8)) / 2),
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, win_opts)
	if not win or win == 0 then
		notify("Failed to create floating window", vim.log.levels.ERROR)
		return
	end

	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	vim.api.nvim_set_option_value("winblend", 10, { win = win })

	-- Run terminal command
	vim.fn.termopen(command, {
		on_exit = function(_, exit_code)
			if exit_code == 0 then
				notify("Neovim update completed successfully!", vim.log.levels.INFO)
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
			else
				notify("Neovim update failed with exit code: " .. exit_code, vim.log.levels.ERROR)

				-- Add specific keymap for 'q' to close the terminal window on an error
				vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
					noremap = true,
					silent = true,
					callback = function()
						if vim.api.nvim_win_is_valid(win) then
							vim.api.nvim_win_close(win, true)
						end
					end,
					desc = "Close the terminal window",
				})
			end
		end,
	})

	-- Switch to terminal insert mode
	vim.treesitter.stop(buf) -- Stop treesitter
	vim.api.nvim_set_current_win(win)
	vim.cmd("startinsert!")
end

---@function M.update_neovim
--- Update Neovim from source based on provided or default configuration options.
--- If the directory does not exist, first clone the repository.
--- Responsible for building Neovim against the defined branch and build type.
---@param opts table|nil Optional parameters 'source_dir', 'build_type', and 'branch'
function M.update_neovim(opts)
	opts = opts or {}
	local source_dir = opts.source_dir ~= "" and opts.source_dir or default_config.source_dir
	local build_type = opts.build_type ~= "" and opts.build_type or default_config.build_type
	local branch = opts.branch ~= "" and opts.branch or default_config.branch

	local notification_msg = "Starting Neovim Update:\n"
	notification_msg = notification_msg .. "Source Directory: " .. source_dir .. "\n"
	notification_msg = notification_msg .. "Branch: " .. branch .. "\n"
	notification_msg = notification_msg .. "Build Type: " .. build_type .. "\n"

	local dir_exists = directory_exists(source_dir)
	local git_commands = ""

	if not dir_exists then
		notification_msg = notification_msg .. "Cloning repository...\n"
		git_commands = "git clone https://github.com/neovim/neovim " .. source_dir
		git_commands = git_commands .. " && cd " .. source_dir
	else
		notification_msg = notification_msg .. "Updating existing repository...\n"
		git_commands = "cd " .. source_dir
	end

	-- Checkout branch and pull the latest changes
	git_commands = git_commands .. " && git fetch origin && git checkout " .. branch .. " && git pull"

	notification_msg = notification_msg .. "Building repository...\n"
	local build_commands = "cd "
		.. source_dir
		.. " && make clean && make CMAKE_BUILD_TYPE="
		.. build_type
		.. " && sudo make install"

	notify(notification_msg, vim.log.levels.INFO)

	-- Execute the commands
	M.open_floating_terminal(git_commands .. " && " .. build_commands)
end

---@function M.remove_source_dir
--- Remove Neovim source directory or a user-specified one
---@param opts table|nil Optional table for 'source_dir'
function M.remove_source_dir(opts)
	opts = opts or {}
	local source_dir = opts.source_dir ~= "" and opts.source_dir or default_config.source_dir

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
	-- User command to Update Neovim with optional arguments for branch, build type, and source directory
	vim.api.nvim_create_user_command("UpdateNeovim", function(opts)
		local args = vim.split(opts.args, " ")
		local branch = (args[1] == "" and default_config.branch or args[1])
		local build_type = (args[2] == "" and default_config.build_type or args[2])
		local source_dir = (args[3] == "" and default_config.source_dir or args[3])

		M.update_neovim({ branch = branch, build_type = build_type, source_dir = source_dir })
	end, {
		desc = "Update Neovim with optional branch, build_type, and source_dir",
		nargs = "*", -- Allows a flexible number of arguments
	})

	-- User command to remove Neovim source directory with optional source_dir argument
	vim.api.nvim_create_user_command("RemoveNeovimSource", function(opts)
		local args = vim.split(opts.args, " ")
		M.remove_source_dir({
			source_dir = #args > 0 and (args[1] == "" and default_config.source_dir or args[1]) or nil,
		})
	end, {
		desc = "Remove Neovim source directory (can specify custom path)",
		nargs = "?", -- Optional, single argument
	})
end

return M
