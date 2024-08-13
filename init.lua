-- Plugin to make some Yazi commands smarter
-- Written in Lua 5.4

-- The enum for which group of items to operate on
local ItemGroup = {
    Hovered = "hovered",
    Selected = "selected",
    None = "none",
    Prompt = "prompt",
}

-- The enum for the archive extraction behaviour
local ExtractBehaviour = {
    Overwrite = "overwrite",
    Rename = "rename",
    RenameExisting = "rename_existing",
    Skip = "skip",
}

-- The enum for the flags for the archive extraction behaviour
local ExtractBehaviourFlags = {
    [ExtractBehaviour.Overwrite] = "-aoa",
    [ExtractBehaviour.Rename] = "-aou",
    [ExtractBehaviour.RenameExisting] = "-aot",
    [ExtractBehaviour.Skip] = "-aos",
}

-- The enum for the supported commands
local Commands = {
    Open = "open",
    Enter = "enter",
    Leave = "leave",
    Rename = "rename",
    Remove = "remove",
    Paste = "paste",
    Shell = "shell",
    Arrow = "arrow",
    ParentArrow = "parent-arrow",
    Editor = "editor",
    Pager = "pager",
}

-- The default configuration for the plugin
local DEFAULT_CONFIG = {
    prompt = false,
    default_item_group_for_prompt = ItemGroup.Hovered,
    smart_enter = true,
    smart_paste = false,
    enter_archives = true,
    extract_behaviour = ExtractBehaviour.Rename,
    extract_retries = 3,
    must_have_hovered_item = true,
    skip_single_subdirectory_on_enter = true,
    skip_single_subdirectory_on_leave = true,
    ignore_hidden_items = false,
    wraparound_file_navigation = false,
}

-- The default notification options for this plugin
local DEFAULT_NOTIFICATION_OPTIONS = {
    title = "Augment Command Plugin",
    timeout = 5.0,
}

-- The default input options for this plugin
local DEFAULT_INPUT_OPTIONS = {
    position = { "top-center", y = 2, w = 50 },
}

-- The table of input options for the prompt
local INPUT_OPTIONS_TABLE = {
    [ItemGroup.Hovered] = "(H/s)",
    [ItemGroup.Selected] = "(h/S)",
    [ItemGroup.None] = "(h/s)",
}

-- The list of archive mime types
local ARCHIVE_MIME_TYPES = {
    "application/zip",
    "application/gzip",
    "application/x-tar",
    "application/x-bzip",
    "application/x-bzip2",
    "application/x-7z-compressed",
    "application/x-rar",
    "application/x-xz",
}

-- The pattern to get the double dash from the front of the argument
local double_dash_pattern = "^%-%-"

-- The pattern to get the parent directory of the current directory
local get_parent_directory_pattern = "(.*)[/\\].*"

-- The pattern to get if a file path is a directory
local is_directory_pattern = "(.*)[/\\]$"

-- The pattern to get the filename of a file
local get_filename_pattern = "(.*)%.[^%.]+$"

-- The pattern to get the shell variables in a command
local shell_variable_pattern = "[%$%%][%*@0]"

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

                -- Set the value mapped to the index
                new_table[index] = value

                -- Increment the index
                index = index + 1

            -- Otherwise, the key isn't a number
            else

                -- Set the key in the new table to the value given
                new_table[key] = value
            end
        end
    end

    -- Return the new table
    return new_table
end

-- Function to check if a list contains a given value
local function list_contains(list, value)
    --

    -- Iterate over all of the items in the list
    for _, item in ipairs(list) do
        --

        -- If the item is equal to the given value,
        -- then return true
        if item == value then return true end
    end

    -- Otherwise, return false if the item isn't in the list
    return false
end

-- Function to split a string into a list
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

