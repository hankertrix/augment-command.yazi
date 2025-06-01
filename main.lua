--- @since 25.5.31

-- Plugin to make some Yazi commands smarter
-- Written in Lua 5.4

-- Type aliases

-- The type for the arguments
---@alias Arguments table<string|number, string|number|boolean>

-- The type for the function to handle a command
--
-- Description of the function parameters:
--	args: The arguments to pass to the command
--	config: The configuration object
---@alias CommandFunction fun(
---	args: Arguments,
---	config: Configuration,
---): nil

-- The type of the command table
---@alias CommandTable table<SupportedCommands, CommandFunction>

-- The type for the archiver list items command
---@alias Archiver.ListItemsCommand fun(
---	self: Archiver,
---): output: CommandOutput|nil, error: Error|nil

-- The type for the archiver get items function
---@alias Archiver.GetItems fun(
---	self: Archiver,
---): files: string[], directories: string[], error: string|nil

-- The type for the archiver extract function
---@alias Archiver.Extract fun(
---	self: Archiver,
---	has_only_one_file: boolean|nil,
---): Archiver.Result

-- The type for the archiver archive function
---@alias Archiver.Archive fun(
---	self: Archiver,
---	item_paths: string[],
---	password: string|nil,
---	encrypt_headers: boolean|nil,
---): Archiver.Result

-- The type for the archiver command function
---@alias Archiver.Command fun(): output: CommandOutput|nil, error: Error|nil

-- The type of the function to get the password options
---@alias GetPasswordOptions fun(is_confirm_password: boolean): YaziInputOptions

-- Custom types

-- The type of the user configuration table
-- The user configuration for the plugin
---@class (exact) UserConfiguration
---@field prompt boolean Whether or not to prompt the user
---@field default_item_group_for_prompt ItemGroup The default prompt item group
---@field smart_enter boolean Whether to use smart enter
---@field smart_paste boolean Whether to use smart paste
---@field smart_tab_create boolean Whether to use smart tab create
---@field smart_tab_switch boolean Whether to use smart tab switch
---@field confirm_on_quit boolean Whether to show a confirmation when quitting
---@field open_file_after_creation boolean Whether to open after creation
---@field enter_directory_after_creation boolean Whether to enter after creation
---@field use_default_create_behaviour boolean Use Yazi's create behaviour?
---@field enter_archives boolean Whether to enter archives
---@field extract_retries number How many times to retry extracting
---@field recursively_extract_archives boolean Extract inner archives or not
---@field encrypt_archives boolean Whether to encrypt created archives
---@field encrypt_archive_headers boolean Whether to encrypt archive headers
---@field reveal_created_archive boolean Whether to reveal the created archive
---@field remove_archived_files boolean Whether to remove archived files
---@field preserve_file_permissions boolean Whether to preserve file permissions
---@field must_have_hovered_item boolean Whether to stop when no item is hovered
---@field skip_single_subdirectory_on_enter boolean Skip single subdir on enter
---@field skip_single_subdirectory_on_leave boolean Skip single subdir on leave
---@field smooth_scrolling boolean Whether to smoothly scroll or not
---@field scroll_delay number The scroll delay in seconds for smooth scrolling
---@field wraparound_file_navigation boolean Have wraparound navigation or not

-- The full configuration for the plugin
---@class (exact) Configuration: UserConfiguration
---@field sudo_edit_supported boolean Whether sudo edit is supported

-- The type for the state
---@class (exact) State
---@field config Configuration The configuration object

-- The type for the archiver function result
---@class (exact) Archiver.Result
---@field successful boolean Whether the archiver function was successful
---@field output string|nil The output of the archiver function
---@field cancelled boolean|nil boolean Whether the archiver was cancelled
---@field error string|nil The error message
---@field archive_path string|nil The path to the archive
---@field destination_path string|nil The path to the destination
---@field extracted_items_path string|nil The path to the extracted items
---@field archiver_name string|nil The name of the archiver

-- The module table
---@class AugmentCommandPlugin
local M = {}

-- The name of the plugin
---@type string
local PLUGIN_NAME = "augment-command"

-- The enum for the supported commands
---@enum SupportedCommands
local Commands = {
	Open = "open",
	Extract = "extract",
	Enter = "enter",
	Leave = "leave",
	Rename = "rename",
	Remove = "remove",
	Copy = "copy",
	Create = "create",
	Shell = "shell",
	Paste = "paste",
	TabCreate = "tab_create",
	TabSwitch = "tab_switch",
	Quit = "quit",
	Arrow = "arrow",
	ParentArrow = "parent_arrow",
	Archive = "archive",
	Emit = "emit",
	Editor = "editor",
	Pager = "pager",
}

-- The enum for which group of items to operate on
---@enum ItemGroup
local ItemGroup = {
	Hovered = "hovered",
	Selected = "selected",
	None = "none",
	Prompt = "prompt",
}

-- Initialise the enum of components for the theme configuration
local ConfigurableComponents = {

	---@enum BuiltInComponents
	BuiltIn = {
		Create = "create",
		Overwrite = "overwrite",
	},

	---@enum PluginComponents
	Plugin = {
		ItemGroup = "item_group",
		ExtractPassword = "extract_password",
		Quit = "quit",
		Archive = "archive",
		ArchivePassword = "archive_password",
		Emit = "emit",
	},
}

-- The theme options for the input and confirm prompts
local INPUT_AND_CONFIRM_OPTIONS = {
	"title",
	"origin",
	"offset",
	"content",
}

-- The default configuration for the plugin
---@type UserConfiguration
local DEFAULT_CONFIG = {
	prompt = false,
	default_item_group_for_prompt = ItemGroup.Hovered,
	smart_enter = true,
	smart_paste = false,
	smart_tab_create = false,
	smart_tab_switch = false,
	confirm_on_quit = true,
	open_file_after_creation = false,
	enter_directory_after_creation = false,
	use_default_create_behaviour = false,
	enter_archives = true,
	extract_retries = 3,
	recursively_extract_archives = true,
	preserve_file_permissions = false,
	encrypt_archives = false,
	encrypt_archive_headers = false,
	reveal_created_archive = true,
	remove_archived_files = false,
	must_have_hovered_item = true,
	skip_single_subdirectory_on_enter = true,
	skip_single_subdirectory_on_leave = true,
	smooth_scrolling = false,
	scroll_delay = 0.02,
	wraparound_file_navigation = true,
}

-- The default input options for this plugin
local DEFAULT_INPUT_OPTIONS = {
	pos = { "top-center", x = 0, y = 2, w = 50, h = 3 },
}

-- The default confirm options for this plugin
local DEFAULT_CONFIRM_OPTIONS = {
	pos = { "center", x = 0, y = 0, w = 50, h = 15 },
}

-- The default notification options for this plugin
local DEFAULT_NOTIFICATION_OPTIONS = {
	title = "Augment Command Plugin",
	timeout = 5,
}

-- The tab preference keys.
-- The values are just dummy values
-- so that I don't have to maintain two
-- different types for the same thing.
---@type tab.Preference
local TAB_PREFERENCE_KEYS = {
	sort_by = "alphabetical",
	sort_sensitive = false,
	sort_reverse = false,
	sort_dir_first = true,
	sort_translit = false,
	linemode = "none",
	show_hidden = false,
}

-- The table of input options for the prompt
---@type table<ItemGroup, string>
local INPUT_OPTIONS_TABLE = {
	[ItemGroup.Hovered] = "(H/s)",
	[ItemGroup.Selected] = "(h/S)",
	[ItemGroup.None] = "(h/s)",
}

-- The archiver names
---@enum ArchiverName
local ArchiverName = {
	SevenZip = "7-Zip",
	Tar = "Tar",
}

-- The extract behaviour flags
---@enum ExtractBehaviour
local ExtractBehaviour = {
	Overwrite = "overwrite",
	Rename = "rename",
}

-- The table of archive file extensions
---@type table<string, boolean>
local ARCHIVE_FILE_EXTENSIONS = {
	["7z"] = true,
	boz = true,
	bz = true,
	bz2 = true,
	bzip2 = true,
	cb7 = true,
	cbr = true,
	cbt = true,
	cbz = true,
	gz = true,
	gzip = true,
	rar = true,
	s7z = true,
	svgz = true,
	tar = true,
	tbz = true,
	tbz2 = true,
	tgz = true,
	txz = true,
	xz = true,
	zip = true,
}

-- The table of archive file extensions that
-- supports header encryption
local ARCHIVE_FILE_EXTENSIONS_WITH_HEADER_ENCRYPTION = {
	["7z"] = true,
}

-- The error for the base archiver class
-- which is an abstract base class that
-- does not implement any functionality
---@type string
local BASE_ARCHIVER_ERROR = table.concat({
	"The Archiver class is does not implement any functionality.",
	"How did you even manage to get here?",
}, "\n")

-- Class definitions

-- The base archiver that all archivers inherit from
---@class Archiver
---@field name string The name of the archiver
---@field command string|nil The shell command for the archiver
---@field commands string[] The possible archiver commands
---
--- Whether the archiver supports preserving file permissions
---@field supports_file_permissions boolean
---
--- The map of the extract behaviour strings to the command flags
---@field extract_behaviour_map table<ExtractBehaviour, string>
local Archiver = {
	name = "BaseArchiver",
	command = nil,
	commands = {},
	supports_file_permissions = false,
	extract_behaviour_map = {},
}

-- The function to create a subclass of the abstract base archiver
---@param subclass table The subclass to create
---@return Archiver subclass Subclass of the base archiver
function Archiver:subclass(subclass)
	--

	-- Create a new instance
	local instance = setmetatable(subclass or {}, self)

	-- Set where to find the object's methods or properties
	self.__index = self

	-- Return the instance
	return instance
end

-- The method to get the archive items
---@type Archiver.GetItems
function Archiver:get_items() return {}, {}, BASE_ARCHIVER_ERROR end

-- The method to extract the archive
---@type Archiver.Extract
function Archiver:extract(_)
	return {
		successful = false,
		error = BASE_ARCHIVER_ERROR,
	}
end

-- The method to add items to an archive
---@type Archiver.Archive
function Archiver:archive(_)
	return {
		successful = false,
		error = BASE_ARCHIVER_ERROR,
	}
end

-- The 7-Zip archiver
---@class SevenZip: Archiver
---@field password string The password to the archive
local SevenZip = Archiver:subclass({
	name = ArchiverName.SevenZip,
	commands = { "7z", "7zz" },

	-- https://documentation.help/7-Zip/overwrite.htm
	extract_behaviour_map = {
		[ExtractBehaviour.Overwrite] = "-aoa",
		[ExtractBehaviour.Rename] = "-aou",
	},

	password = "",
})

-- The Tar archiver
---@class Tar: Archiver
local Tar = Archiver:subclass({
	name = ArchiverName.Tar,
	commands = { "gtar", "tar" },
	supports_file_permissions = true,

	-- https://www.man7.org/linux/man-pages/man1/tar.1.html
	-- https://ss64.com/mac/tar.html
	extract_behaviour_map = {

		-- Tar overwrites by default
		[ExtractBehaviour.Overwrite] = "",
		[ExtractBehaviour.Rename] = "-k",
	},
})

-- The default archiver, which is set to 7-Zip
---@class DefaultArchiver: SevenZip
local DefaultArchiver = SevenZip:subclass({})

-- The table of archive mime types
---@type table<string, Archiver>
local ARCHIVE_MIME_TYPE_TO_ARCHIVER_MAP = {
	["application/zip"] = DefaultArchiver,
	["application/gzip"] = DefaultArchiver,
	["application/tar"] = Tar,
	["application/bzip"] = DefaultArchiver,
	["application/bzip2"] = DefaultArchiver,
	["application/7z-compressed"] = DefaultArchiver,
	["application/rar"] = DefaultArchiver,
	["application/xz"] = DefaultArchiver,
}

-- Patterns

-- The list of mime type prefixes to remove
--
-- The prefixes are used in a lua pattern
-- to match on the mime type, so special
-- characters need to be escaped
---@type string[]
local MIME_TYPE_PREFIXES_TO_REMOVE = {
	"x%-",
	"vnd%.",
}

-- The pattern template to get the mime type without a prefix
---@type string
local get_mime_type_without_prefix_template_pattern =
	"^(%%a-)/%s([%%-%%d%%a]-)$"

-- The pattern to get the shell variables in a command
---@type string
local shell_variable_pattern = "[%$%%][%*@0]"

-- The pattern to match the bat command
---@type string
local bat_command_pattern = "%f[%a]bat%f[%A]"

-- Utility functions

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
---@param deep_or_target table<any, any>|boolean|nil Recursively merge or not
---@param target table<any, any> The target table to merge
---@param ... table<any, any>[] The tables to merge
---@return table<any, any> merged_table The merged table
local function merge_tables(deep_or_target, target, ...)
	--

	-- Initialise the target table
	local target_table = nil

	-- Initialise the arguments
	local args = nil

	-- Initialise the recursive variable
	local recursive = false

	-- If the deep or target variable is a boolean
	if type(deep_or_target) == "boolean" then
		--

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
		--

		-- Set the target table to the deep or target variable
		-- if it is a table, otherwise, set it to an empty table
		target_table = type(deep_or_target) == "table" and deep_or_target or {}

		-- Set the arguments to the target variable
		-- and the rest of the arguments
		args = { target, ... }
	end

	-- Initialise the index variable
	local index = #target_table + 1

	-- Iterates over the tables given
	for _, table in ipairs(args) do
		--

		-- Iterate over all of the keys and values
		for key, value in pairs(table) do
			--

			-- If the key is a number, then add using the index
			-- instead of the key.
			-- This is to allow lists to be merged.
			if type(key) == "number" then
				--

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
				--

				-- Call the merge table function
				-- recursively on the target table's
				-- key to merge the table recursively
				merge_tables(target_table[key], value)

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
---@param separator string|nil The character to split the string by
---@return string[] splitted_strings The list of strings split by the character
local function string_split(given_string, separator)
	--

	-- If the separator isn't given, set it to the whitespace character
	separator = separator or "%s"

	-- Initialise the list of splitted strings
	local splitted_strings = {}

	-- Iterate over all of the strings found by pattern
	for string in string.gmatch(given_string, "([^" .. separator .. "]+)") do
		--

		-- Add the string to the list of splitted strings
		table.insert(splitted_strings, string)
	end

	-- Return the list of splitted strings
	return splitted_strings
