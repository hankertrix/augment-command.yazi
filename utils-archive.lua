-- The module containing the utilities to deal with archiving files

-- Types for the archiver class

-- The type for the new function of the archiver class
---@alias Archiver.New fun(
---	self: self,
---	archive_path: string,
---	config: Configuration,
---	destination_path: string?,
---): instance: self?

-- The type for the function to get the items from the archiver
---@alias Archiver.GetItems fun(
---	self: self,
---): files: string[], directories: string[],
---	is_single_folder_archive: boolean, result: Archiver.Result

-- The type for the function to extract an archive
---@alias Archiver.Extract fun(
---	self: self,
---	has_only_one_file: boolean?,
---): result: Archiver.Result

-- The type for the function to create an archive
---@alias Archiver.Archive fun(
---	self: self,
---	item_paths: string[],
---	password: string?,
---	encrypt_headers: boolean?,
---): result: Archiver.Result

-- The type for the archiver command function
---@alias Archiver.Command fun(self: self): output: Output?, error: Error?

-- The type of the function to get the password options
---@alias GetPasswordOptions fun(is_confirm_password: boolean): YaziInputOptions

-- The type for the archiver function result
---@class (exact) Archiver.Result
---@field successful boolean Whether the archiver function was successful
---@field output string? The output of the archiver function
---@field cancelled boolean? boolean Whether the archiver was cancelled
---@field error string? The error message
---@field archive_path string? The path to the archive
---@field destination_path string? The path to the destination
---@field extracted_items_path string? The path to the extracted items
---@field archiver_name string? The name of the archiver

-- The type for the archiver
---@class Archiver
---@field name string The name of the archiver
---@field command string? The shell command for the archiver
---@field commands string[] The possible archiver commands
---@field config Configuration The configuration object
---@field archive_path string The path to the archive
---@field destination_path string? The path to destination of the extraction
---
--- Whether the archiver supports preserving file permissions
---@field supports_file_permissions boolean
---
--- The map of the extract behaviour strings to the command flags
---@field extract_behaviour_map table<ExtractBehaviour, string>
---
--- Function to create a new instance of the archiver
---@field new Archiver.New
---
--- Function to get the files and directories from the archiver
---@field get_items Archiver.GetItems
---
--- Function to extract an archive
---@field extract Archiver.Extract
---
--- Function to create an archive
---@field archive Archiver.Archive

-- Import the utilities module
local utils = require(".utils")

-- Import the 7z and tar archivers
local SevenZip = require(".archiver-seven-zip")
local Tar = require(".archiver-tar")

-- The module table
local M = {}

-- The possible commands
---@enum ArchiverCommands
M.ArchiverCommands = {
	Extract = "extract",
	Archive = "archive",
}

-- The default archiver
local DefaultArchiver = SevenZip

-- The table of archive mime types
---@type table<string, Archiver>
local ARCHIVE_MIME_TYPE_TO_ARCHIVER_MAP = {
	["application/zip"] = DefaultArchiver,
	["application/gzip"] = DefaultArchiver,
	["application/tar"] = Tar,
	["application/bzip"] = DefaultArchiver,
	["application/bzip2"] = DefaultArchiver,
	["application/7z-compressed"] = DefaultArchiver,
	["application/rar"] = DefaultArchiver,
	["application/xz"] = DefaultArchiver,
	["application/zstd"] = DefaultArchiver,
}

-- The table of archive file extensions
---@type table<string, boolean>
local ARCHIVE_FILE_EXTENSIONS = {
	["7z"] = true,
	boz = true,
	bz = true,
	bz2 = true,
	bzip2 = true,
	cb7 = true,
	cbr = true,
	cbt = true,
	cbz = true,
	gz = true,
	gzip = true,
	rar = true,
	s7z = true,
	svgz = true,
	tar = true,
	tbz = true,
	tbz2 = true,
	tgz = true,
	txz = true,
	xz = true,
	zip = true,
	zst = true,
}

