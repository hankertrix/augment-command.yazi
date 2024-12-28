-- Plugin to make some Yazi commands smarter
-- Written in Lua 5.4

-- Type aliases

-- The type for the arguments
---@alias Arguments table<string|number, string|number|boolean>

-- The type for the function to handle a command
--
-- Description of the function parameters:
--     args: The arguments to pass to the command
--     config: The configuration object
--     command_table: The command table containing all the command functions
---@alias CommandFunction fun(
---    args: Arguments,
---    config: Configuration,
---    command_table: CommandTable): nil

-- The type of the command table
---@alias CommandTable table<SupportedCommands, CommandFunction>

-- The type for the extractor command
---@alias ExtractorFunction fun(
---    password: string|nil,
---    configuration: Configuration): CommandOutput|nil, integer

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
---@field open_file_after_creation boolean Whether to open after creation
---@field enter_directory_after_creation boolean Whether to enter after creation
---@field use_default_create_behaviour boolean Use Yazi's create behaviour?
---@field enter_archives boolean Whether to enter archives
---@field extract_retries number How many times to retry extracting
---@field recursively_extract_archives boolean Extract inner archives or not
---@field must_have_hovered_item boolean Whether to stop when no item is hovered
---@field skip_single_subdirectory_on_enter boolean Skip single subdir on enter
---@field skip_single_subdirectory_on_leave boolean Skip single subdir on leave
---@field wraparound_file_navigation boolean Have wraparound navigation or not

-- The additional data passed to the function to initialise the configuration
---@class (exact) AdditionalData
---@field extractor_command string The extractor shell command, like 7z

-- The full configuration for the plugin
---@class (exact) Configuration: UserConfiguration, AdditionalData

-- The type for the state
---@class (exact) State
---@field config Configuration

-- The type for the extraction results
---@class (exact) ExtractionResult
---@field archive_path string
---@field successful boolean
---@field extracted_items_path string|nil
---@field error_message string|nil

-- The enum for which group of items to operate on
---@enum ItemGroup
local ItemGroup = {
    Hovered = "hovered",
    Selected = "selected",
    None = "none",
    Prompt = "prompt",
}

-- The enum for the supported commands
---@enum SupportedCommands
local Commands = {
    Open = "open",
    Enter = "enter",
    Leave = "leave",
    Rename = "rename",
    Remove = "remove",
    Create = "create",
    Shell = "shell",
    Paste = "paste",
    TabCreate = "tab_create",
    TabSwitch = "tab_switch",
    Arrow = "arrow",
    ParentArrow = "parent_arrow",
    Editor = "editor",
    Pager = "pager",
}

-- The extract behaviour flags
-- https://documentation.help/7-Zip/overwrite.htm
---@enum ExtractBehaviour
local ExtractBehaviour = {
    Overwrite = "-aoa",
    Skip = "-aos",
    Rename = "-aou",
    RenameExisting = "-aot",
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
    open_file_after_creation = false,
    enter_directory_after_creation = false,
    use_default_create_behaviour = false,
    enter_archives = true,
    extract_retries = 3,
    recursively_extract_archives = true,
    must_have_hovered_item = true,
    skip_single_subdirectory_on_enter = true,
    skip_single_subdirectory_on_leave = true,
    wraparound_file_navigation = false,
}

-- The default input options for this plugin
local DEFAULT_INPUT_OPTIONS = {
    position = { "top-center", x = 0, y = 2, w = 50, h = 3 },
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
---@enum InputOptionsTable
local INPUT_OPTIONS_TABLE = {
    [ItemGroup.Hovered] = "(H/s)",
    [ItemGroup.Selected] = "(h/S)",
    [ItemGroup.None] = "(h/s)",
}

-- The table of archive mime types
---@type table<string, boolean>
local ARCHIVE_MIME_TYPES = {
    ["application/zip"] = true,
    ["application/gzip"] = true,
    ["application/tar"] = true,
    ["application/bzip"] = true,
    ["application/bzip2"] = true,
    ["application/7z-compressed"] = true,
    ["application/rar"] = true,
    ["application/xz"] = true,

    -- Bug in file(1) that classifies
    -- some zip archives as a data stream,
    -- hopefully this can be removed in the future.
    --
    -- Link to bug report:
    -- https://bugs.astron.com/view.php?id=571
    ["application/octet-stream"] = true,
}

-- The list of archive file extensions
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
    tar = true,
    tbz = true,
    tbz2 = true,
    tgz = true,
    txz = true,
    xz = true,
    zip = true,
}

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

-- The pattern to get the information from an archive item
---@type string
local archive_item_info_pattern = "%s+([%.%a]+)%s+(%d+)%s+(%d+)%s+(.+)$"

-- The pattern to get the file extension
---@type string
local file_extension_pattern = "%.([%a]+)$"

-- The pattern to get the shell variables in a command
---@type string
local shell_variable_pattern = "[%$%%][%*@0]"

-- The pattern to match the bat command with the pager option passed
---@type string
local bat_command_with_pager_pattern = "%f[%a]bat%f[%A].*%-%-pager%s+"

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
---@param ... table<any, any>[] The tables to merge
---@return table<any, any> merged_table The merged table
local function merge_tables(...)
    --

    -- Initialise a new table
    local new_table = {}

    -- Initialise the index variable
    local index = 1

    -- Iterates over the tables given
    for _, table in ipairs({ ... }) do
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
                new_table[index] = value

                -- Increment the index
                index = index + 1

            -- Otherwise, the key isn't a number
            else
                --

                -- Set the key in the new table to the value given
                new_table[key] = value
            end
        end
    end

    -- Return the new table
    return new_table
end

-- Function to split a string into a list
---@param given_string string The string to split
---@param separator string The character to split the string by
---@return string[] splitted_strings The list of strings split by the character
local function string_split(given_string, separator)
    --

    -- If the separator isn't given, set it to the whitespace character
    if separator == nil then separator = "%s" end

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

-- Function to show a warning
---@param warning_message string The warning message
---@return nil
local function show_warning(warning_message)
    return ya.notify(merge_tables(DEFAULT_NOTIFICATION_OPTIONS, {
        content = warning_message,
        level = "warn",
    }))
end

-- Function to show an error
---@param error_message string The error message
---@return nil
local function show_error(error_message)
    return ya.notify(merge_tables(DEFAULT_NOTIFICATION_OPTIONS, {
        content = error_message,
        level = "error",
    }))