end

-- Function to trim a string
---@param string string The string to trim
---@return string trimmed_string The trimmed string
local function string_trim(string)
	--

	-- Return the string with the whitespace characters
	-- removed from the start and end
	return string:match("^%s*(.-)%s*$")
end

-- Function to get a value from a table
-- and return the default value if the key doesn't exist
---@param table table The table to get the value from
---@param key string|number The key to get the value from
---@param default any The default value to return if the key doesn't exist
local function table_get(table, key, default) return table[key] or default end

-- Function to pop a key from a table
---@param table table The table to pop from
---@param key string|number The key to pop
---@param default any The default value to return if the key doesn't exist
---@return any value The value of the key or the default value
local function table_pop(table, key, default)
	--

	-- Get the value of the key from the table
	local value = table[key]

	-- Remove the key from the table
	table[key] = nil

	-- Return the value if it exist,
	-- otherwise return the default value
	return value or default
end

-- Function to escape a percentage sign %
-- in the string that is being replaced
---@param replacement_string string The string to escape
---@return string replacement_result The escaped string
local function escape_replacement_string(replacement_string)
	--

	-- Get the result of the replacement
	local replacement_result = replacement_string:gsub("%%", "%%%%")

	-- Return the result of the replacement
	return replacement_result
end

-- Function to parse the number arguments to the number type
---@param args Arguments The arguments to parse
---@return Arguments parsed_args The parsed arguments
local function parse_number_arguments(args)
	--

	-- The parsed arguments
	---@type Arguments
	local parsed_args = {}

	-- Iterate over the arguments given
	for arg_name, arg_value in pairs(args) do
		--

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
---@param args Arguments The arguments to convert
---@return string args_string The string of the arguments
local function convert_arguments_to_string(args)
	--

	-- The table of string arguments
	---@type string[]
	local string_arguments = {}

	-- Iterate all the items in the argument table
	for key, value in pairs(args) do
		--

		-- If the key is a number
		if type(key) == "number" then
			--

			-- Add the stringified value to the string arguments table
			table.insert(string_arguments, tostring(value))

		-- Otherwise, if the key is a string
		elseif type(key) == "string" then
			--

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
---@param options YaziNotificationOptions|nil Options for the notification
---@return nil
local function show_warning(warning_message, options)
	return ya.notify(
		merge_tables({}, DEFAULT_NOTIFICATION_OPTIONS, options or {}, {
			content = tostring(warning_message),
			level = "warn",
		})
	)
end

-- Function to show an error
---@param error_message any The error message
---@param options YaziNotificationOptions|nil Options for the notification
---@return nil
local function show_error(error_message, options)
	return ya.notify(
		merge_tables({}, DEFAULT_NOTIFICATION_OPTIONS, options or {}, {
			content = tostring(error_message),
			level = "error",
		})
	)
end

-- Function to throw an error
---@param error_message any The error message as a format string
---@param ... any The items to substitute into the error message given
local function throw_error(error_message, ...)
	return error(string.format(error_message, ...))
end

-- Function to get the theme from an async function
---@type fun(): Th The theme object
local get_theme = ya.sync(function(state) return state.theme end)

-- Function to get the component option string
---@param component BuiltInComponents|PluginComponents The component name
---@param option string The option
---@return string component_option The component option string
local function get_component_option_string(component, option)
	return string.format("%s_%s", component, option)
end

-- Function to get the user's configuration for the input or confirm components.
---@param component BuiltInComponents|PluginComponents The name of the component
---@param defaults {
---		prompts: string|string[],    -- The default prompts
---		content: string|ui.Line|ui.Text|nil,    -- The default contents
---		origin: string|nil,    -- The default origin
---		offset: Position|nil,    -- The default offset
---}
---@param is_plugin_options boolean|nil Whether the options are plugin specific
---@param is_confirm boolean|nil Whether the component is the confirm component
---@param title_index integer|nil The index to get the title
---@return YaziInputOptions|YaziConfirmOptions options The resolved options
local function get_user_input_or_confirm_options(
	component,
	defaults,
	is_plugin_options,
	is_confirm,
	title_index
)
	--

	-- Initialise the default prompts
	local default_prompts = type(defaults.prompts) == "string"
			and { defaults.prompts }
		or defaults.prompts

	-- Initialise the title index
	title_index = title_index or 1

	-- Get the theme object
	local theme = get_theme() or {}

	-- Initialise the theme configuration
	---@diagnostic disable-next-line: undefined-field
	local theme_config = is_plugin_options and (theme.augment_command or {})
		or theme

	-- Get the default options
	local default_options = (
		is_confirm and DEFAULT_CONFIRM_OPTIONS or DEFAULT_INPUT_OPTIONS
	).pos

	-- Initialise the list of options
	local option_list = {}

	-- Initialise the list of option suffixes
	local option_suffixes = merge_tables({}, INPUT_AND_CONFIRM_OPTIONS)

	-- If the component is not the confirm component, remove the last suffix
	if not is_confirm then table.remove(option_suffixes) end

	-- Create the list of options
	for _, option_suffix in ipairs(option_suffixes) do
		table.insert(
			option_list,
			get_component_option_string(component, option_suffix)
		)
	end

	-- Unpack the options
	local title_option, origin_option, offset_option, content_option =
		table.unpack(option_list)

	-- Get the value of all the options
	---@type string|string[]
	local raw_title = theme_config[title_option or ""] or {}
	local origin = theme_config[origin_option or ""]
		or defaults.origin
		or default_options[1]
	local offset = theme_config[offset_option or ""] or {}
	local content = theme_config[content_option or ""] or defaults.content

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
		[is_confirm and "pos" or "position"] = position,
		content = content,
	}
end

-- Function to get a password from the user
---@param get_password_options GetPasswordOptions Get password options function
---@param want_confirmation boolean|nil Whether to get a confirmation password
---@return string|nil password The password or nil if the user cancelled
---@return InputEvent|nil event The event for the input function
local function get_password(get_password_options, want_confirmation)
	--

	-- Merge the obscure option with the password options
	local password_options =
		merge_tables(get_password_options(false), { obscure = true })

	-- If reconfirmation for the password is not wanted,
	-- just obtain the user's password and return it
	if not want_confirmation then return ya.input(password_options) end

	-- Merge the obscure option with the confirm password options
	local confirm_password_options =
		merge_tables(get_password_options(true), { obscure = true })

	-- Otherwise, initialise the password and the event
	local password = nil
	local event = nil

	-- While the password isn't set
	while not password do
		--

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
			--

			-- Set the password to the confirmation password
			password = confirmation_password

			-- Set the event to the confirmation event
			event = confirmation_event

			-- Break out of the loop
			break
		end

		-- Otherwise, tell the user their passwords don't match
		show_error("Passwords do not match, please try again")
	end

	-- Return the password and event
	return password, event
end

-- Function to show an overwrite prompt
---@param file_path_to_overwrite string|Url The file path to overwrite
---@return boolean overwrite Whether the user chooses to overwrite the file
local function show_overwrite_prompt(file_path_to_overwrite)
	--

	-- Get the user's configuration for the overwrite prompt
	local overwrite_confirm_options = get_user_input_or_confirm_options(
		ConfigurableComponents.BuiltIn.Overwrite,
		{
			prompts = "Overwrite file?",
			content = ui.Line("Will overwrite the following file:"),
		},
		false,
		true
	)

	-- Get the type of the overwrite content
	local overwrite_content_type = type(overwrite_confirm_options.content)

	-- Initialise the first line of the content
	local first_line = nil

	-- If the content section is a string
	if
		overwrite_content_type == "string"
		or overwrite_content_type == "table"
	then
		--

		-- Wrap the string in a line and align it to the center.
		first_line = ui.Line(overwrite_confirm_options.content)
			:align(ui.Align.CENTER)

		-- Otherwise, just set the first line to the content given
	else
		first_line = overwrite_confirm_options.content
	end

	-- Create the content for the overwrite prompt
	---@cast first_line ui.Line|ui.Span
	overwrite_confirm_options.content = ui.Text({
		first_line,
		ui.Line(string.rep("─", overwrite_confirm_options.pos.w - 2))
			:style(ui.Style(th.confirm.border))
			:align(ui.Align.LEFT),
		ui.Line(tostring(file_path_to_overwrite)):align(ui.Align.LEFT),
	}):wrap(ui.Wrap.TRIM)

	-- Get the user's confirmation for
	-- whether they want to overwrite the item
	local user_confirmation = ya.confirm(overwrite_confirm_options)

	-- Return whether the user wants to overwrite the file or not
	return user_confirmation
end

-- Function to merge the given configuration table with the default one
---@param config UserConfiguration|nil The configuration table to merge
---@return UserConfiguration merged_config The merged configuration table
local function merge_configuration(config)
	--

	-- If the configuration isn't given, then use the default one
	if config == nil then return DEFAULT_CONFIG end

	-- Initialise the list of invalid configuration options
	local invalid_configuration_options = {}

	-- Initialise the merged configuration
	local merged_config = {}

	-- Iterate over the default configuration table
	for key, value in pairs(DEFAULT_CONFIG) do
		--

		-- Add the default configuration to the merged configuration
		merged_config[key] = value
	end

	-- Iterate over the given configuration table
	for key, value in pairs(config) do
		--

		-- If the key is not in the merged configuration
		if merged_config[key] == nil then
			--

			-- Add the key to the list of invalid configuration options
			table.insert(invalid_configuration_options, key)

			-- Continue the loop
			goto continue
		end

		-- Otherwise, overwrite the value in the merged configuration
		merged_config[key] = value

		-- The label to continue the loop
		::continue::
	end

	-- If there are no invalid configuration options,
	-- then return the merged configuration
	if #invalid_configuration_options <= 0 then return merged_config end

	-- Otherwise, warn the user of the invalid configuration options
	show_warning(
		"Invalid configuration options: "
			.. table.concat(invalid_configuration_options, ", ")
	)

	-- Return the merged configuration
	return merged_config
end

-- Function to get whether sudo edit is supported
---@return boolean sudo_edit_supported Whether sudo edit is supported
local function get_sudo_edit_supported()
	--

	-- Call the "sudo --help" command and get the handle
	--
	-- The "2>&1" redirects the standard error
	-- to the file descriptor of the standard output.
	--
	-- Since Yazi displays its UI on standard error,
	-- we don't want the command to output to the standard error,
	-- which will mess up Yazi's UI, so we redirect
	-- the standard error output to the standard output.
	--
	-- References:
	-- https://stackoverflow.com/questions/10508843/what-is-dev-null-21
	-- https://stackoverflow.com/questions/818255/what-does-21-mean
	-- https://www.gnu.org/software/bash/manual/html_node/Redirections.html
	local handle = io.popen("sudo --help 2>&1")

	-- If the call fails, return false
	if not handle then return false end

	-- Otherwise, get the output of the command
	local output = handle:read("*a")

	-- Close the handle
	handle:close()

	-- If the output contains the edit flag,
	-- sudo edit is supported, otherwise, it isn't
	local sudo_edit_supported = output:match("%-e, %-%-edit") ~= nil

	-- Return whether sudo edit is supported
	return sudo_edit_supported
end

-- Function to initialise the configuration
---@type fun(
---	user_config: UserConfiguration|nil,    -- The configuration object
---): Configuration The initialised configuration object
local initialise_config = ya.sync(function(state, user_config)
	--

	-- Merge the default configuration with the user given one,
	-- as well as the additional data given.
	local config = merge_configuration(user_config)

	-- Set the sudo_edit_supported property
	---@cast config Configuration
	config.sudo_edit_supported = get_sudo_edit_supported()

	-- Set the configuration to the state
	state.config = config

	-- Return the configuration object for async functions
	return state.config
end)

-- Function to initialise the theme configuration
---@type fun(): Th
local initialise_theme = ya.sync(function(state)
	--

	-- Initialise the theme configuration table
	local theme_config = {}

	-- Iterate over all the built-in components
	for _, component in pairs(ConfigurableComponents.BuiltIn) do
		--

		-- Iterate over all the options
		for _, option in ipairs(INPUT_AND_CONFIRM_OPTIONS) do
			--

			-- Get the component's option
			local component_option =
				get_component_option_string(component, option)

			-- Get the value for the option
			local value = th[component_option]

			-- If the value isn't nil, add it to the theme configuration
			if value ~= nil then theme_config[component_option] = value end
		end
	end

	-- Add the plugin specific theme configuration to the theme configuration
	---@diagnostic disable-next-line: undefined-field
	theme_config.augment_command = th.augment_command

	-- Set the theme configuration to the state
	state.theme = theme_config

	-- Return the theme object
	return state.theme
end)