-- The table of archive file extensions that
-- supports header encryption
local ARCHIVE_FILE_EXTENSIONS_WITH_HEADER_ENCRYPTION = {
	["7z"] = true,
}

-- Function to check if a given mime type is an archive
---@param mime_type string? The mime type of the file
---@return boolean is_archive Whether the mime type is an archive
function M.is_archive_mime_type(mime_type)

	-- If the mime type is nil, return false
	if not mime_type then return false end

	-- Standardise the mime type
	local standardised_mime_type = utils.standardise_mime_type(mime_type)

	-- Get the archiver for the mime type
	local archiver = ARCHIVE_MIME_TYPE_TO_ARCHIVER_MAP[standardised_mime_type]

	-- Return if an archiver exists for the mime type
	return archiver ~= nil
end

-- Function to check if a given file extension
-- is an archive file extension
---@param file_extension string? The file extension of the file
---@return boolean is_archive Whether the file extension is an archive
function M.is_archive_file_extension(file_extension)

	-- If the file extension is nil, return false
	if not file_extension then return false end

	-- Make the file extension lower case
	file_extension = file_extension:lower()

	-- Trim the whitespace from the file extension
	file_extension = utils.string_trim(file_extension)

	-- Get if the file extension is an archive
	local is_archive =
		utils.table_get(ARCHIVE_FILE_EXTENSIONS, file_extension, false)

	-- Return if the file extension is an archive file extension
	return is_archive
end

-- Function to get if the hovered item is an archive
---@type fun(): boolean
M.hovered_item_is_archive = ya.sync(function(_)

	-- Get the hovered item
	local hovered_item = cx.active.current.hovered

	-- Return if the hovered item exists and is an archive
	return hovered_item and M.is_archive_mime_type(hovered_item:mime())
end)

-- Function to create a temporary directory
---@param path string The path to the item to create a temporary directory
---@param destination_given boolean? Whether the destination was given
---@return Url? url The url of the temporary directory
---@return Error? error The error object if the creation failed
local function create_temp_directory(path, destination_given)

	-- Get the url of the path given
	local path_url = Url(path)

	-- Initialise the parent directory to be the path given
	local parent_directory_url = path_url

	-- If the destination is not given
	if not destination_given then

		-- Get the parent directory of the given path
		parent_directory_url = path_url.parent

		-- If the parent directory doesn't exit, return nil
		if not parent_directory_url then return nil end
	end

	-- Initialise the temporary directory and error variables
	local temporary_directory_url, err = fs.unique(
		"dir",
		parent_directory_url:join(utils.get_temporary_name(path))
	)

	-- Return the url of the temporary directory
	return temporary_directory_url, err
end

-- Function to get the archiver for the file type
---@param archive_path string The path to the archive file
---@param command ArchiverCommands The command the archiver is used for
---@param config Configuration The configuration for the plugin
---@param destination_path string? The path to the destination directory
---@return Archiver? archiver The archiver for the file type
---@return Archiver.Result result The results of getting the archiver
function M.get_archiver(archive_path, command, config, destination_path)

	-- Get the mime type of the archive file
	local mime_type = utils.get_mime_type(archive_path)

	-- Get the archiver for the mime type
	local archiver = command == M.ArchiverCommands.Archive and DefaultArchiver
		or ARCHIVE_MIME_TYPE_TO_ARCHIVER_MAP[mime_type]

	-- If there is no archiver,
	-- return that it is not successful,
	-- but that it has been cancelled
	-- as the mime type is not an archive
	if not archiver then
		return archiver, {
			successful = false,
			cancelled = true,
		}
	end

	-- Instantiate an instance of the archiver
	local archiver_instance =
		archiver:new(archive_path, config, destination_path)

	-- While the archiver instance failed to be created
	while not archiver_instance do

		-- If the archiver instance is the default archiver,
		-- then return an error telling the user to install the
		-- default archiver
		if archiver.name == SevenZip.name then
			return archiver_instance,
				{
					successful = false,
					error = table.concat({
						string.format("%s is not installed,", SevenZip.name),
						string.format(
							"please install it before using the '%s' command",
							command
						),
					}, " "),
				}
		end

		-- Try instantiating the default archiver
		archiver_instance = SevenZip:new(archive_path, config, destination_path)
	end

	-- If the user wants to preserve file permissions,
	-- and the target archiver for the mime type supports
	-- preserving file permissions, but the archiver
	-- instantiated does not, show a warning to the user
	if
		config.preserve_file_permissions
		and archiver.supports_file_permissions
		and not archiver_instance.supports_file_permissions
	then

		-- The warning to show the user
		local warning = table.concat({
			string.format(
				"%s is not installed, defaulting to %s.",
				archiver.name,
				archiver_instance.name
			),
			string.format(
				"However, %s does not support preserving file permissions.",
				archiver_instance.name
			),
		}, "\n")

		-- Show the warning to the user
		utils.show_warning(warning)
	end

	-- Return the archiver instance
	return archiver_instance, { successful = true }
