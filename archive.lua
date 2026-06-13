--- @since 26.5.6

-- The module to handle the archive command

-- Import the utilities module
local utils = require(".utils")

-- Import the configuration module
local utils_config = require("augment-command")

-- Import the required constants
local constants = require(".constants")
local ItemGroup = constants.ItemGroup
local ConfigurableComponents = constants.ConfigurableComponents

-- Import the archive module
local archive_utils = require(".utils-archive")
local ArchiverCommands = archive_utils.ArchiverCommands

-- The module table
local M = {}

-- Function to delete files and directories
---@param item_paths string[] The paths to the items to remove
---@return nil
local function delete_items(item_paths)

	-- Iterate over the item paths
	for _, item_path in ipairs(item_paths) do

		-- Get the url of the item
		local item_url = Url(item_path)

		-- Get the cha of the item
		local item_cha = fs.cha(item_url, false)

		-- If the item is a directory
		if item_cha and item_cha.is_dir then

			-- Remove everything
			fs.remove("dir_all", item_url)

		-- Otherwise, remove the file
		else
			fs.remove("file", item_url)
		end
	end
end

-- Function to handle the archive command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = utils_config.parse_args_and_init(job)

	-- Get the item group
	local item_group = utils.get_item_group(config)

	-- If there is no item group, exit the function
	if not item_group then return end

	-- Initialise the paths to the items to add to the archive
	local item_paths = nil

	-- If the item group is the selected items
	if item_group == ItemGroup.Selected then
		item_paths = utils.get_paths_of_selected_items()

	-- Otherwise, the item group is the hovered item
	else

		-- Get the hovered item
		local hovered_item_path = utils.get_path_of_hovered_item()

		-- If the hovered item is nil somehow, then exit the function
		if hovered_item_path == nil then return end

		-- Otherwise, set the item paths to the hovered item
		item_paths = { hovered_item_path }
	end

	-- If the item paths is nil, exit the function
	if not item_paths then return end

	-- Get the user's archive input options
	local archive_input_options = utils.get_user_input_or_confirm_options(
		ConfigurableComponents.Plugin.Archive,
		{ prompts = "Archive name:" }
	)

	-- Get the user's input
	---@cast archive_input_options YaziInputOptions
	local user_input, event = ya.input(archive_input_options)

	-- If the user did not confirm the input,
	-- exit the function
	if event ~= 1 then return end

	-- Get the archive path
	local archive_path = user_input or ""

	-- If the archive path is empty
	if #utils.string_trim(archive_path) < 1 then

		-- If the item group is not the hovered item,
		-- exit the function
		if item_group ~= ItemGroup.Hovered then return end

		-- Otherwise, get the path of the hovered item
		local hovered_item_path = table.unpack(item_paths)

		-- Set the archive name to the hovered item path
		-- plus the zip extension
		archive_path = hovered_item_path .. ".zip"
	end

	-- If the archive path doesn't have a file extension,
	-- add the ".zip" file extension
	if not Url(archive_path).ext then archive_path = archive_path .. ".zip" end

	-- Get the full url of the archive path
	local archive_url = Url(utils.get_current_directory()):join(archive_path)

	-- Get the full archive path from the url
	archive_path = tostring(archive_url.path)

	-- If the archive already exists and the force flag isn't passed
	if
		fs.cha(archive_url, false) and not utils.table_pop(args, "force", false)
	then

		-- Get whether the user wants to overwrite the existing file
		local should_overwrite = utils.show_overwrite_prompt(archive_url.path)

		-- If the user doesn't want to overwrite the file, exit the function
		if not should_overwrite then return end
	end

	-- Get the archiver
	local archiver, get_archiver_results = archive_utils.get_archiver(
		archive_path,
		ArchiverCommands.Archive,
		config
	)

	-- If the archiver can't be instantiated,
	-- show the error and exit the function
	if not archiver then
		return archive_utils.throw_archiver_error(get_archiver_results)
	end

	-- Initialise the password
	local password = nil

	-- If the user wants to encrypt the archive
	if config.encrypt_archives or utils.table_pop(args, "encrypt", false) then

		-- Function to get the user's archive password options
		---@type GetPasswordOptions
		local function get_user_archive_password_options(is_confirm_password)

			-- Get the user's archive password options
			local archive_password_options =
				utils.get_user_input_or_confirm_options(
					ConfigurableComponents.Plugin.ArchivePassword,
					{
						prompts = {
							"Archive password:",
							"Confirm archive password:",
						},
					},
					false,
					is_confirm_password and 2 or 1
				)

			-- Return the user's archive password options
			---@cast archive_password_options YaziInputOptions
			return archive_password_options
		end

		-- Get the user's password
		password = utils.get_password(get_user_archive_password_options, true)
	end

	-- Get whether to encrypt the headers or not
	local encrypt_headers = archive_utils.archive_supports_header_encryption(
		archive_url,
		password
			and (
				config.encrypt_archive_headers
				or utils.table_pop(args, "encrypt_headers", false)
			)
	)

	-- Call the function to add items to an archive
	local archiver_result =
		archiver:archive(item_paths, password, encrypt_headers)

	-- If the archiver is not successful,
	-- show the error and exit the function
	if not archiver_result.successful then
		return archive_utils.throw_archiver_error(archiver_result)
	end

	-- If the user wants to remove archived files
	if
		config.remove_archived_files or utils.table_pop(args, "remove", false)
	then

		-- If the current directory is protected
		if utils_config.current_directory_protected() then

			-- Show the delete confirmation prompt
			local user_confirmation = utils.show_delete_prompt(item_paths)

			-- If the user wants to delete the items, delete them
			if user_confirmation then delete_items(item_paths) end

		-- Otherwise, delete the items
		else
			delete_items(item_paths)
		end
	end

	-- If the user wants to reveal the created archive
	if
		config.reveal_created_archive or utils.table_pop(args, "reveal", false)
	then

		-- Wait for the path to exist in Yazi before revealing it
		utils.wait_until_path_exists_in_yazi(archive_path)

		-- Reveal the archive
		ya.emit("reveal", { archive_path })
	end
end

-- Return the module table
return M
