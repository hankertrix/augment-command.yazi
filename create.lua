--- @since 26.5.6

-- The module to handle the create command

-- Import the utilities module
local utils = require(".utils")

-- Import the required constants
local ConfigurableComponents = require(".constants").ConfigurableComponents

-- The module table
local M = {}

-- Function to enter or open the created file
---@param item_url Url The url of the item to create
---@param is_directory boolean? Whether the item to create is a directory
---@param args ParsedArgs The arguments passed to the plugin
---@param config Configuration The configuration object
---@return nil
local function enter_or_open_created_item(item_url, is_directory, args, config)

	-- If the item is a directory
	if is_directory then

		-- If user does not want to enter the directory
		-- after creating it, exit the function
		if
			not (
				config.enter_directory_after_creation
				or utils.table_pop(args, "enter", false)
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
		not (
			config.open_file_after_creation
			or utils.table_pop(args, "open", false)
		)
	then
		return
	end

	-- Call the function to open the file
	return ya.emit("open", { hovered = true })
end

-- Function to execute the create command
---@param item_url Url The url of the item to create
---@param is_directory boolean Whether the item to create is a directory
---@param args ParsedArgs The arguments passed to the plugin
---@param config Configuration The configuration object
---@return nil
local function exec(item_url, is_directory, args, config)

	-- Get the parent directory of the file to create
	local parent_directory_url = item_url.parent

	-- If the parent directory doesn't exist,
	-- then show an error and exit the function
	if not parent_directory_url then
		return utils.throw_error(
			"Parent directory of the item to create doesn't exist"
		)
	end

	-- If the item to create is a directory
	if is_directory then

		-- Call the function to create the directory
		local successful, error_message = fs.create("dir_all", item_url)

		-- If the function is not successful,
		-- show the error message and exit the function
		if not successful then return utils.throw_error(error_message) end

	-- Otherwise, the item to create is a file
	else

		-- Create the parent directory if it doesn't exist
		if not fs.cha(parent_directory_url, false) then

			-- Call the function to create the parent directory
			local successful, error_message =
				fs.create("dir_all", parent_directory_url)

			-- If the function is not successful,
			-- show the error message and exit the function
			if not successful then return utils.throw_error(error_message) end
		end

		-- Create the file
		local successful, error_message = fs.write(item_url, "")

		-- If the function is not successful,
		-- show the error message and exit the function
		if not successful then return utils.throw_error(error_message) end
	end

	-- Wait for the path to exist in Yazi before revealing it
	utils.wait_until_path_exists_in_yazi(tostring(item_url.path))

	-- Reveal the created item
	ya.emit("reveal", { tostring(item_url.path) })

	-- Call the function to enter or open the created item
	enter_or_open_created_item(item_url, is_directory, args, config)
end

-- Function to handle the create command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- Get the directory flag
	local dir_flag = utils.table_pop(args, "dir", false)

	-- Get the user's input options for the create command
	local create_input_options = utils.get_user_input_or_confirm_options(
		ConfigurableComponents.BuiltIn.Create,
		{ prompts = { "Create:", "Create (dir):" } },
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
	local current_working_directory = Url(utils.get_current_directory())

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
			or utils.table_pop(args, "default_behaviour", false)
		)
	then

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
	if
		fs.cha(full_url, false) and not utils.table_pop(args, "force", false)
	then

		-- Get whether the user wants to overwrite the file
		local should_overwrite = utils.show_overwrite_prompt(full_url.path)

		-- If the user does not want to overwrite the file,
		-- then exit the function
		if not should_overwrite then return end
	end

	-- Call the function to execute the create command
	return exec(full_url, is_directory, args, config)
end

-- Return the module table
return M
