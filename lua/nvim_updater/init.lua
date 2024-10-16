-- lua/nvim_updater/init.lua

-- Define the Neovim updater plugin
local P = {}

-- Import the 'utils' module for helper functions
local utils = require("nvim_updater.utils")

-- Default values for plugin options (editable via user config)
P.default_config = {
	source_dir = vim.fn.expand("~/.local/src/neovim"), -- Default Neovim source location
	build_type = "RelWithDebInfo", -- Default build type
	branch = "master", -- Default Neovim branch to track
	check_for_updates = false, -- Checks for new updates automatically
	update_interval = (60 * 60 * 6), -- Update interval in seconds (6 hours)
	notify_updates = false, -- Enable update notification
	verbose = false, -- Default verbose mode
	default_keymaps = false, -- Use default keymaps
}

P.last_status = {
	count = "?",
}

--- Setup default keymaps for updating Neovim or removing source based on user configuration.
---@function setup_plug_keymaps
local function setup_plug_keymaps()
	-- Create <Plug> mappings for update and remove functionalities
	vim.keymap.set("n", "<Plug>(NVUpdateNeovim)", function()
		P.update_neovim()
	end, { desc = "Update Neovim via <Plug>", noremap = false, silent = true })

	vim.keymap.set("n", "<Plug>(NVUpdateNeovimDebug)", function()
		P.update_neovim({ build_type = "Debug" })
	end, { desc = "Update Neovim with Debug build via <Plug>", noremap = false, silent = true })

	vim.keymap.set("n", "<Plug>(NVUpdateNeovimRelease)", function()
		P.update_neovim({ build_type = "Release" })
	end, { desc = "Update Neovim with Release build via <Plug>", noremap = false, silent = true })

	vim.keymap.set("n", "<Plug>(NVUpdateRemoveSource)", function()
		P.remove_source_dir()
	end, { desc = "Remove Neovim source directory via <Plug>", noremap = false, silent = true })

	vim.keymap.set("n", "<Plug(NVUpdateCloneSource)", function()
		P.generate_source_dir()
	end, { desc = "Generate Neovim source directory via <Plug>", noremap = false, silent = true })

	vim.keymap.set("n", "<Plug>(NVUpdateShowNewCommits)", function()
		P.show_new_commits()
	end, { desc = "Show new commits via <Plug>", noremap = false, silent = true })

	vim.keymap.set("n", "<Plug>(NVUpdateShowNewDiffs)", function()
		P.show_new_commits_in_diffview()
	end, { desc = "Show new diffs via <Plug>", noremap = false, silent = true })

	vim.keymap.set("n", "<Plug>(NVUpdatePickNewCommits)", function()
		P.show_new_commits_in_telescope()
	end, { desc = "Show new diffs via <Plug>", noremap = false, silent = true })
end

--- Setup user-friendly key mappings for updating Neovim or removing source.
---@function setup_user_friendly_keymaps
local function setup_user_friendly_keymaps()
	-- Create user-friendly bindings for the <Plug> mappings using <Leader> keys
	if P.default_config.default_keymaps then
		vim.keymap.set(
			"n",
			"<Leader>uU",
			"<Plug>(NVUpdateNeovim)",
			{ desc = "Update Neovim", noremap = true, silent = true }
		)
		vim.keymap.set(
			"n",
			"<Leader>uD",
			"<Plug>(NVUpdateNeovimDebug)",
			{ desc = "Update Neovim with Debug build", noremap = true, silent = true }
		)
		vim.keymap.set(
			"n",
			"<Leader>uR",
			"<Plug>(NVUpdateNeovimRelease)",
			{ desc = "Update Neovim with Release build", noremap = true, silent = true }
		)
		vim.keymap.set(
			"n",
			"<Leader>uC",
			"<Plug>(NVUpdateRemoveSource)",
			{ desc = "Remove Neovim source directory", noremap = true, silent = true }
		)

		vim.keymap.set(
			"n",
			"<Leader>un",
			"<Plug>(NVUpdateShowNewCommits)",
			{ desc = "Show new commits in terminal", noremap = true, silent = true }
		)
	end
end

--- Setup default keymaps during plugin initialization.
---@function setup_default_keymaps
local function setup_default_keymaps()
	setup_plug_keymaps() -- Set up <Plug> mappings
	setup_user_friendly_keymaps() -- Set up user-friendly mappings
