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
		vim.notify("Invalid message type passed to health_msg: " .. msg_type, vim.log.levels.WARN)
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
function U.notify(message, level)
	vim.notify(message, level, { title = "Neovim Updater" })
end

--- Helper to display floating terminal in a centered, minimal Neovim window.
--- This is useful for running long shell commands like building Neovim.
---@param command string Shell command to be executed inside the terminal
---@param filetype string Custom filetype for terminal buffer (for integration if needed)
---@function open_floating_terminal
function U.open_floating_terminal(command, filetype)
	-- Create a new buffer for the terminal, set it as non-listed and scratch
	local buf = vim.api.nvim_create_buf(false, true)
	if not buf or buf == 0 then
		vim.notify("Failed to create terminal buffer", vim.log.levels.ERROR, { title = "Floating Terminal" })
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
		vim.notify("Failed to create floating window", vim.log.levels.ERROR, { title = "Floating Window" })
		return
	end

	-- Set buffer and window options
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	vim.api.nvim_set_option_value("winblend", 10, { win = win })

	-- Run the terminal command
	vim.fn.termopen(command, {
		on_exit = function(_, exit_code)
			if exit_code == 0 then
				vim.notify("Command completed successfully!", vim.log.levels.INFO, { title = "Floating Terminal" })
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
				-- If NVIMUPDATER_HEADLESS is set, exit immediately
				if os.getenv("NVIMUPDATER_HEADLESS") then
					vim.cmd("qa")
				end
			else
				vim.notify(
					"Command failed with exit code: " .. exit_code,
					vim.log.levels.ERROR,
					{ title = "Floating Terminal" }
				)
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

return U
