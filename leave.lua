--- @since 26.5.6

-- The module to handle the leave command

-- Import the utilities module
local utils = require(".utils")

-- The module table
local M = {}

-- Function to handle the leave command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- Always emit the leave command
	ya.emit("leave", args)

	-- If the user doesn't want to skip single subdirectories on leave,
	-- or one of the arguments passed is no skip,
	-- then exit the function
	if
		not config.skip_single_subdirectory_on_leave
		or utils.table_pop(args, "no_skip", false)
	then
		return
	end

	-- Otherwise, initialise the directory to the current directory
	local directory = utils.get_current_directory()

	-- Get the tab preferences
	local tab_preferences = utils.get_tab_preferences()

	-- Start an infinite loop
	while true do

		-- Get all the items in the current directory
		local directory_items =
			utils.get_directory_items(directory, tab_preferences.show_hidden)

		-- If the number of directory items is not 1,
		-- then break out of the loop.
		if #directory_items ~= 1 then break end

		-- Get the parent directory of the current directory
		local parent_directory = Url(directory).parent

		-- If the parent directory is nil,
		-- break the loop
		if not parent_directory then break end

		-- Otherwise, set the new directory to the parent directory
		directory = tostring(parent_directory.path)
	end

	-- Emit the change directory command to change to the directory variable
	ya.emit("cd", { directory })
end

-- Return the module table
return M
