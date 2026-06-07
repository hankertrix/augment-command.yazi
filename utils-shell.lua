-- The module containing the utilities to deal with shell commands

-- Import the utilities module
local utils = require(".utils")

-- Import the constants required
local ItemGroup = require(".constants").ItemGroup

-- The module table
local M = {}

-- The pattern to get the shell variables in a command
---@type string
local shell_variable_pattern = "%%[hs]%d?"

-- The pattern to match the pager argument for the bat command
---@type string
local bat_pager_pattern = "(%-%-pager)%s+(%S+)"

-- The default bat pager command without the -F flag
---@type string
local bat_default_pager_command_without_f_flag = "less -RX"

-- Function to match a binary name against a search string
---@param binary_name string The name of the binary
---@param search_string string The string to search for the binary name
---@return string binary_pattern The pattern for the binary
---@return string? binary_path The path to the binary
local function match_binary_name(binary_name, search_string)

	-- The binary pattern
	local binary_pattern = "%f[%w_%-%.].*" .. binary_name .. "%f[%W%s]"

	-- Get the binary path
	local binary_path = search_string:match(binary_pattern)

	-- Escape the binary path if it's not nil
	if binary_path ~= nil then
		binary_path = utils.escape_replacement_string(binary_path)
	end

	-- Return the binary pattern and the path
	return binary_pattern, binary_path
end

-- Function to remove the F flag from the less command
---@param command string The shell command containing the less command
---@param less_binary_pattern string The pattern to match the less binary
---@return string command The command with the F flag removed
---@return boolean f_flag_found Whether the F flag was found
local function remove_f_flag_from_less_command(command, less_binary_pattern)

	-- Initialise the variable to store if the F flag is found
	local f_flag_found = false

	-- Initialise the variable to store the replacement count
	local replacement_count = 0

	-- Initialised the modified command
	local modified_command = command

	-- Remove the F flag when it is passed at the start
	-- of the flags given to the less command
	modified_command, replacement_count =
		modified_command:gsub("(" .. less_binary_pattern .. ".*)%-F", "%1")

	-- If the replacement count is not 0,
	-- set the f_flag_found variable to true
	if replacement_count ~= 0 then f_flag_found = true end

	-- Remove the F flag when it is passed in the middle
	-- or end of the flags given to the less command command
	modified_command, replacement_count = modified_command:gsub(
		"(" .. less_binary_pattern .. ".*%-)(%a*)F(%a*)",
		"%1%2%3"
	)

	-- If the replacement count is not 0,
	-- set the f_flag_found variable to true
	if replacement_count ~= 0 then f_flag_found = true end

	-- Return the command and whether or not the F flag was found
	return modified_command, f_flag_found
end

-- Function to fix a command containing less.
-- All this function does is remove
-- the F flag from a command containing less.
---@param command string The shell command containing the less command
---@param less_binary_pattern string The pattern to match the less binary
---@param less_binary_path string The path to the less binary
---@return string command The fixed shell command
local function fix_shell_command_containing_less(
	command,
	less_binary_pattern,
	less_binary_path
)

	-- Remove the F flag from the given command
	local fixed_command =
		remove_f_flag_from_less_command(command, less_binary_pattern)

	-- Get the LESS environment variable
	local less_environment_variable = os.getenv("LESS")

	-- If the LESS environment variable is not set,
	-- then return the given command with the F flag removed
	if not less_environment_variable then return fixed_command end

	-- Otherwise, remove the F flag from the LESS environment variable
	-- and check if the F flag was found
	local less_command_with_modified_env_variables, f_flag_found =
		remove_f_flag_from_less_command(
			string.format("%s %s", less_binary_path, less_environment_variable),
			less_binary_pattern
		)

	-- If the F flag isn't found,
	-- then return the given command with the F flag removed
	if not f_flag_found then return fixed_command end

	-- Add the less environment variable flags to the less command
	fixed_command = fixed_command:gsub(
		less_binary_pattern,
		utils.escape_replacement_string(
			less_command_with_modified_env_variables
		)
	)

	-- Unset the LESS environment variable before calling the command
	fixed_command = "unset LESS; " .. fixed_command

	-- Return the fixed command
	return fixed_command
