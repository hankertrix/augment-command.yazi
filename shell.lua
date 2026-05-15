--- @since 26.5.6

-- The module to handle the shell command

-- The module table
local M = {}

-- Function to handle the shell command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- Call the shell function
	require(".utils-shell").handle(args, config)
end

-- Return the module table
return M