end

-- Function to move the extracted items out of the temporary directory
---@param archive_url Url The url of the archive
---@param destination_url Url The url of the destination
---@return Archiver.Result result The result of the move
local function move_extracted_items(archive_url, destination_url)

	-- The function to clean up the destination directory
	-- and return the archiver result in the event of an error
	---@param err string The error message to return
	---@param empty_dir_only boolean? Whether to remove the empty dir only
	---@return Archiver.Result
	local function fail(err, empty_dir_only)

		-- Clean up the destination path
		fs.remove(empty_dir_only and "dir" or "dir_all", destination_url)

		-- Return the archiver result
		---@type Archiver.Result
		return {
			successful = false,
			error = err,
		}
	end

	-- Get the extracted items in the destination.
	-- There is a limit of 2 as we just need to
	-- know if the destination contains only
	-- a single item or not.
	local extracted_items = fs.read_dir(destination_url, { limit = 2 })

	-- If the extracted items doesn't exist,
	-- clean up and return the error
	if not extracted_items then
		return fail(
			string.format(
				"Failed to read the destination directory: %s",
				tostring(destination_url.path)
			)
		)
	end

	-- If there are no extracted items,
	-- clean up and return the error
	if #extracted_items == 0 then
		return fail("No files extracted from the archive", true)
	end

	-- Get the parent directory of the destination
	local parent_directory_url = destination_url.parent

	-- If the parent directory doesn't exist,
	-- clean up and return the error
	if not parent_directory_url then
		return fail("Destination path has no parent directory")
	end

	-- Get the name of the archive without the extension
	local archive_name = archive_url.stem

	-- If the name of the archive doesn't exist,
	-- clean up and return the error
	if not archive_name then
		return fail("Archive has no name without its extension")
	end

	-- Get the first extracted item
	local first_extracted_item = table.unpack(extracted_items)

	-- Initialise the variable to indicate whether the archive has only one item
	local only_one_item = false

	-- Initialise the target directory url to move the extracted items to,
	-- which is the parent directory of the archive
	-- joined with the file name of the archive without the extension
	local target_url = parent_directory_url:join(archive_name)

	-- Initialise that the target url is a directory by default
	local target_url_is_directory = true

	-- If there is only one item in the archive
	if #extracted_items == 1 then

		-- Set the only one item variable to true
		only_one_item = true

		-- Get the name of the first extracted item
		local first_extracted_item_name = first_extracted_item.url.name

		-- Get if the item is a file
		target_url_is_directory = first_extracted_item.cha.is_dir

		-- If the first extracted item has no name,
		-- then clean up and return the error
		if not first_extracted_item_name then
			return fail("The only extracted item has no name")
		end

		-- Otherwise, set the target url to the parent directory
		-- of the destination joined with the file name of the extracted item
		target_url = parent_directory_url:join(first_extracted_item_name)
	end

	-- Get a unique name for the target url
	local unique_target_url =
		fs.unique(target_url_is_directory and "dir" or "file", target_url)

	-- If the unique target url is nil,
	-- clean up and return the error
	if not unique_target_url then
		return fail(
			"Failed to get a unique name to move the extracted items to"
		)
	end

	-- Set the target path to the string of the target url
	local target_path = tostring(unique_target_url.path)

	-- Initialise the move successful variable and the error message
	local error_message, move_successful = nil, false

	-- If there is only one item in the archive
	if only_one_item then

		-- Move the item to the target path
		move_successful, error_message =
			fs.rename(first_extracted_item.url, Url(target_path))

	-- Otherwise
	else

		-- Rename the destination directory itself to the target path
		move_successful, error_message =
			fs.rename(Url(destination_url), Url(target_path))
	end

	-- Clean up the destination directory
	fs.remove(move_successful and "dir" or "dir_all", destination_url)

	-- Return the archiver result with the target path as the
	-- path to the extracted items
	return {
		successful = move_successful,
		error = error_message,
		extracted_items_path = target_path,
	}
