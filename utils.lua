-- The module containing the utility functions

-- Type aliases

-- The type for the parsed arguments from Yazi
---@alias ParsedArgs table<string|number, string|number|boolean>

-- The type for the function to modify the arguments
---@alias ModifyArgsFunction fun(args: ParsedArgs): ParsedArgs

-- Import the constants needed
local constants = require(".constants")
local DEFAULT_NOTIFICATION_OPTIONS = constants.DEFAULT_NOTIFICATION_OPTIONS
local DEFAULT_CONFIRM_OPTIONS = constants.DEFAULT_CONFIRM_OPTIONS
local DEFAULT_INPUT_OPTIONS = constants.DEFAULT_INPUT_OPTIONS
local INPUT_AND_CONFIRM_OPTIONS = constants.INPUT_AND_CONFIRM_OPTIONS
local PLUGIN_NAME = constants.PLUGIN_NAME
local MIME_TYPE_PREFIXES_TO_REMOVE = constants.MIME_TYPE_PREFIXES_TO_REMOVE
local TAB_PREFERENCE_KEYS = constants.TAB_PREFERENCE_KEYS
local INPUT_OPTIONS_TABLE = constants.INPUT_OPTIONS_TABLE
local ConfigurableComponents = constants.ConfigurableComponents
local ItemGroup = constants.ItemGroup

-- The module table
local M = {}

-- The pattern template to get the mime type without a prefix
---@type string
local get_mime_type_without_prefix_template_pattern =
	"^(%%a-)/%s([%%-%%d%%a]-)$"

-- The pattern to get the root of the path
local get_path_root_pattern = "^(.-)%f[/]"

-- Function to merge tables.
--
-- The key-value pairs of the tables given later
-- in the argument list WILL OVERRIDE
-- the tables given earlier in the argument list.
--
-- The list items in the table will be added in order,
-- with the items in the first table being added first,
-- and the items in the second table being added second,
-- and so on.
--
-- Pass true as the first parameter to get the function
-- to merge the tables recursively.
---@param deep_or_target table<any, any>|boolean Recursively merge or not
---@param target table<any, any>? The target table to merge
---@param ... table<any, any>[]? The tables to merge
---@return table<any, any> merged_table The merged table
function M.merge_tables(deep_or_target, target, ...)

	-- Initialise the target table
	local target_table = nil

	-- Initialise the arguments
	local args = nil

	-- Initialise the recursive variable
	local recursive = false

	-- If the deep or target variable is a boolean
	if type(deep_or_target) == "boolean" then

		-- Set the recursive variable to the boolean value of the
		-- deep or target variable
		recursive = deep_or_target

		-- Set the target table to the target variable
		target_table = target

		-- Set the arguments to the rest of the arguments
		args = { ... }

	-- Otherwise, the deep or target variable is not a boolean,
	-- and is most likely a table.
	else

		-- Set the target table to the deep or target variable
		-- if it is a table, otherwise, set it to an empty table
		target_table = type(deep_or_target) == "table" and deep_or_target or {}

		-- Set the arguments to the target variable
		-- and the rest of the arguments
		args = { target, ... }
	end

	-- The target table will definitely be a table
	---@cast target_table table<any, any>

	-- Initialise the index variable
	local index = #target_table + 1

	-- Iterates over the tables given
	for _, table in ipairs(args) do

		-- Iterate over all of the keys and values
		for key, value in pairs(table) do

			-- If the key is a number, then add using the index
			-- instead of the key.
			-- This is to allow lists to be merged.
			if type(key) == "number" then

				-- Set the value mapped to the index
				target_table[index] = value

				-- Increment the index
				index = index + 1

				-- Continue the loop
				goto continue
			end

			-- If recursive merging is wanted
			-- and the key for the target table
			-- and the value are both tables
			if
				recursive
				and type(target_table[key]) == "table"
				and type(value) == "table"
			then

				-- Call the merge table function
				-- recursively on the target table's
				-- key to merge the table recursively
				M.merge_tables(target_table[key], value)

				-- Continue the loop
				goto continue
			end

			-- Otherwise, set the key in the target table to the value given
			target_table[key] = value

			-- The label to continue the loop
			::continue::
		end
	end

	-- Return the target table
	return target_table
end

