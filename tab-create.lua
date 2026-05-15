--- @since 26.5.6

-- The module to handle the tab create command

-- The module table
local M = {}

-- Function to execute the tab create command
---@type fun(
---	args: ParsedArgs,    -- The arguments passed to the plugin
---	config: Configuration,    -- The configuration object
---): nil
local exec = ya.sync(function(_, args, config)

	-- Get the hovered item
	local hovered_item = cx.active.current.hovered

	-- If the hovered item is nil,
	-- or if the hovered item is not a directory,
	-- or if the user doesn't want to smartly
	-- create a tab in the hovered directory
	if
		not hovered_item
		or not hovered_item.cha.is_dir
		or not (
			config.smart_tab_create
			or require(".utils").table_pop(args, "smart", false)
		)
	then

		-- Emit the command to create a new tab with the arguments
		-- and exit the function
		return ya.emit("tab_create", args)
	end

	-- Otherwise, emit the command to create a new tab
	-- with the hovered item's url
	ya.emit("tab_create", { hovered_item.url })
end)

-- Function to handle the tab create command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- Call the function to execute the tab create command
	exec(args, config)
end

-- Return the module table
return M