end

-- Function to recursively extract archives
---@param archive_path string The path to the archive
---@param args ParsedArgs The arguments passed to the plugin
---@param config Configuration The configuration object
---@param destination_path string? The destination path to extract to
---@return Archiver.Result extraction_result The extraction results
function M.recursively_extract_archive(
	archive_path,
	args,
	config,
	destination_path
)

	-- Get whether the destination path is given
	local destination_path_given = destination_path ~= nil

	-- Initialise the destination path to the archive path if it is not given
	local destination = destination_path or archive_path

	-- Get the temporary directory url
	local temp_directory_url, create_temp_dir_error =
		create_temp_directory(destination, destination_path_given)

	-- If the temporary directory can't be created
	-- then return the result
	if not temp_directory_url then
		return {
			successful = false,
			error = "Failed to create a temporary directory. Error: "
				.. tostring(create_temp_dir_error),
			archive_path = archive_path,
			destination_path = destination_path,
		}
	end

	-- Get an the archiver for the archive
	local archiver, get_archiver_result = M.get_archiver(
		archive_path,
		M.ArchiverCommands.Extract,
		config,
		tostring(temp_directory_url.path)
	)

	-- If there is no archiver, return the result
	if not archiver then
		return utils.merge_tables({}, get_archiver_result, {
			archive_path = archive_path,
			destination_path = destination_path,
		})
	end

	-- Function to add additional information to the extraction result
	-- The additional information are:
	--      - The archive path
	--      - The destination path
	--      - The name of the archiver
	---@param result Archiver.Result The result to add the paths to
	---@return Archiver.Result modified_result The result with the paths added
	local function add_additional_info(result)
		return utils.merge_tables({}, result, {
			archive_path = archive_path,
			destination_path = destination_path,
			archiver_name = archiver.name,
		})
	end

	-- Get the list of archive files and directories,
	-- whether the archive is a single folder archive,
	-- the error message and the password
	local archive_files, archive_dirs, is_single_folder, archiver_result =
		archiver:get_items()

	-- If there are no are no archive files and directories,
	-- return the extraction result
	if #archive_files + #archive_dirs < 1 then
		return add_additional_info(archiver_result)
	end

	-- Get if the archive has only one file
	local archive_has_only_one_file = #archive_files == 1 and #archive_dirs == 0

	-- Extract the given archive
	local extraction_result = archiver:extract(archive_has_only_one_file)

	-- If the extraction result is not successful, return it
	if not extraction_result.successful then
		return add_additional_info(extraction_result)
	end

	-- Get the result of moving the extracted items
	local move_result =
		move_extracted_items(Url(archive_path), temp_directory_url)

	-- Get the extracted items path
	local extracted_items_path = move_result.extracted_items_path

	-- If moving the extracted items isn't successful,
	-- or if the extracted items path is nil,
	-- or if the user does not want to extract archives recursively,
	-- return the move results
	if
		not move_result.successful
		or not extracted_items_path
		or not config.recursively_extract_archives
	then
		return add_additional_info(move_result)
	end

	-- Get the url of the extracted items path
	local extracted_items_url = Url(extracted_items_path)

	-- Initialise the base url for the extracted items
	local base_url = extracted_items_url

	-- Get the parent directory of the extracted items path
	local parent_directory_url = extracted_items_url.parent

	-- If the parent directory doesn't exist
	if not parent_directory_url then

		-- Modify the move result with a custom error
		---@type Archiver.Result
		local modified_move_result = utils.merge_tables({}, move_result, {
			error = "Archive has no parent directory",
			archive_path = archive_path,
			destination_path = destination_path,
		})

		-- Return the modified move result
		return modified_move_result
	end

	-- If the archive has only one file,
	-- or the archive is a single folder archive
	if archive_has_only_one_file or is_single_folder then

		-- Set the base url to the parent directory of the extracted items path
		base_url = parent_directory_url
	end

	-- Iterate over the archive files
	for _, file in ipairs(archive_files) do

		-- Get the file extension of the file
		local file_extension = Url(file).ext

		-- If the file extension is not found, then skip the file
		if not file_extension then goto continue end

		-- If the file extension is not an archive file extension, skip the file
		if not M.is_archive_file_extension(file_extension) then
			goto continue
		end

		-- Otherwise, get the full url to the archive
		local full_archive_url = base_url:join(file)

		-- Get the full path to the archive
		local full_archive_path = tostring(full_archive_url.path)

		-- Yazi is now way too quick (a good problem to have, really),
		-- so we slow it down a little to make sure that the
		-- extracted files are not overwritten by each other
		ya.sleep(10e-3)

		-- Recursively extract the archive
		utils.emit_augmented_command(
			"extract",
			utils.merge_tables({}, args, {
				archive_path = ya.quote(full_archive_path),
				remove = true,
			})
		)

		-- The label the continue the loop
		::continue::
	end

	-- Return the move result
	return add_additional_info(move_result)
