--- @since 26.8.15

-- The module to handle the augment command

-- Get the utilities module
local utils = require(".utils")

-- Import the item group
local ItemGroup = require(".constants").ItemGroup

-- The module table
local M = {}

-- The function to augment a Yazi command to determine the item group
-- Function to handle a Yazi command
---@param command string A Yazi command
---@param args ParsedArgs The arguments passed to the plugin
---@param config Configuration The configuration object
---@param modify_args ModifyArgsFunction? Function to modify the arguments
---@return nil
function M.augment_yazi_command(command, args, config, modify_args)

	-- Call the function to get the item group
	local item_group = utils.get_item_group(config)

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
	local args, config = require(".main").parse_args_and_init(job)

	-- Get the command given by the user
	local given_command = table.remove(args, 1)

	-- Call the given command with item group handling
	return M.augment_yazi_command(given_command, args, config)
end

-- Return the module table
return M
