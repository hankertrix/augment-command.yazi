--- @since 26.5.6

-- The module to handle the tab switch command

-- The module table
local M = {}

-- Function to execute the tab switch command
---@type fun(
---	args: ParsedArgs,    -- The arguments passed to the plugin
---	config: Configuration,    -- The configuration object
---): nil
local exec = ya.sync(function(_, args, config)

	-- Get the tab index
	local tab_index = args[1]

	-- If no tab index is given, exit the function
	if not tab_index then return end

	-- If the user doesn't want to create tabs
	-- when switching to a new tab,
	-- or the tab index is not given,
	-- then just call the tab switch command
	-- and exit the function
	if
		not (
			config.smart_tab_switch
			or require(".utils").table_pop(args, "smart", false)
		)
	then
		return ya.emit("tab_switch", args)
	end

	-- Get the current tab
	local current_tab = cx.active.current

	-- Get the number of tabs currently open
	local number_of_open_tabs = #cx.tabs

	-- Iterate from the number of current open tabs
	-- to the given tab number
	for _ = number_of_open_tabs, tab_index - 1 do

		-- Call the tab create command
		ya.emit("tab_create", { current_tab.cwd })

		-- If there is a hovered item
		if current_tab.hovered then

			-- Reveal the hovered item
			ya.emit("reveal", { current_tab.hovered.url })
		end
	end

	-- Switch to the given tab index
	ya.emit("tab_switch", args)
end)

-- Function to handle the tab switch command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- Call the function to execute the tab switch command
	exec(args, config)
end

-- Return the module table
return M