-- Function to split a string into a list
---@param given_string string The string to split
---@param separator string? The character to split the string by
---@return string[] split_strings The list of strings split by the character
function M.string_split(given_string, separator)

	-- If the separator isn't given, set it to the whitespace character
	separator = separator or "%s"

	-- Initialise the list of split strings
	local split_strings = {}

	-- Iterate over all of the strings found by pattern
	for string in string.gmatch(given_string, "([^" .. separator .. "]+)") do

		-- Add the string to the list of split strings
		table.insert(split_strings, string)
	end

	-- Return the list of split strings
	return split_strings
end

-- Function to trim a string
---@param string string The string to trim
---@return string trimmed_string The trimmed string
function M.string_trim(string)

	-- Return the string with the whitespace characters
	-- removed from the start and end
	return string:match("^%s*(.-)%s*$")
end

-- Function to map over the values in the table
-- and return a new table with the mapping function applied on each item
---@param given_table table The table to map over
---@param func fun(item: any): any The function to apply on each item
---@return table mapped_table The new table with the mapping function applied
function M.table_map(given_table, func)

	-- Initialise the table
	local mapped_table = {}

	-- Iterate over the items in the table
	-- and call the function on the value,
	-- then save the item to the new mapped table
	for key, value in pairs(given_table) do
		mapped_table[key] = func(value)
	end

	-- Return the mapped table
	return mapped_table
end

-- Function to get a value from a table
-- and return the default value if the key doesn't exist
---@param table table The table to get the value from
---@param key string|number The key to get the value from
---@param default any The default value to return if the key doesn't exist
function M.table_get(table, key, default) return table[key] or default end

-- Function to pop a key from a table
---@param table table The table to pop from
---@param key string|number The key to pop
---@param default any The default value to return if the key doesn't exist
---@return any value The value of the key or the default value
function M.table_pop(table, key, default)

	-- Get the value of the key from the table
	local value = table[key]

	-- Remove the key from the table
	table[key] = nil

	-- Return the value if it exist,
	-- otherwise return the default value
	return value or default
end

-- Function to get whether the given table contains an item
---@param given_table table The table to check
---@param item_to_check any The item to check
---@return boolean is_in_table Whether the item is in the table
function M.table_contains(given_table, item_to_check)

	-- Iterate over the table and return if the item is in the table
	for _, item in pairs(given_table) do
		if item == item_to_check then return true end
	end

	-- Otherwise, return false
	return false
end

-- Function to get the dictionary length
---@param dictionary table<any, any> The dictionary to get the length of
---@return number The length of the dictionary
function M.get_dictionary_length(dictionary)

	-- Initialise the number of items
	local number_of_items = 0

	-- Iterate over the dictionary and increment the number of items
	for _ in pairs(dictionary) do
		number_of_items = number_of_items + 1
	end

	-- Return the number of items
	return number_of_items
end

-- Function to escape a percentage sign %
-- in the string that is being replaced
---@param replacement_string string The string to escape
---@return string replacement_result The escaped string
function M.escape_replacement_string(replacement_string)

	-- Get the result of the replacement
	local replacement_result = replacement_string:gsub("%%", "%%%%")

	-- Return the result of the replacement
	return replacement_result
end

-- Function to escape a match pattern
---@param match_pattern string The match pattern to escape
---@return string escaped_match_pattern The escaped match pattern
function M.escape_match_pattern(match_pattern)

	-- The escaped match pattern
	local escaped_match_pattern = match_pattern:gsub(
		"[%(%)%.%+%-%[%]%?%^%$]",
		function(match) return "%" .. match end
	)

	-- Return the escaped match pattern
	return escaped_match_pattern
end

-- Function to parse the number arguments to the number type
---@param args YaziArgs The arguments to parse
---@return ParsedArgs parsed_args The parsed arguments
function M.parse_number_arguments(args)

	-- The parsed arguments
	---@type ParsedArgs
	local parsed_args = {}

	-- Iterate over the arguments given
	for arg_name, arg_value in pairs(args) do

		-- Try to convert the argument to a number
		local number_arg_value = tonumber(arg_value)

		-- Set the argument to the number argument value
		-- if the argument is a number,
		-- otherwise just set it to the given argument value
		parsed_args[arg_name] = number_arg_value or arg_value
	end

	-- Return the parsed arguments
	return parsed_args
end

