-- lua/nvim_updater/utils.lua

local U = {}

--- Helper to heck if a directory exists
---@function directory_exists
---@param path string The directory path to check
---@return boolean exists True if the directory exists, false otherwise
function U.directory_exists(path)
	local expanded_path = vim.fn.expand(path)
	return vim.fn.isdirectory(expanded_path) == 1
end

--- Create a temporary file to check write permissions in the directory or parent directory.
---@function check_write_permissions
---@param dir string The directory path to check
---@return boolean writable True if the directory is writable, false otherwise
function U.check_write_permissions(dir)
	local temp_file_path = dir .. "/nvim_updater_tmp_file.txt"

	-- Try to open the temporary file for writing
	local file = io.open(temp_file_path, "w")

	if file then
		file:close() -- Close the file to ensure it's written
		vim.fn.delete(temp_file_path) -- Cleanup: remove the temporary file
		return true -- Directory is writable
	else
		return false -- Directory is not writable
	end
end

--- Helper to display notifications consistently
---@function notify
---@param message string The message to display in a notification
---@param level number The logging level of the notification (e.g., vim.log.levels.INFO or vim.log.levels.ERROR)
---@param force? boolean True if the notification should be displayed regardless of the config settings
function U.notify(message, level, force)
	-- Get config
	local default_config = require("nvim_updater").default_config
	-- Check if the config verbose option is false.
	-- If so, suppress INFO and DEBUG notifications based on the log level.
	if (level == vim.log.levels.INFO or level == vim.log.levels.DEBUG) and not default_config.verbose then
		-- If the notification is not forced, return early.
		if not force then
			return
		end
	end

	-- If config verbose = true then display all notifications
	vim.notify(message, level, { title = "Neovim Updater" })
end

---@function Function to generate a y/n confirmation prompt
---@param prompt string The prompt text to display
---@param action function|string The action to execute if the user confirms the prompt, or a Vim command as a string
---@return boolean condition true if the user confirms the prompt, false otherwise
function U.ConfirmPrompt(prompt, action)
	-- Validate the action parameter
	local function perform_action()
		if type(action) == "function" then
			action() -- Call the function
		elseif type(action) == "string" then
			vim.fn.nvim_exec_lua(action, {}) -- Run the Vim command as Lua
		else
			U.notify("Action must be a function or a string", vim.log.levels.ERROR)
		end
	end

	-- Create a new buffer
	local buf = vim.api.nvim_create_buf(false, true) -- Create a new empty buffer

	-- Set the prompt text in the buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { prompt, "y/n: " })

	-- Variables for the floating window
	local win_height = 2 -- Height of the floating window
	local win_width = math.floor(vim.o.columns * 0.25) -- Width of the floating window
	local row = math.floor((vim.o.lines - win_height) / 2) -- Position row
	local col = math.floor((vim.o.columns - win_width) / 2) -- Position column
	local win_border = "rounded"
	local style = "minimal"

	-- Create a floating window
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = win_width,
		height = win_height,
		col = col,
		row = row,
		style = style,
		border = win_border,
	})

	-- Move the cursor to the end of the buffer
	vim.api.nvim_win_set_cursor(win, { 2, 5 })

	-- Function for closing the window and cleaning up
	local autocmd_id
	local function close_window()
		if autocmd_id then
			vim.api.nvim_del_autocmd(autocmd_id) -- Remove the resize autocmd
			autocmd_id = nil
		end
		vim.api.nvim_win_close(win, true) -- Close the window
	end

	-- Update the floating window size on Vim resize events
	autocmd_id = vim.api.nvim_create_autocmd({ "VimResized" }, {
		callback = function()
			-- Get new dimensions of the main UI
			win_width = math.floor(vim.o.columns * 0.25) -- Update width
			col = math.floor((vim.o.columns - win_width) / 2) -- Recalculate center column
			row = math.floor((vim.o.lines - win_height) / 2) -- Recalculate center row

			-- Update floating window configuration
			vim.api.nvim_win_set_config(win, {
				relative = "editor",
				width = win_width,
				height = win_height,
				col = col,
				row = row,
			})
		end,
	})

	-- Define the yes function
	local yes = function()
		close_window() -- Close window before performing action
		perform_action() -- Perform the action
		return true
	end

	-- Define the no function
	local no = function()
		close_window() -- Close window and notify
		U.notify("Action Canceled", vim.log.levels.INFO)
	end

	-- Define buffer-specific key mappings
	local keymaps = {
		y = yes,
		n = no,
		q = no,
		["<Esc>"] = no,
	}

	-- Set the key mappings
	for key, callback in pairs(keymaps) do
		vim.api.nvim_buf_set_keymap(buf, "n", key, "", {
			noremap = true,
			nowait = true,
			callback = callback,
			desc = key == "y" and "Confirm action" or "Cancel action",
		})
	end

	return false