end

-- Function to get the user's input
---@param prompt string The prompt to show to the user
---@return string|nil user_input The user's input
---@return InputEvent event The event for the input function
local function get_user_input(prompt)
    return ya.input(merge_tables(DEFAULT_INPUT_OPTIONS, {
        title = prompt,
    }))
end

-- Function to get the user's confirmation
-- TODO: Remove the `ya.input` version once `ya.confirm` is stable
---@param prompt string The prompt to show to the user
---@param title string|ui.Line The title of the confirmation prompt
---@param content string|ui.Text The content of the confirmation prompt
---@return boolean confirmation Whether the user has confirmed or not
local function get_user_confirmation(prompt, title, content)
    --

    -- If the ya.confirm API exists, use it
    if ya.confirm then
        --

        -- Get the user's confirmation
        local confirmation = ya.confirm(merge_tables(DEFAULT_CONFIRM_OPTIONS, {
            title = title,
            content = content,
        }))

        -- Return the result of the confirmation
        return confirmation
    end

    -- TODO: Remove everything after this when `ya.confirm` is stable

    -- Get the user's input
    local user_input, event = get_user_input(prompt)

    -- If the user has not confirmed the input,
    -- or the user input is nil,
    -- then return false
    if not user_input or event ~= 1 then return false end

    -- Lowercase the user's input
    user_input = user_input:lower()

    -- If the user input starts with a "y", then return true
    if user_input:find("^y") then return true end

    -- Otherwise, return false
    return false
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

-- Function to initialise the configuration
---@param state State The state object
---@param user_config Configuration|nil The configuration object
---@param additional_data AdditionalData The additional data
---@return Configuration config The initialised configuration object
local initialise_config = ya.sync(function(state, user_config, additional_data)
    --

    -- Merge the default configuration with the user given one,
    -- as well as the additional data given,
    -- and set it to the state.
    state.config =
        merge_tables(merge_configuration(user_config), additional_data)

    -- Return the configuration object for async functions
    return state.config
end)

-- Function to try if a shell command exists
---@param shell_command string The shell command to check
---@return boolean shell_command_exists Whether the shell command exists
local function shell_command_exists(shell_command)
    --

    -- Initialise the null output
    local null_output = "/dev/null"

    -- If the OS is Windows
    if ya.target_family() == "windows" then
        --

        -- Set the null output to the NUL device
        null_output = "NUL"
    end

    -- Get whether the shell command is successfully executed
    --
    -- "1> /dev/null" redirects the standard output
    -- of the shell command to /dev/null, which accepts
    -- and discards all input and produces no output.
    --
    -- "2>&1" redirects the standard error to the file
    -- descriptor of the standard output, which is the
    -- /dev/null file or the NUL device on Windows,
    -- which accepts and discards
    -- all input and produces no output.
    --
    -- The full thing, "1> /dev/null 2>&1" just makes sure
    -- the shell command doesn't produce any output when executed.
    --
    -- The equivalent command on Windows is "1> NUL 2>&1".
    --
    -- https://stackoverflow.com/questions/10508843/what-is-dev-null-21
    -- https://stackoverflow.com/questions/818255/what-does-21-mean
    -- https://www.gnu.org/software/bash/manual/html_node/Redirections.html
    local successfully_executed =
        os.execute(shell_command .. " 1> " .. null_output .. " 2>&1")

    -- If the command was not successfully executed,
    -- set the successfully executed variable to false
    if not successfully_executed then successfully_executed = false end

    -- Return the result of the os.execute command
    return successfully_executed
end

-- Function to initialise the plugin
---@param opts Configuration|nil The options given to the plugin
---@return Configuration config The initialised configuration object
local function initialise_plugin(opts)
    --

    -- Initialise the extractor command
    local extractor_command = "7z"

    -- If the 7zz command exists
    if shell_command_exists("7zz") then
        --

        -- Set the 7z command to the 7zz command
        extractor_command = "7zz"
    end

    -- Initialise the configuration object
    local config = initialise_config(opts, {
        extractor_command = extractor_command,
    }, opts)

    -- Return the configuration object
    return config
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

    -- Get if the mime type is an archive
    local is_archive =
        table_get(ARCHIVE_MIME_TYPES, standardised_mime_type, false)

    -- Return if the mime type is an archive
    return is_archive
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

-- Function to get the configuration from an async function
---@param state State The state object
---@return Configuration config The configuration object
local get_config = ya.sync(function(state)
    --

    -- Returns the configuration object
    return state.config
end)

-- Function to get the current working directory
---@type fun(_): Url Returns the current working directory as a url
local get_current_directory_url = ya.sync(
    function(_) return cx.active.current.cwd end
)

-- Function to get the path of the hovered item
---@param _ any
---@param quote boolean Whether to shell escape the characters in the path
---@return string|nil hovered_item_path The path of the hovered item
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
---@param _ any
---@return boolean is_directory Whether the hovered item is a directory
local hovered_item_is_dir = ya.sync(function(_)
    --

    -- Get the hovered item
    local hovered_item = cx.active.current.hovered

    -- Return if the hovered item exists and is a directory
    return hovered_item and hovered_item.cha.is_dir
end)

-- Function to get if the hovered item is an archive
---@param _ any
---@return boolean is_archive Whether the hovered item is an archive
local hovered_item_is_archive = ya.sync(function(_)
    --

    -- Get the hovered item
    local hovered_item = cx.active.current.hovered

    -- Return if the hovered item exists and is an archive
    return hovered_item and is_archive_mime_type(hovered_item:mime())
end)

-- Function to get the paths of the selected items
---@param _ any
---@param quote boolean Whether to shell escape the characters in the path
---@return string[]|nil paths The list of paths of the selected items
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

-- Function to get the tab preferences
---@param _ State
---@return tab.Preference
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

-- Function to get if Yazi is loading
---@type fun(_): boolean Returns whether Yazi is loading
local yazi_is_loading = ya.sync(
    function(_) return cx.active.current.stage.is_loading end
)

-- Function to wait until Yazi is loaded
---@return nil
local function wait_until_yazi_is_loaded()
    while yazi_is_loading() do
    end
end