end

--- Show new commits then perform update
---@function update_with_changes
function P.update_with_changes()
	P.show_new_commits(true)
end

--- Update Neovim from source and show progress in a floating terminal.
---@param opts table|nil Optional options for the update process (branch, build_type, etc.)
function P.update_neovim(opts)
	opts = opts or {}
	local source_dir = opts.source_dir ~= "" and opts.source_dir or P.default_config.source_dir
	local build_type = opts.build_type ~= "" and opts.build_type or P.default_config.build_type
	local branch = opts.branch ~= "" and opts.branch or P.default_config.branch

	local notification_msg = "Starting Neovim update...\nSource: "
		.. source_dir
		.. "\nBranch: "
		.. branch
		.. "\nBuild: "
		.. build_type
	utils.notify(notification_msg, vim.log.levels.INFO)

	local dir_exists = utils.directory_exists(source_dir)
	local git_commands = ""

	if not dir_exists then
		git_commands = "git clone https://github.com/neovim/neovim " .. source_dir .. " && cd " .. source_dir
	else
		git_commands = "cd " .. source_dir
	end

	-- Checkout branch and pull latest changes
	git_commands = git_commands .. " && git fetch origin && git checkout " .. branch .. " && git pull"

	local build_command = "cd " .. source_dir .. " && make CMAKE_BUILD_TYPE=" .. build_type .. " && sudo make install"

	-- Use the open_floating_terminal from the 'utils' module
	utils.open_floating_terminal(git_commands .. " && " .. build_command, "neovim_updater_term.updating", false, true)

	-- Go to insert mode
	vim.cmd("startinsert")

	-- Update the status count
	P.last_status.count = "0"
end

--- Remove the Neovim source directory or a custom one.
---@function P.remove_source_dir
---@param opts table|nil Optional table for 'source_dir'
---@return boolean success True if the directory was successfully removed, false otherwise
function P.remove_source_dir(opts)
	opts = opts or {}
	local source_dir = opts.source_dir ~= "" and opts.source_dir or P.default_config.source_dir

	if utils.directory_exists(source_dir) then
		-- Check if vim.fs.rm is available
		if vim.fs.rm then
			-- Use pcall to attempt to call the function
			local success, err = pcall(vim.fs.rm, source_dir, { recursive = true, force = true })
			if success then
				utils.notify("Successfully removed Neovim source directory: " .. source_dir, vim.log.levels.INFO)
				utils.notify("Source directory removed with vim.fs.rm", vim.log.levels.DEBUG)
				return true
			else
				if not err then
					err = "Unknown error"
				end
				utils.notify(
					"Error removing Neovim source directory: " .. source_dir .. "\n" .. err,
					vim.log.levels.ERROR
				)
				utils.notify("Source directory removal failed with vim.fs.rm", vim.log.levels.DEBUG)
				return false
			end
		end
		-- Fallback to vim.fn.delete if vim.fs.rm is not available
		local success, err = vim.fn.delete(source_dir, "rf")
		if success == 0 then
			utils.notify("Successfully removed Neovim source directory: " .. source_dir, vim.log.levels.INFO)
			utils.notify("Source directory removed with vim.fn.delete", vim.log.levels.DEBUG)
			return true
		else
			if not err then
				err = "Unknown error"
			end
			utils.notify("Error removing Neovim source directory: " .. source_dir .. "\n" .. err, vim.log.levels.ERROR)
			utils.notify("Source directory removal failed with vim.fn.delete", vim.log.levels.DEBUG)
			return false
		end
	else
		utils.notify("Source directory does not exist: " .. source_dir, vim.log.levels.WARN)
		return false
	end
end

--- Generate the Neovim source directory.
---@function P.generate_source_dir
---@param opts table|nil Optional table for 'source_dir'
---@return string source_dir The source directory
function P.generate_source_dir(opts)
	opts = opts or {}
	-- Define the source
	local source_dir = opts.source_dir ~= "" and opts.source_dir or P.default_config.source_dir
	local repo = "https://github.com/neovim/neovim.git"
	local branch = opts.branch ~= "" and opts.branch or P.default_config.branch

	-- Build the command to fetch the latest changes from the remote repository
	local fetch_command = ("cd ~ && git clone %s %s"):format(repo, source_dir)

	-- Checkout the branch
	local checkout_command = "cd " .. source_dir .. " && git checkout " .. branch

	-- Combine commands
	local complete_command = fetch_command .. " && " .. checkout_command

	-- Notify the user that the clone is starting
	utils.notify("Cloning Neovim source...", vim.log.levels.INFO)

	-- Open a terminal window
	utils.open_floating_terminal(complete_command, "neovim_updater_term.cloning", false, false)

	-- Set the update count to "0"
	P.last_status.count = "0"

	-- Return the source directory
	return source_dir