end
-- Helper to display floating terminal in a centered, minimal Neovim window.
-- This is useful for running long shell commands like building Neovim.
-- You can pass arguments either as positional or as a table of options.
---@param command_or_opts string|table Either a shell command (string) or a table with options
---@param filetype? string Custom filetype for terminal buffer (optional if using table)
---@param ispreupdate? boolean Whether the terminal is for changelog before updating Neovim (optional if using table)
---@param autoclose? boolean Whether the terminal should be automatically closed (optional if using table)
---@function open_floating_terminal
function U.open_floating_terminal(command_or_opts, filetype, ispreupdate, autoclose)
	local opts

	-- Determine if the first argument is a table or positional arguments
	if type(command_or_opts) == "table" then
		opts = command_or_opts
	else
		opts = {
			command = command_or_opts or "",
			filetype = filetype or "floating.term", -- Default filetype
			ispreupdate = ispreupdate or false,
			autoclose = autoclose or false,
		}
	end

	-- Extract options from the table
	local command = opts.command or ""
	filetype = opts.filetype or "FloatingTerm"
	ispreupdate = opts.ispreupdate or false
	autoclose = opts.autoclose or false

	-- Create a new buffer for the terminal, set it as non-listed and scratch
	local buf = vim.api.nvim_create_buf(false, true)
	if not buf or buf == 0 then
		U.notify("Failed to create terminal buffer", vim.log.levels.ERROR)
		return
	end

	-- Set the filetype of the terminal buffer
	vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })

	-- Create the floating window
	local win
	local autocmd_id

	local function open_window()
		-- Get UI dimensions to calculate window size
		local ui = vim.api.nvim_list_uis()[1]
		local win_width = math.floor(ui.width * 0.8)
		local win_height = math.floor(ui.height * 0.8)

		-- Define window options
		local win_opts = {
			style = "minimal",
			relative = "editor",
			width = win_width,
			height = win_height,
			row = math.floor((ui.height - win_height) / 2),
			col = math.floor((ui.width - win_width) / 2),
			border = "rounded",
		}

		-- Create or update the floating window
		if win and vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_set_config(win, win_opts) -- Update window config
		else
			win = vim.api.nvim_open_win(buf, true, win_opts) -- Open new window
			if not win or win == 0 then
				U.notify("Failed to create floating window", vim.log.levels.ERROR)
				return
			end
		end

		-- Additional settings for the window
		vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
		vim.api.nvim_set_option_value("winblend", 10, { win = win })
	end

	open_window() -- Initial window creation

	-- Update window size on Vim resize events
	autocmd_id = vim.api.nvim_create_autocmd({ "VimResized" }, {
		callback = function()
			open_window() -- Call the function to update the window size
		end,
	})

	-- Create the closing callback
	local function closing()
		-- Remove the autocmd to prevent errors after the window is closed
		if autocmd_id then
			vim.api.nvim_del_autocmd(autocmd_id)
			autocmd_id = nil
		end

		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
		if os.getenv("NVIMUPDATER_HEADLESS") then
			vim.cmd("qa")
		end
		if ispreupdate then
			U.ConfirmPrompt("Perform Neovim update?", function()
				require("nvim_updater").update_neovim()
			end)
		end
	end

	-- Run the terminal command
	vim.fn.termopen(command, {
		on_exit = function(_, exit_code)
			if exit_code == 0 then
				if autoclose then -- If autoclose is true, close the terminal window
					closing()
					return
				end

				-- Wait for a keypress before closing the terminal window
				-- Bind different keys to closing the terminal
				for _, key in ipairs({ "q", "<Space>", "<CR>", "<Esc>", "y" }) do
					vim.api.nvim_buf_set_keymap(buf, "n", key, "", {
						noremap = true,
						silent = true,
						callback = function()
							closing()
						end,
						desc = "Close terminal window",
					})
				end
			else
				U.notify("Command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
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
end

--- Helper function to return the number of pending commits
---@function get_update_status
---@return string formatted_messge The formatted status message
function U.get_commit_count()
	-- Define the path to the Neovim source directory
	local source_dir = require("nvim_updater").default_config.source_dir

	-- Build the command to fetch the latest changes from the remote repository
	local fetch_command = ("cd %s && git fetch"):format(source_dir)

	-- Execute the fetch command
	vim.fn.system(fetch_command)

	-- Build the command to get the current branch name
	local current_branch_cmd = ("cd %s && git rev-parse --abbrev-ref HEAD"):format(source_dir)

	local current_branch = vim.fn.system(current_branch_cmd):gsub("%s+", "") -- Trim whitespace

	-- Check for errors in executing the branch command
	if vim.v.shell_error ~= 0 then
		return "?"
	end

	-- Build the command to count new commits in the remote branch
	local commit_count_cmd = ("cd %s && git rev-list --count %s..origin/%s"):format(
		source_dir,
		current_branch,
		current_branch
	)

	-- Execute the command to get the count of new commits
	local commit_count = vim.fn.system(commit_count_cmd):gsub("%s+", "") -- Trim whitespace

	-- Update cached status
	require("nvim_updater").last_status.count = commit_count
	return commit_count
end

--- Timer function to run a function periodically
---@param fn function The function to run
local timer = function(fn)
	local function timedFn()
		local wait = fn()
		vim.defer_fn(timedFn, wait)
	end
	timedFn()
end

--- Function to set up an update timer
---@param interval number The interval to wait before checking for updates
function U.update_timer(interval)
	timer(function()
		local default_config = require("nvim_updater").default_config
		U.get_commit_count()
		if default_config.notify_updates then
			require("nvim_updater").notify_new_commits({ show_none = false, level = vim.log.levels.INFO })
		end
		return interval * 1000
	end)
end

--- Helper function to check if a plugin is installed
---@function is_installed
---@param plugin string The name of the plugin to check
---@return boolean is_installed True if the plugin is installed, false otherwise
function U.is_installed(plugin)
	if pcall(require, plugin) then
		return true
	else
		return false
	end
end

return U
