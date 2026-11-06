--- @since 26.8.15

-- The module to handle the remove command

-- Import the configuration module
local config_utils = require(".main")

-- The module table
local M = {}

-- The function to handle the remove command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = config_utils.parse_args_and_init(job)

	-- Call the remove command with item group handling
	return require(".augment").augment_yazi_command(
		"remove",
		args,
		config,
		function(arguments, paths)

			-- Iterate over the given paths
			for _, path in ipairs(paths) do

				-- If the path is protected
				-- remove the force flag from the given arguments
				if config_utils.path_is_protected(path) then
					require(".utils").table_pop(arguments, "force")
				end
			end

			-- Return the modified arguments
			return arguments
		end
	)
end

-- Return the module table
return M