-- Function to convert a table of arguments to a string
---@param args ParsedArgs The arguments to convert
---@return string args_string The string of the arguments
function M.convert_arguments_to_string(args)

	-- The table of string arguments
	---@type string[]
	local string_arguments = {}

	-- Iterate all the items in the argument table
	for key, value in pairs(args) do

		-- If the key is a number
		if type(key) == "number" then

			-- Add the stringified value to the string arguments table
			table.insert(string_arguments, tostring(value))

		-- Otherwise, if the key is a string
		elseif type(key) == "string" then

			-- Replace the underscores and spaces in the key with dashes
			local key_with_dashes = key:gsub("_", "-"):gsub("%s", "-")

			-- If the value is a boolean and the boolean is true,
			-- add the value to the string
			if type(value) == "boolean" and value then
				table.insert(
					string_arguments,
					string.format("--%s", key_with_dashes)
				)

			-- Otherwise, just add the key and the value to the string
			else
				table.insert(
					string_arguments,
					string.format("--%s=%s", key_with_dashes, value)
				)
			end
		end
	end

	-- Combine the string arguments into a single string
	local string_args = table.concat(string_arguments, " ")

	-- Return the string arguments
	return string_args
end

-- Function to show a warning
---@param warning_message any The warning message
---@param options YaziNotificationOptions? Options for the notification
---@return nil
function M.show_warning(warning_message, options)
	return ya.notify(
		M.merge_tables({}, DEFAULT_NOTIFICATION_OPTIONS, options or {}, {
			content = tostring(warning_message),
			level = "warn",
		})
	)
end

-- Function to show an error
---@param error_message any The error message
---@param options YaziNotificationOptions? Options for the notification
---@return nil
function M.show_error(error_message, options)
	return ya.notify(
		M.merge_tables({}, DEFAULT_NOTIFICATION_OPTIONS, options or {}, {
			content = tostring(error_message),
			level = "error",
		})
	)
end

-- Function to throw an error
---@param error_message any The error message as a format string
---@param ... any The items to substitute into the error message given
function M.throw_error(error_message, ...)
	return error(string.format(error_message, ...))
end

-- Function to get the component option string
---@param component BuiltInComponents|PluginComponents The component name
---@param option string The option
---@return string component_option The component option string
function M.get_component_option_string(component, option)
	return string.format("%s_%s", component, option)
end

-- Function to get the user's configuration for the input or confirm components.
---@param component BuiltInComponents|PluginComponents The name of the component
---@param defaults {
---		prompts: string|string[],    -- The default prompts
---		body: string|ui.Line|ui.Text?,    -- The default body
---		origin: string?,    -- The default origin
---		pos: ui.Pos?,    -- The default offset
---} The defaults for the component
---@param is_confirm boolean? Whether the component is the confirm component
---@param title_index integer? The index to get the title
---@return YaziInputOptions|YaziConfirmOptions options The resolved options
function M.get_user_input_or_confirm_options(
	component,
	defaults,
	is_confirm,
	title_index
)

	-- Initialise the default prompts
	local default_prompts = type(defaults.prompts) == "string"
			and { defaults.prompts }
		or defaults.prompts

	-- Initialise the title index
	title_index = title_index or 1

	-- Get the theme object
	local theme = require(".main").get_theme() or {}

	-- Get whether the component is a plugin component
	local is_plugin_component =
		M.table_contains(ConfigurableComponents.Plugin, component)

	-- Initialise the theme configuration
	---@diagnostic disable-next-line: undefined-field
	local theme_config = is_plugin_component and (theme.augment_command or {})
		or theme

	-- Get the default options
	local default_options = (
		is_confirm and DEFAULT_CONFIRM_OPTIONS or DEFAULT_INPUT_OPTIONS
	).pos

	-- Initialise the list of options
	local option_list = {}

	-- Initialise the list of option suffixes
	local option_suffixes = M.merge_tables({}, INPUT_AND_CONFIRM_OPTIONS)

	-- If the component is not the confirm component, remove the last suffix
	if not is_confirm then table.remove(option_suffixes) end

	-- Create the list of options
	for _, option_suffix in ipairs(option_suffixes) do
		table.insert(
			option_list,
			M.get_component_option_string(component, option_suffix)
		)
	end

	-- Unpack the options
	local title_option, origin_option, offset_option, body_option =
		table.unpack(option_list)

	-- Get the value of all the options
	---@type string|string[]
	local raw_title = theme_config[title_option or ""] or {}
	local origin = theme_config[origin_option or ""] or default_options[1]
	local offset = theme_config[offset_option or ""] or {}
	local body = theme_config[body_option or ""] or defaults.body or ""

	-- Get the title
	local title = type(raw_title) == "string" and raw_title
		or raw_title[title_index]
		or default_prompts[title_index]

	-- Get the position object
	local position = {
		origin,
		x = offset.x or default_options.x,
		y = offset.y or default_options.y,
		w = offset.w or default_options.w,
		h = offset.h or default_options.h,
	}

	-- Return the options
	return {
		title = title,
		pos = position,
		body = body,
	}