-- Function to choose which group of items to operate on.
-- It returns ItemGroup.Hovered for the hovered item,
-- ItemGroup.Selected for the selected items,
-- and ItemGroup.Prompt to tell the calling function
-- to prompt the user.
---@param state State The state object
---@return ItemGroup|nil item_group The desired item group
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
    local default_item_group = config.default_item_group_for_prompt

    -- Get the input options
    local input_options = INPUT_OPTIONS_TABLE[default_item_group]

    -- If the default item group is None, then set it to nil
    if default_item_group == ItemGroup.None then default_item_group = nil end

    -- Prompt the user for their input
    local user_input, event = get_user_input(
        "Operate on hovered or selected items? " .. input_options
    )

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
---@param directory_url Url The url to the directory
---@param get_hidden_items boolean Whether to get hidden items
---@param directories_only boolean|nil Whether to only get directories
---@return Url[] directory_items The list of urls to the directory items
local function get_directory_items(
    directory_url,
    get_hidden_items,
    directories_only
)
    --

    -- Initialise the list of directory items
    local directory_items = {}

    -- Read the contents of the directory
    local directory_contents, _ = fs.read_dir(directory_url, {})

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

        -- Otherwise, add the item url to the list of directory items
        table.insert(directory_items, item.url)

        -- The continue label to continue the loop
        ::continue::
    end

    -- Return the list of directory items
    return directory_items
end

-- Function to skip child directories with only one directory
---@param initial_directory_url Url The url of the initial directory
---@return nil
local function skip_single_child_directories(initial_directory_url)
    --

    -- Initialise the directory variable to the initial directory given
    local directory = initial_directory_url

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
        ---@type Url
        local directory_item_url = table.unpack(directory_items)

        -- Get the cha object of the directory item
        -- and don't follow symbolic links
        local directory_item_cha = fs.cha(directory_item_url, false)

        -- If the cha object of the directory item is nil
        -- then break the loop
        if not directory_item_cha then break end

        -- If the directory item is not a directory,
        -- break the loop
        if not directory_item_cha.is_dir then break end

        -- Otherwise, set the directory to the inner directory
        directory = directory_item_url
    end

    -- Emit the change directory command to change to the directory variable
    ya.manager_emit("cd", { directory })
end

-- Function to check if an archive is password protected
---@param command_error_string string The error string from the extractor
---@return boolean is_encrypted Whether the archive is password protected
local function archive_is_encrypted(command_error_string)
    --

    -- Return true if the string contains the word "wrong password",
    -- and false otherwise
    if command_error_string:lower():find("wrong password", 1, true) then
        return true
    else
        return false
    end
end

-- Function to handle retrying the extractor command
--
-- The initial password is the password given to the extractor command
-- and the test encryption is to test the archive password without
-- actually executing the given extractor command.
---@param extractor_function ExtractorFunction Function to run the extractor
---@param config Configuration The configuration object
---@param initial_password string|nil The initial password to try
---@param archive_path string|nil The path to the archive file
---@return boolean successful Whether the extraction was successful
---@return string|nil error_message An error message for unsuccessful extracts
---@return string|nil stdout The standard output of the extractor command
---@return string|nil correct_password The correct password to the archive
local function retry_extractor(
    extractor_function,
    config,
    initial_password,
    archive_path
)
    --

    -- Initialise the password to the initial password
    -- or an empty string if it's not given
    local password = initial_password or ""

    -- Initialise the archive path to the given archive path
    -- or an empty string if it's not given
    archive_path = archive_path or ""

    -- Initialise the error message from the archive extractor
    local error_message = ""

    -- Initialise the number of tries
    -- to the number of retries plus 1
    local total_number_of_tries = config.extract_retries + 1

    -- Initialise the initial password prompt
    local initial_password_prompt =
        "Archive is encrypted, please enter the password:"

    -- Initialise the wrong password prompt
    local wrong_password_prompt =
        "Wrong password, please enter another password:"

    -- Iterate over the number of times to try the extraction
    for tries = 0, total_number_of_tries do
        --

        -- Execute the extractor command
        local output, err = extractor_function(password, config)

        -- If there is no output
        -- then return false, the error as a string,
        -- nil for the output, and nil for the password
        if not output then return false, tostring(err), nil, nil end

        -- If the output was 0, which means the extractor command was successful
        if output.status.code == 0 then
            --

            -- Initialise the correct password to nil
            local correct_password = nil

            -- If the password is not empty,
            -- then set the correct password to the password
            if string.len(string_trim(password)) > 0 then
                correct_password = password
            end

            -- Return true, nil for the error message,
            -- the standard output of the output,
            -- and the correct password
            return true, nil, output.stdout, correct_password
        end

        -- Set the error message to the standard error
        -- from the archive extractor
        error_message = output.stderr

        -- If the command failed for some other reason other
        -- than the archive being encrypted, then return false,
        -- the error message, the standard output of the output,
        -- and nil for the password to the archive
        if
            not (
                output.status.code == 2 and archive_is_encrypted(output.stderr)
            )
        then
            return false, error_message, output.stdout, nil
        end

        -- If it is the last try, then return false
        -- and the error message, the standard output of the output,
        -- and nil for the password to the archive.
        if tries == total_number_of_tries then
            return false, error_message, output.stdout, nil
        end

        -- Ask the user for the password
        local user_input, event = get_user_input(
            tries == 0 and initial_password_prompt or wrong_password_prompt
        )

        -- If the user has confirmed the input,
        -- and the user input is not nil,
        -- set the password to the user's input
        if event == 1 and user_input ~= nil then
            password = user_input

        -- Otherwise, return false, the error message,
        -- the standard output of the output,
        -- and nil for the password to the archive
        -- as the user has cancelled the prompt,
        -- or an unknown error has occurred
        else
            return false, error_message, output.stdout, nil
        end
    end

    -- If all the tries have been exhausted,
    -- then return false, the error message
    -- and nil
    return false, error_message, nil, nil
end

