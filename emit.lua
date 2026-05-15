--- @since 26.5.6

-- The module to handle the emit command

-- Import the utilities module
local utils = require(".utils")

-- Import the required constants
local ConfigurableComponents = require(".constants").ConfigurableComponents

-- The module table
local M = {}

-- Function to handle the emit command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments
	local args = require("augment-command").parse_args_and_init(job)

	-- Get the command to emit given by the user
	local given_command = table.remove(args, 1)

	-- Get whether the user wants a plugin command
	local is_plugin_command = args.plugin

	-- Get whether the user wants an augmented command
	local is_augmented_command = args.augmented

	-- Initialise the emit title index
	local emit_title_index = nil

	-- Initialise the command function
	---@type fun(command: string, arguments: ParsedArgs): nil
	local function command_function(_, _) end

	-- If the user wants an augmented command
	if is_augmented_command then

		-- Set the emit title index to 3
		emit_title_index = 3

		-- Set the command function to emit an augmented command
		function command_function(command, arguments)
			utils.emit_augmented_command(command, arguments)
		end

	-- Otherwise, if the user wants a plugin command
	elseif is_plugin_command then

		-- Set the emit title index to 2
		emit_title_index = 2

		-- Set the command function to emit a plugin command
		function command_function(command, arguments)
			ya.emit(
				"plugin",
				{ command, utils.convert_arguments_to_string(arguments) }
			)
		end

	-- Otherwise, the user wants a regular Yazi command
	else

		-- Set the emit title index to 1
		emit_title_index = 1

		-- Set the command function to emit a Yazi command
		function command_function(command, arguments)
			ya.emit(command, arguments)
		end
	end

	-- If the command isn't given
	if not given_command then

		-- Get the user's options for the emit input
		local emit_input_options = utils.get_user_input_or_confirm_options(
			ConfigurableComponents.Plugin.Emit,
			{
				prompts = {
					"Yazi command:",
					"Plugin command:",
					"Augmented command:",
				},
			},
			false,
			emit_title_index
		)

		-- If the emit input options is nil, exit the function
		if not emit_input_options then return end

		-- Prompt the user for the command
		---@cast emit_input_options YaziInputOptions
		given_command = ya.input(emit_input_options) or ""

		-- If the given command is empty, then exit the function
		if #utils.string_trim(given_command) < 1 then return end

		-- Emit the command to call the plugin's emit function
		-- with the user's command
		return utils.emit_augmented_command(
			"emit",

			-- The arguments that are being propagated
			-- needs to come before the command,
			-- otherwise, if the command contains a --,
			-- then the wrong command will be emitted by the plugin
			string.format(
				"%s %s",
				utils.convert_arguments_to_string(args),
				given_command
			)
		)
	end

	-- Remove the plugin and augmented flag from the arguments
	utils.table_pop(args, "plugin")
	utils.table_pop(args, "augmented")

	-- Call the command function
	command_function(given_command, args)
end

-- Return the module table
return M
