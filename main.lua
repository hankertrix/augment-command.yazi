--- @since 26.8.15

-- The plugin's main module
--
-- Currently doesn't do anything other
-- than warning the user about wrong syntax,
-- since this file is required for all plugins
-- to be installable using ya pkg

-- Import the utilities module
local utils = require(".utils")

-- The module table
local M = {}

-- The error to show
local ERROR_STRING = table.concat({
	"Invalid syntax, please use `plugin augment-command.command`"
		.. "to execute a command in this plugin.",
	"For example, use `plugin augment-command.open` for the open command.",
}, "\n\n")

-- Function to tell the user that they should call a specific file
-- in the plugin instead of the plugin itself
function M:entry() return utils.show_error(ERROR_STRING, { timeout = 10 }) end

-- Return the module table
return M