end

--- Function to return a statusline component
---@function get_statusline
---@return table status The statusline component
---   - count: The number of new commits
---   - text: The text of the status
---   - icon: The icon of the status
---   - icon_text: The icon and text of the status
---   - icon_count: The icon and count of the status
---   - color: The color of the status
function P.get_statusline()
	local status = {}
	local count = P.last_status.count
	status.count = count
	if count == "?" then
		status.text = "ERROR"
		status.icon = "󰨹 "
		status.color = "DiagnosticError"
	elseif count == "0" then
		status.text = "Up to date"
		status.icon = "󰅠 "
		status.color = "DiagnosticOk"
	elseif count == "1" then
		status.text = count .. " new update"
		status.icon = "󰅢 "
		status.color = "DiagnosticWarn"
	else
		status.text = count .. " new updates"
		status.icon = "󰅢 "
		status.color = "DiagnosticWarn"
	end

	status.icon_text = status.icon .. " " .. status.text
	status.icon_count = status.icon .. " " .. count

	return status
end

---@class NVNoticeOpts
---@field show_none boolean|table Optional. If a boolean, determines whether to show a notification if there are no new commits.
---@field level number Optional. The log level to use for the notification. Only used if `show_none` is a boolean.

--- Check for new commits and create a notification if there are any.
--- Can be called with either positional arguments or a table of options.
--- @param show_none boolean|NVNoticeOpts Optional.
---   If a boolean, determines whether to show a notification if there are no new commits.
---   If a table, it can contain `show_none` and `level` options.
--- @param level? number Optional.
---   The log level to use for the notification. Only used if `show_none` is a boolean.
function P.notify_new_commits(show_none, level)
	-- If the first argument is a table, treat it as an options table.
	if type(show_none) == "table" then
		local opts = show_none
		show_none = opts.show_none
		level = opts.level
	end
	-- Set default value for show_none to true
	if show_none == nil then
		show_none = true
	end

	-- Set default value for level to INFO
	if level == nil then
		level = vim.log.levels.INFO
	end

	-- Define the path to the Neovim source directory
	local source_dir = P.default_config.source_dir

	-- Build the command to fetch the latest changes from the remote repository
	local fetch_command = ("cd %s && git fetch"):format(source_dir)

	-- Execute the fetch command
	vim.fn.system(fetch_command)

	-- Build the command to get the current branch name
	local current_branch_cmd = ("cd %s && git rev-parse --abbrev-ref HEAD"):format(source_dir)

	local current_branch = vim.fn.system(current_branch_cmd):gsub("%s+", "") -- Trim whitespace

	-- Check for errors in executing the branch command
	if vim.v.shell_error ~= 0 then
		utils.notify("Failed to retrieve the current branch.", vim.log.levels.ERROR)
		return
	end

	-- Build the command to count new commits in the remote branch
	local commit_count_cmd = ("cd %s && git rev-list --count %s..origin/%s"):format(
		source_dir,
		current_branch,
		current_branch
	)

	-- Execute the command to get the count of new commits
	local commit_count = vim.fn.system(commit_count_cmd):gsub("%s+", "") -- Trim whitespace

	-- Check for errors in executing the commit count command
	if vim.v.shell_error == 0 then
		if tonumber(commit_count) > 0 then
			-- Adjust the notification message based on the number of commits found
			local commit_word = tonumber(commit_count) == 1 and "commit" or "commits"
			utils.notify(("%d new Neovim %s."):format(tonumber(commit_count), commit_word), level, true)
		else
			if show_none then
				utils.notify("No new Neovim commits.", level, true)
			end
		end
	else
		utils.notify("Failed to count new Neovim commits.", vim.log.levels.ERROR)
	end
end

