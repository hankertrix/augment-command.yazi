--- @since 26.8.15

-- The module to handle the create command

-- Import the utilities module
local utils = require(".utils")

-- Import the required constants
local ConfigurableComponents = require(".constants").ConfigurableComponents

-- The module table
local M = {}

-- Function to enter or open the created file
---@param item_url Url The url of the created item
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

		-- Wait until the directory exists in Yazi
		utils.wait_until_path_exists_in_yazi(item_url)

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

	-- Wait until the file exists in Yazi
	utils.wait_until_path_exists_in_yazi(item_url)

	-- Call the function to open the file
	return ya.emit("open", { hovered = true })
end

-- Function to handle the create command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require(".main").parse_args_and_init(job)

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

	-- Get the position of the path delimiter
	local path_delimiter_position = user_input:find("[/\\]$")

	-- Initialise if the is_directory variable
	local is_directory = dir_flag

	-- If the path delimiter position exists,
	-- set the is_directory variable to true
	if path_delimiter_position then is_directory = true end

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

	-- Create the item
	ya.emit("create", { user_input, dir = is_directory })

	-- Call the function to enter or open the created item
	enter_or_open_created_item(
		utils.get_current_directory():join(user_input),
		is_directory,
		args,
		config
	)
end

-- Return the module table
return M