-- Function to parse the arguments given.
-- This function takes the arguments passed to the entry function
local function parse_args(args)
    --

    -- The table of arguments to pass to ya.manager_emit
    local parsed_arguments = {}

    -- Iterates over the arguments given
    for index, argument in ipairs(args) do
        --

        -- If the index isn't 1,
        -- which means it is the arguments to the command given
        if index ~= 1 then
            --

            -- If the argument doesn't start with a double dash
            if not argument:match(double_dash_pattern) then
                --

                -- Try to convert the argument to a number
                local number_argument = tonumber(argument)

                -- Add the argument to the list of options
                table.insert(
                    parsed_arguments,
                    number_argument and number_argument or argument
                )

                -- Continue the loop
                goto continue
            end

            -- Otherwise, remove the double dash from the front of the argument
            local cleaned_argument = argument:gsub(double_dash_pattern, "")

            -- Replace all of the dashes with underscores
            cleaned_argument = cleaned_argument:gsub("%-", "_")

            -- Split the arguments at the = character
            local arg_name, arg_value =
                table.unpack(string_split(cleaned_argument, "="))

            -- If the argument value is nil
            if arg_value == nil then
                --

                -- Set the argument name to the cleaned argument
                arg_name = cleaned_argument

                -- Set the argument value to true
                arg_value = true

            -- Otherwise
            else
                --

                -- Try to convert the argument value to a number
                local number_arg_value = tonumber(arg_value)

                -- Set the argument value to the number
                -- if the the argument value can be converted to a number
                arg_value = number_arg_value and number_arg_value or arg_value
            end

            -- Add the argument name and value to the options
            parsed_arguments[arg_name] = arg_value
        end

        -- The label to continue the loop
        ::continue::
    end

    -- Return the table of arguments
    return parsed_arguments
end

-- Function to initialise the configuration
local initialise_config = ya.sync(function(state, opts)
    --

    -- Merge the default configuration with the given one
    -- and set it to the state.
    state.config = merge_tables(DEFAULT_CONFIG, opts)

    -- Get the operating system family
    local os_family = ya.target_family()

    -- Get whether the operating system is windows
    local is_windows = os_family == "windows"

    -- Initialise the shell variables
    local shell_variables = {
        hovered_items = is_windows and "%0" or "$0",
        selected_items = is_windows and "%*" or "$@",
    }

    -- Set the shell variables in the config
    state.config.shell_variables = shell_variables

    -- Return the configuration object for async functions
    return state.config
end)

-- The function to try if a shell command exists
local function shell_command_exists(command, args)
    --

    -- Initialise the arguments if none are given
    args = args or {}

    -- Spawn the shell command and get the output
    local output, err = Command(command)
        :args(args)
        :stdout(Command.PIPED)
        :stderr(Command.PIPED)
        :output()

    -- Return true if there is an output
    -- and false otherwise
    return output and true or false
end

-- The function to initialise the plugin
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
    local config = initialise_config(
        merge_tables({ extractor_command = extractor_command }, opts)
    )

    -- Return the configuration object
    return config
end

-- Function to get the configuration from an async function
local get_config = ya.sync(function(state)
    --

    -- Returns the configuration object
    return state.config
end)

-- Function to get the current working directory
local get_current_directory = ya.sync(function(_)
    return tostring(cx.active.current.cwd)
end)

-- Function to get the parent working directory
local get_parent_directory = ya.sync(function(_)
    --

    -- Get the parent directory
    local parent_directory = cx.active.parent

    -- If the parent directory doesn't exist,
    -- return nil
    if not parent_directory then return nil end

    -- Otherwise, return the path of the parent directory
    return tostring(parent_directory.cwd)
end)

-- Function to get the hovered item path
local get_hovered_item_path = ya.sync(function(_)
    --

    -- Get the hovered item
    local hovered_item = cx.active.current.hovered

    -- If the hovered item exists
    if hovered_item then
        --

        -- Return the path of the hovered item
        return tostring(cx.active.current.hovered.url)

    -- Otherwise, return nil
    else
        return nil
    end
end)

-- Function to get if the hovered item is a directory
local hovered_item_is_dir = ya.sync(function(_)
    --

    -- Get the hovered item
    local hovered_item = cx.active.current.hovered

    -- Return if the hovered item exists and is a directory
    return hovered_item and hovered_item.cha.is_dir
end)

-- Function to get if the hovered item is an archive
local hovered_item_is_archive = ya.sync(function(_)
    --

    -- Get the hovered item
    local hovered_item = cx.active.current.hovered

    -- Return if the hovered item exists and is an archive
    return hovered_item
        and list_contains(ARCHIVE_MIME_TYPES, hovered_item:mime())
end)

-- Function to choose which group of items to operate on.
-- It returns ItemGroup.Hovered for the hovered item,
-- ItemGroup.Selected for the selected items,
-- and ItemGroup.Prompt to tell the calling function
-- to prompt the user.
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
    local user_input, event = ya.input(merge_tables(DEFAULT_INPUT_OPTIONS, {
        title = "Operate on hovered or selected items? " .. input_options,
    }))

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

