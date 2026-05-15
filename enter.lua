--- @since 26.5.6

-- The module to handle the enter command

-- Import the utilities module
local utils = require(".utils")

-- The module table
local M = {}

-- Function to handle the enter command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- If the hovered item is not a directory
	if not utils.hovered_item_is_dir() then

		-- If smart enter is wanted,
		-- call the function for the open command
		-- and exit the function
		if config.smart_enter or utils.table_pop(args, "smart", false) then
			return utils.emit_augmented_command("open", args)
		end

		-- Otherwise, just exit the function
		return
	end

	-- Otherwise, always emit the enter command,
	ya.emit("enter", args)

	-- If the user doesn't want to skip single subdirectories on enter,
	-- or one of the arguments passed is no skip,
	-- then exit the function
	if
		not config.skip_single_subdirectory_on_enter
		or utils.table_pop(args, "no_skip", false)
	then
		return
	end

	-- Otherwise, call the function to skip child directories
	-- with only a single directory inside
	utils.skip_single_child_directories(utils.get_current_directory())
end

-- Return the module table
return M