-- The command to list the items in an archive
---@param archive_path string The path to the archive
---@param config Configuration The configuration object
---@param password string|nil The password to the archive
---@param remove_headers boolean|nil Whether to remove the headers
---@param show_details boolean|nil Whether to show the details
---@return CommandOutput|nil, integer
local function list_archive_items_command(
    archive_path,
    config,
    password,
    remove_headers,
    show_details
)
    --

    -- Initialise the password to an empty string if it's not given
    password = password or ""

    -- Initialise the remove headers flag to false if it's not given
    remove_headers = remove_headers or false

    -- Initialise the show details flag to false if it's not given
    show_details = show_details or false

    -- Initialise the arguments for the command
    local arguments = {

        -- List the items in the archive
        "l",

        -- Use UTF-8 encoding for console input and output
        "-sccUTF-8",

        -- Pass the password to the command
        "-p" .. password,
    }

    -- If the remove headers flag is passed
    if remove_headers then
        --

        -- Add the switch to remove the headers (undocumented switch)
        table.insert(arguments, "-ba")
    end

    -- If the show details flag is passed
    if show_details then
        --

        -- Add the switch to show the details
        table.insert(arguments, "-slt")
    end

    -- Add the archive path to the arguments
    table.insert(arguments, archive_path)

    -- Return the result of the command to list the items in the archive
    return Command(config.extractor_command)
        :args(arguments)
        :stdout(Command.PIPED)
        :stderr(Command.PIPED)
        :output()
end

-- Function to get if the archive
-- file has more than one file in it.
---@param archive_path string The path to the archive file
---@param config Configuration The configuration object
---@return table<string> files The list of files in the archive
---@return table<string> directories The list of directories in the archive
---@return string|nil error_message The error message for an incorrect password
---@return string|nil correct_password The correct password to the archive
local function get_archive_items(archive_path, config)
    --

    -- Function to list the items in the archive
    local function list_items_in_archive(password, configuration, _)
        return list_archive_items_command(
            archive_path,
            configuration,
            password,
            true
        )
    end

    -- Initialise the list of files in the archive
    ---@type string[]
    local files = {}

    -- Initialise the list of directories
    ---@type string[]
    local directories = {}

    -- Call the function to retry the extractor command
    -- with the list items in the archive function
    local successful, error_message, output, password =
        retry_extractor(list_items_in_archive, config)

    -- If the extractor command was not successful,
    -- or the output was nil,
    -- then return nil the error message,
    -- and nil as the correct password
    if not successful or not output then
        return files, directories, error_message, nil
    end

    -- Otherwise, split the output at the newline character
    local output_lines = string_split(output, "\n")

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
    return files, directories, error_message, password
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
---@return Url|nil url The url of the temporary directory
local function get_temporary_directory_url(path)
    --

    -- Get the parent directory of the file path
    ---@type Url
    local parent_directory = Url(path):parent()

    -- If the parent directory doesn't exist, then return nil
    if not parent_directory then return nil end

    -- Otherwise, create the temporary directory path
    local temporary_directory_url =
        fs.unique_name(parent_directory:join(get_temporary_name(path)))

    -- Return the temporary directory path
    return temporary_directory_url
end

-- The extract command to extract an archive
---@param archive_path string The path to the archive
---@param destination_directory_path string The destination folder
---@param config Configuration The configuration object
---@param password string|nil The password to the archive
---@param extract_files_only boolean|nil Extract the files only or not
---@param extract_behaviour ExtractBehaviour|nil The extraction behaviour
---@return CommandOutput|nil, integer
local function extract_command(
    archive_path,
    destination_directory_path,
    config,
    password,
    extract_files_only,
    extract_behaviour
)
    --

    -- Initialise the password to an empty string if it's not given
    password = password or ""

    -- Initialise the extract files only flag to false if it's not given
    extract_files_only = extract_files_only or false

    -- Initialise the extract behaviour to rename if it's not given
    extract_behaviour = extract_behaviour or ExtractBehaviour.Rename

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
        "-p" .. password,

        -- The archive file to extract
        archive_path,

        -- The destination directory path
        "-o" .. destination_directory_path,
    }

    -- Return the command to extract the archive
    return Command(config.extractor_command)
        :args(arguments)
        :stdout(Command.PIPED)
        :stderr(Command.PIPED)
        :output()
end

