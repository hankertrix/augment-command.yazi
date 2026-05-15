--- @since 26.5.6

-- The module to handle the copy command

-- The module table
local M = {}

-- The function to handle the copy command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- Call the copy command with item group handling
	return require(".utils").handle_yazi_command("copy", args, config)
end

-- Return the module table
return M
