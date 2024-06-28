-- Plugin to make some Yazi commands smarter

-- The default configuration for the plugin
local DEFAULT_CONFIG = {
    prompt = false,
    smart_enter = true,
    enter_archives = true,
    must_have_hovered_item = true,
    bypass_single_subdirectory_on_enter = true,
    bypass_single_subdirectory_on_leave = true,
    use_workaround = true,
}

-- The default notification options for this plugin
local DEFAULT_NOTIFICATION_OPTIONS = {
    title = "Smarter Commands Plugin",
    timeout = 5.0
}

-- The default input options for this plugin
local DEFAULT_INPUT_OPTIONS = {
    position = { "center", w = 50 }
}

-- The enum for which group of files to operate on
local FileGroup = {
    Hovered = "hovered",
    Selected = "selected",
    Prompt = "prompt"
}

-- The pattern to remove the double dash from the front of the argument
local remove_double_dash_pattern = "^%-%-"

-- The pattern to split the arguments at the = character
local split_argument_pattern = "([^=]*)=([^=]*)"


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

            -- Remove the double dash from the front of the argument
            local cleaned_argument =
                argument:gsub(remove_double_dash_pattern, "")

            -- Split the arguments at the = character
            local arg_name, arg_value =
                cleaned_argument:match(split_argument_pattern)

            -- If the argument name is nil
            if arg_name == nil then

                -- Set the argument name to the cleaned argument
                arg_name = cleaned_argument

                -- Set the argument value to true
                arg_value = true
            end

            -- Add the argument name and value to the options
            options[arg_name] = arg_value
        end

    end

    -- Return the table of options
    return options
end


-- Function to handle the enter command
local handle_enter = ya.sync(function(state, args)

    -- If there bypassing a single subdirectory isn't wanted,
    -- then simply emit the enter command.
    if not state.config.bypass_single_subdirectory_on_enter then
        return ya.manager_emit("enter", args)
    end

    -- Start an infinite loop
    while true do

        -- Emit the command
        ya.manager_emit("enter", args)

        -- Get the hovered item
        local hovered_item = cx.active.current.hovered

        -- If the hovered item is not a directory and there are other
        -- files in the directory as the hovered item, exit the function
        if not hovered_item.cha.is_dir and #cx.active.current.files ~= 1 then
            return
        end
    end
end)


-- Function to handle the leave command
local handle_leave = ya.sync(function(state, args)

    -- If there bypassing a single subdirectory isn't wanted,
    -- then simply emit the leave command.
    if not state.config.bypass_single_subdirectory_on_leave then
        return ya.manager_emit("leave", args)
    end

    -- Start an infinite loop
    while true do

        -- Emit the command
        ya.manager_emit("leave", args)

        -- Get the parent folder
        local parent_folder = cx.active.parent

        -- If there are more than one file in the parent folder,
        -- exit the function
        if parent_folder.files ~= 1 then return end
    end
end)


-- Function to choose which group of files to operate on.
-- It returns FileGroup.Hovered for the hovered file,
-- FileGroup.Selected for the selected files,
-- and FileGroup.Prompt to tell the calling function
-- to prompt the user.
local get_file_group_from_state = ya.sync(function(state)

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

        -- Otherwise, return the enum for the selected files
        else return FileGroup.Selected end

    -- Otherwise, there is a hovered item
    -- and if there are no selected items,
    -- return the enum for the hovered item.
    elseif no_selected_items then return FileGroup.Hovered

    -- Otherwise if there are selected items and the user wants a prompt,
    -- then tells the calling function to prompt them
    elseif state.config.prompt then
        return FileGroup.Prompt

    -- Otherwise, if the hovered item is selected,
    -- then return the enum for the selected files
    elseif hovered_item:is_selected() then return FileGroup.Selected

    -- Otherwise, return the enum for the hovered file
    else return FileGroup.Hovered end
end)


-- Function to prompt the user for their desired file group
local function prompt_for_desired_file_group()

    -- Prompt the user for their input
    local user_input, event = ya.input(merge_tables(DEFAULT_INPUT_OPTIONS, {
        title = "Operate on the hovered item? (y/N)"
    }))

    -- Lowercase the user's input
    user_input = user_input:lower()

    -- If the user did not confirm the input, exit the function
    if event ~= 1 then return

    -- Otherwise, if the user's input starts with "y",
    -- return the file group representing the hovered file
    elseif user_input:find("^y") then return FileGroup.Hovered

    -- Otherwise, if the user's input starts with "n",
    -- return the file group representing the selected files
    elseif user_input:find("^n") then return FileGroup.Selected

    -- Otherwise, exit the function
    else return end
end


