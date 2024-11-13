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

--- Options table for configuring the floating terminal.
---@class TerminalOptions
---@field command string The shell command to run in the terminal
---@field filetype? string Custom filetype for terminal buffer (optional)
---@field ispreupdate? boolean @deprecated Whether the terminal is for changelog before updating Neovim (optional)
---                            (This is deprecated and will be removed in a future version)
---                            Please use the `callback` function instead.
---@field autoclose? boolean Whether the terminal should be automatically closed (optional)
---@field callback? fun(params?: TerminalCloseParams) Callback function to run after the terminal is closed

--- Callback parameter table for the floating terminal close event.
---@class TerminalCloseParams
---@field ev? table The close event object (optional)
---@field result_code? integer The exit code of the terminal command process (optional)
---@field output? string The complete terminal output (optional)

-- Helper to display floating terminal in a centered, minimal Neovim window.
-- This is useful for running long shell commands like building Neovim.
-- You can pass arguments either as positional values or as a table of options.
---@param command_or_opts string|TerminalOptions Either a shell command (string) or a table of options
---@param filetype? string Custom filetype for terminal buffer (optional if using positional arguments)
---@param ispreupdate? boolean @deprecated Whether the terminal is for changelog before updating Neovim (optional if using positional arguments)
---                            (This is deprecated and will be removed in a future version)
---                            Please use the `callback` function instead.
---@param autoclose? boolean Whether the terminal should be automatically closed (optional if using positional arguments)
---@param callback? fun(params?: TerminalCloseParams) Callback function to run after the terminal is closed
function U.open_floating_terminal(command_or_opts, filetype, ispreupdate, autoclose, callback)
    local opts
    local result_code = -1 -- Indicates the command is still running
    local output_lines = {} -- Store terminal output lines

    -- Determine if the first argument is a table or positional arguments
    if type(command_or_opts) == "table" then
        opts = command_or_opts
    else
        opts = {
            command = command_or_opts or "",
            filetype = filetype or "floating.term", -- Default filetype
            ispreupdate = ispreupdate or false,
            autoclose = autoclose or false,
            callback = callback or nil,
        }
    end

    -- Extract options from the table
    local command = opts.command or ""
    filetype = opts.filetype or "FloatingTerm"
    ispreupdate = opts.ispreupdate or false
    autoclose = opts.autoclose or false
    callback = opts.callback or function()
        return true
    end

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
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    table.insert(output_lines, line)
                end
            end
        end,
        on_stderr = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    table.insert(output_lines, line)
                end
            end
        end,
        on_exit = function(_, exit_code)
            result_code = exit_code
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
                U.notify("Command failed with exit code: " .. exit_code, vim.log.levels.DEBUG)
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

    -- Create an autocmd for the window closing callback
    if callback then
        local winid = tostring(win)
        vim.api.nvim_create_autocmd("WinClosed", {
            pattern = winid, -- Use the window ID as the pattern
            callback = function(ev)
                callback({
                    ev = ev,
                    result_code = result_code,
                    output = table.concat(output_lines, "\n")
                })
                return true
            end,
        })
    end
end

--- Helper function to return the number of pending commits
---@function get_update_status
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

--- Function to execute a shell command and return the output as a table
---@param command string|string[] The shell command(s) to execute
---@return string[] output The output of the shell command
function U.run_hidden_command(command)
	-- Convert the command to a string if it's a table
	if type(command) == "table" then
		command = table.concat(command, "\n")
	end
	-- Execute the command and capture the output
	local handle = io.popen(command)

	-- Check if the handle is nil (command may have failed)
	if not handle then
		error("Failed to run command: " .. command) -- Raise an error if the command failed
	end

	local output = handle:read("*a") -- Read all output
	handle:close() -- Important to close the handle safely

	-- Check if the output is nil to avoid issues with splitting
	if output == nil then
		return {} -- Return an empty table if there is no output
	end

	-- Split output by newline into a table
	local lines = {}
	for line in output:gmatch("[^\n]+") do
		table.insert(lines, line) -- Insert each line into the table
	end

	return lines
end

--- Function to draw a floating window to display data
---@param data string[] The data to display in the floating window
---@return boolean success True if the floating window was successfully drawn
function U.draw_floating_window(data)
	-- Verify the data is not empty
	if not data or #data == 0 then
		U.notify("No data to display", vim.log.levels.WARN)
		return false
	end

	-- Add a padding character to each line
	for i = 1, #data do
		data[i] = data[i] .. " "
	end

	local width = 0
	local height = #data - 2

	-- Find the width of the longest line for proper sizing
	for _, line in ipairs(data) do
		width = math.max(width, #line)
	end

	-- Determine padding and calculate window size
	local padded_width = width + 2
	local padded_height = height + 2

	-- Get the current window's dimensions
	local win_id = vim.api.nvim_get_current_win()
	local win_config = vim.api.nvim_win_get_config(win_id)
	local current_win_width = win_config.width
	local current_win_height = win_config.height

	-- Calculate the center position for the floating window
	local col = math.floor((current_win_width - padded_width) / 2)
	local row = math.floor((current_win_height - padded_height) / 2)

	local buf_id = vim.api.nvim_create_buf(false, true) -- Create a new buffer (scratch)

	-- Set buffer content to the output
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, data)

	-- Set window options for floating window
	local opts = {
		relative = "win",
		win = win_id,
		width = padded_width,
		height = padded_height,
		anchor = "NW",
		col = col,
		row = row,
		border = "rounded", -- Rounded border
	}

	-- Create floating window
	local float_win_id = vim.api.nvim_open_win(buf_id, true, opts)

	-- Disable line numbers
	vim.api.nvim_set_option_value("number", false, { scope = "local", win = float_win_id }) -- Disable line numbers
	vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = float_win_id }) -- Disable relative line numbers

	-- Set additional options for the floating window
	vim.api.nvim_set_option_value("wrap", true, { scope = "local", win = float_win_id }) -- Enable line wrapping
	vim.api.nvim_set_option_value("scrolloff", 0, { scope = "local", win = float_win_id }) -- Disable scrolloff for horizontal
	vim.api.nvim_set_option_value("sidescrolloff", 0, { scope = "local", win = float_win_id }) -- Disable scrolloff for vertical
	vim.api.nvim_set_option_value("list", false, { scope = "local", win = float_win_id }) -- Disable whitespace characters

	-- Helper function to close the floating window
	local function closing()
		vim.api.nvim_win_close(float_win_id, true)
	end

	-- Helper function to pick an item
	local function picking()
		local line = vim.api.nvim_get_current_line()
		local item = line:match("%s*(.*)"):gsub("%s+$", "") -- Remove trailing spaces
		-- Store item in register
		vim.fn.setreg('"', item)
		closing()
	end

	-- Bind keys for closing
	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.api.nvim_buf_set_keymap(buf_id, "n", key, "", {
			noremap = true,
			silent = true,
			callback = function()
				closing()
			end,
			desc = "Close terminal window",
		})
	end

	-- Bind keys for picking
	for _, key in ipairs({ "y", "<CR>", "<Space>" }) do
		vim.api.nvim_buf_set_keymap(buf_id, "n", key, "", {
			noremap = true,
			silent = true,
			callback = function()
				picking()
			end,
			desc = "Select item",
		})
	end

	-- Check for errors
	if float_win_id == 0 then
		U.notify("Failed to create floating window", vim.log.levels.ERROR)
		return false
	end
	return true
end

return U