end

-- Function to fix the bat default pager command
---@param command string The command containing the bat default pager command
---@param bat_binary_pattern string The pattern to match the bat binary
---@param bat_binary_path string The path to the bat binary
---@return string command The fixed bat command
local function fix_shell_command_containing_bat(
	command,
	bat_binary_pattern,
	bat_binary_path
)

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

	-- Replace the bat command with the command to use
	-- the bat default pager command without the F flag
	local modified_command = command:gsub(
		bat_binary_pattern,
		string.format(
			"%s --pager '%s'",
			bat_binary_path,
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

	-- Get the bat binary pattern and path from the command
	local bat_binary_pattern, bat_binary_path =
		match_binary_name("bat", command)

	-- Initialise the fixed command
	local fixed_command = command

	-- If the bat binary is in the command
	if bat_binary_path ~= nil then

		-- Calls the command to fix the bat command
		fixed_command = fix_shell_command_containing_bat(
			command,
			bat_binary_pattern,
			bat_binary_path
		)
	end

	-- Get the less binary pattern and path from the fixed command
	local less_binary_pattern, less_binary_path =
		match_binary_name("less", fixed_command)

	-- If the less binary is in the command
	if less_binary_path ~= nil then

		-- Fix the command containing less
		fixed_command = fix_shell_command_containing_less(
			fixed_command,
			less_binary_pattern,
			less_binary_path
		)
	end

	-- Return the fixed command
	return fixed_command
end

-- Function to handle a shell command
---@param args ParsedArgs The arguments to pass to the command
---@param config Configuration The configuration object
function M.handle(args, config)

	-- Get the first item of the arguments given
	-- and set it to the command variable
	local command = table.remove(args, 1)

	-- Get the type of the command variable
	local command_type = type(command)

	-- If the command isn't a string,
	-- show an error message and exit the function
	if command_type ~= "string" then
		return utils.throw_error(
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
	local item_group = utils.get_item_group(config)

	-- If no item group is returned, exit the function
	if not item_group then return end

	-- Get whether the exit if directory flag is passed
	local exit_if_dir = utils.table_pop(args, "exit_if_dir", false)

	-- If the item group is the selected items
	if item_group == ItemGroup.Selected then

		-- Get the paths of the selected items
		local selected_items = utils.get_paths_of_selected_items(true)

		-- If there are no selected items, exit the function
		if not selected_items then return end

		-- If the exit if directory flag is passed
		if exit_if_dir then

			-- Initialise the number of files
			local number_of_files = 0

			-- Iterate over all of the selected items
			for _, item in pairs(selected_items) do

				-- Get the cha object of the item
				local item_cha = fs.cha(Url(item), false)

				-- If the item isn't a directory
				if not (item_cha or {}).is_dir then

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
			utils.escape_replacement_string(table.concat(selected_items, " "))
		)

	-- If the item group is the hovered item
	elseif item_group == ItemGroup.Hovered then

		-- Get the hovered item path
		local hovered_item_path = utils.get_path_of_hovered_item(true)

		-- If the hovered item path is nil, exit the function
		if not hovered_item_path then return end

		-- If the exit if directory flag is passed,
		-- and the hovered item is a directory,
		-- then exit the function
		if exit_if_dir and utils.hovered_item_is_dir() then return end

		-- Replace the shell variable in the command
		-- with the quoted path of the hovered item
		command = command:gsub(
			shell_variable_pattern,
			utils.escape_replacement_string(hovered_item_path)
		)

	-- Otherwise, exit the function
	else
		return
	end

	-- Merge the command back into the arguments given
	args = utils.merge_tables({ command }, args)

	-- Emit the command to operate on the hovered item
	ya.emit("shell", args)
end

-- Return the module table
return M
