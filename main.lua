-- The module storing and handling all the configuration for the plugin

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
---@field protected_directories string[] Directories that are safe from deletion

-- The full configuration for the plugin
---@class (exact) Configuration: UserConfiguration
---@field sudo_edit_supported boolean Whether sudo edit is supported

-- The type for the state
---@class (exact) State
---@field config Configuration The configuration object

-- Import the constants needed
local constants = require(".constants")
local INPUT_AND_CONFIRM_OPTIONS = constants.INPUT_AND_CONFIRM_OPTIONS
local ItemGroup = constants.ItemGroup
local ConfigurableComponents = constants.ConfigurableComponents

-- Import the utilities module
local utils = require(".utils")

-- The module table
local M = {}

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
	protected_directories = {},
}

-- Function to merge the given configuration table with the default one
---@param config UserConfiguration? The configuration table to merge
---@return UserConfiguration merged_config The merged configuration table
local function merge_configuration(config)

	-- If the configuration isn't given, then use the default one
	if config == nil then return DEFAULT_CONFIG end

	-- Initialise the list of invalid configuration options
	local invalid_configuration_options = {}

	-- Initialise the merged configuration
	local merged_config = {}

	-- Iterate over the default configuration table
	for key, value in pairs(DEFAULT_CONFIG) do

		-- Add the default configuration to the merged configuration
		merged_config[key] = value
	end

	-- Iterate over the given configuration table
	for key, value in pairs(config) do

		-- If the key is not in the merged configuration
		if merged_config[key] == nil then

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
	utils.show_warning(
		"Invalid configuration options: "
			.. table.concat(invalid_configuration_options, ", ")
	)

	-- Return the merged configuration
	return merged_config
end

-- Function to get whether sudo edit is supported
---@return boolean sudo_edit_supported Whether sudo edit is supported
local function get_sudo_edit_supported()

	-- If the platform is Windows, return false immediately
	-- as Windows does not have sudo
	if ya.target_family() == "windows" then return false end

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

-- Function to get the configuration from an async function
---@type fun(): Configuration The configuration object
M.get_config = ya.sync(function(state) return state.config end)

-- Function to initialise the configuration
---@type fun(
---	user_config: UserConfiguration?,    -- The configuration object
---): Configuration The initialised configuration object
local initialise_config = ya.sync(function(state, user_config)

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

-- Function to get the theme from an async function
---@type fun(): th The theme object
M.get_theme = ya.sync(function(state) return state.theme end)

-- Function to copy the component configuration
---@param component_type ConfigurableComponents The type of the component
---@return table component_configuration The component configuration
local copy_component_configuration = function(component_type)

	-- Initialise the configuration
	local config = {}

	-- Get whether the given component type is the plugin component type
	local is_plugin = component_type == ConfigurableComponents.Plugin

	-- If there is nothing in the plugin configuration, return the empty config
	---@diagnostic disable-next-line: undefined-field
	if is_plugin and th.augment_command == nil then return config end

	-- Iterate over the components
	for _, component in pairs(component_type) do

		-- Iterate over all the options
		for _, option in ipairs(INPUT_AND_CONFIRM_OPTIONS) do

			-- Get the component option
			local component_option =
				utils.get_component_option_string(component, option)

			-- Get the value for the option
			---@diagnostic disable-next-line: undefined-field
			local value = is_plugin and th.augment_command[component_option]
				or th[component_option]

			-- If the value isn't nil, add it to the theme configuration
			if value ~= nil then config[component_option] = value end
		end
	end

	-- Return the component configuration
	return config
end

-- Function to initialise the theme configuration
---@type fun(): th
local initialise_theme = ya.sync(function(state)

	-- Initialise the theme configuration table
	local theme_config = {}

	-- Copy the configuration for the built-in components
	theme_config = copy_component_configuration(ConfigurableComponents.BuiltIn)

	-- Copy the configuration for the plugin components
	theme_config.augment_command =
		copy_component_configuration(ConfigurableComponents.Plugin)

	-- Set the theme configuration to the state
	state.theme = theme_config

	-- Return the theme object
	return state.theme
end)

-- Function to subscribe to the augmented-extract event
---@type fun(): nil
local subscribe_to_augmented_extract_event = ya.sync(function()
	return ps.sub_remote("augmented-extract", function(args)

		-- If the arguments given isn't a table,
		-- exit the function
		if type(args) ~= "table" then return end

		-- Iterate over the arguments
		for _, arg in ipairs(args) do

			-- Emit the command to call the plugin's extract function
			-- with the given arguments and flags
			utils.emit_augmented_command("extract", {
				archive_path = ya.quote(arg),
			})
		end
	end)
end)

-- Function to initialise the plugin
---@param opts UserConfiguration? The options given to the plugin
---@return Configuration config The initialised configuration object
---@return th theme The saved theme object
function M:setup(opts)

	-- Subscribe to the augmented extract event
	subscribe_to_augmented_extract_event()

	-- Initialise the configuration object
	local config = initialise_config(opts)

	-- Add the theme configuration to the config
	local theme = initialise_theme()

	-- Return the configuration object
	return config, theme
end

-- Function to parse the arguments and initialise the plugin
---@param job { args: YaziArgs } The job object given by Yazi
---@return ParsedArgs args The command being called
---@return Configuration config The configuration object
function M.parse_args_and_init(job)

	-- Get the arguments to the plugin
	local args = utils.parse_number_arguments(job.args)

	-- Get the configuration object
	local config = M.get_config()

	-- If the configuration hasn't been initialised yet,
	-- then initialise the plugin with the default configuration,
	-- as it hasn't been initialised either
	if not config then config = M:setup() end

	-- Return the arguments and the configuration
	return args, config
end

-- Function to check if the current directory
-- is in the list of protected directories
---@type fun(): boolean
M.current_directory_protected = ya.sync(function(state)

	-- Get the current directory
	local current_directory_path = tostring(cx.active.current.cwd.path)

	-- Iterate over all the directories in the list of protected directories
	for _, protected_directory in ipairs(state.config.protected_directories) do

		-- Match the current directory on the protected directory
		local match = current_directory_path:match(
			utils.escape_match_pattern(protected_directory)
		)

		-- If there is a match, immediately return true
		if match then return true end
	end

	-- Return false if there is no match
	return false
end)

-- Return the module table
return M
