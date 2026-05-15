--- @since 26.5.6

-- The module to handle the paste command

-- Import the utilities module
local utils = require(".utils")

-- The module table
local M = {}

-- Function to handle the paste command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- If the hovered item is not a directory or smart paste is not wanted
	if
		not utils.hovered_item_is_dir()
		or not (config.smart_paste or utils.table_pop(args, "smart", false))
	then

		-- Just paste the items inside the current directory
		-- and exit the function
		return ya.emit("paste", args)
	end

	-- Otherwise, enter the directory
	ya.emit("enter", {})

	-- Paste the items inside the directory
	ya.emit("paste", args)

	-- Leave the directory
	ya.emit("leave", {})
end

-- Return the module table
return M
