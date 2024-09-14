-- lua/nvim_updater/init.lua

local M = {}

-- Default values for plugin options (editable via user config)
local default_config = {
	source_dir = vim.fn.expand("~/.local/src/neovim"), -- Default Neovim source location
	build_type = "RelWithDebInfo", -- Default build type
	branch = "master", -- Default Neovim branch to track
	keys = nil, -- No default custom keys provided
}

--- Setup default keymaps for updating or removing Neovim based on user configuration.
---@function setup_default_keymaps
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

--- Checks if a directory exists
---@function directory_exists
---@param path string The directory path to check
---@return boolean exists True if the directory exists, false otherwise
local function directory_exists(path)
	local expanded_path = vim.fn.expand(path)
	return vim.fn.isdirectory(expanded_path) == 1
end

--- Helper to display notifications consistently
---@function notify
---@param message string The message to display in a notification
---@param level number The logging level of the notification (e.g., vim.log.levels.INFO or vim.log.levels.ERROR)
local function notify(message, level)
	vim.notify(message, level, { title = "Neovim Updater" })
end

--- Open a floating window for a terminal buffer and set a custom filetype for better integration with statusline.
---@function M.open_floating_terminal
---@param command string Shell command to be executed in the terminal
---@param filetype string The custom filetype to assign to the terminal buffer
function M.open_floating_terminal(command, filetype)
	-- Create a new, unnamed buffer for the terminal
	local buf = vim.api.nvim_create_buf(false, true)
	if not buf or buf == 0 then
		notify("Failed to create terminal buffer", vim.log.levels.ERROR)
		return
	end

	-- Set the buffer's custom "filetype" with nvim_set_option_value (Neovim 0.10+ API)
	vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })

	-- Get UI dimensions to calculate window size and positioning
	local ui = vim.api.nvim_list_uis()[1]
	local win_width = math.floor(ui.width * 0.8)
	local win_height = math.floor(ui.height * 0.8)

	-- Define window options, placing it in the center of the screen
	local win_opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = math.floor((ui.height - win_height) / 2),
		col = math.floor((ui.width - win_width) / 2),
		border = "rounded", -- Rounded border for a polished look
	}

	-- Open the floating window with the buffer
	local win = vim.api.nvim_open_win(buf, true, win_opts)
	if not win or win == 0 then
		notify("Failed to create floating window", vim.log.levels.ERROR)
		return
	end

	-- Set additional buffer- and window-specific options
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	vim.api.nvim_set_option_value("winblend", 10, { win = win })

	-- Run the terminal command
	vim.fn.termopen(command, {
		on_exit = function(_, exit_code)
			if exit_code == 0 then
				notify("Neovim update completed successfully!", vim.log.levels.INFO)
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
			else
				notify("Neovim update failed with exit code: " .. exit_code, vim.log.levels.ERROR)
				-- Optionally add keymap to allow closing the window using 'q'
				vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
					noremap = true,
					silent = true,
					callback = function()
						if vim.api.nvim_win_is_valid(win) then
							vim.api.nvim_win_close(win, true)
						end
					end,
					desc = "Close terminal window after failure",
				})
			end
		end,
	})

	-- Enter terminal's insert mode
	vim.treesitter.stop(buf) -- Stop treesitter for terminal buffer
	vim.api.nvim_set_current_win(win)
	vim.cmd("startinsert!")
end

--- Update Neovim from the source based on provided or default options.
--- Clones the repository if the directory does not exist.
--- Checks out the specified branch and builds the project.
---@function M.update_neovim
---@param opts table|nil Table of optional parameters ('source_dir', 'build_type', 'branch')
function M.update_neovim(opts)
	opts = opts or {}
	local source_dir = opts.source_dir ~= "" and opts.source_dir or default_config.source_dir
	local build_type = opts.build_type ~= "" and opts.build_type or default_config.build_type
	local branch = opts.branch ~= "" and opts.branch or default_config.branch

	-- Build notification message to summarize actions being taken
	local notification_msg = "Starting Neovim Update:\n"
	notification_msg = notification_msg .. "Source Directory: " .. source_dir .. "\n"
	notification_msg = notification_msg .. "Branch: " .. branch .. "\n"
	notification_msg = notification_msg .. "Build Type: " .. build_type .. "\n"

	-- Detect if we need to clone the repo or just update it
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

	-- Checkout branch and pull latest changes
	git_commands = git_commands .. " && git fetch origin && git checkout " .. branch .. " && git pull"

	-- Build Neovim using the specified build type
	notification_msg = notification_msg .. "Building repository...\n"
	local build_command = "cd "
		.. source_dir
		.. " && make clean && make CMAKE_BUILD_TYPE="
		.. build_type
		.. " && sudo make install"

	notify(notification_msg, vim.log.levels.INFO)

	-- Execute in floating terminal and set custom filetype
	-- Example: "neovim_updater_term" can be used for conditions in lualine or other plugins
	M.open_floating_terminal(git_commands .. " && " .. build_command, "neovim_updater_term")
end

--- Remove the Neovim source directory or a custom one.
---@function M.remove_source_dir
---@param opts table|nil Optional table for 'source_dir'
function M.remove_source_dir(opts)
	opts = opts or {}
	local source_dir = opts.source_dir ~= "" and opts.source_dir or default_config.source_dir

	if directory_exists(source_dir) then
		-- Safely attempt to delete the directory recursively
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

--- Initialize Neovim updater plugin configuration
---@function M.setup
---@param user_config table|nil User configuration overriding default values
function M.setup(user_config)
	default_config = vim.tbl_deep_extend("force", default_config, user_config or {})

	-- Setup default keymaps only if not overridden by user configuration
	if default_config.keys == nil then
		setup_default_keymaps()
	end

	-- Setup Neovim user commands
	M.setup_usercmd()
end

--- Create user commands for both updating and removing Neovim source directories
---@function M.setup_usercmd
function M.setup_usercmd()
	--- Define UpdateNeovim command to accept branch, build_type, and source_dir as optional arguments
	vim.api.nvim_create_user_command("UpdateNeovim", function(opts)
		local args = vim.split(opts.args, " ")
		local branch = (args[1] == "" and default_config.branch or args[1])
		local build_type = (args[2] == "" and default_config.build_type or args[2])
		local source_dir = (args[3] == "" and default_config.source_dir or args[3])

		M.update_neovim({ branch = branch, build_type = build_type, source_dir = source_dir })
	end, {
		desc = "Update Neovim with optional branch, build_type, and source_dir",
		nargs = "*", -- Accept multiple (optional) arguments
	})

	--- Define RemoveNeovimSource command to optionally accept a custom `source_dir`
	vim.api.nvim_create_user_command("RemoveNeovimSource", function(opts)
		local args = vim.split(opts.args, " ")
		M.remove_source_dir({
			source_dir = #args > 0 and (args[1] == "" and default_config.source_dir or args[1]) or nil,
		})
	end, {
		desc = "Remove Neovim source directory (optionally specify custom path)",
		nargs = "?", -- Allow one optional argument
	})
end

return M
