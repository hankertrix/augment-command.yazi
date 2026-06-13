--- @since 26.5.6

-- The module to handle the extract command

-- Import the utilities module
local utils = require(".utils")

-- Import the configuration module
local utils_config = require("augment-command")

-- Import the required constants
local ItemGroup = require(".constants").ItemGroup

-- Import the archive utilities
local archive_utils = require(".utils-archive")

-- The module table
local M = {
	name = "extract",
}

-- Function to get the archive paths for the extract command
---@param args ParsedArgs The arguments passed to the plugin
---@param config Configuration The configuration object
---@return string|string[]? archive_paths The archive paths
local function get_archive_paths(args, config)

	-- Get the archive path from the arguments given
	local archive_path = utils.table_pop(args, "archive_path")

	-- If the archive path is given, return it immediately
	if archive_path then return archive_path end

	-- Otherwise, get the item group
	local item_group = utils.get_item_group(config)

	-- If there is no item group
	if not item_group then return end

	-- If the item group is the hovered item
	if item_group == ItemGroup.Hovered then

		-- Get the hovered item path
		local hovered_item_path = utils.get_path_of_hovered_item(true)

		-- If the hovered item path is nil, exit the function
		if not hovered_item_path then return end

		-- Otherwise, return the hovered item path
		return hovered_item_path
	end

	-- Otherwise, if the item group is the selected items
	if item_group == ItemGroup.Selected then

		-- Get the list of selected items
		local selected_items = utils.get_paths_of_selected_items(true)

		-- If there are no selected items, exit the function
		if not selected_items then return end

		-- Otherwise, return the list of selected items
		return selected_items
	end
end

-- Function to handle the extract command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = utils_config.parse_args_and_init(job)

	-- Get the archive paths
	local archive_paths = get_archive_paths(args, config)

	-- Get the destination path from the arguments given
	---@type string
	local destination_path = utils.table_pop(args, "destination_path")

	-- If there are no archive paths, exit the function
	if not archive_paths then return end

	-- If the archive path is a list
	if type(archive_paths) == "table" then

		-- Iterate over the archive paths
		-- and call the extract command on them
		for _, archive_path in ipairs(archive_paths) do
			utils.emit_augmented_command(
				"extract",
				utils.merge_tables({}, args, {
					archive_path = ya.quote(archive_path),
				})
			)
		end

		-- Exit the function
		return
	end

	-- Otherwise the archive path is a string
	---@type string
	local archive_path = archive_paths

	-- Call the function to recursively extract the archive
	local extraction_result = archive_utils.recursively_extract_archive(
		archive_path,
		args,
		config,
		destination_path
	)

	-- If the extraction is cancelled, then just exit the function
	if extraction_result.cancelled then return end

	-- Get the extracted items path
	local extracted_items_path = extraction_result.extracted_items_path

	-- If the extraction is not successful, notify the user
	if not extraction_result.successful or not extracted_items_path then
		return archive_utils.throw_archiver_error(extraction_result)
	end

	-- Get the url of the archive
	local archive_url = Url(archive_path)

	-- If the remove flag is passed
	if utils.table_pop(args, "remove", false) then

		-- If the current directory is protected
		if utils_config.current_directory_protected() then

			-- Show the delete confirmation prompt
			local user_confirmation = utils.show_delete_prompt(archive_path)

			-- If the user wants to delete the archive, delete it
			if user_confirmation then fs.remove("file", archive_url) end

		-- Otherwise, delete the archive
		else
			fs.remove("file", archive_url)
		end
	end

	-- If the reveal flag is passed
	if utils.table_pop(args, "reveal", false) then

		-- Get the url of the extracted items
		local extracted_items_url = Url(extracted_items_path)

		-- Get the parent directory of the extracted items
		local parent_directory_url = extracted_items_url.parent

		-- If the parent directory doesn't exist, then exit the function
		if not parent_directory_url then return end

		-- Get the given parent directory
		local given_parent_directory = utils.table_pop(args, "parent_dir")

		-- If there is a parent directory given but the parent directory
		-- of the extracted items isn't the same as the given one,
		-- exit the function
		if
			given_parent_directory
			and given_parent_directory ~= tostring(parent_directory_url.path)
		then
			return
		end

		-- Get the cha of the extracted item
		local extracted_items_cha = fs.cha(extracted_items_url, false)

		-- If the cha of the extracted item doesn't exist,
		-- exit the function
		if not extracted_items_cha then return end

		-- If the extracted item is not a directory
		if not extracted_items_cha.is_dir then

			-- Reveal the item and exit the function
			return ya.emit("reveal", { extracted_items_url })
		end

		-- Otherwise, change the directory to the extracted item.
		-- Note that extracted_items_url is destroyed here.
		ya.emit("cd", { extracted_items_url })

		-- If the user wants to skip single subdirectories on enter,
		-- and the no skip flag is not passed
		if
			config.skip_single_subdirectory_on_enter
			and not utils.table_pop(args, "no_skip", false)
		then

			-- Call the function to skip child directories
			utils.skip_single_child_directories(extracted_items_path)
		end
	end
end

-- Return the module table
return M
