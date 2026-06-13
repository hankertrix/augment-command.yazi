--- @since 26.5.6

-- The module to handle the open command

-- Import the utilities module
local utils = require(".utils")

-- Import the required constants
local ItemGroup = require(".constants").ItemGroup

-- The module table
local M = {}

-- Function to handle the open command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and configuration for the plugin
	local args, config = require("augment-command").parse_args_and_init(job)

	-- Call the function to get the item group
	local item_group = utils.get_item_group(config)

	-- If no item group is returned, exit the function
	if not item_group then return end

	-- If the item group is the selected items,
	-- then execute the command and exit the function
	if item_group == ItemGroup.Selected then

		-- Emit the command and exit the function
		return ya.emit("open", args)
	end

	-- If the hovered item is a directory
	if utils.hovered_item_is_dir() then

		-- If smart enter is wanted,
		-- calls the function to enter the directory
		-- and exit the function
		if config.smart_enter or utils.table_pop(args, "smart", false) then
			return utils.emit_augmented_command("enter", args)
		end

		-- Otherwise, just exit the function
		return
	end

	-- Otherwise, if the hovered item is not an archive,
	-- or entering archives isn't wanted,
	-- or the interactive flag is passed
	if
		not require(".utils-archive").hovered_item_is_archive()
		or not config.enter_archives
		or args.interactive
	then

		-- Simply emit the open command,
		-- opening only the hovered item
		-- as the item group is the hovered item,
		-- and exit the function
		return ya.emit("open", utils.merge_tables({}, args, { hovered = true }))
	end

	-- Otherwise, the hovered item is an archive
	-- and entering archives is wanted,
	-- so get the path of the hovered item
	local archive_path = utils.get_path_of_hovered_item()

	-- If the archive path somehow doesn't exist, then exit the function
	if not archive_path then return end

	-- Get the parent directory of the hovered item
	local parent_directory_url = Url(archive_path).parent

	-- If the parent directory doesn't exist, then exit the function
	if not parent_directory_url then return end

	-- Emit the command to extract the archive
	-- and reveal the extracted items
	utils.emit_augmented_command(
		"extract",
		utils.merge_tables({}, args, {
			archive_path = ya.quote(archive_path),
			reveal = true,
			parent_dir = ya.quote(tostring(parent_directory_url.path)),
		})
	)
end

-- Return the module table
return M
