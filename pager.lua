--- @since 26.5.6

-- The module to handle the pager command

-- The module table
local M = {}

-- Function to handle the pager command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- Get the pager environment variable
	local pager = os.getenv("PAGER")

	-- If the pager is not set, exit the function
	if not pager then return end

	-- Call the handle shell function
	-- with the pager command
	require(".utils-shell").handle(
		require(".utils").merge_tables({
			pager .. " %s",
			block = true,
			exit_if_dir = true,
		}, args),
		config
	)
end

-- Return the module table
return M
