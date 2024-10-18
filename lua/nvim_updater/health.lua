-- health/nvim_updater.lua

-- Import utils for helper functions
local health = vim.health or require("health")
local fn = vim.fn
local fs = vim.fs
local utils = require("nvim_updater.utils")
local check_write_permissions = utils.check_write_permissions

local function get_nvim_version()
	local version = vim.version()
	local versions = {
		major = version.major,
		minor = version.minor,
		patch = version.patch,
		prerelease = version.prerelease,
		build = version.build,
		simple = string.format(
			"%d.%d.%d (%s-%s)",
			version.major,
			version.minor,
			version.patch,
			version.prerelease,
			version.build
		),
	}
	return versions
end

-- Neovim Updater Health Checks
---@function check
local function check()
	health.start("Neovim Updater Health Check")

	-- Get neovim version info
	local nvim_version = get_nvim_version()
	if nvim_version.major > 0 or nvim_version.minor >= 10 then
		utils.health_msg("ok", "Neovim version: v" .. nvim_version.simple)
	elseif nvim_version.major == 0 and nvim_version.minor >= 9 then
		utils.health_msg("warn", "Neovim version: v" .. nvim_version.simple .. " (Deprecated)")
	else
		utils.health_msg("error", "Neovim version: v" .. nvim_version.simple .. " (Unsupported)")
	end
	-- Load user configuration
	local user_config = require("nvim_updater").default_config or {}
	local source_dir = user_config.source_dir or "~/.local/src/neovim"
	source_dir = fn.expand(source_dir)
	local branch = user_config.branch or "master"

	-- Directory Existence Check
	if fn.isdirectory(source_dir) == 1 then
		utils.health_msg("ok", "Source directory exists: " .. source_dir)

		-- Check that the plugin reflects the same
		if utils.directory_exists(source_dir) then
			utils.health_msg("ok", "Source directory matches plugin directory: " .. source_dir)
		else
			utils.health_msg("warn", "Source directory does not match plugin directory: " .. source_dir)
		end

		-- Write permission check using temp file test if the directory exists
		if check_write_permissions(source_dir) then
			utils.health_msg("ok", "Write access to source directory checked successfully")
		else
			utils.health_msg("warn", "No write access to source directory: " .. source_dir)
			utils.health_msg("info", "Hint: Run ':NVRemoveSource' to remove and retry with correct permissions.")
		end
	else
		utils.health_msg("warn", "Source directory does not exist: " .. source_dir)
		utils.health_msg("info", "Hint: Run ':NVCloneSource' to clone the Neovim source directory.")

		-- Parent directory write permissions check
		local parent_dir = fs.dirname(source_dir)
		if check_write_permissions(parent_dir) then
			utils.health_msg("ok", "Write access to parent directory (" .. parent_dir .. ") is available.")
		else
			utils.health_msg("error", "No write access to parent directory: " .. parent_dir)
			utils.health_msg("info", "Hint: Adjust permissions or try a different 'source_dir'.")
		end
	end

	-- Remote Branch Existence Check
	local git_output = fn.systemlist("git ls-remote --heads https://github.com/neovim/neovim " .. branch)
	if fn.empty(git_output) == 1 then
		utils.health_msg("error", "Branch '" .. branch .. "' does not exist on the Neovim GitHub repo!")
	else
		utils.health_msg("ok", "Remote branch exists: " .. branch)
	end
end

return {
	check = check,
}
