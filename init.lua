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
    sort_directories_first = true,
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

-- The pattern to get the filename of a file
local get_filename_pattern = "(.*)%.[^%.]+$"

-- The pattern to get the information from an archive item
local archive_item_info_pattern = "%s+([%.%a]+)%s+(%d+)%s+(%d+)%s+(.+)$"

-- The pattern to get the archive type from the 7z command
local get_archive_type_pattern =
    "%-%-[\r\n]+path%s+=%s+.-[\r\n]+type%s+=%s+(.-)[\r\n]+"

-- The pattern to get the shell variables in a command
local shell_variable_pattern = "[%$%%][%*@0]"

-- The pattern to match the bat command with the pager option passed
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

-- The function to trim a string
local function string_trim(string)
    --

    -- Return the string with the whitespace characters
    -- removed from the start and end
    return string:match("^%s*(.-)%s*$")
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
            if not argument:find(double_dash_pattern) then
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

    -- Return the configuration object for async functions
    return state.config
end)

-- The function to try if a shell command exists
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

    -- Return the result of the os.execute command
    return successfully_executed
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
    local config = initialise_config(merge_tables({
        extractor_command = extractor_command,
    }, opts))

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

-- Function to get the path of the hovered item
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

-- Function to get the paths of the selected items
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

-- The function to get all the items in the given directory
local function get_directory_items(
    directory,
    ignore_hidden_items,
    directories_only
)
    --

    -- Initialise the list of directory items
    local directory_items = {}

    -- Read the contents of the directory
    local directory_contents, _ = fs.read_dir(Url(directory), {})

    -- If there are no directory contents,
    -- then return the empty list of directory items
    if not directory_contents then return directory_items end

    -- Iterate over the directory contents
    for _, item in ipairs(directory_contents) do
        --

        -- If the ignore hidden items flag is passed
        -- and the item is a hidden item,
        -- then continue the loop
        if ignore_hidden_items and item.cha.is_hidden then goto continue end

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

        -- Get all the items in the current directory
        local directory_items =
            get_directory_items(directory, config.ignore_hidden_items)

        -- If the number of directory items is not 1,
        -- then break out of the loop.
        if #directory_items ~= 1 then break end

        -- Otherwise, get the directory item
        local directory_item = table.unpack(directory_items)

        -- Get the cha object of the directory item
        -- and don't follow symbolic links
        local directory_item_cha = fs.cha(Url(directory_item), false)

        -- If the directory item is not a directory,
        -- break the loop
        if not directory_item_cha.is_dir then break end

        -- Otherwise, set the directory to the inner directory
        directory = directory_item
    end

    -- Emit the change directory command to change to the directory variable
    ya.manager_emit("cd", { directory })
end

-- The function to check if an archive is password protected
local function archive_is_encrypted(command_error_string)
    return command_error_string:lower():find("wrong password", 1, true)
end

-- The function to handle retrying the extractor command
--
-- The extractor command is a function that takes
-- three arguments, first being the password to the archive,
-- the second being the configuration object
-- and the third is the overwrite flag.
-- It returns the output and the err
-- from the Command:output() function.
--
-- The initial password is the password given to the extractor command
--
-- The function returns 4 values:
-- 1. A boolean indicating whether the extraction was successful.
-- 2. The error message from the archive extractor.
-- 3. The output.stdout from the Command:output() function.
-- 4. The correct password to the archive.
local function retry_extractor(extractor_command, config, initial_password)
    --

    -- Initialise the password to the initial password
    -- or an empty string if it's not given
    local password = initial_password or ""

    -- Initialise the error message from the archive extractor
    local error_message = ""

    -- Initialise the overwrite flag to false
    local overwrite = false

    -- Initialise the number of tries
    -- to the number of retries plus 1
    local total_number_of_tries = config.extract_retries + 1

    -- Iterate over the number of times to try the extraction
    for tries = 0, total_number_of_tries do
        --

        -- Execute the extractor command
        local output, err = extractor_command(password, config, overwrite)

        -- If there is no output
        -- then return false, the error code as a string,
        -- nil for the output, and nil for the password
        if not output then return false, tostring(err), nil, nil end

        -- If the output was 0, which means the extraction was successful
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

        -- Set the overwrite flag to true.
        --
        -- This overwrite flag is to force the archive extractor
        -- to keep trying to extract the archive even when it
        -- fails due to a wrong password, as it will stop extraction
        -- in the other modes. For example, the skip mode will
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

