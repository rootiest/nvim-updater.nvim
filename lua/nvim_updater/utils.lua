-- lua/nvim_updater/utils.lua

local U = {}

--- Adds an icon to a health check message based on severity type (ok, warn, error, info)
---@param msg_type string The type of health check message ('ok', 'warn', 'error', 'info')
---@param message string The actual message content
---@return string The message prepended with the appropriate icon
function U.add_icon_to_message(msg_type, message)
	local icons = {
		ok = "󰱒", -- Icon for success (OK)
		warn = "", -- Icon for warning (WARN)
		error = "", -- Icon for error (ERROR)
		info = "", -- Icon for information (INFO)
	}

	-- Select the correct icon based on the message type
	local icon = icons[msg_type] or ""
	return icon .. " " .. message
end

--- Prints a health check message based on its type, automatically appending an appropriate icon.
--- This abstracts away the manual use of health.ok, health.warn, etc.
---@param msg_type string The health message type ('ok', 'warn', 'error', 'info')
---@param message string The health message content
function U.health_msg(msg_type, message)
	local health = vim.health or require("health") -- Maintain compatibility with older versions

	-- Add icon to the message using the defined helper
	local formatted_message = U.add_icon_to_message(msg_type, message)

	-- Call corresponding health function depending on the message type
	if msg_type == "ok" then
		health.ok(formatted_message)
	elseif msg_type == "warn" then
		health.warn(formatted_message)
	elseif msg_type == "error" then
		health.error(formatted_message)
	elseif msg_type == "info" then
		health.info(formatted_message)
	else
		U.notify("Invalid message type passed to health_msg: " .. msg_type, vim.log.levels.WARN)
	end
end

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
	-- If config verbose = false then suppress info notifications
	if level == vim.log.levels.INFO and not default_config.verbose then
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
			vim.cmd(action) -- Run the Vim command
		else
			U.notify("Action must be a function or a string", vim.log.levels.ERROR)
		end
	end
	-- Create a new buffer
	local buf = vim.api.nvim_create_buf(false, true) -- Create a new empty buffer
	-- Set the prompt text in the buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { prompt, "y/n: " })
	-- Create a floating window to display the buffer
	local win_height = 2 -- Height of floating window
	local win_width = math.floor(vim.o.columns * 0.25) -- Width of floating window
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
	-- Define the yes function
	local yes = function()
		vim.api.nvim_win_close(win, true)
		perform_action() -- Perform the action
		return true
	end
	-- Define the no function
	local no = function()
		vim.api.nvim_win_close(win, true)
		U.notify("Action Canceled", vim.log.levels.INFO)
	end
	-- Define buffer-specific key mappings
	local keymaps = {
		y = function()
			yes()
		end,
		n = function()
			no()
		end,
		q = function()
			no()
		end,
		["<Esc>"] = function()
			no()
		end,
	}
	-- Set the key mappings
	for key, callback in pairs(keymaps) do
		vim.api.nvim_buf_set_keymap(buf, "n", key, "", {
			noremap = true,
			nowait = true,
			callback = callback,
		})
	end

	return false
end

--- Helper to display floating terminal in a centered, minimal Neovim window.
--- This is useful for running long shell commands like building Neovim.
---@param command string Shell command to be executed inside the terminal
---@param filetype string Custom filetype for terminal buffer (for integration if needed)
---@param ispreupdate? boolean Whether the terminal is for changelog before updating Neovim
---@param autoclose? boolean Whether the terminal should be automatically closed
---@function open_floating_terminal
function U.open_floating_terminal(command, filetype, ispreupdate, autoclose)
	-- Create a new buffer for the terminal, set it as non-listed and scratch
	local buf = vim.api.nvim_create_buf(false, true)
	if not buf or buf == 0 then
		U.notify("Failed to create terminal buffer", vim.log.levels.ERROR)
		return
	end

	-- Set the filetype of the terminal buffer
	vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })

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

	-- Create the floating window
	local win = vim.api.nvim_open_win(buf, true, win_opts)
	if not win or win == 0 then
		U.notify("Failed to create floating window", vim.log.levels.ERROR)
		return
	end

	-- Set buffer and window options
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	vim.api.nvim_set_option_value("winblend", 10, { win = win })

	-- Create the closing callback
	local closing = function()
		-- Close the terminal window
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
		-- If NVIMUPDATER_HEADLESS is set, exit immediately
		if os.getenv("NVIMUPDATER_HEADLESS") then
			vim.cmd("qa")
		end
		-- If isupdate is true, execute NVUpdateNeovim
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
				vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
					noremap = true,
					silent = true,
					callback = function()
						closing()
					end,
					desc = "Close terminal window",
				})
				vim.api.nvim_buf_set_keymap(buf, "n", "<Space>", "", {
					noremap = true,
					silent = true,
					callback = function()
						closing()
					end,
					desc = "Close terminal window",
				})
				vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
					noremap = true,
					silent = true,
					callback = function()
						closing()
					end,
					desc = "Close terminal window",
				})
				vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
					noremap = true,
					silent = true,
					callback = function()
						closing()
					end,
					desc = "Close terminal window",
				})
				vim.api.nvim_buf_set_keymap(buf, "n", "y", "", {
					noremap = true,
					silent = true,
					callback = function()
						closing()
					end,
					desc = "Close terminal window",
				})
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

	-- Enter terminal's insert mode
	vim.treesitter.stop(buf)
	vim.api.nvim_set_current_win(win)
	vim.cmd("startinsert!")
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
		U.get_commit_count()
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