-- The ls command to get the items in the directory
local function ls_command(directory, ignore_hidden_items)
    return Command("ls")
        :args({
            directory,
            ignore_hidden_items and "-1p" or "-1pA",
            "--group-directories-first",
        })
        :stdout(Command.PIPED)
        :stderr(Command.PIPED)
        :output()
end

-- Function to skip child directories with only one directory
local function skip_single_child_directories(args, config, initial_directory)
    --

    -- If the user doesn't want to skip single subdirectories on enter,
    -- or one of the arguments passed is no skip,
    -- then exit the function
    if not config.skip_single_subdirectory_on_enter or args.no_skip then
        return
    end

    -- Initialise the directory variable to the initial directory given
    local directory = initial_directory

    -- Start an infinite loop
    while true do
        --

        -- Run the ls command to get the items in the directory
        local output, _ = ls_command(directory, config.ignore_hidden_items)

        -- If there is no output, then break out of the loop
        if not output then break end

        -- Get the list of items in the directory
        local directory_items = string_split(output.stdout, "\n")

        -- If the number of directory items is not 1,
        -- then break out of the loop
        if #directory_items ~= 1 then break end

        -- Otherwise, get the item in the directory
        local directory_item = table.unpack(directory_items)

        -- Match the directory item against the pattern to
        -- check if it is a directory
        directory_item = directory_item:match(is_directory_pattern)

        -- If the directory item isn't a directory, break the loop
        if directory_item == nil then break end

        -- Otherwise, set the directory to the inner directory
        directory = directory .. "/" .. directory_item
    end

    -- Emit the change directory command to change to the directory variable
    ya.manager_emit("cd", { directory })
end

-- The function to check if an archive is password protected
local function archive_is_encrypted(command_error_string)
    return command_error_string:lower():find("wrong password", 1, true)
end

-- The extract command to extract an archive
local function extract_command(archive_path, config, password, overwrite)
    --

    -- Initialise the password to an empty string if it's not given
    password = password or ""

    -- Initialise the overwrite flag to false if it's not given
    overwrite = overwrite or false

    -- Return the command to extract the archive
    return Command(config.extractor_command)
        :args({

            -- Extract the archive with the full paths,
            -- which keeps the archive structure.
            -- Using e to extract will move all the
            -- files in the archive into the current directory
            -- and ignore the archive folder structure.
            "x",

            -- Assume yes to all prompts
            "-y",

            -- Configure the extraction behaviour.
            -- It only overwrites if the overwrite flag is passed,
            -- which is only used in the extract_archive function
            -- to extract encrypted archives.
            overwrite and ExtractBehaviourFlags[ExtractBehaviour.Overwrite]
                or ExtractBehaviourFlags[config.extract_behaviour],

            -- Pass the password to the command
            "-p" .. password,

            -- The archive file to extract
            archive_path,

            -- Always create a containing directory to contain the archive files
            "-o*",
        })
        :stdout(Command.PIPED)
        :stderr(Command.PIPED)
        :output()
end

-- The function to extract an archive.
-- This function returns a boolean to indicating
-- whether the extraction of the archive was successful or not.
local function extract_archive(archive_path, config)
    --

    -- Initialise the password variable to an empty string
    local password = ""

    -- Initialise the error message from the archive extractor
    local error_message = ""

    -- Initialise the overwrite flag to false
    local overwrite = false

    -- Initialise the number of tries
    -- to the number of retries plus 1.
    --
    -- The plus 1 is because the first try doesn't count
    -- as a retry, so we need to try it once more than
    -- the number of retries given by the user.
    local total_number_of_tries = config.extract_retries + 1

    -- Iterate over the number of times to try the extraction
    for tries = 0, total_number_of_tries do
        --

        -- Use the command to extract the archive
        local output, err =
            extract_command(archive_path, config, password, overwrite)

        -- If there is no output
        -- then return the output and the error
        if not output then return false, err end

        -- If the output was 0, which means the extraction was successful,
        -- return true
        if output.status.code == 0 then return true, err end

        -- Set the error message to the standard error
        -- from the archive extractor
        error_message = output.stderr

        -- If the command failed for some other reason other
        -- than the archive being encrypted, then return false
        -- and the error message
        if
            not (
                output.status.code == 2 and archive_is_encrypted(output.stderr)
            )
        then
            return false, error_message
        end

        -- If it is the last try, then return false
        -- and the error message.
        if tries == total_number_of_tries then
            return false, error_message
        end

        -- Set the overwrite flag to true.
        --
        -- This overwrite flag is to force the archive extractor
        -- to keep trying to extract the archive even when it
        -- fails due to a wrong password, as it will stop extraction
        -- in the other modes like skip will
        -- return that it succeeded in extracting the
        -- encrypted archive despite not actually doing so.
        --
        -- This will allow the loop to continue and hence allow
        -- the plugin to continue prompting the user for the
        -- correct password to open the archive as the archive extractor
        -- will keep reporting that it failed to extract the
        -- archive instead of reporting that it succeeded despite
        -- not actually succeeding in extracting the archive.
        --
        -- This also stops the archive extractor from polluting
        -- the extract directory unlike when using the rename and
        -- rename existing modes.
        overwrite = true

        -- Initialise the prompt for the password
        local password_prompt = "Wrong password, please enter another password:"

        -- If this is the first time opening the archive,
        -- which means the number of tries is 0,
        -- then ask the user for the password
        -- instead of giving the wrong password message.
        if tries == 0 then
            password_prompt = "Archive is encrypted, please enter the password:"
        end

        -- Ask the user for the password
        local user_input, event = ya.input(merge_tables(DEFAULT_INPUT_OPTIONS, {
            title = password_prompt,
        }))

        -- If the user has confirmed the input,
        -- set the password to the user's input
        if event == 1 then
            password = user_input

        -- Otherwise, exit the function
        -- as the user has cancelled the prompt,
        -- or an unknown error has occurred
        else
            return false, error_message
        end
    end

    -- If all the tries have been exhausted,
    -- then return false and the error message
    return false, error_message