-- Function to try if a shell command exists
---@param shell_command string The shell command to check
---@param args string[]|nil The arguments to the shell command
---@return boolean shell_command_exists Whether the shell command exists
---@return CommandOutput|nil output The output of the shell command
local function async_shell_command_exists(shell_command, args)
	--

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
---@param args Arguments|string The arguments to pass to the augmented command
---@return nil
local function emit_augmented_command(command, args)
	--

	-- Initialise the arguments
	local arguments = args

	-- If the arguments are passed in a table,
	-- convert them to a string
	if type(args) == "table" then
		arguments = convert_arguments_to_string(args)
	end

	-- Emit the augmented command
	return ya.emit("plugin", {
		PLUGIN_NAME,
		string.format("%s %s", command, arguments),
	})
end

-- Function to subscribe to the augmented-extract event
---@type fun(): nil
local subscribe_to_augmented_extract_event = ya.sync(function(_)
	return ps.sub_remote("augmented-extract", function(args)
		--

		-- If the arguments given isn't a table,
		-- exit the function
		if type(args) ~= "table" then return end

		-- Iterate over the arguments
		for _, arg in ipairs(args) do
			--

			-- Emit the command to call the plugin's extract function
			-- with the given arguments and flags
			emit_augmented_command("extract", {
				archive_path = ya.quote(arg),
			})
		end
	end)
end)

-- Function to initialise the plugin
---@param opts UserConfiguration|nil The options given to the plugin
---@return Configuration config The initialised configuration object
---@return Th theme The saved theme object
local function initialise_plugin(opts)
	--

	-- Subscribe to the augmented extract event
	subscribe_to_augmented_extract_event()

	-- Initialise the configuration object
	local config = initialise_config(opts)

	-- Add the theme configuration to the config
	local theme = initialise_theme()

	-- Return the configuration object
	return config, theme
end

-- Function to standardise the mime type of a file.
-- This function will follow what Yazi does to standardise
-- mime types returned by the file command.
---@param mime_type string The mime type of the file
---@return string standardised_mime_type The standardised mime type of the file
local function standardise_mime_type(mime_type)
	--

	-- Trim the whitespace from the mime type
	local trimmed_mime_type = string_trim(mime_type)

	-- Iterate over the mime type prefixes to remove
	for _, prefix in ipairs(MIME_TYPE_PREFIXES_TO_REMOVE) do
		--

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

-- Function to check if a given mime type is an archive
---@param mime_type string|nil The mime type of the file
---@return boolean is_archive Whether the mime type is an archive
local function is_archive_mime_type(mime_type)
	--

	-- If the mime type is nil, return false
	if not mime_type then return false end

	-- Standardise the mime type
	local standardised_mime_type = standardise_mime_type(mime_type)

	-- Get the archiver for the mime type
	local archiver = ARCHIVE_MIME_TYPE_TO_ARCHIVER_MAP[standardised_mime_type]

	-- Return if an archiver exists for the mime type
	return archiver ~= nil
end

-- Function to check if a given file extension
-- is an archive file extension
---@param file_extension string|nil The file extension of the file
---@return boolean is_archive Whether the file extension is an archive
local function is_archive_file_extension(file_extension)
	--

	-- If the file extension is nil, return false
	if not file_extension then return false end

	-- Make the file extension lower case
	file_extension = file_extension:lower()

	-- Trim the whitespace from the file extension
	file_extension = string_trim(file_extension)

	-- Get if the file extension is an archive
	local is_archive = table_get(ARCHIVE_FILE_EXTENSIONS, file_extension, false)

	-- Return if the file extension is an archive file extension
	return is_archive
end

-- Function to get the mime type of a file
---@param file_path string The path to the file
---@return string mime_type The mime type of the file
local function get_mime_type(file_path)
	--

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
	local mime_type = string_trim(output.stdout)

	-- Standardise the mime type
	local standardised_mime_type = standardise_mime_type(mime_type)

	-- Return the standardised mime type
	return standardised_mime_type
end

-- Function to get a temporary name.
-- The code is taken from Yazi's source code.
---@param path string The path to the item to create a temporary name
---@return string temporary_name The temporary name for the item
local function get_temporary_name(path)
	return ".tmp_"
		.. ya.hash(string.format("extract//%s//%.10f", path, ya.time()))
end

-- Function to get a temporary directory url
-- for the given file path
---@param path string The path to the item to create a temporary directory
---@param destination_given boolean|nil Whether the destination was given
---@return Url|nil url The url of the temporary directory
local function get_temporary_directory_url(path, destination_given)
	--

	-- Get the url of the path given
	local path_url = Url(path)

	-- Initialise the parent directory to be the path given
	local parent_directory_url = path_url

	-- If the destination is not given
	if not destination_given then
		--

		-- Get the parent directory of the given path
		parent_directory_url = Url(path).parent

		-- If the parent directory doesn't exist, return nil
		if not parent_directory_url then return nil end
	end

	-- Create the temporary directory path
	local temporary_directory_url =
		fs.unique_name(parent_directory_url:join(get_temporary_name(path)))

	-- Return the temporary directory path
	return temporary_directory_url
end

-- Function to get the configuration from an async function
---@type fun(): Configuration The configuration object
local get_config = ya.sync(function(state) return state.config end)

-- Function to get the current working directory
---@type fun(): string Returns the current working directory as a string
local get_current_directory = ya.sync(
	function(_) return tostring(cx.active.current.cwd) end
)

-- Function to get the path of the hovered item
---@type fun(
---	quote: boolean|nil,    -- Whether to escape the characters in the path
---): string|nil The path of the hovered item
local get_path_of_hovered_item = ya.sync(function(_, quote)
	--

	-- Get the hovered item
	local hovered_item = cx.active.current.hovered

	-- If there is no hovered item, exit the function
	if not hovered_item then return end

	-- Convert the url of the hovered item to a string
	local hovered_item_path = tostring(cx.active.current.hovered.url)

	-- If the quote flag is passed,
	-- then quote the path of the hovered item
	if quote then hovered_item_path = ya.quote(hovered_item_path) end

	-- Return the path of the hovered item
	return hovered_item_path
end)

-- Function to get if the hovered item is a directory
---@type fun(): boolean
local hovered_item_is_dir = ya.sync(function(_)
	--

	-- Get the hovered item
	local hovered_item = cx.active.current.hovered

	-- Return if the hovered item exists and is a directory
	return hovered_item and hovered_item.cha.is_dir
end)

-- Function to get if the hovered item is an archive
---@type fun(): boolean
local hovered_item_is_archive = ya.sync(function(_)
	--

	-- Get the hovered item
	local hovered_item = cx.active.current.hovered

	-- Return if the hovered item exists and is an archive
	return hovered_item and is_archive_mime_type(hovered_item:mime())
end)

-- Function to get the paths of the selected items
---@type fun(
---	quote: boolean|nil,    -- Whether to escape the characters in the path
---): string[]|nil The list of paths of the selected items
local get_paths_of_selected_items = ya.sync(function(_, quote)
	--

	-- Get the selected items
	local selected_items = cx.active.selected

	-- If there are no selected items, exit the function
	if #selected_items == 0 then return end

	-- Initialise the list of paths of the selected items
	local paths_of_selected_items = {}

	-- Iterate over the selected items
	for _, item in pairs(selected_items) do
		--

		-- Convert the url of the item to a string
		local item_path = tostring(item)

		-- If the quote flag is passed,
		-- then quote the path of the item
		if quote then item_path = ya.quote(item_path) end

		-- Add the path of the item to the list of paths
		table.insert(paths_of_selected_items, item_path)
	end

	-- Return the list of paths of the selected items
	return paths_of_selected_items
end)

