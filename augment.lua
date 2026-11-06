--- @since 26.8.15

-- The module to handle the augment command

-- Import the constants required
local constants = require(".constants")
local ItemGroup = constants.ItemGroup
local INPUT_OPTIONS_TABLE = constants.INPUT_OPTIONS_TABLE
local ConfigurableComponents = constants.ConfigurableComponents

-- Import the utilities module
local utils = require(".utils")

-- Import the configuration utilities
local config_utils = require(".config")

-- The module table
local M = {}

-- Function to choose which group of items to operate on.
-- It returns ItemGroup.Hovered for the hovered item,
-- ItemGroup.Selected for the selected items,
-- and ItemGroup.Prompt to tell the calling function
-- to prompt the user.
---@type fun(config: Configuration): ItemGroup? The desired item group
local get_item_group_from_state = ya.sync(function(_, config)

	-- Cast the configuration to the correct type
	---@cast config Configuration

	-- Get the hovered item
	local hovered_item = cx.active.current.hovered

	-- The boolean representing that there are no selected items
	local no_selected_items = #cx.active.selected == 0

	-- If the user wants to use Yazi's default item group,
	-- return the enum for the selected items and exit the function
	if config.use_yazi_item_group then return ItemGroup.Selected end

	-- If there is no hovered item
	if not hovered_item then

		-- If there are no selected items, exit the function
		if no_selected_items then
			return

		-- Otherwise, if the configuration is set to have a hovered item,
		-- exit the function
		elseif config.must_have_hovered_item then
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
	elseif config.prompt then
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
---@return ItemGroup? item_group The item group selected by the user
local function prompt_for_desired_item_group()

	-- Get the configuration
	local config = config_utils.get_config()

	-- Get the default item group
	---@type ItemGroup?
	local default_item_group = config.default_item_group_for_prompt

	-- Get the input options, which the (h/s) options
	local input_options = INPUT_OPTIONS_TABLE[default_item_group]

	-- If the default item group is none, then set it to nil
	if default_item_group == ItemGroup.None then default_item_group = nil end

	-- Get the user's input options for the item group prompt
	local item_group_input_options = utils.get_user_input_or_confirm_options(
		ConfigurableComponents.Plugin.ItemGroup,
		{ prompts = "Operate on hovered or selected items?" }
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
---@param config Configuration The configuration object
---@return ItemGroup? item_group The desired item group
function M.get_item_group(config)

	-- Get the item group from the state
	local item_group = get_item_group_from_state(config)

	-- If the item group isn't the prompt one,
	-- then return the item group immediately
	if item_group ~= ItemGroup.Prompt then
		return item_group

	-- Otherwise, prompt the user for the desired item group
	else
		return prompt_for_desired_item_group()
	end
end

-- The function to augment a Yazi command to determine the item group
-- Function to handle a Yazi command
---@param command string A Yazi command
---@param args ParsedArgs The arguments passed to the plugin
---@param config Configuration The configuration object
---@param modify_args ModifyArgsFunction? Function to modify the arguments
---@return nil
function M.augment_yazi_command(command, args, config, modify_args)

	-- Call the function to get the item group
	local item_group = M.get_item_group(config)

	-- If no item group is returned, exit the function
	if not item_group then return end

	-- If the item group is the selected items
	if item_group == ItemGroup.Selected then

		-- Modify the arguments if it is given
		-- and pass the paths of selected items
		if modify_args then
			args = modify_args(args, utils.get_paths_of_selected_items())
		end

		-- Emit the command to operate on the selected items
		ya.emit(command, args)

	-- If the item group is the hovered item
	elseif item_group == ItemGroup.Hovered then

		-- Modify the arguments if it is given
		-- and pass the paths of selected items
		if modify_args then
			args = modify_args(args, { utils.get_path_of_hovered_item() })
		end

		-- Get if the given command is the plugin command
		if command == "plugin" then

			-- Add the hovered option as a string argument
			table.insert(args, "--hovered")

		-- Otherwise, add the hovered option directly to the arguments
		else
			args = utils.merge_tables(args, { hovered = true })
		end

		-- Emit the command with the hovered option
		ya.emit(command, args)
	end
end

-- The function to handle the augment command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = config_utils.parse_args_and_init(job)

	-- Get the command given by the user
	local given_command = table.remove(args, 1)

	-- Call the given command with item group handling
	return M.augment_yazi_command(given_command, args, config)
end

-- Return the module table
return M