end

-- Function to get a password from the user
---@param get_password_options GetPasswordOptions Get password options function
---@param want_confirmation boolean? Whether to get a confirmation password
---@return string? password The password or nil if the user cancelled
---@return number? event The event for the input function
function M.get_password(get_password_options, want_confirmation)

	-- Merge the obscure option with the password options
	local password_options =
		M.merge_tables(get_password_options(false), { obscure = true })

	-- If reconfirmation for the password is not wanted,
	-- just obtain the user's password and return it
	if not want_confirmation then return ya.input(password_options) end

	-- Merge the obscure option with the confirm password options
	local confirm_password_options =
		M.merge_tables(get_password_options(true), { obscure = true })

	-- Otherwise, initialise the password and the event
	local password = nil
	local event = nil

	-- While the password isn't set
	while not password do

		-- Get the initial password from the user
		local initial_password, initial_event = ya.input(password_options)

		-- If the initial password is nil, exit the function
		if initial_password == nil then
			return initial_password, initial_event
		end

		-- Get the confirmation password from the user
		local confirmation_password, confirmation_event =
			ya.input(confirm_password_options)

		-- If the confirmation password is nil, exit the function
		if confirmation_password == nil then
			return confirmation_password, confirmation_event
		end

		-- If the initial password and the confirmation password matches
		if initial_password == confirmation_password then

			-- Set the password to the confirmation password
			password = confirmation_password

			-- Set the event to the confirmation event
			event = confirmation_event

			-- Break out of the loop
			break
		end

		-- Otherwise, tell the user their passwords don't match
		M.show_error("Passwords do not match, please try again")
	end

	-- Return the password and event
	return password, event
end

