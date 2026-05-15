--- @since 26.5.6

-- The module to handle the remove command

-- Import the configuration module
local utils_config = require("augment-command")

-- The module table
local M = {}

-- The function to handle the remove command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = utils_config.parse_args_and_init(job)

	-- Call the remove command with item group handling
	return require(".utils").handle_yazi_command(
		"remove",
		args,
		config,
		function(arguments)

			-- If the current directory is protected,
			-- remove the force flag from the given arguments
			if utils_config.current_directory_protected() then
				require(".utils").table_pop(arguments, "force")
			end

			-- Return the modified arguments
			return arguments
		end
	)
end

-- Return the module table
return M
