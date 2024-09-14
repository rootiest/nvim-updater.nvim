-- lua/nvim_updater/init.lua

-- Import the 'utils' module for helper functions
local utils = require("nvim_updater.utils")
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

--- Update Neovim from source and show progress in a floating terminal.
---@param opts table|nil Optional options for the update process (branch, build_type, etc.)
function M.update_neovim(opts)
	opts = opts or {}
	local source_dir = opts.source_dir ~= "" and opts.source_dir or default_config.source_dir
	local build_type = opts.build_type ~= "" and opts.build_type or default_config.build_type
	local branch = opts.branch ~= "" and opts.branch or default_config.branch

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
	utils.open_floating_terminal(git_commands .. " && " .. build_command, "neovim_updater_term")
end
--- Remove the Neovim source directory or a custom one.
---@function M.remove_source_dir
---@param opts table|nil Optional table for 'source_dir'
function M.remove_source_dir(opts)
	opts = opts or {}
	local source_dir = opts.source_dir ~= "" and opts.source_dir or default_config.source_dir

	if utils.directory_exists(source_dir) then
		-- Safely attempt to delete the directory recursively
		local success = vim.fn.delete(source_dir, "rf")
		if success == 0 then
			utils.notify("Successfully removed Neovim source directory: " .. source_dir, vim.log.levels.INFO)
		else
			utils.notify("Error removing Neovim source directory: " .. source_dir, vim.log.levels.ERROR)
		end
	else
		utils.notify("Source directory does not exist: " .. source_dir, vim.log.levels.WARN)
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
