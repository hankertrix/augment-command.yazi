--- @since 26.8.15

-- The module to handle the shell command

-- The module table
local M = {}

-- Function to handle the shell command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require(".main").parse_args_and_init(job)

	-- Call the shell function
	require(".utils-shell").handle(args, config)
end

-- Return the module table
return M