-- The function to get the items in the archive.
--
-- This function returns a list of archive items
-- as well as the correct password to the archive.
-- If the password is not correct, then the correct password
-- will be nil.
local function get_archive_items(archive_path, config, files_only)
    --

    -- Initialise the files only flag to false if it's not given
    files_only = files_only or false

    -- The function to list the items in the archive
    local function list_items_in_archive(password, configuration, _)
        return list_archive_items_command(
            archive_path,
            configuration,
            password,
            true
        )
    end

    -- Initialise the list of archive items
    local archive_items = {}

    -- Call the function to retry the extractor command
    -- with the list items in the archive function
    local successful, error_message, output, password =
        retry_extractor(list_items_in_archive, config)

    -- If the extractor command was not successful,
    -- then return the empty list of archive items,
    -- the error message, and nil as the correct password
    if not successful then return archive_items, error_message, nil end

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

        -- If the files only flag is passed and the
        -- attributes of the item starts with a "D",
        -- which means the item is a directory,
        -- then continue the loop
        if files_only and attributes and attributes:find("^D") then
            goto continue
        end

        -- Otherwise, add the file path to the list of archive items
        table.insert(archive_items, file_path)

        -- The continue label to continue the loop
        ::continue::
    end

    -- Return the list of archive items,
    -- nil for the error message and the correct password
    return archive_items, nil, password
end

-- The extract command to extract an archive
local function extract_command(
    archive_path,
    config,
    password,
    files_only,
    overwrite
)
    --

    -- Initialise the password to an empty string if it's not given
    password = password or ""

    -- Initialise the files only flag to false if it's not given
    files_only = files_only or false

    -- Initialise the overwrite flag to false if it's not given
    overwrite = overwrite or false

    -- Initialise the extraction mode to use.
    -- By default, it extracts the archive with
    -- full paths, which keeps the archive structure.
    local extraction_mode = "x"

    -- If the files only flag is passed
    if files_only then
        --

        -- Use the regular extract,
        -- without the full paths, which will move
        -- all files in the archive into the current directory
        -- and ignore the archive folder structure.
        extraction_mode = "e"

        -- Set overwrite to false,
        -- as the files in the archive
        -- are being extracted directly
        -- to the current directory,
        -- which can result in data loss.
        -- Unless, of course, the user has
        -- configured the extraction behaviour
        -- to overwrite the existing files
        -- when extracting the archive.
        overwrite = false
    end

    -- Initialise the arguments for the command
    local arguments = {

        -- The extraction mode
        extraction_mode,

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
    }

    -- If the files only flag is not passed
    if not files_only then
        --

        -- Add the argument to always create a containing directory
        -- to contain the archive files
        table.insert(arguments, "-o*")
    end

    -- Return the command to extract the archive
    return Command(config.extractor_command)
        :args(arguments)
        :stdout(Command.PIPED)
        :stderr(Command.PIPED)
        :output()
end

-- The function to check if a file is a tar archive
local function is_tar_archive(file_path, config)
    --

    -- Initialise the is tar variable to false
    local is_tar = false

    -- Call the function to list the items in the archive
    local output, _ =
        list_archive_items_command(file_path, config, nil, false, true)

    -- If the output is nil, then return the is tar variable
    if not output then return is_tar end

    -- If the file cannot be opened as an archive
    -- then return the is tar variable
    if output.status.code ~= 0 then return is_tar end

    -- Otherwise, get the standard output of the command
    local standard_out = output.stdout:lower()

    -- Get the archive type from the standard output
    local archive_type = standard_out:match(get_archive_type_pattern)

    -- If the archive type is not found, then return the is tar variable
    if not archive_type then return is_tar end

    -- Otherwise, if the archive type is "tar"
    is_tar = archive_type == "tar"

    -- Return the is tar variable
    return is_tar