end

-- Function to handle the open command
local function handle_open(args, config, command_table)
    --

    -- Call the function to get the item group
    local item_group = get_item_group()

    -- If no item group is returned, exit the function
    if not item_group then return end

    -- If the item group is the selected items,
    -- then execute the command and exit the function
    if item_group == ItemGroup.Selected then
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
        if config.smart_enter then
            return enter_command(args, config, command_table)

        -- Otherwise, just exit the function
        else
            return
        end
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
    local archive_path = get_hovered_item_path()

    -- If the archive path somehow doesn't exist, then exit the function
    if not archive_path then return end

    -- Run the function to extract the archive
    local extract_successful, err =
        extract_archive(archive_path, config)

    -- If the extraction of the archive isn't successful,
    -- notify the user and exit the function
    if not extract_successful then
        return ya.notify(merge_tables(DEFAULT_NOTIFICATION_OPTIONS, {
            content = "Failed to extract archive at: "
                .. archive_path
                .. "\nError: "
                .. tostring(err),
            level = "error",
        }))
    end

    -- Get the filename of the archive
    local archive_filename = archive_path:match(get_filename_pattern)

    -- Enter the archive directory
    ya.manager_emit("cd", { archive_filename })

    -- Calls the function to skip child directories
    -- with only a single directory inside
    skip_single_child_directories(args, config, archive_filename)
end

-- Function to handle the enter command
local function handle_enter(args, config, command_table)
    --

    -- Get the function for the open command
    local open_command = command_table[Commands.Open]

    -- If the hovered item is not a directory
    if not hovered_item_is_dir() and config.smart_enter then
        --

        -- If smart enter is wanted,
        -- call the function for the open command
        -- and exit the function
        if config.smart_enter then
            return open_command(args, config, command_table)

        -- Otherwise, just exit the function
        else
            return
        end
    end

    -- Otherwise, always emit the enter command,
    ya.manager_emit("enter", args)

    -- Calls the function to skip child directories
    -- with only a single directory inside
    skip_single_child_directories(args, config, get_current_directory())
end

-- Function to handle the leave command
local function handle_leave(args, config)
    --

    -- Always emit the leave command
    ya.manager_emit("leave", args)

    -- If the user doesn't want to skip single subdirectories on leave,
    -- or one of the arguments passed is no skip,
    -- then exit the function
    if not config.skip_single_subdirectory_on_leave or args.no_skip then
        return
    end

    -- Otherwise, initialise the directory to the current directory
    local directory = get_current_directory()

    -- Otherwise, start an infinite loop
    while true do
        --

        -- Run the ls command to get the items in the directory
        local output, _ = ls_command(directory, config.ignore_hidden_items)

        -- If there is no output, then break out of the loop
        if not output then break end

        -- Get the list of items in the directory
        local directory_items = string_split(output.stdout, "\n")

        -- If the number of directory items is not 1,
        -- then break out of the loop
        if #directory_items ~= 1 then break end

        -- Otherwise, set the new directory
        -- to the parent of the current directory
        directory = directory:match(get_parent_directory_pattern)
    end

    -- Emit the change directory command to change to the directory variable
    ya.manager_emit("cd", { directory })