-- Function to get the mime type of a file
---@param file_path string The path to the file
---@return string mime_type The mime type of the file
local function get_mime_type(file_path)
    --

    -- Get the output of the file command
    local output, _ = Command("file")
        :args({

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

    -- Return the mime type
    return mime_type
end

-- Function to check if a file is an archive
---@param file_path string The path to the file
---@return boolean is_archive Whether the file is an archive
local function is_archive_file(file_path)
    --

    -- Initialise the is archive variable to false
    local is_archive = false

    -- Call the function to get the mime type of the file
    local mime_type = get_mime_type(file_path)

    -- Set the is archive variable
    is_archive = is_archive_mime_type(mime_type)

    -- Return the is archive variable
    return is_archive
end

-- Function to clean up the temporary directory
-- after extracting an archive.
---@param temporary_directory_url Url The url of the temporary directory
---@param removal_mode "dir" | "dir_all" | "dir_clean" The removal mode
---@param ... any Return values
---@return ... Returns the given return values
local function clean_up_temporary_directory(
    temporary_directory_url,
    removal_mode,
    ...
)
    --

    -- Remove the temporary directory
    fs.remove(removal_mode, temporary_directory_url)

    -- Return the given return values
    return ...
end

-- Function to move extracted items out of the temporary directory
---@param archive_url Url The url of the archive
---@param temporary_directory_url Url The url of the temporary directory
---@return boolean move_successful Whether the move was successful
---@return string|nil error_message An error message for unsuccessful extracts
---@return string|nil extracted_items_path The path of the extracted item
local function move_extracted_items_to_archive_parent_directory(
    archive_url,
    temporary_directory_url
)
    --

    -- Initialise whether or not the move is successful to false
    local move_successful = false

    -- Initialise the path of the extracted items
    local extracted_items_path = nil

    -- Get the extracted items in the directory
    -- containing the extracted items.
    -- There is a limit of 2 as there should only be
    -- a single item in the directory.
    local extracted_items = fs.read_dir(temporary_directory_url, { limit = 2 })

    -- If the extracted items doesn't exist,
    -- clean up the temporary directory and
    -- return that the move successful variable
    -- the error message, and the extracted item path
    if not extracted_items then
        return clean_up_temporary_directory(
            temporary_directory_url,
            "dir_all",
            move_successful,
            "Failed to read the temporary directory",
            extracted_items_path
        )
    end

    -- If there are no extracted items,
    -- clean up the temporary directory and
    -- return that the move successful variable
    -- the error message, and the extracted item path
    if #extracted_items == 0 then
        return clean_up_temporary_directory(
            temporary_directory_url,
            "dir",
            move_successful,
            "No files extracted from the archive",
            extracted_items_path
        )
    end

    -- Get the parent directory url of the archive
    local parent_directory_url = archive_url:parent()

    -- If the parent directory url is nil,
    -- then return the move successful variable,
    -- the error message, and the extracted item path
    if not parent_directory_url then
        return clean_up_temporary_directory(
            temporary_directory_url,
            "dir_all",
            move_successful,
            "Parent directory doesn't exist",
            extracted_items_path
        )
    end

    -- Get the file name of the archive without the extension
    local archive_file_name = archive_url:stem()

    -- If the archive file name is nil,
    -- then return the move successful variable,
    -- the error message, and the extracted item path
    if not archive_file_name then
        return clean_up_temporary_directory(
            temporary_directory_url,
            "dir_all",
            move_successful,
            "Archive's file name is empty",
            extracted_items_path
        )
    end

    -- Get the first extracted item
    local first_extracted_item = table.unpack(extracted_items)

    -- Get the url of the first extracted item
    local first_extracted_item_url = first_extracted_item.url

    -- Initialise the variable to
    -- store whether there is only
    -- a single file in the archive
    local only_one_item_in_archive = false

    -- Initialise the target directory url to move the extracted items to,
    -- which is the parent directory of the archive
    -- joined with the file name of the archive without the extension
    local target_url = parent_directory_url:join(archive_file_name)

    -- If there is only one item in the archive
    if #extracted_items == 1 then
        --

        -- Set the only one item in archive variable to true
        only_one_item_in_archive = true

        -- Get the name of the first extracted item
        local first_extracted_item_name = first_extracted_item_url:name()

        -- If the first extracted item name is nil,
        -- then clean up the temporary directory
        -- and exit the function
        if not first_extracted_item_name then
            return clean_up_temporary_directory(
                temporary_directory_url,
                "dir_all",
                move_successful,
                "Failed to get a name for the extracted item.",
                extracted_items_path
            )
        end

        -- Set the target url to the parent directory of the archive
        -- joined with the file name of the extracted item
        target_url = parent_directory_url:join(first_extracted_item_name)
    end

    -- Get a unique name for the target url
    local unique_target_url = fs.unique_name(target_url)

    -- If the unique target url is nil somehow,
    -- clean up the temporary directory and
    -- return the move successful variable,
    -- the error message and the extracted item path
    if not unique_target_url then
        return clean_up_temporary_directory(
            temporary_directory_url,
            "dir_all",
            move_successful,
            "Failed to get a unique name to move the extracted items to",
            extracted_items_path
        )
    end

    -- Otherwise, set the target url to the unique target url
    target_url = unique_target_url

    -- Set the extracted items path to the target path
    extracted_items_path = tostring(target_url)

    -- Initialise the error message to nil
    local error_message = nil

    -- If there is only one item in the archive
    if only_one_item_in_archive then
        --

        -- Move the item to the target path
        move_successful, error_message =
            os.rename(tostring(first_extracted_item_url), extracted_items_path)

    -- Otherwise
    else
        --

        -- Rename the temporary directory itself to the target path
        move_successful, error_message =
            os.rename(tostring(temporary_directory_url), extracted_items_path)
    end

    -- Clean up the temporary directory
    -- and return if the move was successful
    -- the error message and the extracted item path
    return clean_up_temporary_directory(
        temporary_directory_url,
        move_successful and "dir" or "dir_all",
        move_successful,
        error_message,
        extracted_items_path
    )
end

--- Function to extract an archive.
---@param archive_path string The path to the archive
---@param config Configuration The configuration object
---@param has_only_one_file boolean Whether the archive has only one file
---@param initial_password string|nil The initial password to try
---@return ExtractionResult extraction_result The result of the extraction
local function extract_archive(
    archive_path,
    config,
    has_only_one_file,
    initial_password
)
    --

    -- Initialise the successful variable to false
    local successful = false

    -- Initialise the error message to nil
    local error_message = nil

    -- Initialise the extracted items path to nil
    local extracted_items_path = nil

    -- Get the url of the temporary directory
    local temporary_directory_url = get_temporary_directory_url(archive_path)

    -- If the temporary directory url is nil,
    -- then return the successful variable, an error message
    -- saying a path for the temporary directory
    -- cannot be determined, and the extracted items path
    if not temporary_directory_url then
        return {
            archive_path = archive_path,
            successful = successful,
            extracted_items_path = extracted_items_path,
            error_message = "Failed to determine a path "
                .. "for the temporary directory",
        }
    end

    -- Get the url of the archive
    ---@type Url
    local archive_url = Url(archive_path)

    -- Get the name of the archive
    local archive_name = archive_url:stem()

    -- If the archive name is nil,
    -- then return the successful variable,
    -- an error message saying
    -- that the archive file name is somehow empty,
    -- and the extracted items path
    if not archive_name then
        return {
            archive_path = archive_path,
            successful = successful,
            extracted_items_path = extracted_items_path,
            error_message = "Archive file name is empty",
        }
    end

    -- Create the extractor command
    local function extractor_command(password, configuration)
        return extract_command(
            archive_path,
            tostring(temporary_directory_url),
            configuration,
            password,
            has_only_one_file,
            ExtractBehaviour.Overwrite
        )
    end

    -- Call the function to retry the extractor command
    successful, error_message, _, _ = retry_extractor(
        extractor_command,
        config,
        initial_password,
        archive_path
    )

    -- If the extraction was not successful,
    if not successful then
        --

        -- Clean up the temporary directory
        clean_up_temporary_directory(temporary_directory_url, "dir_all")

        -- Return the extraction results
        return {
            archive_path = archive_path,
            successful = successful,
            extracted_items_path = extracted_items_path,
            error_message = error_message,
        }
    end

    -- Otherwise, move the extracted items
    -- to the parent directory of the archive
    successful, error_message, extracted_items_path =
        move_extracted_items_to_archive_parent_directory(
            archive_url,
            temporary_directory_url
        )

    -- Create the extraction result
    ---@type ExtractionResult
    local extraction_result = {
        archive_path = archive_path,
        successful = successful,
        extracted_items_path = extracted_items_path,
        error_message = error_message,
    }

    -- Return the result of the extraction
    return extraction_result
end

-- Function to recursively extract archives
---@param archive_path string The path to the archive
---@param config Configuration The configuration object
---@return ExtractionResult[] extraction_results The list of extraction results
---@return string|nil extracted_items_path The path to the extracted items
local function recursively_extract_archives(archive_path, config)
    --

    -- Initialise the table of extraction results
    ---@type ExtractionResult[]
    local list_of_extraction_results = {}

    -- Get the list of archive files and directories,
    -- the error message and the password
    local archive_files, archive_directories, err, password =
        get_archive_items(archive_path, config)

    -- If there are no are no archive files and directories
    if #archive_files == 0 and #archive_directories == 0 then
        --

        -- Add that the archive is empty if there is no error message
        table.insert(list_of_extraction_results, {
            archive_path = archive_path,
            successful = false,
            error_message = err or "Archive is empty",
        })

        -- Return the list of extraction results
        return list_of_extraction_results
    end

    -- Get if the archive has only one file
    local archive_has_only_one_file = #archive_files == 1
        and #archive_directories == 0

    -- Extract the given archive
    local extraction_results = extract_archive(
        archive_path,
        config,
        archive_has_only_one_file,
        password
    )

    -- Add the extraction results to the list of extraction results
    table.insert(list_of_extraction_results, extraction_results)

    -- Get the extracted items path
    local extracted_items_path = extraction_results.extracted_items_path

    -- If the extraction of the archive isn't successful,
    -- or if the extracted items path is nil,
    -- or if the user does not want to extract archives recursively,
    -- return the list of extraction results
    if
        not extraction_results.successful
        or not extracted_items_path
        or not config.recursively_extract_archives
    then
        return list_of_extraction_results, extracted_items_path
    end

    -- Get the url of the extracted items path
    ---@type Url
    local extracted_items_url = Url(extracted_items_path)

    -- Initialise the base url for the extracted items
    local base_url = extracted_items_url

    -- Get the parent directory of the extracted items path
    local parent_directory_url = extracted_items_url:parent()

    -- If the parent directory doesn't exist,
    -- then return the list of extraction results
    if not parent_directory_url then return list_of_extraction_results end

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
        local file_extension = file:match(file_extension_pattern)

        -- If the file extension is not found, then skip the file
        if not file_extension then goto continue end

        -- If the file extension is not an archive file extension, skip the file
        if not is_archive_file_extension(file_extension) then goto continue end

        -- Otherwise, get the full url to the archive
        local full_archive_url = base_url:join(file)

        -- Get the full path to the archive
        local full_archive_path = tostring(full_archive_url)

        -- If the file is not an archive, skip the file
        if not is_archive_file(full_archive_path) then goto continue end

        -- Otherwise, recursively extract the archive
        local archive_extraction_results, extracted_archive_path =
            recursively_extract_archives(full_archive_path, config)

        -- Merge the results with the existing list of extraction results
        list_of_extraction_results =
            merge_tables(list_of_extraction_results, archive_extraction_results)

        -- If the archive has only one file,
        -- update the extracted items path
        -- to the extracted archive path
        if archive_has_only_one_file then
            extracted_items_path = extracted_archive_path
        end

        -- Remove the archive file after extracting it
        fs.remove("file", full_archive_url)

        -- The label the continue the loop
        ::continue::
    end

    -- Return the list of extraction results and the extracted items path
    return list_of_extraction_results, extracted_items_path
end

-- Function to handle the open command
---@type CommandFunction
local function handle_open(args, config, command_table)
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
        return ya.manager_emit("open", args)
    end

    -- Otherwise, the item group is the hovered item.
    -- Get the function to handle the enter command.
    local enter_command = command_table[Commands.Enter]

    -- If the hovered item is a directory
    if hovered_item_is_dir() then
        --

        -- If smart enter is wanted,
        -- calls the function to enter the directory
        -- and exit the function
        if config.smart_enter or table_pop(args, "smart", false) then
            return enter_command(args, config, command_table)
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
        return ya.manager_emit("open", merge_tables(args, { hovered = true }))
    end

    -- Otherwise, the hovered item is an archive
    -- and entering archives is wanted,
    -- so get the path of the hovered item
    local archive_path = get_path_of_hovered_item()

    -- If the archive path somehow doesn't exist, then exit the function
    if not archive_path then return end

    -- Run the function to extract the archive
    local extraction_results, extracted_items_path =
        recursively_extract_archives(archive_path, config)

    -- Iterate over the extraction results
    for _, extraction_result in ipairs(extraction_results) do
        --

        -- If the extraction is not successful, notify the user
        if not extraction_result.successful then
            show_error(
                "Failed to extract archive at: "
                    .. extraction_result.archive_path
                    .. "\nError: "
                    .. extraction_result.error_message
            )
        end
    end

    -- If the extracted items path is nil,
    -- then exit the function
    if not extracted_items_path then return end

    -- Get the cha object of the extracted items path
    local extracted_items_cha = fs.cha(Url(extracted_items_path), false)

    -- If the cha object of the extracted items path is nil
    -- then exit the function
    if not extracted_items_cha then return end

    -- If the extracted items path is not a directory,
    -- then exit the function
    if not extracted_items_cha.is_dir then return end

    -- Enter the archive directory
    ya.manager_emit("cd", { extracted_items_path })

    -- If the user doesn't want to skip single subdirectories on enter,
    -- or one of the arguments passed is no skip,
    -- then exit the function
    if
        not config.skip_single_subdirectory_on_enter
        or table_pop(args, "no_skip", false)
    then
        return
    end

    -- Calls the function to skip child directories
    -- with only a single directory inside
    skip_single_child_directories(Url(extracted_items_path))
end

-- Function to handle the enter command
---@type CommandFunction
local function handle_enter(args, config, command_table)
    --

    -- Get the function for the open command
    local open_command = command_table[Commands.Open]

    -- If the hovered item is not a directory
    if not hovered_item_is_dir() then
        --

        -- If smart enter is wanted,
        -- call the function for the open command
        -- and exit the function
        if config.smart_enter or table_pop(args, "smart", false) then
            return open_command(args, config, command_table)
        end

        -- Otherwise, just exit the function
        return
    end

    -- Otherwise, always emit the enter command,
    ya.manager_emit("enter", args)

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
    skip_single_child_directories(get_current_directory_url())
end

-- Function to handle the leave command
---@type CommandFunction
local function handle_leave(args, config)
    --

    -- Always emit the leave command
    ya.manager_emit("leave", args)

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
    ---@type Url
    local directory = get_current_directory_url()

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
        ---@type Url|nil
        local parent_directory = directory:parent()

        -- If the parent directory is nil,
        -- break the loop
        if not parent_directory then break end

        -- Otherwise, set the new directory to the parent directory
        directory = parent_directory
    end

    -- Emit the change directory command to change to the directory variable
    ya.manager_emit("cd", { directory })
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
        ya.manager_emit(command, args)

    -- If the item group is the hovered item
    elseif item_group == ItemGroup.Hovered then
        --

        -- Emit the command with the hovered option
        ya.manager_emit(command, merge_tables(args, { hovered = true }))
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
        return ya.manager_emit("cd", { tostring(item_url) })
    end

    -- Otherwise, the item is a file

    -- If the user does not want to open the file
    -- after creating it, exit the function
    if
        not (config.open_file_after_creation or table_pop(args, "open", false))
    then
        return
    end

    -- Otherwise, call the function to reveal the created file
    ya.manager_emit("reveal", { tostring(item_url) })

    -- Wait for Yazi to finish loading
    wait_until_yazi_is_loaded()

    -- Call the function to open the file
    return ya.manager_emit("open", { hovered = true })
end

-- Function to execute the create command
---@param item_url Url The url of the item to create
---@param args Arguments The arguments passed to the plugin
---@param config Configuration The configuration object
---@return nil
local function execute_create(item_url, is_directory, args, config)
    --

    -- Get the parent directory of the file to create
    local parent_directory_url = item_url:parent()

    -- If the parent directory doesn't exist,
    -- then show an error and exit the function
    if not parent_directory_url then
        return show_error(
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
        if not successful then return show_error(tostring(error_message)) end

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
            if not successful then
                return show_error(tostring(error_message))
            end
        end

        -- Otherwise, create the file
        local successful, error_message = fs.write(item_url, "")

        -- If the function is not successful,
        -- show the error message and exit the function
        if not successful then return show_error(tostring(error_message)) end
    end

    -- Call the function to enter or open the created item
    enter_or_open_created_item(item_url, is_directory, args, config)
end

-- Function to handle the create command
---@type CommandFunction
local function handle_create(args, config)
    --

    -- Get the directory flag
    local dir_flag = table_pop(args, "dir", false)

    -- Get the user's input for the item to create
    local user_input, event =
        get_user_input(dir_flag and "Create (dir):" or "Create:")

    -- If the user input is nil,
    -- or if the user did not confirm the input,
    -- exit the function
    if not user_input or event ~= 1 then return end

    -- Get the current working directory as a url
    ---@type Url
    local current_working_directory = get_current_directory_url()

    -- Get whether the url ends with a path delimiter
    local ends_with_path_delimiter = user_input:find("[/\\]$")

    -- Get the whether the given item is a directory or not based
    -- on the default conditions for a directory
    local is_directory = ends_with_path_delimiter or dir_flag

    -- Get the url from the user's input
    ---@type Url
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
        local file_extension = user_input:match(file_extension_pattern)

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

        -- Get the user's confirmation for
        -- whether they want to overwrite the item
        local user_confirmation = get_user_confirmation(

            -- TODO: Remove the line below
            "The item already exists, overwrite? (y/N)",
            "Overwrite file?",
            ui.Text({
                ui.Line("Will overwrite the following file:")
                    :align(ui.Line.CENTER),
                ui.Line(string.rep("-", DEFAULT_CONFIRM_OPTIONS.pos.w))
                    :align(ui.Line.LEFT),
                ui.Line(tostring(full_url)):align(ui.Line.LEFT),
            })
        )

        -- If the user did not confirm the overwrite,
        -- then exit the function
        if not user_confirmation then return end
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
local function fix_bat_default_pager_shell_command(command)
    --

    -- Initialise the default pager command for bat without the F flag
    local bat_default_pager_command_without_f_flag = "less -RX"

    -- Get the modified command and the replacement count
    -- when replacing the less command when it is quoted
    local modified_command, replacement_count = command:gsub(
        "("
            .. bat_command_with_pager_pattern
            .. "['\"]+%s*"
            .. ")"
            .. "less"
            .. "(%s*['\"]+)",
        "%1" .. bat_default_pager_command_without_f_flag .. "%2"
    )

    -- If the replacement count is not 0,
    -- then return the modified command
    if replacement_count ~= 0 then return modified_command end

    -- Otherwise, get the modified command and the replacement count
    -- when replacing the less command when it is unquoted
    modified_command, replacement_count = command:gsub(
        "(" .. bat_command_with_pager_pattern .. ")" .. "less",
        '%1"' .. bat_default_pager_command_without_f_flag .. '"'
    )

    -- If the replacement count is not 0,
    -- then return the modified command
    if replacement_count ~= 0 then return modified_command end

    -- Otherwise, return the given command
    return command
end

-- Function to fix the shell commands given to work properly with Yazi
---@param command string A shell command
---@return string command The fixed shell command
local function fix_shell_command(command)
    --

    -- If the given command includes the less command
    if command:find("%f[%a]less%f[%A]") ~= nil then
        --

        -- Fix the command containing less
        command = fix_shell_command_containing_less(command)
    end

    -- If the given command contains the bat command with the pager
    -- option passed
    if command:find(bat_command_with_pager_pattern) ~= nil then
        --

        -- Calls the command to fix the bat command with the default pager
        command = fix_bat_default_pager_shell_command(command)
    end

    -- Return the modified command
    return command
end

-- Function to handle a shell command
---@type CommandFunction
local function handle_shell(args, _, _)
    --

    -- Get the first item of the arguments given
    -- and set it to the command variable
    local command = table.remove(args, 1)

    -- Get the type of the command variable
    local command_type = type(command)

    -- If the command isn't a string,
    -- show an error message and exit the function
    if command_type ~= "string" then
        return show_error(
            string.format(
                "Shell command given is not a string, "
                    .. "instead it is a '%s', "
                    .. "with value '%s'",
                command_type,
                tostring(command)
            )
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

        -- If the exit if directory flag is passed
        if exit_if_dir then
            --

            -- Initialise the number of files
            local number_of_files = 0

            -- Iterate over all of the selected items
            for _, item in pairs(get_paths_of_selected_items()) do
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
            escape_replacement_string(
                table.concat(get_paths_of_selected_items(true), " ")
            )
        )

    -- If the item group is the hovered item
    elseif item_group == ItemGroup.Hovered then
        --

        -- If the exit if directory flag is passed,
        -- and the hovered item is a directory,
        -- then exit the function
        if exit_if_dir and hovered_item_is_dir() then return end

        -- Replace the shell variable in the command
        -- with the quoted path of the hovered item
        command = command:gsub(
            shell_variable_pattern,
            escape_replacement_string(get_path_of_hovered_item(true))
        )

    -- Otherwise, exit the function
    else
        return
    end

    -- Merge the command back into the arguments given
    args = merge_tables({ command }, args)

    -- Emit the command to operate on the hovered item
    ya.manager_emit("shell", args)
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
        return ya.manager_emit("paste", args)
    end

    -- Otherwise, enter the directory
    ya.manager_emit("enter", {})

    -- Paste the items inside the directory
    ya.manager_emit("paste", args)

    -- Leave the directory
    ya.manager_emit("leave", {})
end

-- Function to execute the tab create command
---@param state State The state object
---@param args Arguments The arguments passed to the plugin
---@return nil
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
            state.config.smart_tab_create
            or table_pop(args, "smart", false)
        )
    then
        --

        -- Emit the command to create a new tab with the arguments
        -- and exit the function
        return ya.manager_emit("tab_create", args)
    end

    -- Otherwise, emit the command to create a new tab
    -- with the hovered item's url
    ya.manager_emit("tab_create", { hovered_item.url })
end)

-- Function to handle the tab create command
---@type CommandFunction
local function handle_tab_create(args)
    --

    -- Call the function to execute the tab create command
    execute_tab_create(args)
end

-- Function to execute the tab switch command
---@param state State The state object
---@param args Arguments The arguments passed to the plugin
---@return nil
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
        return ya.manager_emit("tab_switch", args)
    end

    -- Get the number of tabs currently open
    local number_of_open_tabs = #cx.tabs

    -- Iterate from the number of current open tabs
    -- to the given tab number
    for _ = number_of_open_tabs, tab_index do
        --

        -- Call the tab create command
        ya.manager_emit("tab_create", { current = true })
    end

    -- Switch to the given tab index
    ya.manager_emit("tab_switch", args)
end)

