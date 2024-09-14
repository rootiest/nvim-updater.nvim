-- health/nvim_updater.lua

local health = vim.health or require("health") -- Handles compatibility between older/newer versions of Neovim
local fn = vim.fn
local fs = vim.fs -- Module for filesystem operations in Neovim 0.10+
local utils = require("nvim_updater.utils")
local check_write_permissions = utils.check_write_permissions

-- Neovim Updater Health Checks
---@function check
local function check()
	health.start("Neovim Updater Health Check")

	-- Load user configuration
	local user_config = require("nvim_updater").default_config or {}
	local source_dir = user_config.source_dir or "~/.local/src/neovim"
	source_dir = fn.expand(source_dir) -- Ensure "~" paths are correctly expanded
	local branch = user_config.branch or "master"

	-- Directory Existence Check
	if fn.isdirectory(source_dir) == 1 then
		health.ok("Source directory exists: " .. source_dir)

		-- Check that the plugin reflects the same
		if utils.directory_exists(source_dir) then
			health.ok("Source directory matches plugin directory: " .. source_dir)
		else
			health.warn("Source directory does not match plugin directory: " .. source_dir)
		end

		-- Write permission check using temp file test if the directory exists
		if check_write_permissions(source_dir) then
			health.ok("Write access to source directory checked successfully")
		else
			health.warn(
				"No write access to source directory. Make sure you have correct permissions for: " .. source_dir
			)
			health.info(
				"Hint: Try running ':RemoveNeovimSource' to remove the source directory and retry after correcting permissions."
			)
		end
	else
		health.warn("Source directory does not exist: " .. source_dir)

		-- If the source directory doesn't exist, check write permissions for its parent directory
		local parent_dir = fs.dirname(source_dir)
		if check_write_permissions(parent_dir) then
			health.ok(
				"Write access to parent directory (" .. parent_dir .. ") available for creating the source directory."
			)
		else
			health.error(
				"No write access to parent directory (" .. parent_dir .. "). Unable to create the source directory."
			)
			health.info("Hint: Adjust permissions of the parent directory or try a different 'source_dir' path.")
		end
	end

	-- Remote Branch Existence Check
	local git_output = fn.systemlist("git ls-remote --heads https://github.com/neovim/neovim " .. branch)
	if fn.empty(git_output) == 1 then
		health.error("Branch '" .. branch .. "' does not exist on the Neovim GitHub repository!")
	else
		health.ok("Remote branch exists: " .. branch)
	end
end

return {
	check = check,
}