end

-- Function to handle a Yazi command
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

    -- Otherwise, exit the function
    else
        return
    end
end

-- Function to handle the paste command
local function handle_paste(args, config)
    --

    -- If the hovered item is a directory and smart paste is wanted
    if hovered_item_is_dir() and (config.smart_paste or args.smart) then
        --

        -- Enter the directory
        ya.manager_emit("enter", {})

        -- Paste the items inside the directory
        ya.manager_emit("paste", args)

        -- Leave the directory
        ya.manager_emit("leave", {})

    -- Otherwise, just paste the items inside the current directory
    else
        ya.manager_emit("paste", args)
    end
end

-- Function to remove the F flag from the less command
local function remove_f_flag_from_less_command(command)

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
    command, replacement_count = command:gsub(
        "(%f[%a]less%f[%A].*%-)(%a*)F(%a*)", "%1%2%3"
    )

    -- If the replacement count is not 0,
    -- set the f_flag_found variable to true
    if replacement_count ~= 0 then f_flag_found = true end

    -- Return the command and whether or not the F flag was found
    return command, f_flag_found
end

-- Function to fix a command containing less.
-- All this function does is remove
-- the F flag from a command containing less.
local function fix_command_containing_less(command)

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
        less_command_with_modified_env_variables
    )

    -- Unset the LESS environment variable before calling the command
    fixed_command = "unset LESS; " .. fixed_command

    -- Return the fixed command
    return fixed_command
end

-- Function to fix the commands given to work properly with Yazi
local function fix_command(command)
    --

    -- If the given command doesn't include the less command
    -- just return the given command
    if command:find("%f[%a]less%f[%A]") == nil then return command end

    -- Otherwise, the command is a command containing
    -- the less command, so fix it and return the result
    return fix_command_containing_less(command)
end

-- Function to handle a shell command
local function handle_shell(args, config)
    --

    -- Get the first item of the arguments given
    -- and set it to the command variable
    local command = table.remove(args, 1)

    -- If the command isn't a string, exit the function
    if type(command) ~= "string" then return end

    -- Fix the given command
    command = fix_command(command)

    -- Call the function to get the item group
    local item_group = get_item_group()

    -- If no item group is returned, exit the function
    if not item_group then return end

    -- If the item group is the selected items
    if item_group == ItemGroup.Selected then
        --

        -- Replace the shell variable in the command
        -- with the shell variable for the selected items
        command = command:gsub(
            shell_variable_pattern,
            config.shell_variables.selected_items
        )

    -- If the item group is the hovered item
    elseif item_group == ItemGroup.Hovered then
        --

        -- Replace the shell variable in the command
        -- with the shell variable for the hovered item
        command = command:gsub(
            shell_variable_pattern,
            config.shell_variables.hovered_items
        )

    -- Otherwise, exit the function
    else return end

    -- Merge the command back into the arguments given
    args = merge_tables({ command }, args)

    -- Emit the command to operate on the hovered item
    ya.manager_emit("shell", args)
end

-- Function to do the wraparound for the arrow command
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

-- Function to execute the parent arrow command
local execute_parent_arrow_command = ya.sync(
    function(state, args, number_of_directories)
        --

        -- Gets the parent directory
        local parent_directory = cx.active.parent

        -- If the parent directory doesn't exist,
        -- then exit the function
        if not parent_directory then return end

        -- Get the step from the arguments given
        local step = table.remove(args, 1)

        -- Initialise the new cursor index
        -- to the current parent cursor index
        local new_cursor_index = parent_directory.cursor

        -- Otherwise, if wraparound file navigation is wanted
        -- and the number of directories is given and isn't 0
        if
            state.config.wraparound_file_navigation
            and number_of_directories
            and number_of_directories ~= 0
        then
            --

            -- Get the new cursor index by adding the step,
            -- and modding the whole thing by the number of
            -- directories given.
            new_cursor_index = (parent_directory.cursor + step)
                % number_of_directories

        -- Otherwise, get the new cursor index normally.
        else
            new_cursor_index = parent_directory.cursor + step
        end

        -- Increment the cursor index by 1.
        -- The cursor index needs to be increased by 1
        -- as the cursor index is 0-based, while Lua
        -- tables are 1-based.
        new_cursor_index = new_cursor_index + 1

        -- Get the target directory
        local target_directory = parent_directory.files[new_cursor_index]

        -- If the target directory exists and is a directory
        if target_directory and target_directory.cha.is_dir then
            --

            -- Emit the command to change directory
            -- to the target directory
            ya.manager_emit("cd", { target_directory.url })
        end
    end
)