-- Function to handle the tab switch command
---@type CommandFunction
local function handle_tab_switch(args)
    --

    -- Call the function to execute the tab switch command
    execute_tab_switch(args)
end

-- Function to do the wraparound for the arrow command
---@param _ any
---@param args Arguments The arguments passed to the plugin
---@return nil
local wraparound_arrow = ya.sync(function(_, args)
    --

    -- Get the current tab
    local current_tab = cx.active.current

    -- Get the step from the arguments given
    local step = table.remove(args, 1)

    -- Get the number of files in the current tab
    local number_of_files = #current_tab.files

    -- If there are no files in the current tab, exit the function
    if number_of_files == 0 then return end

    -- Get the new cursor index,
    -- which is the current cursor position plus the step given
    -- to the arrow function, modulus the number of files in
    -- the current tab
    local new_cursor_index = (current_tab.cursor + step) % number_of_files

    -- Emit the arrow function with the new cursor index minus
    -- the current cursor index to determine how to move the cursor
    ya.manager_emit(
        "arrow",
        merge_tables(args, { new_cursor_index - current_tab.cursor })
    )
end)

-- Function to handle the arrow command
---@type CommandFunction
local function handle_arrow(args, config)
    --

    -- If wraparound file navigation isn't wanted,
    -- then execute the arrow command
    if not config.wraparound_file_navigation then
        ya.manager_emit("arrow", args)

    -- Otherwise, call the wraparound arrow function
    else
        wraparound_arrow(args)
    end
