--- @since 26.5.6

-- The module to handle the parent arrow command

-- Import the utilities module
local utils = require(".utils")

-- The module table
local M = {}

-- Function to get the directory items in the parent directory
---@type fun(
---	directories_only: boolean,    -- Whether to only get directories
---): string[] directory_items The list of paths to the directory items
local get_parent_directory_items = ya.sync(function(_, directories_only)

	-- Initialise the list of directory items
	local directory_items = {}

	-- Get the parent directory
	local parent_directory = cx.active.parent

	-- If the parent directory doesn't exist,
	-- return the empty list of directory items
	if not parent_directory then return directory_items end

	-- Otherwise, iterate over the items in the parent directory
	for _, item in ipairs(parent_directory.files) do

		-- If the directories only flag is passed,
		-- and the item is not a directory,
		-- then skip the item
		if directories_only and not item.cha.is_dir then goto continue end

		-- Otherwise, add the item to the list of directory items
		table.insert(directory_items, item)

		-- The continue label to skip the item
		::continue::
	end

	-- Return the list of directory items
	return directory_items
end)

-- Function to execute the parent arrow command
---@type fun(
---	args: ParsedArgs,    -- The arguments passed to the plugin
---	config: Configuration,    -- The configuration object
---): nil
local exec = ya.sync(function(_, args, config)

	-- Gets the parent directory
	local parent_directory = cx.active.parent

	-- If the parent directory doesn't exist,
	-- then exit the function
	if not parent_directory then return end

	-- Get the offset from the arguments given
	local offset = table.remove(args, 1) or 1

	-- Get the type of the offset
	local offset_type = type(offset)

	-- If the offset is not a number,
	-- then show an error that the offset is not a number
	-- and exit the function
	if offset_type ~= "number" then
		return utils.throw_error(
			"The given offset is not of the type 'number', "
				.. "instead it is a '%s', "
				.. "with value '%s'",
			offset_type,
			tostring(offset)
		)
	end

	-- Get the number of items in the parent directory
	local number_of_items = #parent_directory.files

	-- Initialise the new cursor index
	-- to the current cursor index
	local new_cursor_index = parent_directory.cursor

	-- Get whether the user wants to sort directories first
	local sort_directories_first = cx.active.pref.sort_dir_first

	-- If wraparound file navigation is wanted
	-- and the no_wrap argument isn't passed
	if
		config.wraparound_file_navigation
		and not utils.table_pop(args, "no_wrap", false)
	then

		-- If the user sorts their directories first
		if sort_directories_first then

			-- Get the directories in the parent directory
			local directories = get_parent_directory_items(true)

			-- Get the number of directories in the parent directory
			local number_of_directories = #directories

			-- If the number of directories is 0, then exit the function
			if number_of_directories == 0 then return end

			-- Get the new cursor index by adding the offset,
			-- and modding the whole thing by the number of directories
			new_cursor_index = (parent_directory.cursor + offset)
				% number_of_directories

		-- Otherwise, if the user doesn't sort their directories first
		else

			-- Get the new cursor index by adding the offset,
			-- and modding the whole thing by the number of
			-- items in the parent directory
			new_cursor_index = (parent_directory.cursor + offset)
				% number_of_items
		end

	-- Otherwise, get the new cursor index normally
	-- by adding the offset to the cursor index
	else
		new_cursor_index = parent_directory.cursor + offset
	end

	-- Increment the cursor index by 1.
	-- The cursor index needs to be increased by 1
	-- as the cursor index is 0-based, while Lua
	-- tables are 1-based.
	new_cursor_index = new_cursor_index + 1

	-- Get the starting index of the loop
	local start_index = new_cursor_index

	-- Get the ending index of the loop.
	--
	-- If the offset given is negative, set the end index to 1,
	-- as the loop will iterate backwards.
	-- Otherwise, if the step given is positive,
	-- set the end index to the number of items in the
	-- parent directory.
	local end_index = offset < 0 and 1 or number_of_items

	-- Get the step for the loop.
	--
	-- If the offset given is negative, set the step to -1,
	-- as the loop will iterate backwards.
	-- Otherwise, if the step given is positive, set
	-- the step to 1 to iterate forwards.
	local step = offset < 0 and -1 or 1

	-- Iterate over the parent directory items
	for i = start_index, end_index, step do

		-- Get the directory item
		local directory_item = parent_directory.files[i]

		-- If the directory item exists and is a directory
		if directory_item and directory_item.cha.is_dir then

			-- Emit the command to change directory to
			-- the directory item and exit the function
			return ya.emit("cd", { directory_item.url })
		end
	end
end)

-- Function to handle the parent arrow command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- If smooth scrolling is not wanted,
	-- call the function to execute the parent arrow command
	if not config.smooth_scrolling then return exec(args, config) end

	-- Otherwise, smooth scrolling is wanted,
	-- so get the number of steps from the arguments given
	local steps = table.remove(args, 1) or 1

	-- Call the function to smoothly scroll the parent arrow command
	utils.smoothly_scroll(
		steps,
		config.scroll_delay,
		function(step) exec(utils.merge_tables({ step }, args), config) end
	)
end

-- Return the module table
return M