-- Function to handle the parent arrow command
local function handle_parent_arrow(args, config)
    --

    -- If wraparound file navigation isn't wanted,
    -- then execute the parent arrow command and exit the function
    if not config.wraparound_file_navigation then
        return execute_parent_arrow_command(args)
    end

    -- Otherwise, get the path of the parent directory
    local parent_directory_path = get_parent_directory()

    -- If there is no parent directory, exit the function
    if not parent_directory_path then return end

    -- Call the ls command to get the number of directories
    local output, _ =
        ls_command(parent_directory_path, config.ignore_hidden_items)

    -- If there is no output, exit the function
    if not output then return end

    -- Get the item in the parent directory
    local directory_items = string_split(output.stdout, "\n")

    -- Initialise the number of directories
    local number_of_directories = 0

    -- Iterate over the directory items
    for _, item in ipairs(directory_items) do
        --

        -- If the item is a directory
        if item:match(is_directory_pattern) then
            --

            -- Increment the number of directories by 1
            number_of_directories = number_of_directories + 1

        -- Otherwise, break out of the loop,
        -- as the directories are grouped together
        else
            break
        end
    end

    -- Call the function to execute the parent arrow command
    execute_parent_arrow_command(args, number_of_directories)
end

-- Function to handle the editor command
local function handle_editor(args, config)
    --

    -- Call the function to get the item group
    local item_group = get_item_group()

    -- If no item group is returned, exit the function
    if not item_group then return end

    -- Get the editor environment variable
    local editor = os.getenv("EDITOR")

    -- If the editor not set, exit the function
    if not editor then return end

    -- Call the handle shell function
    -- with the editor command
    handle_shell(merge_tables({
        editor .. " $@",
        confirm = true,
        block = true,
    }, args), config)
end

-- Function to handle the pager command
local function handle_pager(args, config)
    --

    -- Get the pager environment variable
    local pager = os.getenv("PAGER")

    -- If the pager is not set, exit the function
    if not pager then return end

    -- If the pager is the less command
    if pager:find("^less") ~= nil then
        --

        -- Remove the F flag from the command
        pager = pager:gsub("%-F", ""):gsub("(%a*)F(%a*)", "%1%2")
    end

    -- Call the handle shell function
    -- with the pager command
    handle_shell(merge_tables({
        pager .. " $@",
        confirm = true,
        block = true,
    }, args), config)
end

-- Function to run the commands given
local function run_command_func(command, args, config)
    --

    -- The command table
    local command_table = {
        [Commands.Open] = handle_open,
        [Commands.Enter] = handle_enter,
        [Commands.Leave] = handle_leave,
        [Commands.Rename] = function(_)
            handle_yazi_command("rename", args)
        end,
        [Commands.Remove] = function(_)
            handle_yazi_command("remove", args)
        end,
        [Commands.Paste] = handle_paste,
        [Commands.Shell] = handle_shell,
        [Commands.Arrow] = handle_arrow,
        [Commands.ParentArrow] = handle_parent_arrow,
        [Commands.Editor] = handle_editor,
        [Commands.Pager] = handle_pager,
    }

    -- Get the function for the command
    local command_func = command_table[command]

    -- If the function isn't found, notify the user and exit the function
    if not command_func then
        return ya.notify(merge_tables(DEFAULT_NOTIFICATION_OPTIONS, {
            content = "Unknown command: " .. command,
            level = "error",
        }))
    end

    -- Parse the arguments and set it to the args variable
    args = parse_args(args)

    -- Otherwise, call the function for the command
    command_func(args, config, command_table)
end

-- The setup function to setup the plugin
local function setup(_, opts)
    --

    -- Initialise the plugin
    initialise_plugin(opts)
end

-- The function to be called to use the plugin
local function entry(_, args)
    --

    -- Gets the command passed to the plugin
    local command = args[1]

    -- If the command isn't given, exit the function
    if not command then return end

    -- Gets the configuration object
    local config = get_config()

    -- If the configuration hasn't been initialised yet,
    -- then initialise the plugin with the default configuration,
    -- as it hasn't been initialised either
    if not config then config = initialise_plugin() end

    -- Call the function to handle the commands
    run_command_func(command, args, config)
end

-- Returns the table required for Yazi to run the plugin
return {
    setup = setup,
    entry = entry,
}
