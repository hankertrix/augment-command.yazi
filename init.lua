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
    Skip = "skip",
}

-- The enum for the flags for the archive extraction behaviour
local ExtractBehaviourFlags = {
    [ExtractBehaviour.Overwrite] = "-f",
    [ExtractBehaviour.Rename] = "-r",
    [ExtractBehaviour.Skip] = "-s",
}

-- The enum for the supported commands
local Commands = {
    Open = "open",
    Enter = "enter",
    Leave = "leave",
    Rename = "rename",
    Remove = "remove",
    Paste = "paste",
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
    extract_behaviour = ExtractBehaviour.Skip,
    must_have_hovered_item = true,
    skip_single_subdirectory_on_enter = true,
    skip_single_subdirectory_on_leave = true,
    ignore_hidden_items = false,
    wraparound_file_navigation = false,
}

-- The default notification options for this plugin
local DEFAULT_NOTIFICATION_OPTIONS = {
    title = "Augment Command Plugin",
    timeout = 5.0
}

-- The default input options for this plugin
local DEFAULT_INPUT_OPTIONS = {
    position = { "top-center", y = 2, w = 50 }
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
local get_parent_directory_pattern = "(.*)/.*"

-- The pattern to get if a file path is a directory
local is_directory_pattern = "(.*)/$"

-- The pattern to get the filename of a file
local get_filename_pattern = "(.*)%.[^%.]+$"


-- Function to merge tables.
-- The tables given later in the argument list WILL OVERRIDE
-- the tables given earlier in the argument list.
local function merge_tables(...)

    -- Initialise a new table
    local new_table = {}

    -- Iterates over the tables given
    for _, table in ipairs({...}) do

        -- Iterate over all of the keys and values
        for key, value in pairs(table) do

            -- Set the key in the new table to the value given
            new_table[key] = value
        end
    end

    -- Return the new table
    return new_table
end


-- Function to check if a list contains a given value
local function list_contains(list, value)

    -- Iterate over all of the items in the list
    for _, item in ipairs(list) do

        -- If the item is equal to the given value,
        -- then return true
        if item == value then return true end
    end

    -- Otherwise, return false if the item isn't in the list
    return false
end


-- Function to split a string into a list
local function string_split(given_string, separator)

    -- If the separator isn't given, set it to the whitespace character
    if separator == nil then
        separator = "%s"
    end

    -- Initialise the list of splitted strings
    local splitted_strings = {}

    -- Iterate over all of the strings found by pattern
    for string in string.gmatch(given_string, "([^" .. separator .. "]+)") do

        -- Add the string to the list of splitted strings
        table.insert(splitted_strings, string)
    end

    -- Return the list of splitted strings
    return splitted_strings
end


-- Function to parse the arguments given.
-- This function takes the arguments passed to the entry function
local function parse_args(args)

    -- The table of options to pass to ya.manager_emit
    local options = {}

    -- Iterates over the arguments given
    for index, argument in ipairs(args) do

        -- If the index isn't 1,
        -- which means it is the arguments to the command given
        if index ~= 1 then

            -- If the argument doesn't start with a double dash
            if not argument:match(double_dash_pattern) then

                -- Try to convert the argument to a number
                local number_argument = tonumber(argument)

                -- Add the argument to the list of options
                table.insert(
                    options,
                    number_argument and number_argument or argument
                )

                -- Continue the loop
                goto continue
            end

            -- Otherwise, remove the double dash from the front of the argument
            local cleaned_argument =
                argument:gsub(double_dash_pattern, "")

            -- Replace all of the dashes with underscores
            cleaned_argument = cleaned_argument:gsub("%-", "_")

            -- Split the arguments at the = character
            local arg_name, arg_value = table.unpack(
                string_split(cleaned_argument, "=")
            )

            -- If the argument value is nil
            if arg_value == nil then

                -- Set the argument name to the cleaned argument
                arg_name = cleaned_argument

                -- Set the argument value to true
                arg_value = true
            end

            -- Add the argument name and value to the options
            options[arg_name] = arg_value
        end

        -- The label to continue the loop
        ::continue::
    end

    -- Return the table of options
    return options
end


-- Function to initialise the configuration
local initialise_config = ya.sync(function(state, opts)

    -- Merge the default configuration with the given one
    -- and set it to the state.
    state.config = merge_tables(DEFAULT_CONFIG, opts)

    -- Return the configuration object for async functions
    return state.config
end)


-- Function to get the configuration from an async function
local get_config = ya.sync(function(state)

    -- Returns the configuration object
    return state.config
end)


-- Function to get the current working directory
local get_current_directory = ya.sync(function(_)
    return tostring(cx.active.current.cwd)
end)


-- Function to get the parent working directory
local get_parent_directory = ya.sync(function(_)

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

    -- Get the hovered item
    local hovered_item = cx.active.current.hovered

    -- If the hovered item exists
    if hovered_item then

        -- Return the path of the hovered item
        return tostring(cx.active.current.hovered.url)

    -- Otherwise, return nil
    else return nil end
end)


-- Function to get if the hovered item is a directory
local hovered_item_is_dir = ya.sync(function(_)

    -- Get the hovered item
    local hovered_item = cx.active.current.hovered

    -- Return if the hovered item exists and is a directory
    return hovered_item and hovered_item.cha.is_dir
end)


-- Function to get if the hovered item is an archive
local hovered_item_is_archive = ya.sync(function(_)

    -- Get the hovered item
    local hovered_item = cx.active.current.hovered

    -- Return if the hovered item exists and is an archive
    return hovered_item and list_contains(
        ARCHIVE_MIME_TYPES, hovered_item:mime()
    )
end)


-- Function to choose which group of items to operate on.
-- It returns ItemGroup.Hovered for the hovered item,
-- ItemGroup.Selected for the selected items,
-- and ItemGroup.Prompt to tell the calling function
-- to prompt the user.
local get_item_group_from_state = ya.sync(function(state)

    -- Get the hovered item
    local hovered_item = cx.active.current.hovered

    -- The boolean representing that there are no selected items
    local no_selected_items = #cx.active.selected == 0

    -- If there is no hovered item
    if not hovered_item then

        -- If there are no selected items, exit the function
        if no_selected_items then return

        -- Otherwise, if the configuration is set to have a hovered item,
        -- exit the function
        elseif state.config.must_have_hovered_item then return

        -- Otherwise, return the enum for the selected items
        else return ItemGroup.Selected end

    -- Otherwise, there is a hovered item
    -- and if there are no selected items,
    -- return the enum for the hovered item.
    elseif no_selected_items then return ItemGroup.Hovered

    -- Otherwise if there are selected items and the user wants a prompt,
    -- then tells the calling function to prompt them
    elseif state.config.prompt then
        return ItemGroup.Prompt

    -- Otherwise, if the hovered item is selected,
    -- then return the enum for the selected items
    elseif hovered_item:is_selected() then return ItemGroup.Selected

    -- Otherwise, return the enum for the hovered item
    else return ItemGroup.Hovered end
end)


-- Function to prompt the user for their desired item group
local function prompt_for_desired_item_group()

    -- Get the configuration
    local config = get_config()

    -- Get the default item group
    local default_item_group = config.default_item_group_for_prompt

    -- Get the input options
    local input_options = INPUT_OPTIONS_TABLE[default_item_group]

    -- If the default item group is None, then set it to nil
    if default_item_group == ItemGroup.None then
        default_item_group = nil
    end

    -- Prompt the user for their input
    local user_input, event = ya.input(merge_tables(DEFAULT_INPUT_OPTIONS, {
        title = "Operate on hovered or selected items? " .. input_options
    }))

    -- Lowercase the user's input
    user_input = user_input:lower()

    -- If the user did not confirm the input, exit the function
    if event ~= 1 then return

    -- Otherwise, if the user's input starts with "h",
    -- return the item group representing the hovered item
    elseif user_input:find("^h") then return ItemGroup.Hovered

    -- Otherwise, if the user's input starts with "s",
    -- return the item group representing the selected items
    elseif user_input:find("^s") then return ItemGroup.Selected

    -- Otherwise, return the default item group
    else return default_item_group end
end


-- Function to get the item group
local function get_item_group()

    -- Get the item group from the state
    local item_group = get_item_group_from_state()

    -- If the item group isn't the prompt one,
    -- then return the item group immediately
    if item_group ~= ItemGroup.Prompt then return item_group

    -- Otherwise, prompt the user for the desired item group
    else return prompt_for_desired_item_group() end
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


-- Function to handle the open command
local function handle_open(args, config, command_table)

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

        -- If smart enter is wanted,
        -- calls the function to enter the directory
        -- and exit the function
        if config.smart_enter then
            return enter_command(args, config, command_table)

        -- Otherwise, just exit the function
        else return end
    end

    -- Otherwise, if the hovered item is not an archive,
    -- or entering archives isn't wanted
    if not hovered_item_is_archive() or not config.enter_archives then

        -- Simply emit the open command and exit the function
        return ya.manager_emit("open", args)
    end

    -- Otherwise, the hovered item is an archive
    -- and entering archives is wanted,
    -- so get the path of the hovered item
    local archive_path = get_hovered_item_path()

    -- If the archive path somehow doesn't exist, then exit the function
    if not archive_path then return end

    -- Run the command to extract the archive
    local output, err = Command("unar")
        :args({
            "-d",
            ExtractBehaviourFlags[config.extract_behaviour],
            archive_path
        })
        :stdout(Command.PIPED)
        :stderr(Command.PIPED)
        :output()

    -- If the command isn't successful, notify the user
    if not output then
        return ya.notify(merge_tables(DEFAULT_NOTIFICATION_OPTIONS, {
            content = "Failed to extract archive at: "
                .. archive_path
                .. "\nError code: "
                .. tostring(err),
            level = "error"
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

    -- Get the function for the open command
    local open_command = command_table[Commands.Open]

    -- If the hovered item is not a directory
    if not hovered_item_is_dir() and config.smart_enter then

        -- If smart enter is wanted,
        -- call the function for the open command
        -- and exit the function
        if config.smart_enter then
            return open_command(args, config, command_table)

        -- Otherwise, just exit the function
        else return end
    end

    -- Otherwise, always emit the enter command,
    ya.manager_emit("enter", args)

    -- Calls the function to skip child directories
    -- with only a single directory inside
    skip_single_child_directories(args, config, get_current_directory())
end


-- Function to handle the leave command
local function handle_leave(args, config)

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


-- Function to handle the a command
local function handle_command(command, args)

    -- Call the function to get the item group
    local item_group = get_item_group()

    -- If no item group is returned, exit the function
    if not item_group then return end

    -- If the item group is the selected items
    if item_group == ItemGroup.Selected then

        -- Emit the command to operate on the selected items
        ya.manager_emit(command, args)

    -- If the item group is the hovered item
    elseif item_group == ItemGroup.Hovered then

        -- Emit the command with the hovered option
        ya.manager_emit(command, merge_tables(args, { hovered = true }))

    -- Otherwise, exit the function
    else return end
end


-- Function to handle a shell command
local function handle_shell_command(command, args)

    -- Call the function to get the item group
    local item_group = get_item_group()

    -- If no item group is returned, exit the function
    if not item_group then return end

    -- If the item group is the selected items
    if item_group == ItemGroup.Selected then

        -- Merge the arguments for the shell command with additional ones
        args = merge_tables({
            command .. " $@",
            confirm = true,
            block = true,
        }, args)

        -- Emit the command to operate the selected items
        ya.manager_emit("shell", args)

    -- If the item group is the hovered item
    elseif item_group == ItemGroup.Hovered then

        -- Merge the arguments for the shell command with additional ones
        args = merge_tables({
            command .. " $0",
            confirm = true,
            block = true,
        }, args)

        -- Emit the command to operate on the hovered item
        ya.manager_emit("shell", args)

    -- Otherwise, exit the function
    else return end
end


-- Function to handle the paste command
local function handle_paste(args, config)

    -- If the hovered item is a directory and smart paste is wanted
    if hovered_item_is_dir() and (config.smart_paste or args.smart) then

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


-- Function to do the wraparound for the arrow command
local wraparound_arrow = ya.sync(function(_, args)

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
    ya.manager_emit("arrow", merge_tables(
        args,
        { new_cursor_index - current_tab.cursor }
    ))
end)


-- Function to handle the arrow command
local function handle_arrow(args, config)

    -- If wraparound file navigation isn't wanted,
    -- then execute the arrow command
    if not config.wraparound_file_navigation then
        ya.manager_emit("arrow", args)

    -- Otherwise, call the wraparound arrow function
    else wraparound_arrow(args) end
end


-- Function to execute the parent arrow command
local execute_parent_arrow_command = ya.sync(
    function(state, args, number_of_directories)

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

            -- Get the new cursor index by adding the step,
            -- and modding the whole thing by the number of
            -- directories given.
            new_cursor_index = (parent_directory.cursor + step)
                % number_of_directories
        else

            -- Otherwise, get the new cursor index normally.
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

            -- Emit the command to change directory
            -- to the target directory
            ya.manager_emit("cd", { target_directory.url })
        end
    end
)


-- Function to handle the parent arrow command
local function handle_parent_arrow(args, config)

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
    local output, _ = ls_command(
        parent_directory_path,
        config.ignore_hidden_items
    )

    -- If there is no output, exit the function
    if not output then return end

    -- Get the item in the parent directory
    local directory_items = string_split(output.stdout, "\n")

    -- Initialise the number of directories
    local number_of_directories = 0

    -- Iterate over the directory items
    for _, item in ipairs(directory_items) do

        -- If the item is a directory
        if item:match(is_directory_pattern) then

            -- Increment the number of directories by 1
            number_of_directories = number_of_directories + 1

        -- Otherwise, break out of the loop,
        -- as the directories are grouped together
        else break end
    end

    -- Call the function to execute the parent arrow command
    execute_parent_arrow_command(args, number_of_directories)
end


-- Function to handle the pager command
local function handle_pager(args)

    -- Call the function to get the item group
    local item_group = get_item_group()

    -- If no item group is returned, exit the function
    if not item_group then return end

    -- If the item group is the selected items,
    -- then execute the command and exit the function
    if item_group == ItemGroup.Selected then

        -- Combine the arguments with additional ones
        args = merge_tables({
            "$PAGER $@",
            confirm = true,
            block = true
        }, args)

        -- Emit the command and exit the function
        return ya.manager_emit("shell", args)
    end

    -- Otherwise, the item group is the hovered item,
    -- and if the hovered item is a directory, exit the function
    if hovered_item_is_dir() then return

    -- Otherwise
    else

        -- Combine the arguments with additional ones
        args = merge_tables({
            "$PAGER $0",
            confirm = true,
            block = true
        }, args)

        -- Emit the command and exit the function
        return ya.manager_emit("shell", args)
    end
end


-- Function to run the commands given
local function run_command_func(command, args, config)

    -- The command table
    local command_table = {
        [Commands.Open] = handle_open,
        [Commands.Enter] = handle_enter,
        [Commands.Leave] = handle_leave,
        [Commands.Rename] = function(_)
            handle_command("rename", args)
        end,
        [Commands.Remove] = function(_)
            handle_command("remove", args)
        end,
        [Commands.Paste] = handle_paste,
        [Commands.Arrow] = handle_arrow,
        [Commands.ParentArrow] = handle_parent_arrow,
        [Commands.Editor] = function(_)
            handle_shell_command("$EDITOR", args)
        end,
        [Commands.Pager] = handle_pager,
    }

    -- Get the function for the command
    local command_func = command_table[command]

    -- If the function isn't found, notify the user and exit the function
    if not command_func then
        return ya.notify(
            merge_tables(DEFAULT_NOTIFICATION_OPTIONS, {
                content = "Unknown command: " .. command,
                level = "error"
            })
        )
    end

    -- Parse the arguments and set it to the args variable
    args = parse_args(args)

    -- Otherwise, call the function for the command
    command_func(args, config, command_table)
end

-- The setup function to setup the plugin
local function setup(_, opts)

    -- Initialise the configuration with the default configuration
    initialise_config(opts)
end


-- The function to be called to use the plugin
local function entry(_, args)

    -- Gets the command passed to the plugin
    local command = args[1]

    -- If the command isn't given, exit the function
    if not command then return end

    -- Gets the configuration object
    local config = get_config()

    -- If the configuration hasn't been initialised,
    -- then initialise the configuration
    if not config then
        config = initialise_config()
    end

    -- Call the function to handle the commands
    run_command_func(command, args, config)
end

-- Returns the table required for Yazi to run the plugin
return {
    setup = setup,
    entry = entry,
}