---@class NVCommitsOpts
---@field isupdate boolean True if this is part of an update
---@field short boolean True to only show short commit messages

--- Show commits that exist in the remote branch but not in the local branch.
--- @param isupdate? boolean|NVCommitsOpts Optional. If a boolean, determines whether to update the commit list.
---   If a table, it can contain `isupdate` and `short` options.
--- @param short? boolean Optional. Whether to show a short commit list. Only used if `isupdate` is a boolean.
function P.show_new_commits(isupdate, short)
	-- If the first argument is a table, treat it as an options table.
	if type(isupdate) == "table" then
		local opts = isupdate
		isupdate = opts.isupdate
		short = opts.short
	end
	-- Define the path to the Neovim source directory
	local source_dir = P.default_config.source_dir

	-- Set short default to true
	local shortmessage = "--decorate=short "
	if short == nil then
		short = true
	end

	-- Build the command to fetch the latest changes from the remote repository
	local fetch_command = ("cd %s && git fetch"):format(source_dir)

	-- Execute the fetch command
	vim.fn.system(fetch_command)

	-- Build the git command to show commits that are in the remote branch but not in local
	local current_branch_cmd = ("cd %s && git rev-parse --abbrev-ref HEAD"):format(source_dir)

	local current_branch = vim.fn.system(current_branch_cmd):gsub("%s+", "") -- Trim whitespace

	-- Build the command to count new commits in the remote branch
	local commit_count_cmd = ("cd %s && git rev-list --count %s..origin/%s"):format(
		source_dir,
		current_branch,
		current_branch
	)

	-- Set up shortmessage
	if short then
		shortmessage = "--decorate=short --pretty=oneline "
	end

	-- Execute the command to get the count of new commits
	local commit_count = vim.fn.system(commit_count_cmd):gsub("%s+", "") -- Trim whitespace

	-- Check for errors in executing the command
	if vim.v.shell_error == 0 then
		if tonumber(commit_count) > 0 then
			-- Display the commit logs
			utils.notify("Opening Neovim changes in terminal", vim.log.levels.INFO)
			-- Open the terminal in a new window
			local term_command = ("cd %s && git --no-pager log %s%s..origin/%s"):format(
				source_dir,
				shortmessage,
				current_branch,
				current_branch
			)
			utils.open_floating_terminal({
				command = term_command,
				filetype = "neovim_updater_term.changes",
				ispreupdate = isupdate,
				autoclose = false,
			})
		else
			utils.notify("No new Neovim commits.", vim.log.levels.INFO)
			-- Update status count
			P.last_status.count = "0"
		end
	else
		utils.notify("Failed to retrieve commit logs.", vim.log.levels.ERROR)
	end
end

--- Show commits that exist in the remote branch but not in the local branch.
function P.show_new_commits_in_diffview()
	-- Check for diffview plugin
	-- If not installed, fallback to using the floating terminal window
	if not utils.is_installed("diffview") then
		utils.notify("DiffView plugin not found.", vim.log.levels.ERROR)
		P.show_new_commits()
		return
	end
	-- Define the path to the Neovim source directory
	local source_dir = P.default_config.source_dir

	-- Build the command to fetch the latest changes from the remote repository
	local fetch_command = ("cd %s && git fetch"):format(source_dir)

	-- Execute the fetch command
	vim.fn.system(fetch_command)

	-- Build the git command to show commits that are in the remote branch but not in local
	local current_branch_cmd = ("cd %s && git rev-parse --abbrev-ref HEAD"):format(source_dir)

	local current_branch = vim.fn.system(current_branch_cmd):gsub("%s+", "") -- Trim whitespace

	-- Check for errors in executing the command
	if vim.v.shell_error == 0 then
		utils.notify("Opening Neovim changes in Diffview", vim.log.levels.INFO)
		vim.cmd(":DiffviewOpen HEAD...origin/" .. current_branch .. " -C=" .. source_dir)
		require("diffview.actions").open_commit_log()
	else
		utils.notify("Failed to retrieve commit logs.", vim.log.levels.ERROR)
	end
end