-- Function to show a delete confirmation prompt
---@param item_paths string|string[] The path to the items to delete
---@return boolean delete Whether the user wants to delete the items
function M.show_delete_prompt(item_paths)

	-- If the item paths is a string, convert it to a list
	if type(item_paths) == "string" then item_paths = { item_paths } end

	-- Pattern to replace the placeholders in the prompt
	local placeholder_pattern = "{%l}"

	-- Create the confirmation prompt
	local confirmation_prompt = "Permanently delete {n} selected file{s}?"

	-- Create the body for the prompt
	local prompt_body = M.table_map(
		item_paths,
		function(item) return ui.Line(item):align(ui.Align.LEFT) end
	)

	-- Get the options for the confirmation prompt
	local delete_confirmation_options = M.get_user_input_or_confirm_options(
		ConfigurableComponents.BuiltIn.Delete,
		{
			prompts = confirmation_prompt,
			body = ui.Text(prompt_body):wrap(ui.Wrap.TRIM),
			pos = { "center", x = 0, y = 0, w = 70, h = 20 },
		},
		true
	)

	-- Get the prompt and replace the placeholders
	delete_confirmation_options.title =
		tostring(delete_confirmation_options.title)
			:gsub(placeholder_pattern, "%%s")
			:format(#item_paths, #item_paths == 1 and "" or "s")

	-- Get the user's confirmation
	---@cast delete_confirmation_options YaziConfirmOptions
	local user_confirmation = ya.confirm(delete_confirmation_options)

	-- Return the user's confirmation
	return user_confirmation
end

-- Function to show an overwrite prompt
---@param file_path_to_overwrite string|Path The file path to overwrite
---@return boolean overwrite Whether the user chooses to overwrite the file
function M.show_overwrite_prompt(file_path_to_overwrite)

	-- Get the user's configuration for the overwrite prompt
	local overwrite_confirm_options = M.get_user_input_or_confirm_options(
		ConfigurableComponents.BuiltIn.Overwrite,
		{
			prompts = "Overwrite file?",
			body = ui.Line("Will overwrite the following file:"),
		},
		true
	)

	-- Get the type of the overwrite body
	---@cast overwrite_confirm_options YaziConfirmOptions
	local overwrite_body_type = type(overwrite_confirm_options.body)

	-- Initialise the first line of the body
	local first_line = nil

	-- If the body section is a string or table
	if overwrite_body_type == "string" or overwrite_body_type == "table" then

		-- Wrap the string in a line and align it to the center.
		first_line = ui.Line(overwrite_confirm_options.body)
			:align(ui.Align.CENTER)

	-- Otherwise, just set the first line to the body given
	else
		first_line = overwrite_confirm_options.body
	end

	-- Create the body for the overwrite prompt
	---@cast first_line ui.Line|ui.Span
	overwrite_confirm_options.body = ui.Text({
		first_line,
		ui.Line(string.rep("─", overwrite_confirm_options.pos.w - 2))
			:style(th.confirm.border)
			:align(ui.Align.LEFT),
		ui.Line(tostring(file_path_to_overwrite)):align(ui.Align.LEFT),
	}):wrap(ui.Wrap.TRIM)

	-- Get the user's confirmation for
	-- whether they want to overwrite the item
	local user_confirmation = ya.confirm(overwrite_confirm_options)

	-- Return whether the user wants to overwrite the file or not
	return user_confirmation
end

-- Function to try if a shell command exists
---@param shell_command string The shell command to check
---@param args string[]? The arguments to the shell command
---@return boolean shell_command_exists Whether the shell command exists
---@return Output? output The output of the shell command
function M.async_shell_command_exists(shell_command, args)

	-- Get the output of the shell command with the given arguments
	local output = Command(shell_command)
		:arg(args or {})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	-- Return true if there's an output and false otherwise
	return output ~= nil, output
end

-- Function to emit a command from this plugin
---@param command string The augmented command to emit
---@param args ParsedArgs|string The arguments to pass to the augmented command
---@return nil
function M.emit_augmented_command(command, args)

	-- Initialise the arguments
	local arguments = args

	-- If the arguments are passed in a table,
	-- convert them to a string
	if type(args) == "table" then
		arguments = M.convert_arguments_to_string(args)
	end

	-- Emit the augmented command
	return ya.emit("plugin", {
		string.format("%s.%s", PLUGIN_NAME, command),
		arguments,
	})
end

-- Function to standardise the mime type of a file.
-- This function will follow what Yazi does to standardise
-- mime types returned by the file command.
---@param mime_type string The mime type of the file
---@return string standardised_mime_type The standardised mime type of the file
function M.standardise_mime_type(mime_type)

	-- Trim the whitespace from the mime type
	local trimmed_mime_type = M.string_trim(mime_type)

	-- Iterate over the mime type prefixes to remove
	for _, prefix in ipairs(MIME_TYPE_PREFIXES_TO_REMOVE) do

		-- Get the pattern to remove the mime type prefix
		local pattern =
			get_mime_type_without_prefix_template_pattern:format(prefix)

		-- Remove the prefix from the mime type
		local mime_type_without_prefix, replacement_count =
			trimmed_mime_type:gsub(pattern, "%1/%2")

		-- If the replacement count is greater than zero,
		-- return the mime type without the prefix
		if replacement_count > 0 then return mime_type_without_prefix end
	end

	-- Return the mime type with whitespace removed
	return trimmed_mime_type
end

-- Function to get the mime type of a file
---@param file_path string The path to the file
---@return string mime_type The mime type of the file
function M.get_mime_type(file_path)

	-- Get the output of the file command
	local output, _ = Command("file")
		:arg({

			-- Don't prepend file names to the output
			"-b",

			-- Print the mime type of the file
			"--mime-type",

			-- The file path to get the mime type of
			file_path,
		})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	-- If there is no output, then return an empty string
	if not output then return "" end

	-- Otherwise, get the mime type from the standard output
	local mime_type = M.string_trim(output.stdout)

	-- Standardise the mime type
	local standardised_mime_type = M.standardise_mime_type(mime_type)

	-- Return the standardised mime type
	return standardised_mime_type
end

-- Function to get a temporary name.
-- The code is taken from Yazi's source code.
---@param path string The path to the item to create a temporary name
---@return string temporary_name The temporary name for the item
function M.get_temporary_name(path)
	return ".tmp_"
		.. ya.hash(string.format("extract//%s//%.10f", path, ya.time()))
end

-- Function to get the current working directory
---@type fun(): string Returns the current working directory as a string
M.get_current_directory = ya.sync(
	function(_) return tostring(cx.active.current.cwd.path) end
)

-- Function to get the path of the hovered item
---@type fun(
---	quote: boolean?,    -- Whether to escape the characters in the path
---): string? The path of the hovered item
M.get_path_of_hovered_item = ya.sync(function(_, quote)

	-- Get the hovered item
	local hovered_item = cx.active.current.hovered

	-- If there is no hovered item, exit the function
	if not hovered_item then return end

	-- Convert the path of the hovered item to a string
	local hovered_item_path = tostring(cx.active.current.hovered.url.path)

	-- If the quote flag is passed,
	-- then quote the path of the hovered item
	if quote then hovered_item_path = ya.quote(hovered_item_path) end

	-- Return the path of the hovered item
	return hovered_item_path
end)

-- Function to get if the hovered item is a directory
---@type fun(): boolean
M.hovered_item_is_dir = ya.sync(function(_)

	-- Get the hovered item
	local hovered_item = cx.active.current.hovered

	-- Return if the hovered item exists and is a directory
	return hovered_item and hovered_item.cha.is_dir
end)

-- Function to get the paths of the selected items
---@type fun(
---	quote: boolean?,    -- Whether to escape the characters in the path
---): string[]? The list of paths of the selected items
M.get_paths_of_selected_items = ya.sync(function(_, quote)

	-- Get the selected items
	local selected_items = cx.active.selected

	-- If there are no selected items, exit the function
	if #selected_items == 0 then return end

	-- Initialise the list of paths of the selected items
	local paths_of_selected_items = {}

	-- Iterate over the selected items
	for _, item in pairs(selected_items) do

		-- Convert the path of the item to a string
		local item_path = tostring(item.path)

		-- If the quote flag is passed,
		-- then quote the path of the item
		if quote then item_path = ya.quote(item_path) end

		-- Add the path of the item to the list of paths
		table.insert(paths_of_selected_items, item_path)
	end

	-- Return the list of paths of the selected items
	return paths_of_selected_items
end)

-- Function to get the path root
---@type fun(path: string): string? The path root
function M.get_path_root(path) return path:match(get_path_root_pattern) end

-- Function to get the number of tabs currently open
---@type fun(): number
M.get_number_of_tabs = ya.sync(function() return #cx.tabs end)

-- Function to get the tab preferences
---@type fun(): tab__Pref
M.get_tab_preferences = ya.sync(function(_)

	-- Create the table to store the tab preferences
	local tab_preferences = {}

	-- Iterate over the tab preference keys
	for key, _ in pairs(TAB_PREFERENCE_KEYS) do

		-- Set the key in the table to the value
		-- from the state
		tab_preferences[key] = cx.active.pref[key]
	end

	-- Return the tab preferences
	return tab_preferences
end)

-- Function to choose which group of items to operate on.
-- It returns ItemGroup.Hovered for the hovered item,
-- ItemGroup.Selected for the selected items,
-- and ItemGroup.Prompt to tell the calling function
-- to prompt the user.
---@type fun(config: Configuration): ItemGroup? The desired item group
local get_item_group_from_state = ya.sync(function(_, config)

	-- Get the hovered item
	local hovered_item = cx.active.current.hovered

	-- The boolean representing that there are no selected items
	local no_selected_items = #cx.active.selected == 0

	-- If there is no hovered item
	if not hovered_item then

		-- If there are no selected items, exit the function
		if no_selected_items then
			return

		-- Otherwise, if the configuration is set to have a hovered item,
		-- exit the function
		elseif config.must_have_hovered_item then
			return

		-- Otherwise, return the enum for the selected items
		else
			return ItemGroup.Selected
		end

	-- Otherwise, there is a hovered item
	-- and if there are no selected items,
	-- return the enum for the hovered item.
	elseif no_selected_items then
		return ItemGroup.Hovered

	-- Otherwise if there are selected items and the user wants a prompt,
	-- then tells the calling function to prompt them
	elseif config.prompt then
		return ItemGroup.Prompt

	-- Otherwise, if the hovered item is selected,
	-- then return the enum for the selected items
	elseif hovered_item:is_selected() then
		return ItemGroup.Selected

	-- Otherwise, return the enum for the hovered item
	else
		return ItemGroup.Hovered
	end
end)

-- Function to prompt the user for their desired item group
---@return ItemGroup? item_group The item group selected by the user
local function prompt_for_desired_item_group()

	-- Get the configuration
	local config = require(".main").get_config()

	-- Get the default item group
	---@type ItemGroup?
	local default_item_group = config.default_item_group_for_prompt

	-- Get the input options, which the (h/s) options
	local input_options = INPUT_OPTIONS_TABLE[default_item_group]

	-- If the default item group is none, then set it to nil
	if default_item_group == ItemGroup.None then default_item_group = nil end

	-- Get the user's input options for the item group prompt
	local item_group_input_options = M.get_user_input_or_confirm_options(
		ConfigurableComponents.Plugin.ItemGroup,
		{ prompts = "Operate on hovered or selected items?" }
	)

	-- Add the input options to the title
	item_group_input_options.title =
		string.format("%s %s", item_group_input_options.title, input_options)

	-- Prompt the user for their input
	---@cast item_group_input_options YaziInputOptions
	local user_input, event = ya.input(item_group_input_options)

	-- If the user input is empty, then exit the function
	if not user_input then return end

	-- Lowercase the user's input
	user_input = user_input:lower()

	-- If the user did not confirm the input, exit the function
	if event ~= 1 then
		return

	-- Otherwise, if the user's input starts with "h",
	-- return the item group representing the hovered item
	elseif user_input:find("^h") then
		return ItemGroup.Hovered

	-- Otherwise, if the user's input starts with "s",
	-- return the item group representing the selected items
	elseif user_input:find("^s") then
		return ItemGroup.Selected

	-- Otherwise, return the default item group
	else
		return default_item_group
	end
end

-- Function to get the item group
---@param config Configuration The configuration object
---@return ItemGroup? item_group The desired item group
function M.get_item_group(config)

	-- Get the item group from the state
	local item_group = get_item_group_from_state(config)

	-- If the item group isn't the prompt one,
	-- then return the item group immediately
	if item_group ~= ItemGroup.Prompt then
		return item_group

	-- Otherwise, prompt the user for the desired item group
	else
		return prompt_for_desired_item_group()
	end
end

-- Function to get all the items in the given directory
---@param directory_path string The path to the directory
---@param get_hidden_items boolean Whether to get hidden items
---@param directories_only boolean? Whether to only get directories
---@return string[] directory_items The list of urls to the directory items
function M.get_directory_items(
	directory_path,
	get_hidden_items,
	directories_only
)

	-- Initialise the list of directory items
	---@type string[]
	local directory_items = {}

	-- Read the contents of the directory
	local directory_contents, _ = fs.read_dir(Url(directory_path), {})

	-- If there are no directory contents,
	-- then return the empty list of directory items
	if not directory_contents then return directory_items end

	-- Iterate over the directory contents
	for _, item in ipairs(directory_contents) do

		-- If the get hidden items flag is set to false
		-- and the item is a hidden item,
		-- then continue the loop
		if not get_hidden_items and item.cha.is_hidden then goto continue end

		-- If the directories only flag is passed
		-- and the item is not a directory,
		-- then continue the loop
		if directories_only and not item.cha.is_dir then goto continue end

		-- Otherwise, add the item path to the list of directory items
		table.insert(directory_items, tostring(item.url.path))

		-- The continue label to continue the loop
		::continue::
	end

	-- Return the list of directory items
	return directory_items
end

-- Function to skip child directories with only one directory
---@param initial_directory_path string The path of the initial directory
---@return nil
function M.skip_single_child_directories(initial_directory_path)

	-- Initialise the directory variable to the initial directory given
	local directory = initial_directory_path

	-- Get the tab preferences
	local tab_preferences = M.get_tab_preferences()

	-- Start an infinite loop
	while true do

		-- Get all the items in the current directory
		local directory_items =
			M.get_directory_items(directory, tab_preferences.show_hidden)

		-- If the number of directory items is not 1,
		-- then break out of the loop.
		if #directory_items ~= 1 then break end

		-- Otherwise, get the directory item
		local directory_item = table.unpack(directory_items)

		-- Get the cha object of the directory item
		-- and don't follow symbolic links
		local directory_item_cha = fs.cha(Url(directory_item), false)

		-- If the cha object of the directory item is nil
		-- then break the loop
		if not directory_item_cha then break end

		-- If the directory item is not a directory,
		-- break the loop
		if not directory_item_cha.is_dir then break end

		-- Otherwise, set the directory to the inner directory
		directory = directory_item
	end

	-- Emit the change directory command to change to the directory variable
	ya.emit("cd", { directory })
end

-- Function to handle a Yazi command
---@param command string A Yazi command
---@param args ParsedArgs The arguments passed to the plugin
---@param config Configuration The configuration object
---@param modify_args ModifyArgsFunction? Function to modify the arguments
---@return nil
function M.handle_yazi_command(command, args, config, modify_args)

	-- Call the function to get the item group
	local item_group = M.get_item_group(config)

	-- If the function to modify the arguments is given,
	-- modify the arguments with it
	if modify_args then args = modify_args(args) end

	-- If no item group is returned, exit the function
	if not item_group then return end

	-- If the item group is the selected items
	if item_group == ItemGroup.Selected then

		-- Emit the command to operate on the selected items
		ya.emit(command, args)

	-- If the item group is the hovered item
	elseif item_group == ItemGroup.Hovered then

		-- Emit the command with the hovered option
		ya.emit(command, M.merge_tables({}, args, { hovered = true }))
	end
end

-- Function to handle smooth scrolling
---@param steps number The number of steps to scroll
---@param scroll_delay number The scroll delay in seconds
---@param scroll_func fun(step: integer): nil The function to call to scroll
function M.smoothly_scroll(steps, scroll_delay, scroll_func)

	-- Initialise the direction to positive 1
	local direction = 1

	-- If the number of steps is negative
	if steps < 0 then

		-- Set the direction to negative 1
		direction = -1

		-- Convert the number of steps to positive
		steps = -steps
	end

	-- Iterate over the number of steps
	for _ = 1, steps do

		-- Call the function to scroll
		scroll_func(direction)

		-- Pause for the scroll delay
		ya.sleep(scroll_delay)
	end
end

-- Function to get the part of the path
-- that is in Yazi's current working directory
---@param given_path string|Url The path to get the part of
---@return Url path_part The part of the path that is in Yazi's CWD
local function get_part_of_path_in_yazi_cwd(given_path)

	-- If the given path is a string, turn it into a url
	if type(given_path) == "string" then given_path = Url(given_path) end

	-- Get the current working directory
	local current_working_directory = Url(M.get_current_directory())

	-- Strip the current working directory from the front of the given path
	local remaining_path = given_path:strip_prefix(current_working_directory)

	-- Get the root of the remaining path
	local remaining_path_root = M.get_path_root(tostring(remaining_path))

	-- Initialise the path part
	local path_part

	-- If the remaining path root does not exist
	if remaining_path_root == nil then

		-- Set the path part to the given path,
		-- since the whole path is in Yazi's current working directory
		path_part = given_path

	-- Otherwise, set the path part to the current working directory
	-- joined with the remaining path root
	else
		path_part = current_working_directory:join(remaining_path_root)
	end

	-- Return the path part
	return path_part
end

-- Function to check if the path exists in Yazi's current working directory
---@param path string The path to check for
---@return boolean path_exists Whether the path exists in Yazi
local path_exists_in_yazi_cwd = ya.sync(function(_, path)

	-- Get the current files
	local files = cx.active.current.files

	-- Check if the path exists in the files
	for _, file in ipairs(files) do

		-- If the file's path is the same as the given path, return true
		if tostring(file.url.path) == path then return true end
	end

	-- Otherwise, return false
	return false
end)

-- Function to wait until the given path exists in Yazi
---@param given_path string|Url The path to check for
function M.wait_until_path_exists_in_yazi(given_path)

	-- Get the part of the path in Yazi's current working directory
	local path_part = tostring(get_part_of_path_in_yazi_cwd(given_path))

	-- Get whether the path exists in Yazi
	local path_exists = path_exists_in_yazi_cwd(path_part)

	-- While the path does not exist in Yazi, try again
	while not path_exists do
		path_exists = path_exists_in_yazi_cwd(path_part)
	end
end

-- Return the module table
return M
