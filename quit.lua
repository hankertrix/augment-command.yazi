--- @since 26.5.6

-- The module to handle the quit command

-- Import the utilities module
local utils = require(".utils")

-- Import the constants required
local ConfigurableComponents = require(".constants").ConfigurableComponents

-- The module table
local M = {}

-- Function to execute the quit command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- Get the number of tabs
	local number_of_tabs = utils.get_number_of_tabs()

	-- If the user doesn't want the confirm on quit functionality,
	-- or if the number of tabs is 1 or less,
	-- then emit the quit command
	if
		not (config.confirm_on_quit or utils.table_pop(args, "confirm", false))
		or number_of_tabs <= 1
	then
		return ya.emit("quit", args)
	end

	-- Otherwise, get the user's confirm options
	local quit_confirm_options = utils.get_user_input_or_confirm_options(
		ConfigurableComponents.Plugin.Quit,
		{
			prompts = "Quit?",
			body = ui.Text({
				"There are multiple tabs open.",
				"Are you sure you want to quit?",
			}):wrap(ui.Wrap.TRIM),
		},
		true
	)

	-- Get the type of the quit body
	local quit_body_type = type(quit_confirm_options.body)

	-- If the type of the quit body is a string or a list of strings
	if quit_body_type == "string" or quit_body_type == "table" then
		quit_confirm_options.body = ui.Text(quit_confirm_options.body)
			:wrap(ui.Wrap.TRIM)
	end

	-- Get the user's confirmation for quitting
	---@cast quit_confirm_options YaziConfirmOptions
	local user_confirmation = ya.confirm(quit_confirm_options)

	-- If the user didn't confirm, then exit the function
	if not user_confirmation then return end

	-- Otherwise, emit the quit command
	ya.emit("quit", args)
end

-- Return the module table
return M