end

-- The function to extract an archive.
-- This function returns 2 values:
-- 1. A boolean to indicate whether the extraction of the archive was successful
-- 2. An error message if the extraction was unsuccessful
-- 3. Whether or not to change the directory to the extract directory
local function extract_archive(archive_path, config)
    --

    -- Initialise the files only flag to false
    local files_only = false

    -- Get the list of archive items, the error message and the password
    local archive_items, archive_items_error_message, correct_password =
        get_archive_items(archive_path, config, true)

    -- If there are no files in the archive,
    -- then return false, the error message
    -- and false to not change the directory to the extract directory.
    if #archive_items == 0 then
        return false, archive_items_error_message, false
    end

    -- Otherwise, if the number of archive items is 1,
    -- then set the files only flag to true
    if #archive_items == 1 then files_only = true end

    -- The variable to determine whether to change the directory
    -- to the extract directory.
    -- It is the opposite of the files only flag
    -- as we don't want to change the directory when
    -- we are extracting the files into the current directory.
    local change_directory = not files_only

    -- Create the extractor command
    local function extractor_command(password, configuration, overwrite)
        return extract_command(
            archive_path,
            configuration,
            password,
            files_only,
            overwrite
        )
    end

    -- Call the function to retry the extractor command
    local successful, error_message, _, _ =
        retry_extractor(extractor_command, config, correct_password)

    -- If the extraction was not successful,
    -- then return whether the extraction was successful,
    -- the error message and the change directory variable
    if not successful then
        return successful, error_message, change_directory
    end

    -- If the files only flag is false,
    -- then return whether the extraction was successful,
    -- the error message and the change directory variable
    if not files_only then
        return successful, error_message, change_directory
    end

    -- Otherwise, get the single archive item
    local archive_item = table.unpack(archive_items)

    -- Get the parent directory of the given archive path
    local parent_directory = Url(archive_path):parent()

    -- If there is no parent directory somehow,
    -- then return whether the extraction was successful,
    -- the error message and the change directory variable.
    --
    -- This should never happen, but it's better to be safe than sorry.
    if not parent_directory then
        return successful, error_message, change_directory
    end

    -- Otherwise, join the parent directory path with the archive item
    local archive_item_url = parent_directory:join(archive_item)

    -- Get the string version of the archive item url
    local archive_item_path = tostring(archive_item_url)

    -- If the item is not a tar archive
    -- then return whether the extraction was successful,
    -- the error message and the change directory variable
    if not is_tar_archive(archive_item_path, config) then
        return successful, error_message, change_directory
    end

    -- Otherwise, extract the archive item
    successful, error_message, change_directory =
        extract_archive(archive_item_path, config)

    -- Remove the archive item after extracting it
    fs.remove("file", archive_item_url)

    -- Return the result of the extraction
    return successful, error_message, change_directory
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
    local archive_path = get_path_of_hovered_item()

    -- If the archive path somehow doesn't exist, then exit the function
    if not archive_path then return end

    -- Run the function to extract the archive
    local extract_successful, err, change_directory =
        extract_archive(archive_path, config)

    -- If the extraction of the archive isn't successful,
    -- notify the user and exit the function
    if not extract_successful then
        return ya.notify(merge_tables(DEFAULT_NOTIFICATION_OPTIONS, {
            content = "Failed to extract archive at: "
                .. archive_path
                .. "\nError: "
                .. err,
            level = "error",
        }))
    end

    -- If the change directory flag variable is false,
    -- then exit the function
    if not change_directory then return end

    -- Otherwise, get the filename of the archive
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

    -- Start an infinite loop
    while true do
        --

        -- Get all the items in the current directory
        local directory_items =
            get_directory_items(directory, config.ignore_hidden_items)

        -- If the number of directory items is not 1,
        -- then break out of the loop.
        if #directory_items ~= 1 then break end

        -- Get the parent directory of the current directory
        local parent_directory = Url(directory):parent()

        -- If the parent directory is nil,
        -- break the loop
        if not parent_directory then break end

        -- Otherwise, set the new directory to the parent directory
        directory = tostring(parent_directory)
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
        less_command_with_modified_env_variables
    )

    -- Unset the LESS environment variable before calling the command
    fixed_command = "unset LESS; " .. fixed_command

    -- Return the fixed command
    return fixed_command