-- Function to get the number of tabs currently open
---@type fun(): number
local get_number_of_tabs = ya.sync(function() return #cx.tabs end)

-- Function to get the tab preferences
---@type fun(): tab.Preference
local get_tab_preferences = ya.sync(function(_)
	--

	-- Create the table to store the tab preferences
	local tab_preferences = {}

	-- Iterate over the tab preference keys
	for key, _ in pairs(TAB_PREFERENCE_KEYS) do
		--

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
---@type fun(): ItemGroup|nil The desired item group
local get_item_group_from_state = ya.sync(function(state)
	--

	-- Get the hovered item
	local hovered_item = cx.active.current.hovered

	-- The boolean representing that there are no selected items
	local no_selected_items = #cx.active.selected == 0

	-- If there is no hovered item
	if not hovered_item then
		--

		-- If there are no selected items, exit the function
		if no_selected_items then
			return

		-- Otherwise, if the configuration is set to have a hovered item,
		-- exit the function
		elseif state.config.must_have_hovered_item then
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
	elseif state.config.prompt then
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
---@return ItemGroup|nil item_group The item group selected by the user
local function prompt_for_desired_item_group()
	--

	-- Get the configuration
	local config = get_config()

	-- Get the default item group
	---@type ItemGroup|nil
	local default_item_group = config.default_item_group_for_prompt

	-- Get the input options, which the (h/s) options
	local input_options = INPUT_OPTIONS_TABLE[default_item_group]

	-- If the default item group is none, then set it to nil
	if default_item_group == ItemGroup.None then default_item_group = nil end

	-- Get the user's input options for the item group prompt
	local item_group_input_options = get_user_input_or_confirm_options(
		ConfigurableComponents.Plugin.ItemGroup,
		{ prompts = "Operate on hovered or selected items?" },
		true
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
---@return ItemGroup|nil item_group The desired item group
local function get_item_group()
	--

	-- Get the item group from the state
	local item_group = get_item_group_from_state()

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
---@param directories_only boolean|nil Whether to only get directories
---@return string[] directory_items The list of urls to the directory items
local function get_directory_items(
	directory_path,
	get_hidden_items,
	directories_only
)
	--

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
		--

		-- If the get hidden items flag is set to false
		-- and the item is a hidden item,
		-- then continue the loop
		if not get_hidden_items and item.cha.is_hidden then goto continue end

		-- If the directories only flag is passed
		-- and the item is not a directory,
		-- then continue the loop
		if directories_only and not item.cha.is_dir then goto continue end

		-- Otherwise, add the item path to the list of directory items
		table.insert(directory_items, tostring(item.url))

		-- The continue label to continue the loop
		::continue::
	end

	-- Return the list of directory items
	return directory_items
end

-- Function to skip child directories with only one directory
---@param initial_directory_path string The path of the initial directory
---@return nil
local function skip_single_child_directories(initial_directory_path)
	--

	-- Initialise the directory variable to the initial directory given
	local directory = initial_directory_path

	-- Get the tab preferences
	local tab_preferences = get_tab_preferences()

	-- Start an infinite loop
	while true do
		--

		-- Get all the items in the current directory
		local directory_items =
			get_directory_items(directory, tab_preferences.show_hidden)

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

-- Class implementations

-- The function to create a new instance of the archiver
---@param archive_path string The path to the archive
---@param config Configuration The configuration object
---@param destination_path string|nil The path to extract to
---@return Archiver|nil instance An instance of the archiver if available
function Archiver:new(archive_path, config, destination_path)
	--

	-- Initialise whether the archiver is available
	local available = self.command ~= nil

	-- If the archiver has not been initialised
	if not available then
		--

		-- Iterate over the commands
		for _, command in ipairs(self.commands) do
			--

			-- Call the shell command exists function
			-- on the command
			local exists = async_shell_command_exists(command)

			-- If the command exists
			if exists then
				--

				-- Save the command
				self.command = command

				-- Set the available variable to true
				available = true

				-- Break out of the loop
				break
			end
		end
	end

	-- If none of the commands for the archiver are available,
	-- then return nil
	if not available then return nil end

	-- Otherwise, create a new instance
	local instance = setmetatable({}, self)

	-- Set where to find the object's methods or properties
	self.__index = self

	-- Save the parameters given
	self.archive_path = archive_path
	self.destination_path = destination_path
	self.config = config

	-- Return the instance
	return instance
end

-- Function to retry the archiver
---@private
---@param archiver_function Archiver.Command Archiver command to retry
---@param clean_up_wanted boolean|nil Whether to clean up the destination path
---@return Archiver.Result result Result of the archiver function
function SevenZip:retry_archiver(archiver_function, clean_up_wanted)
	--

	-- Initialise the number of tries
	-- to the number of retries plus 1
	local total_number_of_tries = self.config.extract_retries + 1

	-- Get the url of the archive
	local archive_url = Url(self.archive_path)

	-- Get the archive name
	local archive_name = archive_url.name

	-- If the archive name is nil,
	-- return the result of the archiver function
	if not archive_name then
		return {
			successful = false,
			error = string.format("%s does not have a name", self.archive_path),
		}
	end

	-- Initialise the initial password prompt
	local initial_password_prompt = string.format("%s password:", archive_name)

	-- Initialise the wrong password prompt
	local wrong_password_prompt =
		string.format("Wrong password, %s password:", archive_name)

	-- Initialise the clean up function
	local clean_up = clean_up_wanted
			and function() fs.remove("dir_all", Url(self.destination_path)) end
		or function() end

	-- Initialise the error message
	local error_message = nil

	-- Iterate over the number of times to try the extraction
	for tries = 0, total_number_of_tries do
		--

		-- Execute the archiver function
		local output, error = archiver_function()

		-- If there is no output
		if not output then
			--

			-- Clean up the extracted files
			clean_up()

			-- Return the result of the archiver function
			return {
				successful = false,
				error = tostring(error),
			}
		end

		-- If the output status code is 0,
		-- which means the command was successful,
		-- return the result of the archiver function
		if output.status.code == 0 then
			return {
				successful = true,
				output = output.stdout,
			}
		end

		-- Clean up the extracted files
		clean_up()

		-- Set the error message to the standard error
		error_message = output.stderr

		-- If the command failed for a reason other
		-- than the archive being encrypted,
		-- or if the current try count
		-- is the same as the total number of tries
		if
			not (
				output.status.code == 2
				and error_message:lower():find("wrong password")
			) or tries == total_number_of_tries
		then
			--

			-- Return the archiver function result
			return {
				successful = false,
				error = error_message,
			}
		end

		-- Otherwise, get the prompt for the password
		local password_prompt = tries == 0 and initial_password_prompt
			or wrong_password_prompt

		-- Initialise the width of the input element
		local input_width = DEFAULT_INPUT_OPTIONS.pos.w

		-- If the length of the password prompt is larger
		-- than the default input with, set the input width
		-- to the length of the password prompt + 1
		if #password_prompt > input_width then
			input_width = #password_prompt + 1
		end

		-- Function to get the user's input option
		-- for the extract password prompt
		---@type GetPasswordOptions
		local function get_user_extract_password_options(_)
			--

			-- Get the password input options
			local password_input_options = get_user_input_or_confirm_options(
				ConfigurableComponents.Plugin.ExtractPassword,
				{ prompts = password_prompt },
				true
			)

			-- Set the width of the component to the input width
			---@cast password_input_options YaziInputOptions
			password_input_options.position.w = input_width

			-- Return the password input options
			return password_input_options
		end

		-- Ask the user for the password
		local user_input, event =
			get_password(get_user_extract_password_options)

		-- If the user has confirmed the input,
		-- and the user input is not nil,
		-- set the password to the user's input
		if event == 1 and user_input ~= nil then
			self.password = user_input

		-- Otherwise, the user has cancelled the input
		else
			--

			-- Return the result of the archiver command
			return {
				successful = false,
				cancelled = true,
				error = error_message,
			}
		end
	end

	-- If all the tries have been exhausted,
	-- call the clean up function
	clean_up()

	-- Return the result of the archiver command
	return {
		successful = false,
		error = error_message,
	}
end

-- Function to list the archive items with the command
---@type Archiver.ListItemsCommand
function SevenZip:list_items_command()
	--

	-- Initialise the arguments for the command
	local arguments = {

		-- List the items in the archive
		"l",

		-- Use UTF-8 encoding for console input and output
		"-sccUTF-8",

		-- Pass the password to the command
		"-p" .. self.password,

		-- Remove the headers (undocumented switch)
		"-ba",

		-- The archive path
		self.archive_path,
	}

	-- Return the result of the command to list the items in the archive
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to get the items in the archive
---@type Archiver.GetItems
function SevenZip:get_items()
	--

	-- Initialise the list of files in the archive
	---@type string[]
	local files = {}

	-- Initialise the list of directories
	---@type string[]
	local directories = {}

	-- Call the function to retry the archiver command
	-- with the list items in the archive function
	local archiver_result = self:retry_archiver(
		function() return self:list_items_command() end
	)

	-- Get the output
	local output = archiver_result.output

	-- Get the error
	local error = archiver_result.error

	-- If the archiver command was not successful,
	-- or the output was nil,
	-- then return nil the error message,
	-- and nil as the correct password
	if not archiver_result.successful or not output then
		return files, directories, error
	end

	-- Otherwise, split the output at the newline character
	local output_lines = string_split(output, "\n")

	-- The pattern to get the information from an archive item
	---@type string
	local archive_item_info_pattern = "%s+([%.%a]+)%s+(%d+)%s+(%d+)%s+(.+)$"

	-- Iterate over the lines of the output
	for _, line in ipairs(output_lines) do
		--

		-- Get the information about the archive item from the line.
		-- The information is in the format:
		-- Attributes, Size, Compressed Size, File Path
		local attributes, _, _, file_path =
			line:match(archive_item_info_pattern)

		-- If the file path doesn't exist, then continue the loop
		if not file_path then goto continue end

		-- If the attributes of the item starts with a "D",
		-- which means the item is a directory
		if attributes and attributes:find("^D") then
			--

			-- Add the directory to the list of directories
			table.insert(directories, file_path)

			-- Continue the loop
			goto continue
		end

		-- Otherwise, add the file path to the list of archive items
		table.insert(files, file_path)

		-- The continue label to continue the loop
		::continue::
	end

	-- Return the list of files, the list of directories,
	-- the error message, and the password
	return files, directories, error
end

-- Function to extract an archive using the command
---@param extract_files_only boolean|nil Extract the files only or not
---@param extract_behaviour ExtractBehaviour|nil The extraction behaviour
---@return CommandOutput|nil output The output of the command
---@return Error|nil error The error if any
function SevenZip:extract_command(extract_files_only, extract_behaviour)
	--

	-- Initialise the extract files only flag to false if it's not given
	extract_files_only = extract_files_only or false

	-- Initialise the extract behaviour to rename if it's not given
	extract_behaviour =
		self.extract_behaviour_map[extract_behaviour or ExtractBehaviour.Rename]

	-- Initialise the extraction mode to use.
	-- By default, it extracts the archive with
	-- full paths, which keeps the archive structure.
	local extraction_mode = "x"

	-- If the extract files only flag is passed
	if extract_files_only then
		--

		-- Use the regular extract,
		-- without the full paths, which will move
		-- all files in the archive into the current directory
		-- and ignore the archive folder structure.
		extraction_mode = "e"
	end

	-- Initialise the arguments for the command
	local arguments = {

		-- The extraction mode
		extraction_mode,

		-- Assume yes to all prompts
		"-y",

		-- Use UTF-8 encoding for console input and output
		"-sccUTF-8",

		-- Configure the extraction behaviour
		extract_behaviour,

		-- Pass the password to the command
		"-p" .. self.password,

		-- The archive file to extract
		self.archive_path,

		-- The destination directory path
		"-o" .. self.destination_path,
	}

	-- Return the output of the command
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to extract the archive
---@type Archiver.Extract
function SevenZip:extract(has_only_one_file)
	--

	-- Extract the archive with the extract command
	local result = self:retry_archiver(
		function() return self:extract_command(has_only_one_file) end,
		true
	)

	-- Return the archiver result
	return result
end

-- Function to call the command to add items to an archive
---@param item_paths string[] The path to the items being added to the archive
---@param password string|nil The password to encrypt the archive with
---@param encrypt_headers boolean|nil Whether to encrypt the archive headers
---@return CommandOutput|nil output The output of the command
---@return Error|nil error The error if any
function SevenZip:archive_command(item_paths, password, encrypt_headers)
	--

	-- Initialise the arguments for the command
	local arguments = {

		-- Add to the archive
		"a",

		-- Use UTF-8 encoding for console input and output
		"-sccUTF-8",
	}

	-- If the password is given, add the password
	if password then table.insert(arguments, "-p" .. password) end

	-- If encrypting headers is wanted,
	-- add the argument to encrypt the headers
	if encrypt_headers then table.insert(arguments, "-mhe") end

	-- Add the archive path and the item paths
	merge_tables(arguments, {
		self.archive_path,
		table.unpack(item_paths),
	})

	-- Return the output of the command
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to add items to an archive
---@type Archiver.Archive
function SevenZip:archive(item_paths, password, encrypt_headers)
	--

	-- Get the output of the command
	local output, error =
		self:archive_command(item_paths, password, encrypt_headers)

	-- If there is no output, return the archiver result
	if not output then
		return {
			successful = false,
			error = tostring(error),
		}
	end

	-- If the output status code is not 0
	-- return the archiver result
	if output.status.code ~= 0 then
		return {
			successful = false,
			error = tostring(output.stderr),
		}
	end

	-- Otherwise, return successful and the archive path
	return {
		successful = true,
		archive_path = self.archive_path,
	}
end

-- Function to list the archive items with the command
---@type Archiver.ListItemsCommand
function Tar:list_items_command()
	--

	-- Initialise the arguments for the command
	local arguments = {

		-- List the items in the archive
		"-t",

		-- Pass the file
		"-f",

		-- The archive file path
		self.archive_path,
	}

	-- Return the result of the command
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to get the items in the archive
---@type Archiver.GetItems
function Tar:get_items()
	--

	-- Call the function to get the list of items in the archive
	local output, error = self:list_items_command()

	-- Initialise the list of files
	---@type string[]
	local files = {}

	-- Initialise the list of directories
	---@type string[]
	local directories = {}

	-- If there is no output, return the empty lists and the error
	if not output then return files, directories, tostring(error) end

	-- Otherwise, split the output into lines and iterate over it
	for _, line in ipairs(string_split(output.stdout, "\n")) do
		--

		-- If the line ends with a slash, it's a directory
		if line:sub(-1) == "/" then
			--

			-- Add the directory without the trailing slash
			-- to the list of directories
			table.insert(directories, line:sub(1, -2))

			-- Continue the loop
			goto continue
		end

		-- Otherwise, the item is a file, so add it to the list of files
		table.insert(files, line)

		-- The label to continue the loop
		::continue::
	end

	-- Return the list of files and directories and the error
	return files, directories, output.stderr
end

-- Function to extract an archive using the command
---@param extract_behaviour ExtractBehaviour|nil The extract behaviour to use
function Tar:extract_command(extract_behaviour)
	--

	-- Initialise the extract behaviour to rename if it is not given
	extract_behaviour =
		self.extract_behaviour_map[extract_behaviour or ExtractBehaviour.Rename]

	-- Initialise the arguments for the command
	local arguments = {

		-- Extract the archive
		"-x",

		-- Verbose
		"-v",

		-- The extract behaviour flag
		extract_behaviour,

		-- Specify the destination directory
		"-C",

		-- The destination directory path
		self.destination_path,
	}

	-- If keeping permissions is wanted, add the -p flag
	if self.config.preserve_file_permissions then
		table.insert(arguments, "-p")
	end

	-- Add the -f flag and the archive path to the arguments
	table.insert(arguments, "-f")
	table.insert(arguments, self.archive_path)

	-- Create the destination path first.
	--
	-- This is required because tar does not
	-- automatically create the directory
	-- pointed to by the -C flag.
	-- Instead, tar just tries to change
	-- the working directory to the directory
	-- pointed to by the -C flag, which can
	-- fail if the directory does not exist.
	--
	-- GNU tar has a --one-top-level=[DIR] option,
	-- which will automatically create the directory
	-- given, but macOS tar does not have this option.
	--
	-- The error here is ignored because if there
	-- is an error creating the directory,
	-- then the archiver will fail anyway.
	fs.create("dir_all", Url(self.destination_path))

	-- Return the output of the command
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to extract the archive.
--
-- Tar automatically decompresses and extracts the archive
-- in one command, so there's no need to run it twice to
-- extract compressed tarballs.
---@type Archiver.Extract
function Tar:extract(_)
	--

	-- Call the command to extract the archive
	local output, error = self:extract_command()

	-- If there is no output, return the result
	if not output then
		return {
			successful = false,
			error = tostring(error),
		}
	end

	-- Otherwise, if the status code is not 0,
	-- which means the extraction was not successful,
	-- return the result
	if output.status.code ~= 0 then
		return {
			successful = false,
			output = output.stdout,
			error = output.stderr,
		}
	end

	-- Otherwise, return the successful result
	return {
		successful = true,
		output = output.stdout,
	}
end

-- Function to call the command to add items to an archive
---@param item_paths string[] The path to the items being added to the archive
function Tar:archive_command(item_paths)
	--

	-- Initialise the arguments to the command
	local arguments = {

		-- Add the items to an archive
		"-rf",

		-- The archive path
		self.archive_path,

		-- The item paths
		table.unpack(item_paths),
	}

	-- Return the output of the command
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to add items to an archive
---@type Archiver.Archive
function Tar:archive(item_paths)
	--

	-- Get the output of the command
	local output, error = self:archive_command(item_paths)

	-- If there is no output, return the archiver result
	if not output then
		return {
			successful = false,
			error = tostring(error),
		}
	end

	-- If the output status code is not 0
	-- return the archiver result
	if output.status.code ~= 0 then
		return {
			successful = false,
			error = tostring(output.stderr),
		}
	end

	-- Otherwise, return successful and the archive path
	return {
		successful = true,
		archive_path = self.archive_path,
	}
end

-- Functions for the commands

-- Function to get the archiver for the file type
---@param archive_path string The path to the archive file
---@param command SupportedCommands The command the archiver is used for
---@param config Configuration The configuration for the plugin
---@param destination_path string|nil The path to the destination directory
---@return Archiver|nil archiver The archiver for the file type
---@return Archiver.Result result The results of getting the archiver
local function get_archiver(archive_path, command, config, destination_path)
	--

	-- Get the mime type of the archive file
	local mime_type = get_mime_type(archive_path)

	-- Get the archiver for the mime type
	local archiver = command == Commands.Archive and DefaultArchiver
		or ARCHIVE_MIME_TYPE_TO_ARCHIVER_MAP[mime_type]

	-- If there is no archiver,
	-- return that it is not successful,
	-- but that it has been cancelled
	-- as the mime type is not an archive
	if not archiver then
		return archiver, {
			successful = false,
			cancelled = true,
		}
	end

	-- Instantiate an instance of the archiver
	local archiver_instance =
		archiver:new(archive_path, config, destination_path)

	-- While the archiver instance failed to be created
	while not archiver_instance do
		--

		-- If the archiver instance is the default archiver,
		-- then return an error telling the user to install the
		-- default archiver
		if archiver.name == DefaultArchiver.name then
			return archiver_instance,
				{
					successful = false,
					error = table.concat({
						string.format(
							"%s is not installed,",
							DefaultArchiver.name
						),
						string.format(
							"please install it before using the '%s' command",
							command
						),
					}, " "),
				}
		end

		-- Try instantiating the default archiver
		archiver_instance =
			DefaultArchiver:new(archive_path, config, destination_path)
	end

	-- If the user wants to preserve file permissions,
	-- and the target archiver for the mime type supports
	-- preserving file permissions, but the archiver
	-- instantiated does not, show a warning to the user
	if
		config.preserve_file_permissions
		and archiver.supports_file_permissions
		and not archiver_instance.supports_file_permissions
	then
		--

		-- The warning to show the user
		local warning = table.concat({
			string.format(
				"%s is not installed, defaulting to %s.",
				archiver.name,
				archiver_instance.name
			),
			string.format(
				"However, %s does not support preserving file permissions.",
				archiver_instance.name
			),
		}, "\n")

		-- Show the warning to the user
		show_warning(warning)
	end

	-- Return the archiver instance
	return archiver_instance, { successful = true }
end

-- Function to move the extracted items out of the temporary directory
---@param archive_url Url The url of the archive
---@param destination_url Url The url of the destination
---@return Archiver.Result result The result of the move
local function move_extracted_items(archive_url, destination_url)
	--

	-- The function to clean up the destination directory
	-- and return the archiver result in the event of an error
	---@param error string The error message to return
	---@param empty_dir_only boolean|nil Whether to remove the empty dir only
	---@return Archiver.Result
	local function fail(error, empty_dir_only)
		--

		-- Clean up the destination path
		fs.remove(empty_dir_only and "dir" or "dir_all", destination_url)

		-- Return the archiver result
		---@type Archiver.Result
		return {
			successful = false,
			error = error,
		}
	end

	-- Get the extracted items in the destination.
	-- There is a limit of 2 as we just need to
	-- know if the destination contains only
	-- a single item or not.
	local extracted_items = fs.read_dir(destination_url, { limit = 2 })

	-- If the extracted items doesn't exist,
	-- clean up and return the error
	if not extracted_items then
		return fail(
			string.format(
				"Failed to read the destination directory: %s",
				tostring(destination_url)
			)
		)
	end

	-- If there are no extracted items,
	-- clean up and return the error
	if #extracted_items == 0 then
		return fail("No files extracted from the archive", true)
	end

	-- Get the parent directory of the destination
	local parent_directory_url = destination_url.parent

	-- If the parent directory doesn't exist,
	-- clean up and return the error
	if not parent_directory_url then
		return fail("Destination path has no parent directory")
	end

	-- Get the name of the archive without the extension
	local archive_name = archive_url.stem

	-- If the name of the archive doesn't exist,
	-- clean up and return the error
	if not archive_name then
		return fail("Archive has no name without its extension")
	end

	-- Get the first extracted item
	local first_extracted_item = table.unpack(extracted_items)

	-- Initialise the variable to indicate whether the archive has only one item
	local only_one_item = false

	-- Initialise the target directory url to move the extracted items to,
	-- which is the parent directory of the archive
	-- joined with the file name of the archive without the extension
	local target_url = parent_directory_url:join(archive_name)

	-- If there is only one item in the archive
	if #extracted_items == 1 then
		--

		-- Set the only one item variable to true
		only_one_item = true

		-- Get the name of the first extracted item
		local first_extracted_item_name = first_extracted_item.url.name

		-- If the first extracted item has no name,
		-- then clean up and return the error
		if not first_extracted_item_name then
			return fail("The only extracted item has no name")
		end

		-- Otherwise, set the target url to the parent directory
		-- of the destination joined with the file name of the extracted item
		target_url = parent_directory_url:join(first_extracted_item_name)
	end

	-- Get a unique name for the target url
	local unique_target_url = fs.unique_name(target_url)

	-- If the unique target url is nil,
	-- clean up and return the error
	if not unique_target_url then
		return fail(
			"Failed to get a unique name to move the extracted items to"
		)
	end

	-- Set the target path to the string of the target url
	local target_path = tostring(unique_target_url)

	-- Initialise the move successful variable and the error message
	local error_message, move_successful = nil, false

	-- If there is only one item in the archive
	if only_one_item then
		--

		-- Move the item to the target path
		move_successful, error_message =
			os.rename(tostring(first_extracted_item.url), target_path)

	-- Otherwise
	else
		--

		-- Rename the destination directory itself to the target path
		move_successful, error_message =
			os.rename(tostring(destination_url), target_path)
	end

	-- Clean up the destination directory
	fs.remove(move_successful and "dir" or "dir_all", destination_url)

	-- Return the archiver result with the target path as the
	-- path to the extracted items
	return {
		successful = move_successful,
		error = error_message,
		extracted_items_path = target_path,
	}
end

-- Function to recursively extract archives
---@param archive_path string The path to the archive
---@param args Arguments The arguments passed to the plugin
---@param config Configuration The configuration object
---@param destination_path string|nil The destination path to extract to
---@return Archiver.Result extraction_result The extraction results
local function recursively_extract_archive(
	archive_path,
	args,
	config,
	destination_path
)
	--

	-- Get whether the destination path is given
	local destination_path_given = destination_path ~= nil

	-- Initialise the destination path to the archive path if it is not given
	local destination = destination_path or archive_path

	-- Get the temporary directory url
	local temporary_directory_url =
		get_temporary_directory_url(destination, destination_path_given)

	-- If the temporary directory can't be created
	-- then return the result
	if not temporary_directory_url then
		return {
			successful = false,
			error = "Failed to create a temporary directory",
			archive_path = archive_path,
			destination_path = destination_path,
		}
	end

	-- Get an the archiver for the archive
	local archiver, get_archiver_result = get_archiver(
		archive_path,
		Commands.Extract,
		config,
		tostring(temporary_directory_url)
	)

	-- If there is no archiver, return the result
	if not archiver then
		return merge_tables({}, get_archiver_result, {
			archive_path = archive_path,
			destination_path = destination_path,
		})
	end

	-- Function to add additional information to the extraction result
	-- The additional information are:
	--      - The archive path
	--      - The destination path
	--      - The name of the archiver
	---@param result Archiver.Result The result to add the paths to
	---@return Archiver.Result modified_result The result with the paths added
	local function add_additional_info(result)
		return merge_tables({}, result, {
			archive_path = archive_path,
			destination_path = destination_path,
			archiver_name = archiver.name,
		})
	end

	-- Get the list of archive files and directories,
	-- the error message and the password
	local archive_files, archive_directories, error = archiver:get_items()

	-- If there are no are no archive files and directories
	if #archive_files == 0 and #archive_directories == 0 then
		--

		-- The extraction result
		---@type Archiver.Result
		local extraction_result = {
			successful = false,
			error = error or "Archive is empty",
		}

		-- Return the extraction result
		return add_additional_info(extraction_result)
	end

	-- Get if the archive has only one file
	local archive_has_only_one_file = #archive_files == 1
		and #archive_directories == 0

	-- Extract the given archive
	local extraction_result = archiver:extract(archive_has_only_one_file)

	-- If the extraction result is not successful, return it
	if not extraction_result.successful then
		return add_additional_info(extraction_result)
	end

	-- Get the result of moving the extracted items
	local move_result =
		move_extracted_items(Url(archive_path), temporary_directory_url)

	-- Get the extracted items path
	local extracted_items_path = move_result.extracted_items_path

	-- If moving the extracted items isn't successful,
	-- or if the extracted items path is nil,
	-- or if the user does not want to extract archives recursively,
	-- return the move results
	if
		not move_result.successful
		or not extracted_items_path
		or not config.recursively_extract_archives
	then
		return add_additional_info(move_result)
	end

	-- Get the url of the extracted items path
	local extracted_items_url = Url(extracted_items_path)

	-- Initialise the base url for the extracted items
	local base_url = extracted_items_url

	-- Get the parent directory of the extracted items path
	local parent_directory_url = extracted_items_url.parent

	-- If the parent directory doesn't exist
	if not parent_directory_url then
		--

		-- Modify the move result with a custom error
		---@type Archiver.Result
		local modified_move_result = merge_tables({}, move_result, {
			error = "Archive has no parent directory",
			archive_path = archive_path,
			destination_path = destination_path,
		})

		-- Return the modified move result
		return modified_move_result
	end

	-- If the archive has only one file
	if archive_has_only_one_file then
		--

		-- Set the base url to the parent directory of the extracted items path
		base_url = parent_directory_url
	end

	-- Iterate over the archive files
	for _, file in ipairs(archive_files) do
		--

		-- Get the file extension of the file
		local file_extension = Url(file).ext

		-- If the file extension is not found, then skip the file
		if not file_extension then goto continue end

		-- If the file extension is not an archive file extension, skip the file
		if not is_archive_file_extension(file_extension) then goto continue end

		-- Otherwise, get the full url to the archive
		local full_archive_url = base_url:join(file)

		-- Get the full path to the archive
		local full_archive_path = tostring(full_archive_url)

		-- Yazi is now way too quick (a good problem to have, really),
		-- so we slow it down a little to make sure that the
		-- extracted files are not overwritten by each other
		ya.sleep(10e-3)

		-- Recursively extract the archive
		emit_augmented_command(
			"extract",
			merge_tables({}, args, {
				archive_path = ya.quote(full_archive_path),
				remove = true,
			})
		)

		-- The label the continue the loop
		::continue::
	end

	-- Return the move result
	return add_additional_info(move_result)
end

-- Function to show an archiver error
---@param archiver_result Archiver.Result The result from the archiver
---@return nil
local function throw_archiver_error(archiver_result)
	--

	-- The line for the error
	local error_line = string.format("Error: %s", archiver_result.error)

	-- If the archiver name exists
	if archiver_result.archiver_name then
		--

		-- Add the archiver's name to the error
		error_line = string.format(
			"%s error: %s",
			archiver_result.archiver_name,
			archiver_result.error
		)
	end

	-- Initialise the error
	local error_string = nil

	-- If the destination path exists,
	-- show the extraction error
	if archiver_result.destination_path then
		error_string = table.concat({
			string.format(
				"Failed to extract archive at: %s",
				archiver_result.archive_path
			),
			string.format("Destination: %s", archiver_result.destination_path),
			error_line,
		}, "\n")

	-- Otherwise, just show the archiver error
	else
		error_string = error_line
	end

	-- Throw the error
	throw_error(error_string)
end

-- Function to handle the open command
---@type CommandFunction
local function handle_open(args, config)
	--

	-- Call the function to get the item group
	local item_group = get_item_group()

	-- If no item group is returned, exit the function
	if not item_group then return end

	-- If the item group is the selected items,
	-- then execute the command and exit the function
	if item_group == ItemGroup.Selected then
		--

		-- Emit the command and exit the function
		return ya.emit("open", args)
	end

	-- If the hovered item is a directory
	if hovered_item_is_dir() then
		--

		-- If smart enter is wanted,
		-- calls the function to enter the directory
		-- and exit the function
		if config.smart_enter or table_pop(args, "smart", false) then
			return emit_augmented_command("enter", args)
		end

		-- Otherwise, just exit the function
		return
	end

	-- Otherwise, if the hovered item is not an archive,
	-- or entering archives isn't wanted,
	-- or the interactive flag is passed
	if
		not hovered_item_is_archive()
		or not config.enter_archives
		or args.interactive
	then
		--

		-- Simply emit the open command,
		-- opening only the hovered item
		-- as the item group is the hovered item,
		-- and exit the function
		return ya.emit("open", merge_tables({}, args, { hovered = true }))
	end

	-- Otherwise, the hovered item is an archive
	-- and entering archives is wanted,
	-- so get the path of the hovered item
	local archive_path = get_path_of_hovered_item()

	-- If the archive path somehow doesn't exist, then exit the function
	if not archive_path then return end

	-- Get the parent directory of the hovered item
	local parent_directory_url = Url(archive_path).parent

	-- If the parent directory doesn't exist, then exit the function
	if not parent_directory_url then return end

	-- Emit the command to extract the archive
	-- and reveal the extracted items
	emit_augmented_command(
		"extract",
		merge_tables({}, args, {
			archive_path = ya.quote(archive_path),
			reveal = true,
			parent_dir = ya.quote(tostring(parent_directory_url)),
		})
	)
end

-- Function to get the archive paths for the extract command
---@param args Arguments The arguments passed to the plugin
---@return string|string[]|nil archive_paths The archive paths
local function get_archive_paths(args)
	--

	-- Get the archive path from the arguments given
	local archive_path = table_pop(args, "archive_path")

	-- If the archive path is given, return it immediately
	if archive_path then return archive_path end

	-- Otherwise, get the item group
	local item_group = get_item_group()

	-- If there is no item group
	if not item_group then return end

	-- If the item group is the hovered item
	if item_group == ItemGroup.Hovered then
		--

		-- Get the hovered item path
		local hovered_item_path = get_path_of_hovered_item(true)

		-- If the hovered item path is nil, exit the function
		if not hovered_item_path then return end

		-- Otherwise, return the hovered item path
		return hovered_item_path
	end

	-- Otherwise, if the item group is the selected items
	if item_group == ItemGroup.Selected then
		--

		-- Get the list of selected items
		local selected_items = get_paths_of_selected_items(true)

		-- If there are no selected items, exit the function
		if not selected_items then return end

		-- Otherwise, return the list of selected items
		return selected_items
	end
end

-- Function to handle the extract command
---@type CommandFunction
local function handle_extract(args, config)
	--

	-- Get the archive paths
	local archive_paths = get_archive_paths(args)

	-- Get the destination path from the arguments given
	---@type string
	local destination_path = table_pop(args, "destination_path")

	-- If there are no archive paths, exit the function
	if not archive_paths then return end

	-- If the archive path is a list
	if type(archive_paths) == "table" then
		--

		-- Iterate over the archive paths
		-- and call the extract command on them
		for _, archive_path in ipairs(archive_paths) do
			emit_augmented_command(
				"extract",
				merge_tables({}, args, {
					archive_path = ya.quote(archive_path),
				})
			)
		end

		-- Exit the function
		return
	end

	-- Otherwise the archive path is a string
	---@type string
	local archive_path = archive_paths

	-- Call the function to recursively extract the archive
	local extraction_result = recursively_extract_archive(
		archive_path,
		args,
		config,
		destination_path
	)

	-- If the extraction is cancelled, then just exit the function
	if extraction_result.cancelled then return end

	-- Get the extracted items path
	local extracted_items_path = extraction_result.extracted_items_path

	-- If the extraction is not successful, notify the user
	if not extraction_result.successful or not extracted_items_path then
		return throw_archiver_error(extraction_result)
	end

	-- Get the url of the archive
	local archive_url = Url(archive_path)

	-- If the remove flag is passed,
	-- then remove the archive after extraction
	if table_pop(args, "remove", false) then fs.remove("file", archive_url) end

	-- If the reveal flag is passed
	if table_pop(args, "reveal", false) then
		--

		-- Get the url of the extracted items
		local extracted_items_url = Url(extracted_items_path)

		-- Get the parent directory of the extracted items
		local parent_directory_url = extracted_items_url.parent

		-- If the parent directory doesn't exist, then exit the function
		if not parent_directory_url then return end

		-- Get the given parent directory
		local given_parent_directory = table_pop(args, "parent_dir")

		-- If there is a parent directory given but the parent directory
		-- of the extracted items isn't the same as the given one,
		-- exit the function
		if
			given_parent_directory
			and given_parent_directory ~= tostring(parent_directory_url)
		then
			return
		end

		-- Get the cha of the extracted item
		local extracted_items_cha = fs.cha(extracted_items_url, false)

		-- If the cha of the extracted item doesn't exist,
		-- exit the function
		if not extracted_items_cha then return end

		-- If the extracted item is not a directory
		if not extracted_items_cha.is_dir then
			--

			-- Reveal the item and exit the function
			return ya.emit("reveal", { extracted_items_url })
		end

		-- Otherwise, change the directory to the extracted item.
		-- Note that extracted_items_url is destroyed here.
		ya.emit("cd", { extracted_items_url })

		-- If the user wants to skip single subdirectories on enter,
		-- and the no skip flag is not passed
		if
			config.skip_single_subdirectory_on_enter
			and not table_pop(args, "no_skip", false)
		then
			--

			-- Call the function to skip child directories
			skip_single_child_directories(extracted_items_path)
		end
	end
end

-- Function to handle the enter command
---@type CommandFunction
local function handle_enter(args, config)
	--

	-- If the hovered item is not a directory
	if not hovered_item_is_dir() then
		--

		-- If smart enter is wanted,
		-- call the function for the open command
		-- and exit the function
		if config.smart_enter or table_pop(args, "smart", false) then
			return emit_augmented_command("open", args)
		end

		-- Otherwise, just exit the function
		return
	end

	-- Otherwise, always emit the enter command,
	ya.emit("enter", args)

	-- If the user doesn't want to skip single subdirectories on enter,
	-- or one of the arguments passed is no skip,
	-- then exit the function
	if
		not config.skip_single_subdirectory_on_enter
		or table_pop(args, "no_skip", false)
	then
		return
	end

	-- Otherwise, call the function to skip child directories
	-- with only a single directory inside
	skip_single_child_directories(get_current_directory())
end

-- Function to handle the leave command
---@type CommandFunction
local function handle_leave(args, config)
	--

	-- Always emit the leave command
	ya.emit("leave", args)

	-- If the user doesn't want to skip single subdirectories on leave,
	-- or one of the arguments passed is no skip,
	-- then exit the function
	if
		not config.skip_single_subdirectory_on_leave
		or table_pop(args, "no_skip", false)
	then
		return
	end

	-- Otherwise, initialise the directory to the current directory
	local directory = get_current_directory()

	-- Get the tab preferences
	local tab_preferences = get_tab_preferences()

	-- Start an infinite loop
	while true do
		--

		-- Get all the items in the current directory
		local directory_items =
			get_directory_items(directory, tab_preferences.show_hidden)

		-- If the number of directory items is not 1,
		-- then break out of the loop.
		if #directory_items ~= 1 then break end

		-- Get the parent directory of the current directory
		local parent_directory = Url(directory).parent

		-- If the parent directory is nil,
		-- break the loop
		if not parent_directory then break end

		-- Otherwise, set the new directory to the parent directory
		directory = tostring(parent_directory)
	end

	-- Emit the change directory command to change to the directory variable
	ya.emit("cd", { directory })
end

-- Function to handle a Yazi command
---@param command string A Yazi command
---@param args Arguments The arguments passed to the plugin
---@return nil
local function handle_yazi_command(command, args)
	--

	-- Call the function to get the item group
	local item_group = get_item_group()

	-- If no item group is returned, exit the function
	if not item_group then return end

	-- If the item group is the selected items
	if item_group == ItemGroup.Selected then
		--

		-- Emit the command to operate on the selected items
		ya.emit(command, args)

	-- If the item group is the hovered item
	elseif item_group == ItemGroup.Hovered then
		--

		-- Emit the command with the hovered option
		ya.emit(command, merge_tables({}, args, { hovered = true }))
	end
end

-- Function to enter or open the created file
---@param item_url Url The url of the item to create
---@param is_directory boolean|nil Whether the item to create is a directory
---@param args Arguments The arguments passed to the plugin
---@param config Configuration The configuration object
---@return nil
local function enter_or_open_created_item(item_url, is_directory, args, config)
	--

	-- If the item is a directory
	if is_directory then
		--

		-- If user does not want to enter the directory
		-- after creating it, exit the function
		if
			not (
				config.enter_directory_after_creation
				or table_pop(args, "enter", false)
			)
		then
			return
		end

		-- Otherwise, call the function change to the created directory
		return ya.emit("cd", { item_url })
	end

	-- Otherwise, the item is a file

	-- If the user does not want to open the file
	-- after creating it, exit the function
	if
		not (config.open_file_after_creation or table_pop(args, "open", false))
	then
		return
	end

	-- Call the function to open the file
	return ya.emit("open", { hovered = true })
end

-- Function to execute the create command
---@param item_url Url The url of the item to create
---@param args Arguments The arguments passed to the plugin
---@param config Configuration The configuration object
---@return nil
local function execute_create(item_url, is_directory, args, config)
	--

	-- Get the parent directory of the file to create
	local parent_directory_url = item_url.parent

	-- If the parent directory doesn't exist,
	-- then show an error and exit the function
	if not parent_directory_url then
		return throw_error(
			"Parent directory of the item to create doesn't exist"
		)
	end

	-- If the item to create is a directory
	if is_directory then
		--

		-- Call the function to create the directory
		local successful, error_message = fs.create("dir_all", item_url)

		-- If the function is not successful,
		-- show the error message and exit the function
		if not successful then return throw_error(error_message) end

	-- Otherwise, the item to create is a file
	else
		--

		-- Otherwise, create the parent directory if it doesn't exist
		if not fs.cha(parent_directory_url, false) then
			--

			-- Call the function to create the parent directory
			local successful, error_message =
				fs.create("dir_all", parent_directory_url)

			-- If the function is not successful,
			-- show the error message and exit the function
			if not successful then return throw_error(error_message) end
		end

		-- Otherwise, create the file
		local successful, error_message = fs.write(item_url, "")

		-- If the function is not successful,
		-- show the error message and exit the function
		if not successful then return throw_error(error_message) end
	end

	-- Wait for a tiny bit for the file to be created
	ya.sleep(10e-2)

	-- Reveal the created item
	ya.emit("reveal", { tostring(item_url) })

	-- Call the function to enter or open the created item
	enter_or_open_created_item(item_url, is_directory, args, config)
end

-- Function to handle the create command
---@type CommandFunction
local function handle_create(args, config)
	--

	-- Get the directory flag
	local dir_flag = table_pop(args, "dir", false)

	-- Get the user's input options for the create command
	local create_input_options = get_user_input_or_confirm_options(
		ConfigurableComponents.BuiltIn.Create,
		{ prompts = { "Create:", "Create (dir):" } },
		false,
		false,
		dir_flag and 2 or 1
	)

	-- Get the user's input for the item to create
	---@cast create_input_options YaziInputOptions
	local user_input, event = ya.input(create_input_options)

	-- If the user input is nil,
	-- or if the user did not confirm the input,
	-- exit the function
	if not user_input or event ~= 1 then return end

	-- Get the current working directory as a url
	local current_working_directory = Url(get_current_directory())

	-- Get whether the url ends with a path delimiter
	local ends_with_path_delimiter = user_input:find("[/\\]$")

	-- Get the whether the given item is a directory or not based
	-- on the default conditions for a directory
	local is_directory = ends_with_path_delimiter or dir_flag

	-- Get the url from the user's input
	local item_url = Url(user_input)

	-- If the user does not want to use the default Yazi create behaviour
	if
		not (
			config.use_default_create_behaviour
			or table_pop(args, "default_behaviour", false)
		)
	then
		--

		-- Get the file extension from the user's input
		local file_extension = item_url.ext

		-- Set the is directory variable to the is directory condition
		-- or if the file extension exists
		is_directory = is_directory or not file_extension
	end

	-- Get the full url of the item to create
	local full_url = current_working_directory:join(item_url)

	-- If the path to the item to create already exists,
	-- and the user did not pass the force flag
	if fs.cha(full_url, false) and not table_pop(args, "force", false) then
		--

		-- Get whether the user wants to overwrite the file
		local should_overwrite = show_overwrite_prompt(full_url)

		-- If the user does not want to overwrite the file,
		-- then exit the function
		if not should_overwrite then return end
	end

	-- Call the function to execute the create command
	return execute_create(full_url, is_directory, args, config)
end

-- Function to remove the F flag from the less command
---@param command string The shell command containing the less command
---@return string command The command with the F flag removed
---@return boolean f_flag_found Whether the F flag was found
local function remove_f_flag_from_less_command(command)
	--

	-- Initialise the variable to store if the F flag is found
	local f_flag_found = false

	-- Initialise the variable to store the replacement count
	local replacement_count = 0

	-- Remove the F flag when it is passed at the start
	-- of the flags given to the less command
	command, replacement_count = command:gsub("(%f[%a]less%f[%A].*)%-F", "%1")

	-- If the replacement count is not 0,
	-- set the f_flag_found variable to true
	if replacement_count ~= 0 then f_flag_found = true end

	-- Remove the F flag when it is passed in the middle
	-- or end of the flags given to the less command command
	command, replacement_count =
		command:gsub("(%f[%a]less%f[%A].*%-)(%a*)F(%a*)", "%1%2%3")

	-- If the replacement count is not 0,
	-- set the f_flag_found variable to true
	if replacement_count ~= 0 then f_flag_found = true end

	-- Return the command and whether or not the F flag was found
	return command, f_flag_found
end

-- Function to fix a command containing less.
-- All this function does is remove
-- the F flag from a command containing less.
---@param command string The shell command containing the less command
---@return string command The fixed shell command
local function fix_shell_command_containing_less(command)
	--

	-- Remove the F flag from the given command
	local fixed_command = remove_f_flag_from_less_command(command)

	-- Get the LESS environment variable
	local less_environment_variable = os.getenv("LESS")

	-- If the LESS environment variable is not set,
	-- then return the given command with the F flag removed
	if not less_environment_variable then return fixed_command end

	-- Otherwise, remove the F flag from the LESS environment variable
	-- and check if the F flag was found
	local less_command_with_modified_env_variables, f_flag_found =
		remove_f_flag_from_less_command("less " .. less_environment_variable)

	-- If the F flag isn't found,
	-- then return the given command with the F flag removed
	if not f_flag_found then return fixed_command end

	-- Add the less environment variable flags to the less command
	fixed_command = fixed_command:gsub(
		"%f[%a]less%f[%A]",
		escape_replacement_string(less_command_with_modified_env_variables)
	)

	-- Unset the LESS environment variable before calling the command
	fixed_command = "unset LESS; " .. fixed_command

	-- Return the fixed command
	return fixed_command
end

-- Function to fix the bat default pager command
---@param command string The command containing the bat default pager command
---@return string command The fixed bat command
local function fix_shell_command_containing_bat(command)
	--

	-- The pattern to match the pager argument for the bat command
	local bat_pager_pattern = "(%-%-pager)%s+(%S+)"

	-- Get the pager argument for the bat command
	local _, pager_argument = command:match(bat_pager_pattern)

	-- If there is a pager argument
	--
	-- We don't need to do much if the pager argument already exists,
	-- as we can rely on the function that fixes the less command to
	-- remove the -F flag that is executed after this function is called.
	--
	-- There's only work to be done if the pager argument isn't quoted,
	-- as we need to quote it so the function that fixes the less command
	-- can execute cleanly without causing shell syntax errors.
	--
	-- The reason why we don't quote the less command in the function
	-- to fix the less command is to not deal with using backslashes
	-- to escape the quotes, which can get really messy and really confusing,
	-- so we just naively replace the less command with the fixed version
	-- without caring about whether the less command is passed as an
	-- argument, or is called as a shell command.
	if pager_argument then
		--

		-- If the pager argument is quoted, return the command immediately
		if pager_argument:find("['\"].+['\"]") then return command end

		-- Otherwise, quote the pager argument with single quotes
		--
		-- It should be fine to quote with single quotes
		-- as the user passing the argument probably isn't
		-- using a shell variable, as they would have quoted
		-- the shell variable in double quotes instead of
		-- omitting the quotes.
		pager_argument = string.format("'%s'", pager_argument)

		-- Replace the pager argument with the quoted version
		local modified_command =
			command:gsub(bat_pager_pattern, "%1 " .. pager_argument)

		-- Return the modified command
		return modified_command
	end

	-- If there is no pager argument,
	-- initialise the default pager command for bat without the F flag
	local bat_default_pager_command_without_f_flag = "less -RX"

	-- Replace the bat command with the command to use the
	-- bat default pager command without the F flag
	local modified_command = command:gsub(
		bat_command_pattern,
		string.format(
			"bat --pager '%s'",
			bat_default_pager_command_without_f_flag
		),
		1
	)

	-- Return the modified command
	return modified_command
end

-- Function to fix the shell commands given to work properly with Yazi
---@param command string A shell command
---@return string command The fixed shell command
local function fix_shell_command(command)
	--

	-- If the given command contains the bat command
	if command:find(bat_command_pattern) ~= nil then
		--

		-- Calls the command to fix the bat command
		command = fix_shell_command_containing_bat(command)
	end

	-- If the given command includes the less command
	if command:find("%f[%a]less%f[%A]") ~= nil then
		--

		-- Fix the command containing less
		command = fix_shell_command_containing_less(command)
	end

	-- Return the modified command
	return command
end

-- Function to handle a shell command
---@type CommandFunction
local function handle_shell(args, _)
	--

	-- Get the first item of the arguments given
	-- and set it to the command variable
	local command = table.remove(args, 1)

	-- Get the type of the command variable
	local command_type = type(command)

	-- If the command isn't a string,
	-- show an error message and exit the function
	if command_type ~= "string" then
		return throw_error(
			"Shell command given is not a string, "
				.. "instead it is a '%s', "
				.. "with value '%s'",
			command_type,
			tostring(command)
		)
	end

	-- Fix the given command
	command = fix_shell_command(command)

	-- Call the function to get the item group
	local item_group = get_item_group()

	-- If no item group is returned, exit the function
	if not item_group then return end

	-- Get whether the exit if directory flag is passed
	local exit_if_dir = table_pop(args, "exit_if_dir", false)

	-- If the item group is the selected items
	if item_group == ItemGroup.Selected then
		--

		-- Get the paths of the selected items
		local selected_items = get_paths_of_selected_items(true)

		-- If there are no selected items, exit the function
		if not selected_items then return end

		-- If the exit if directory flag is passed
		if exit_if_dir then
			--

			-- Initialise the number of files
			local number_of_files = 0

			-- Iterate over all of the selected items
			for _, item in pairs(selected_items) do
				--

				-- Get the cha object of the item
				local item_cha = fs.cha(Url(item), false)

				-- If the item isn't a directory
				if not (item_cha or {}).is_dir then
					--

					-- Increment the number of files
					number_of_files = number_of_files + 1
				end
			end

			-- If the number of files is 0, then exit the function
			if number_of_files == 0 then return end
		end

		-- Replace the shell variable in the command
		-- with the quoted paths of the selected items
		command = command:gsub(
			shell_variable_pattern,
			escape_replacement_string(table.concat(selected_items, " "))
		)

	-- If the item group is the hovered item
	elseif item_group == ItemGroup.Hovered then
		--

		-- Get the hovered item path
		local hovered_item_path = get_path_of_hovered_item(true)

		-- If the hovered item path is nil, exit the function
		if not hovered_item_path then return end

		-- If the exit if directory flag is passed,
		-- and the hovered item is a directory,
		-- then exit the function
		if exit_if_dir and hovered_item_is_dir() then return end

		-- Replace the shell variable in the command
		-- with the quoted path of the hovered item
		command = command:gsub(
			shell_variable_pattern,
			escape_replacement_string(hovered_item_path)
		)

	-- Otherwise, exit the function
	else
		return
	end

	-- Merge the command back into the arguments given
	args = merge_tables({ command }, args)

	-- Emit the command to operate on the hovered item
	ya.emit("shell", args)
end

-- Function to handle the paste command
---@type CommandFunction
local function handle_paste(args, config)
	--

	-- If the hovered item is not a directory or smart paste is not wanted
	if
		not hovered_item_is_dir()
		or not (config.smart_paste or table_pop(args, "smart", false))
	then
		--

		-- Just paste the items inside the current directory
		-- and exit the function
		return ya.emit("paste", args)
	end

	-- Otherwise, enter the directory
	ya.emit("enter", {})

	-- Paste the items inside the directory
	ya.emit("paste", args)

	-- Leave the directory
	ya.emit("leave", {})
end

-- Function to execute the tab create command
---@type fun(
---	args: Arguments,    -- The arguments passed to the plugin
---): nil
local execute_tab_create = ya.sync(function(state, args)
	--

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
			state.config.smart_tab_create or table_pop(args, "smart", false)
		)
	then
		--

		-- Emit the command to create a new tab with the arguments
		-- and exit the function
		return ya.emit("tab_create", args)
	end

	-- Otherwise, emit the command to create a new tab
	-- with the hovered item's url
	ya.emit("tab_create", { hovered_item.url })
end)

-- Function to handle the tab create command
---@type CommandFunction
local function handle_tab_create(args)
	--

	-- Call the function to execute the tab create command
	execute_tab_create(args)
end

-- Function to execute the tab switch command
---@type fun(
---	args: Arguments,    -- The arguments passed to the plugin
---): nil
local execute_tab_switch = ya.sync(function(state, args)
	--

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
		not (state.config.smart_tab_switch or table_pop(args, "smart", false))
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
		--

		-- Call the tab create command
		ya.emit("tab_create", { current_tab.cwd })

		-- If there is a hovered item
		if current_tab.hovered then
			--

			-- Reveal the hovered item
			ya.emit("reveal", { current_tab.hovered.url })
		end
	end

	-- Switch to the given tab index
	ya.emit("tab_switch", args)
end)

-- Function to handle the tab switch command
---@type CommandFunction
local function handle_tab_switch(args)
	--

	-- Call the function to execute the tab switch command
	execute_tab_switch(args)
end

-- Function to execute the quit command
---@type CommandFunction
local function handle_quit(args, config)
	--

	-- Get the number of tabs
	local number_of_tabs = get_number_of_tabs()

	-- If the user doesn't want the confirm on quit functionality,
	-- or if the number of tabs is 1 or less,
	-- then emit the quit command
	if
		not (config.confirm_on_quit or table_pop(args, "confirm", false))
		or number_of_tabs <= 1
	then
		return ya.emit("quit", args)
	end

	-- Otherwise, get the user's confirm options
	local quit_confirm_options =
		get_user_input_or_confirm_options(ConfigurableComponents.Plugin.Quit, {
			prompts = "Quit?",
			content = ui.Text({
				"There are multiple tabs open.",
				"Are you sure you want to quit?",
			}):wrap(ui.Wrap.TRIM),
		}, true, true)

	-- Get the type of the quit content
	local quit_content_type = type(quit_confirm_options.content)

	-- If the type of the quit content is a string or a list of strings
	if quit_content_type == "string" or quit_content_type == "table" then
		quit_confirm_options.content = ui.Text(quit_confirm_options.content)
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

-- Function to handle smooth scrolling
---@param steps number The number of steps to scroll
---@param scroll_delay number The scroll delay in seconds
---@param scroll_func fun(step: integer): nil The function to call to scroll
local function smoothly_scroll(steps, scroll_delay, scroll_func)
	--

	-- Initialise the direction to positive 1
	local direction = 1

	-- If the number of steps is negative
	if steps < 0 then
		--

		-- Set the direction to negative 1
		direction = -1

		-- Convert the number of steps to positive
		steps = -steps
	end

	-- Iterate over the number of steps
	for _ = 1, steps do
		--

		-- Call the function to scroll
		scroll_func(direction)

		-- Pause for the scroll delay
		ya.sleep(scroll_delay)
	end
end

-- Function to do the wraparound for the arrow command
---@param args Arguments -- The arguments passed to the plugin
---@return nil
local function wraparound_arrow(args)
	--

	-- Get the number of steps from the arguments given
	local steps = table.remove(args, 1) or 1

	-- If the number of steps isn't a number,
	-- immediately emit the arrow command
	-- and exit the function
	if type(steps) ~= "number" then
		return ya.emit("arrow", merge_tables({ steps }, args))
	end

	-- Initialise the arrow command to use
	local arrow_command = "next"

	-- If the number of steps is negative,
	if steps < 0 then
		--

		-- Change the number of steps to positive
		steps = -steps

		-- Set the arrow command to "prev"
		arrow_command = "prev"
	end

	-- Iterate over the number of steps
	for _ = 1, steps do
		--

		-- Emit the arrow command
		ya.emit("arrow", merge_tables({ arrow_command }, args))
	end
end

-- Function to handle the arrow command
---@type CommandFunction
local function handle_arrow(args, config)
	--

	-- If smooth scrolling is wanted,
	if config.smooth_scrolling then
		--

		-- Get the number of steps from the arguments given
		local steps = table.remove(args, 1) or 1

		-- If the number of steps isn't a number,
		-- immediately emit the arrow command
		-- and exit the function
		if type(steps) ~= "number" then
			return ya.emit("arrow", merge_tables({ steps }, args))
		end

		-- Initialise the function to the regular arrow command
		local function scroll_func(step)
			ya.emit("arrow", merge_tables({ step }, args))
		end

		-- If wraparound file navigation is wanted
		-- and the no_wrap argument isn't passed
		if
			config.wraparound_file_navigation
			and not table_pop(args, "no_wrap", false)
		then
			--

			-- Use the wraparound arrow function
			function scroll_func(step)
				wraparound_arrow(merge_tables({ step }, args))
			end
		end

		-- Call the smoothly scroll function and exit the function
		return smoothly_scroll(steps, config.scroll_delay, scroll_func)
	end

	-- Otherwise, if smooth scrolling is not wanted,
	-- and wraparound file navigation is wanted,
	-- and the no_wrap argument isn't passed,
	-- call the wraparound arrow function
	-- and exit the function
	if
		config.wraparound_file_navigation
		and not table_pop(args, "no_wrap", false)
	then
		return wraparound_arrow(args)
	end

	-- Otherwise, emit the regular arrow command
	ya.emit("arrow", args)
end

-- Function to get the directory items in the parent directory
---@type fun(
---	directories_only: boolean,    -- Whether to only get directories
---): string[] directory_items The list of paths to the directory items
local get_parent_directory_items = ya.sync(function(_, directories_only)
	--

	-- Initialise the list of directory items
	local directory_items = {}

	-- Get the parent directory
	local parent_directory = cx.active.parent

	-- If the parent directory doesn't exist,
	-- return the empty list of directory items
	if not parent_directory then return directory_items end

	-- Otherwise, iterate over the items in the parent directory
	for _, item in ipairs(parent_directory.files) do
		--

		-- If the directories only flag is passed,
		-- and the item is not a directory,
		-- then skip the item
		if directories_only and not item.cha.is_dir then goto continue end

		-- Otherwise, add the item to the list of directory items
		table.insert(directory_items, item)

		-- The continue label to skip the item
		::continue::
	end

	-- Return the list of directory items
	return directory_items
end)

-- Function to execute the parent arrow command
---@type fun(
---	args: Arguments,    -- The arguments passed to the plugin
---): nil
local execute_parent_arrow = ya.sync(function(state, args)
	--

	-- Gets the parent directory
	local parent_directory = cx.active.parent

	-- If the parent directory doesn't exist,
	-- then exit the function
	if not parent_directory then return end

	-- Get the offset from the arguments given
	local offset = table.remove(args, 1) or 1

	-- Get the type of the offset
	local offset_type = type(offset)

	-- If the offset is not a number,
	-- then show an error that the offset is not a number
	-- and exit the function
	if offset_type ~= "number" then
		return throw_error(
			"The given offset is not of the type 'number', "
				.. "instead it is a '%s', "
				.. "with value '%s'",
			offset_type,
			tostring(offset)
		)
	end

	-- Get the number of items in the parent directory
	local number_of_items = #parent_directory.files

	-- Initialise the new cursor index
	-- to the current cursor index
	local new_cursor_index = parent_directory.cursor

	-- Get whether the user wants to sort directories first
	local sort_directories_first = cx.active.pref.sort_dir_first

	-- If wraparound file navigation is wanted
	-- and the no_wrap argument isn't passed
	if
		state.config.wraparound_file_navigation
		and not table_pop(args, "no_wrap", false)
	then
		--

		-- If the user sorts their directories first
		if sort_directories_first then
			--

			-- Get the directories in the parent directory
			local directories = get_parent_directory_items(true)

			-- Get the number of directories in the parent directory
			local number_of_directories = #directories

			-- If the number of directories is 0, then exit the function
			if number_of_directories == 0 then return end

			-- Get the new cursor index by adding the offset,
			-- and modding the whole thing by the number of directories
			new_cursor_index = (parent_directory.cursor + offset)
				% number_of_directories

		-- Otherwise, if the user doesn't sort their directories first
		else
			--

			-- Get the new cursor index by adding the offset,
			-- and modding the whole thing by the number of
			-- items in the parent directory
			new_cursor_index = (parent_directory.cursor + offset)
				% number_of_items
		end

	-- Otherwise, get the new cursor index normally
	-- by adding the offset to the cursor index
	else
		new_cursor_index = parent_directory.cursor + offset
	end

	-- Increment the cursor index by 1.
	-- The cursor index needs to be increased by 1
	-- as the cursor index is 0-based, while Lua
	-- tables are 1-based.
	new_cursor_index = new_cursor_index + 1

	-- Get the starting index of the loop
	local start_index = new_cursor_index

	-- Get the ending index of the loop.
	--
	-- If the offset given is negative, set the end index to 1,
	-- as the loop will iterate backwards.
	-- Otherwise, if the step given is positive,
	-- set the end index to the number of items in the
	-- parent directory.
	local end_index = offset < 0 and 1 or number_of_items

	-- Get the step for the loop.
	--
	-- If the offset given is negative, set the step to -1,
	-- as the loop will iterate backwards.
	-- Otherwise, if the step given is positive, set
	-- the step to 1 to iterate forwards.
	local step = offset < 0 and -1 or 1

	-- Iterate over the parent directory items
	for i = start_index, end_index, step do
		--

		-- Get the directory item
		local directory_item = parent_directory.files[i]

		-- If the directory item exists and is a directory
		if directory_item and directory_item.cha.is_dir then
			--

			-- Emit the command to change directory to
			-- the directory item and exit the function
			return ya.emit("cd", { directory_item.url })
		end
	end
end)

-- Function to handle the parent arrow command
---@type CommandFunction
local function handle_parent_arrow(args, config)
	--

	-- If smooth scrolling is not wanted,
	-- call the function to execute the parent arrow command
	if not config.smooth_scrolling then execute_parent_arrow(args) end

	-- Otherwise, smooth scrolling is wanted,
	-- so get the number of steps from the arguments given
	local steps = table.remove(args, 1) or 1

	-- Call the function to smoothly scroll the parent arrow command
	smoothly_scroll(
		steps,
		config.scroll_delay,
		function(step) execute_parent_arrow(merge_tables({ step }, args)) end
	)
end

-- Function to check if an archive supports header encryption
---@param archive_path string The path to the archive
---@param wanted boolean Whether header encryption is wanted
---@return boolean supports_header_encryption Header encryption supported or not
local function archive_supports_header_encryption(archive_path, wanted)
	--

	-- If header encryption isn't wanted, immediately return false
	if not wanted then return false end

	-- Otherwise, get the extension of the archive
	local archive_extension = Url(archive_path).ext

	-- If the extension doesn't support header encryption
	local supports_header_encryption =
		ARCHIVE_FILE_EXTENSIONS_WITH_HEADER_ENCRYPTION[archive_extension]

	-- If the archive extension does not support header encryption,
	-- show a warning
	if not supports_header_encryption then
		show_warning(table.concat({
			string.format(
				"'.%s' does not support header encryption,",
				archive_extension
			),
			"continuing archival process without header encryption.",
		}, " "))
	end

	-- Return if the archive supports header encryption
	return supports_header_encryption
end

-- Function to remove files and directories
---@param item_paths string[] The paths to the items to remove
---@return nil
local function remove_items(item_paths)
	--

	-- Iterate over the item paths
	for _, item_path in ipairs(item_paths) do
		--

		-- Get the url of the item
		local item_url = Url(item_path)

		-- Get the cha of the item
		local item_cha = fs.cha(item_url, false)

		-- If the item is a directory
		if item_cha and item_cha.is_dir then
			--

			-- Remove everything
			fs.remove("dir_all", item_url)

		-- Otherwise, remove the item
		else
			fs.remove("file", item_url)
		end
	end
end

-- Function to handle the archive command
---@type CommandFunction
local function handle_archive(args, config)
	--

	-- Get the item group
	local item_group = get_item_group()

	-- If there is no item group, exit the function
	if not item_group then return end

	-- Initialise the paths to the items to add to the archive
	local item_paths = nil

	-- If the item group is the selected items
	if item_group == ItemGroup.Selected then
		item_paths = get_paths_of_selected_items()

	-- Otherwise, the item group is the hovered item
	else
		--

		-- Get the hovered item
		local hovered_item_path = get_path_of_hovered_item()

		-- If the hovered item is nil somehow, then exit the function
		if hovered_item_path == nil then return end

		-- Otherwise, set the item paths to the hovered item
		item_paths = { hovered_item_path }
	end

	-- If the item paths is nil, exit the function
	if not item_paths then return end

	-- Get the user's archive input options
	local archive_input_options = get_user_input_or_confirm_options(
		ConfigurableComponents.Plugin.Archive,
		{ prompts = "Archive name:" },
		true
	)

	-- Get the user's input
	---@cast archive_input_options YaziInputOptions
	local user_input, event = ya.input(archive_input_options)

	-- If the user did not confirm the input,
	-- exit the function
	if event ~= 1 then return end

	-- Get the archive path
	local archive_path = user_input or ""

	-- If the archive path is empty
	if #string_trim(archive_path) < 1 then
		--

		-- If the item group is not the hovered item,
		-- exit the function
		if item_group ~= ItemGroup.Hovered then return end

		-- Otherwise, get the path of the hovered item
		local hovered_item_path = table.unpack(item_paths)

		-- Set the archive name to the hovered item path
		-- plus the zip extension
		archive_path = hovered_item_path .. ".zip"
	end

	-- If the archive path doesn't have a file extension,
	-- add the ".zip" file extension
	if not Url(archive_path).ext then archive_path = archive_path .. ".zip" end

	-- Get the full url of the archive path
	local archive_url = Url(get_current_directory()):join(archive_path)

	-- If the archive already exists and the force flag isn't passed
	if fs.cha(archive_url, false) and not table_pop(args, "force", false) then
		--

		-- Get whether the user wants to overwrite the existing file
		local should_overwrite = show_overwrite_prompt(archive_url)

		-- If the user doesn't want to overwrite the file, exit the function
		if not should_overwrite then return end
	end

	-- Get the archiver
	local archiver, get_archiver_results =
		get_archiver(archive_path, Commands.Archive, config)

	-- If the archiver can't be instantiated,
	-- show the error and exit the function
	if not archiver then return throw_archiver_error(get_archiver_results) end

	-- Initialise the password
	local password = nil

	-- If the user wants to encrypt the archive
	if config.encrypt_archives or table_pop(args, "encrypt", false) then
		--

		-- Function to get the user's archive password options
		---@type GetPasswordOptions
		local function get_user_archive_password_options(is_confirm_password)
			--

			-- Get the user's archive password options
			local archive_password_options = get_user_input_or_confirm_options(
				ConfigurableComponents.Plugin.ArchivePassword,
				{
					prompts = {
						"Archive password:",
						"Confirm archive password:",
					},
				},
				true,
				false,
				is_confirm_password and 2 or 1
			)

			-- Return the user's archive password options
			---@cast archive_password_options YaziInputOptions
			return archive_password_options
		end

		-- Get the user's password
		password = get_password(get_user_archive_password_options, true)
	end

	-- Get whether to encrypt the headers or not
	local encrypt_headers = archive_supports_header_encryption(
		archive_path,
		password
			and (
				config.encrypt_archive_headers
				or table_pop(args, "encrypt_headers", false)
			)
	)

	-- Call the function to add items to an archive
	local archiver_result =
		archiver:archive(item_paths, password, encrypt_headers)

	-- If the archiver is not successful,
	-- show the error and exit the function
	if not archiver_result.successful then
		return throw_archiver_error(archiver_result)
	end

	-- If the user wants to remove archived files, remove them
	if config.remove_archived_files or table_pop(args, "remove", false) then
		remove_items(item_paths)
	end

	-- If the user wants to reveal the created archive
	if config.reveal_created_archive or table_pop(args, "reveal", false) then
		--

		-- Wait for a tiny bit for the archive to be created
		ya.sleep(10e-2)

		-- Reveal the archive
		ya.emit("reveal", { archive_path })
	end
end

-- Function to handle the emit command
---@type CommandFunction
local function handle_emit(args)
	--

	-- Get the command to emit given by the user
	local given_command = table.remove(args, 1)

	-- Get whether the user wants a plugin command
	local is_plugin_command = args.plugin

	-- Get whether the user wants an augmented command
	local is_augmented_command = args.augmented

	-- Initialise the emit title index
	local emit_title_index = nil

	-- Initialise the command function
	---@type fun(command: string, arguments: Arguments): nil
	local function command_function(_, _) end

	-- If the user wants an augmented command
	if is_augmented_command then
		--

		-- Set the emit title index to 3
		emit_title_index = 3

		-- Set the command function to emit an augmented command
		function command_function(command, arguments)
			emit_augmented_command(command, arguments)
		end

	-- Otherwise, if the user wants a plugin command
	elseif is_plugin_command then
		--

		-- Set the emit title index to 2
		emit_title_index = 2

		-- Set the command function to emit a plugin command
		function command_function(command, arguments)
			ya.emit(
				"plugin",
				{ command, convert_arguments_to_string(arguments) }
			)
		end

	-- Otherwise, the user wants a regular Yazi command
	else
		--

		-- Set the emit title index to 1
		emit_title_index = 1

		-- Set the command function to emit a Yazi command
		function command_function(command, arguments)
			ya.emit(command, arguments)
		end
	end

	-- If the command isn't given
	if not given_command then
		--

		-- Get the user's options for the emit input
		local emit_input_options = get_user_input_or_confirm_options(
			ConfigurableComponents.Plugin.Emit,
			{
				prompts = {
					"Yazi command:",
					"Plugin command:",
					"Augmented command:",
				},
			},
			true,
			false,
			emit_title_index
		)

		-- If the emit input options is nil, exit the function
		if not emit_input_options then return end

		-- Prompt the user for the command
		---@cast emit_input_options YaziInputOptions
		given_command = ya.input(emit_input_options) or ""

		-- If the given command is empty, then exit the function
		if #string_trim(given_command) < 1 then return end

		-- Emit the command to call the plugin's emit function
		-- with the user's command
		return emit_augmented_command(
			"emit",

			-- The arguments that are being propagated
			-- needs to come before the command,
			-- otherwise, if the command contains a --,
			-- then the wrong command will be emitted by the plugin
			string.format(
				"%s %s",
				convert_arguments_to_string(args),
				given_command
			)
		)
	end

	-- Remove the plugin and augmented flag from the arguments
	table_pop(args, "plugin")
	table_pop(args, "augmented")

	-- Call the command function
	command_function(given_command, args)
end

-- Function to handle the editor command
---@type CommandFunction
local function handle_editor(args, config)
	--

	-- Get the editor environment variable
	local editor = os.getenv("EDITOR")

	-- If the editor not set, exit the function
	if not editor then return end

	-- Initialise the shell command
	local shell_command = string.format(editor .. " $@")

	-- Get the cha object of the hovered file
	local hovered_item_cha = fs.cha(
		Url(get_path_of_hovered_item() or ""),
		false
	) or {}

	-- If the user ID of the file is root,
	-- and sudo edit is supported,
	-- set the shell command to "sudo -e"
	if config.sudo_edit_supported and hovered_item_cha.uid == 0 then
		shell_command = "sudo -e $@"
	end

	-- Call the handle shell function
	-- with the shell command to open the editor
	handle_shell(
		merge_tables({
			shell_command,
			block = true,
			exit_if_dir = true,
		}, args),
		config
	)
end

-- Function to handle the pager command
---@type CommandFunction
local function handle_pager(args, config)
	--

	-- Get the pager environment variable
	local pager = os.getenv("PAGER")

	-- If the pager is not set, exit the function
	if not pager then return end

	-- Call the handle shell function
	-- with the pager command
	handle_shell(
		merge_tables({
			pager .. " $@",
			block = true,
			exit_if_dir = true,
		}, args),
		config
	)
end

-- Function to run the commands given
---@param command string The command passed to the plugin
---@param args Arguments The arguments passed to the plugin
---@param config Configuration The configuration object
---@return nil
local function run_command_func(command, args, config)
	--

	-- The command table
	---@type CommandTable
	local command_table = {
		[Commands.Open] = handle_open,
		[Commands.Extract] = handle_extract,
		[Commands.Enter] = handle_enter,
		[Commands.Leave] = handle_leave,
		[Commands.Rename] = function(_) handle_yazi_command("rename", args) end,
		[Commands.Remove] = function(_) handle_yazi_command("remove", args) end,
		[Commands.Copy] = function(_) handle_yazi_command("copy", args) end,
		[Commands.Create] = handle_create,
		[Commands.Shell] = handle_shell,
		[Commands.Paste] = handle_paste,
		[Commands.TabCreate] = handle_tab_create,
		[Commands.TabSwitch] = handle_tab_switch,
		[Commands.Quit] = handle_quit,
		[Commands.Arrow] = handle_arrow,
		[Commands.ParentArrow] = handle_parent_arrow,
		[Commands.Archive] = handle_archive,
		[Commands.Emit] = handle_emit,
		[Commands.Editor] = handle_editor,
		[Commands.Pager] = handle_pager,
	}

	-- Get the function for the command
	---@type CommandFunction|nil
	local command_func = command_table[command]

	-- If the function isn't found, notify the user and exit the function
	if not command_func then
		return show_error("Unknown command: " .. command)
	end

	-- Otherwise, call the function for the command
	command_func(args, config)
end

-- The setup function to setup the plugin
---@param opts UserConfiguration|nil The options given to the plugin
---@return nil
function M:setup(opts)
	--

	-- Initialise the plugin
	initialise_plugin(opts)
end

-- Function to be called to use the plugin
---@param job { args: Arguments } The job object given by Yazi
---@return nil
function M:entry(job)
	--

	-- Get the arguments to the plugin
	---@type Arguments
	local args = parse_number_arguments(job.args)

	-- Get the command passed to the plugin
	local command = table.remove(args, 1)

	-- If the command isn't given, exit the function
	if not command then return end

	-- Get the configuration object
	local config = get_config()

	-- If the configuration hasn't been initialised yet,
	-- then initialise the plugin with the default configuration,
	-- as it hasn't been initialised either
	if not config then config = initialise_plugin() end

	-- Call the function to handle the commands
	run_command_func(command, args, config)
end

-- Return the module table
return M