--- Show commits that exist in the remote branch but not in the local branch.
function P.show_new_commits_in_telescope()
	-- Check for telescope plugin
	-- If not installed, fallback to using the floating terminal window
	if not utils.is_installed("telescope") then
		utils.notify("Telescope plugin not found.", vim.log.levels.ERROR)
		P.show_new_commits()
		return
	end

	-- Define the path to the Neovim source directory
	local source_dir = P.default_config.source_dir

	-- Build the command to fetch the latest changes from the remote repository
	local fetch_command = ("cd %s && git fetch"):format(source_dir)

	-- Execute the fetch command
	vim.fn.system(fetch_command)

	-- Build the git command to show commits that are in the remote branch but not in local
	local current_branch_cmd = ("cd %s && git rev-parse --abbrev-ref HEAD"):format(source_dir)

	local current_branch = vim.fn.system(current_branch_cmd):gsub("%s+", "") -- Trim whitespace

	-- Setup the git command for telescope
	local tele_command = ("git log HEAD...origin/%s --pretty=oneline --abbrev-commit -- ."):format(current_branch)

	-- Make it a table like telescope prefers
	local tele_cmd = vim.split(tele_command, " ")

	-- Get the telescope picker
	local builtin = require("telescope.builtin")

	-- Notify
	utils.notify("Opening Neovim changes in Diffview", vim.log.levels.INFO)

	-- Use Telescope's built-in git_commits picker to show commits
	builtin.git_commits({
		cwd = source_dir, -- Set current working directory to the Neovim source
		git_command = tele_cmd,
	})
end

--- Initialize Neovim updater plugin configuration
---@function P.setup
---@param user_config table|nil User configuration overriding default values
function P.setup(user_config)
	P.default_config = vim.tbl_deep_extend("force", P.default_config, user_config or {})

	-- Setup default keymaps only if not overridden by user configuration
	setup_default_keymaps()

	-- Setup Neovim user commands
	P.setup_usercmds()

	-- Check for updates
	if P.default_config.check_for_updates then
		utils.get_commit_count()
		if P.default_config.update_interval > 0 then
			utils.update_timer(P.default_config.update_interval)
		end
	end
end

--- Create user commands for both updating and removing Neovim source directories
---@function P.setup_usercmd
function P.setup_usercmds()
	--- Define NVUpdateNeovim command to accept branch, build_type, and source_dir as optional arguments
	vim.api.nvim_create_user_command("NVUpdateNeovim", function(opts)
		local args = vim.split(opts.args, " ")
		local branch = (args[1] == "" and P.default_config.branch or args[1])
		local build_type = (args[2] == "" and P.default_config.build_type or args[2])
		local source_dir = (args[3] == "" and P.default_config.source_dir or args[3])

		P.update_neovim({ branch = branch, build_type = build_type, source_dir = source_dir })
	end, {
		desc = "Update Neovim with optional branch, build_type, and source_dir",
		nargs = "*", -- Accept multiple (optional) arguments
	})

	--- Define NVUpdateCloneSource command to accept source_dir and branch as optional arguments
	vim.api.nvim_create_user_command("NVUpdateCloneSource", function(opts)
		local args = vim.split(opts.args, " ")
		local source_dir = (args[1] == "" and P.default_config.source_dir or args[1])
		local branch = (args[2] == "" and P.default_config.branch or args[2])

		P.generate_source_dir({ source_dir = source_dir, branch = branch })
	end, {
		desc = "Clone Neovim source directory with optional branch",
		nargs = "*", -- Accept multiple (optional) arguments
	})

	--- Define NVUpdateRemoveSource command to optionally accept a custom `source_dir`
	vim.api.nvim_create_user_command("NVUpdateRemoveSource", function(opts)
		local args = vim.split(opts.args, " ")
		P.remove_source_dir({
			source_dir = #args > 0 and (args[1] == "" and P.default_config.source_dir or args[1]) or nil,
		})
	end, {
		desc = "Remove Neovim source directory (optionally specify custom path)",
		nargs = "?", -- Allow one optional argument
	})

	--- Define NVUpdateShowNewCommits command to show new commits in the terminal
	vim.api.nvim_create_user_command("NVUpdateShowNewCommits", function()
		P.show_new_commits()
	end, {
		desc = "Show new commits in terminal",
	})

	--- Define NVUpdateShowNewDiffs command to show new commits in Diffview
	vim.api.nvim_create_user_command("NVUpdateShowNewDiffs", function()
		P.show_new_commits_in_diffview()
	end, {
		desc = "Show new commits in Diffview",
	})
end

return P