end

-- Function to fix the bat default pager command
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
local function handle_shell(args, _, _, exit_if_directory)
    --

    -- Get the first item of the arguments given
    -- and set it to the command variable
    local command = table.remove(args, 1)

    -- If the command isn't a string, exit the function
    if type(command) ~= "string" then return end

    -- Fix the given command
    command = fix_shell_command(command)

    -- Call the function to get the item group
    local item_group = get_item_group()

    -- If no item group is returned, exit the function
    if not item_group then return end

    -- If the exit if directory flag is not given,
    -- and the arguments contain the
    -- exit if directory flag
    if not exit_if_directory and args.exit_if_directory then
        --

        -- Set the exit if directory flag to true
        exit_if_directory = true
    end

    -- If the item group is the selected items
    if item_group == ItemGroup.Selected then
        --

        -- If the exit if directory flag is passed
        if exit_if_directory then
            --

            -- Initialise the number of files
            local number_of_files = 0

            -- Iterate over all of the selected items
            for _, item in pairs(get_paths_of_selected_items()) do
                --

                -- Get the cha object of the item
                local item_cha = fs.cha(Url(item), false)

                -- If the item isn't a directory
                if not item_cha.is_dir then
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
            table.concat(get_paths_of_selected_items(true), " ")
        )

    -- If the item group is the hovered item
    elseif item_group == ItemGroup.Hovered then
        --

        -- If the exit if directory flag is passed,
        -- and the hovered item is a directory,
        -- then exit the function
        if exit_if_directory and hovered_item_is_dir() then return end

        -- Replace the shell variable in the command
        -- with the quoted path of the hovered item
        command =
            command:gsub(shell_variable_pattern, get_path_of_hovered_item(true))

    -- Otherwise, exit the function
    else
        return
    end

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

-- Function to get the directory items in the parent directory
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
local execute_parent_arrow_command = ya.sync(function(state, args)
    --

    -- Gets the parent directory
    local parent_directory = cx.active.parent

    -- If the parent directory doesn't exist,
    -- then exit the function
    if not parent_directory then return end

    -- Get the offset from the arguments given
    local offset = table.remove(args, 1)

    -- If the offset is not a number, then exit the function
    if type(offset) ~= "number" then return end

    -- Get the number of items in the parent directory
    local number_of_items = #parent_directory.files

    -- Initialise the new cursor index
    -- to the current cursor index
    local new_cursor_index = parent_directory.cursor

    -- If wraparound file navigation is wanted
    if state.config.wraparound_file_navigation then
        --

        -- If the user sorts their directories first
        if state.config.sort_directories_first then
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
local function handle_parent_arrow(args)
    --

    -- Call the function to execute the parent arrow command
    -- with the arguments given
    execute_parent_arrow_command(args)
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
    handle_shell(
        merge_tables({
            editor .. " $@",
            confirm = true,
            block = true,
        }, args),
        config
    )
end

-- Function to handle the pager command
local function handle_pager(args, config, command_table)
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
    handle_shell(
        merge_tables({
            pager .. " $@",
            confirm = true,
            block = true,
        }, args),
        config,
        command_table,
        true
    )
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