-- Function to get the file group
local function get_file_group()

    -- Get the file group from the state
    local file_group = get_file_group_from_state()

    -- If the file group isn't the prompt one,
    -- then return the file group immediately
    if file_group ~= FileGroup.Prompt then return file_group

    -- Otherwise, prompt the user for the desired file group
    else return prompt_for_desired_file_group() end
end


-- The function to run a command on only the hovered item.
-- This is a workaround until Yazi is updated with the commit
-- that implements the hovered option for the rename and remove command.
-- This only runs if the use_workaround option is turned on.
local run_command_on_hovered_item = ya.sync(function(_, command, args)

    -- Gets the currently selected files
    local selected_files = cx.active.selected

    -- Emit the escape command to clear all selected files
    ya.manager_emit("escape", { select = true })

    -- Run the intended command
    ya.manager_emit(command, args)

    -- Reselect all of the selected files
    cx.active.selected = selected_files
end)


-- Function to handle the a command
local function handle_command(command, args, config)

    -- Call the function to get the file group
    local file_group = get_file_group()

    -- If no file group is returned, exit the function
    if not file_group then return end

    -- If the file group is the selected items
    if file_group == FileGroup.Selected then

        -- Emit the command to operate on the selected items
        ya.manager_emit(command, args)

    -- If the file group is the hovered item
    elseif file_group == FileGroup.Hovered then

        -- If the function is rename or remove and
        -- configuration is set to use the workaround
        -- then use the workaround to run the command
        if
            list_contains({ "remove", "rename" }, command)
            and config.use_workaround
        then
            run_command_on_hovered_item(command, args)

        -- Otherwise, emit the command with the hovered option
        else
            ya.manager_emit(command, merge_tables(args, { hovered = true }))
        end

    -- Otherwise, exit the function
    else return end
end


-- Function to handle a shell command
local function handle_shell_command(command, args)

    -- Call the function to get the file group
    local file_group = get_file_group()

    -- If no file group is returned, exit the function
    if not file_group then return end

    -- Merge the arguments for the shell command with additional ones
    args = merge_tables(args, { confirm = true, block = true })

    -- If the file group is the selected items
    if file_group == FileGroup.Selected then

        -- Emit the command to operate the selected items
        ya.manager_emit('shell "' .. command .. ' $@"', args)

    -- If the file group is the hovered item
    elseif file_group == FileGroup.Hovered then

        -- Emit the command to operate on the hovered item
        ya.manager_emit('shell "' .. command .. ' $0"', args)
        ya.err("Command emitted")

    -- Otherwise, exit the function
    else return end
end


-- Function to execute the pager command
local execute_pager_command = ya.sync(function(_, args, file_group)

    -- If the file group is the selected files,
    -- then execute the command and exit the function
    if file_group == FileGroup.Selected then
        return ya.manager_emit('shell "$PAGER $@"', args)
    end

    -- Otherwise, the file group is the hovered item,
    -- so if the hovered item is a directory, exit the function
    if cx.active.current.hovered.cha.is_dir then return

    -- Otherwise, execute the command and exit the function
    else
        ya.manager_emit('shell "$PAGER $0"', args)
    end
end)


-- Function to handle the pager command
local function handle_pager(args)

    -- Call the function to get the file group
    local file_group = get_file_group()

    -- If no file group is returned, exit the function
    if not file_group then return end

    -- Otherwise, combine the arguments with additional ones
    args = merge_tables(args, { confirm = true, block = true })

    -- Execute the pager command
    execute_pager_command(args, file_group)
end


-- Function to run the commands given
local function run_command_func(command, args, config)

    -- The command table
    local command_table = {

        -- Set the enter command to the
        -- open command when smart entering is wanted
        enter = config.smart_enter and handle_open or handle_enter,
        leave = handle_leave,
        rename = function(_) handle_command("rename", args, config) end,
        remove = function(_) handle_command("remove", args, config) end,
        editor = function(_) handle_shell_command("$EDITOR", args) end,
        pager = handle_pager,
        open = handle_open,
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
    command_func(args)
end

-- The setup function to setup the plugin
local function setup(state, opts)

    -- Initialise the configuration with the default configuration
    state.config = merge_tables(DEFAULT_CONFIG, opts)
end


-- The function to be called to use the plugin
local function entry(state, args)

    -- Gets the command passed to the plugin
    local command = args[1]

    -- If the command isn't given, exit the function
    if not command then return end

    -- If the configuration hasn't been initialised,
    -- then set the configuration to the default configuration
    if not state.config then
        state.config = merge_tables(DEFAULT_CONFIG)
    end

    -- Call the function to handle the commands
    run_command_func(command, args, state.config)
end

-- Returns the table required for Yazi to run the plugin
return {
    setup = setup,
    entry = entry,
}