end

-- Function to get the directory items in the parent directory
---@param _ any
---@param directories_only boolean Whether to only get directories
---@return string[] directory_items The list of paths to the directory items
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
---@param state State The state object
---@param args Arguments The arguments passed to the plugin
---@return nil
local execute_parent_arrow = ya.sync(function(state, args)
    --

    -- Gets the parent directory
    local parent_directory = cx.active.parent

    -- If the parent directory doesn't exist,
    -- then exit the function
    if not parent_directory then return end

    -- Get the offset from the arguments given
    local offset = table.remove(args, 1)

    -- Get the type of the offset
    local offset_type = type(offset)

    -- If the offset is not a number,
    -- then show an error that the offset is not a number
    -- and exit the function
    if offset_type ~= "number" then
        return show_error(
            string.format(
                "The given offset is not of the type 'number', "
                    .. "instead it is a '%s', "
                    .. "with value '%s'",
                offset_type,
                tostring(offset)
            )
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
    if state.config.wraparound_file_navigation then
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
            return ya.manager_emit("cd", { directory_item.url })
        end
    end
end)

-- Function to handle the parent arrow command
---@type CommandFunction
local function handle_parent_arrow(args)
    --

    -- Call the function to execute the parent arrow command
    -- with the arguments given
    execute_parent_arrow(args)
end

-- Function to handle the editor command
---@type CommandFunction
local function handle_editor(args, config, command_table)
    --

    -- Get the editor environment variable
    local editor = os.getenv("EDITOR")

    -- If the editor not set, exit the function
    if not editor then return end

    -- Call the handle shell function
    -- with the editor command
    handle_shell(
        merge_tables({
            editor .. " $@",
            block = true,
            exit_if_dir = true,
        }, args),
        config,
        command_table
    )
end

-- Function to handle the pager command
---@type CommandFunction
local function handle_pager(args, config, command_table)
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
        config,
        command_table
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
        [Commands.Enter] = handle_enter,
        [Commands.Leave] = handle_leave,
        [Commands.Rename] = function(_) handle_yazi_command("rename", args) end,
        [Commands.Remove] = function(_) handle_yazi_command("remove", args) end,
        [Commands.Create] = handle_create,
        [Commands.Shell] = handle_shell,
        [Commands.Paste] = handle_paste,
        [Commands.TabCreate] = handle_tab_create,
        [Commands.TabSwitch] = handle_tab_switch,
        [Commands.Arrow] = handle_arrow,
        [Commands.ParentArrow] = handle_parent_arrow,
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
    command_func(args, config, command_table)
end

-- The setup function to setup the plugin
---@param _ any
---@param opts Configuration|nil The options given to the plugin
---@return nil
local function setup(_, opts)
    --

    -- Initialise the plugin
    initialise_plugin(opts)
end

-- Function to be called to use the plugin
---@param _ any
---@param job { args: Arguments } The job object given by Yazi
---@return nil
local function entry(_, job)
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

-- Returns the table required for Yazi to run the plugin
---@return { setup: fun(): nil, entry: fun(): nil }
return {
    setup = setup,
    entry = entry,
}