end

-- Function to show an archiver error
---@param archiver_result Archiver.Result The result from the archiver
---@return nil
function M.throw_archiver_error(archiver_result)

	-- The line for the error
	local error_line = string.format("Error: %s", archiver_result.error)

	-- If the archiver name exists
	if archiver_result.archiver_name then

		-- Add the archiver's name to the error
		error_line = string.format(
			"%s error: %s",
			archiver_result.archiver_name,
			archiver_result.error
		)
	end

	-- Initialise the error
	local error_string = nil

	-- If the destination path exists,
	-- show the extraction error
	if archiver_result.destination_path then
		error_string = table.concat({
			string.format(
				"Failed to extract archive at: %s",
				archiver_result.archive_path
			),
			string.format("Destination: %s", archiver_result.destination_path),
			error_line,
		}, "\n")

	-- Otherwise, just show the archiver error
	else
		error_string = error_line
	end

	-- Throw the error
	utils.throw_error(error_string)
end

-- Function to check if an archive supports header encryption
---@param archive_url Url The url to the archive
---@param wanted boolean Whether header encryption is wanted
---@return boolean supports_header_encryption Header encryption supported or not
function M.archive_supports_header_encryption(archive_url, wanted)

	-- If header encryption isn't wanted, immediately return false
	if not wanted then return false end

	-- Otherwise, get the extension of the archive
	local archive_extension = archive_url.ext

	-- If the extension doesn't support header encryption
	local supports_header_encryption =
		ARCHIVE_FILE_EXTENSIONS_WITH_HEADER_ENCRYPTION[archive_extension]

	-- If the archive extension does not support header encryption,
	-- show a warning
	if not supports_header_encryption then
		utils.show_warning(table.concat({
			string.format(
				"'.%s' does not support header encryption,",
				archive_extension
			),
			"continuing archival process without header encryption.",
		}, " "))
	end

	-- Return if the archive supports header encryption
	return supports_header_encryption
end

-- Return the module table
return M
