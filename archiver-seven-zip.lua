-- The module containing the 7z archiver

-- Import the utilities module
local utils = require(".utils")

-- Import the constants
local constants = require(".constants")
local DEFAULT_INPUT_OPTIONS = constants.DEFAULT_INPUT_OPTIONS
local ConfigurableComponents = constants.ConfigurableComponents
local ArchiverName = constants.ArchiverName
local ExtractBehaviour = constants.ExtractBehaviour

-- The 7-Zip archiver
---@class SevenZip: Archiver
local SevenZip = {
	name = ArchiverName.SevenZip,
	commands = { "7z", "7zz" },

	-- https://documentation.help/7-Zip/overwrite.htm
	extract_behaviour_map = {
		[ExtractBehaviour.Overwrite] = "-aoa",
		[ExtractBehaviour.Rename] = "-aou",
	},

	password = "",
}

---@type Archiver.New
function SevenZip:new(archive_path, config, destination_path)

	-- Initialise whether the archiver is available
	local available = self.command ~= nil

	-- If the archiver has not been initialised
	if not available then

		-- Iterate over the commands
		for _, command in ipairs(self.commands) do

			-- Call the shell command exists function
			-- on the command
			local exists = utils.async_shell_command_exists(command)

			-- If the command exists
			if exists then

				-- Save the command
				self.command = command

				-- Set the available variable to true
				available = true

				-- Break out of the loop
				break
			end
		end
	end

	-- If none of the commands for the archiver are available,
	-- then return nil
	if not available then return nil end

	-- Otherwise, create a new instance
	local instance = setmetatable({}, self)

	-- Set where to find the object's methods or properties
	self.__index = self

	-- Save the parameters given
	self.archive_path = archive_path
	self.destination_path = destination_path
	self.config = config

	-- Return the instance
	return instance
end

-- Function to retry the archiver
---@private
---@param archiver_function Archiver.Command Archiver command to retry
---@param clean_up_wanted boolean? Whether to clean up the destination path
---@return Archiver.Result result Result of the archiver function
function SevenZip:retry_archiver(archiver_function, clean_up_wanted)

	-- Initialise the number of tries
	-- to the number of retries plus 1
	local total_number_of_tries = self.config.extract_retries + 1

	-- Get the url of the archive
	local archive_url = Url(self.archive_path)

	-- Get the archive name
	local archive_name = archive_url.name

	-- If the archive name is nil,
	-- return the result of the archiver function
	if not archive_name then
		return {
			successful = false,
			error = string.format("%s does not have a name", self.archive_path),
		}
	end

	-- Initialise the initial password prompt
	local initial_password_prompt = string.format("%s password:", archive_name)

	-- Initialise the wrong password prompt
	local wrong_password_prompt =
		string.format("Wrong password, %s password:", archive_name)

	-- Initialise the clean up function
	local clean_up = clean_up_wanted
			and function() fs.remove("dir_all", Url(self.destination_path)) end
		or function() end

	-- Initialise the error message
	local error_message = nil

	-- Iterate over the number of times to try the extraction
	for tries = 0, total_number_of_tries do

		-- Execute the archiver function
		local output, error = archiver_function()

		-- If there is no output
		if not output then

			-- Clean up the extracted files
			clean_up()

			-- Return the result of the archiver function
			return {
				successful = false,
				error = tostring(error),
			}
		end

		-- If the output status code is 0,
		-- which means the command was successful,
		-- return the result of the archiver function
		if output.status.code == 0 then
			return {
				successful = true,
				output = output.stdout,
			}
		end

		-- Clean up the extracted files
		clean_up()

		-- Set the error message to the standard error
		error_message = output.stderr

		-- If the command failed for a reason other
		-- than the archive being encrypted,
		-- or if the current try count
		-- is the same as the total number of tries
		if
			not (
				output.status.code == 2
				and error_message:lower():find("wrong password")
			) or tries == total_number_of_tries
		then

			-- Return the archiver function result
			return {
				successful = false,
				error = error_message,
			}
		end

		-- Otherwise, get the prompt for the password
		local password_prompt = tries == 0 and initial_password_prompt
			or wrong_password_prompt

		-- Initialise the width of the input element
		local input_width = DEFAULT_INPUT_OPTIONS.pos.w

		-- If the length of the password prompt is larger
		-- than the default input with, set the input width
		-- to the length of the password prompt + 1
		if #password_prompt > input_width then
			input_width = #password_prompt + 1
		end

		-- Function to get the user's input option
		-- for the extract password prompt
		---@type GetPasswordOptions
		local function get_user_extract_password_options(_)

			-- Get the password input options
			local password_input_options =
				utils.get_user_input_or_confirm_options(
					ConfigurableComponents.Plugin.ExtractPassword,
					{ prompts = password_prompt }
				)

			-- Set the width of the component to the input width
			---@cast password_input_options YaziInputOptions
			password_input_options.pos.w = input_width

			-- Return the password input options
			return password_input_options
		end

		-- Ask the user for the password
		local user_input, event =
			utils.get_password(get_user_extract_password_options)

		-- If the user has confirmed the input,
		-- and the user input is not nil,
		-- set the password to the user's input
		if event == 1 and user_input ~= nil then
			self.password = user_input

		-- Otherwise, the user has cancelled the input
		else

			-- Return the result of the archiver command
			return {
				successful = false,
				cancelled = true,
				error = error_message,
			}
		end
	end

	-- If all the tries have been exhausted,
	-- call the clean up function
	clean_up()

	-- Return the result of the archiver command
	return {
		successful = false,
		error = error_message,
	}
end

-- Function to list the archive items with the command
---@private
---@type Archiver.Command
function SevenZip:list_items_command()

	-- Initialise the arguments for the command
	local arguments = {

		-- List the items in the archive
		"l",

		-- Use UTF-8 encoding for console input and output
		"-sccUTF-8",

		-- Pass the password to the command
		"-p" .. self.password,

		-- Remove the headers (undocumented switch)
		-- typos: ignore-next-line
		"-ba",

		-- The archive path
		self.archive_path,
	}

	-- Return the result of the command to list the items in the archive
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to get the items in the archive
---@type Archiver.GetItems
function SevenZip:get_items()

	-- Initialise the list of files in the archive
	---@type string[]
	local files = {}

	-- Initialise the list of directories
	---@type string[]
	local directories = {}

	-- Initialise whether the archive is a single folder archive
	local is_single_folder_archive = false

	-- Call the function to retry the archiver command
	-- with the list items in the archive function
	local archiver_result = self:retry_archiver(
		function() return self:list_items_command() end
	)

	-- Get the output
	local output = archiver_result.output

	-- If the archiver command was not successful,
	-- or the output was nil,
	-- then return nil the error message,
	-- and nil as the correct password
	if not archiver_result.successful or not output then
		return files, directories, is_single_folder_archive, archiver_result
	end

	-- Otherwise, split the output at the newline character
	local output_lines = utils.string_split(output, "\n")

	-- The pattern to get the information from an archive item
	---@type string
	local archive_item_info_pattern = "%s+([%.%a]+)%s+(%d*)%s+(%d*)%s+(.+)$"

	-- The dictionary of root paths
	local root_paths = {}

	-- Iterate over the lines of the output
	for _, line in ipairs(output_lines) do

		-- Get the information about the archive item from the line.
		-- The information is in the format:
		-- Attributes, Size, Compressed Size, File Path
		local attributes, _, _, file_path =
			line:match(archive_item_info_pattern)

		-- If the file path doesn't exist, then continue the loop
		if not file_path then goto continue end

		-- Get the file's root
		local file_root = utils.get_path_root(file_path)

		-- If the file's root exists, and is not already inside the root path
		if file_root and not root_paths[file_root] then

			-- Add the file's root to the dictionary of root paths
			root_paths[file_root] = true
		end

		-- If the attributes of the item starts with a "D",
		-- which means the item is a directory
		if attributes and attributes:find("^D") then

			-- Add the directory to the list of directories
			table.insert(directories, file_path)

			-- Continue the loop
			goto continue
		end

		-- Otherwise, add the file path to the list of archive items
		table.insert(files, file_path)

		-- The continue label to continue the loop
		::continue::
	end

	-- If the number of root paths is 1,
	-- it is a single folder archive
	if utils.get_dictionary_length(root_paths) == 1 then
		is_single_folder_archive = true
	end

	-- Return the list of files, the list of directories,
	-- the error message, and the password
	return files, directories, is_single_folder_archive, archiver_result
end

-- Function to extract an archive using the command
---@private
---@param extract_files_only boolean? Extract the files only or not
---@param extract_behaviour ExtractBehaviour? The extraction behaviour
---@return Output? output The output of the command
---@return Error? error The error if any
function SevenZip:extract_command(extract_files_only, extract_behaviour)

	-- Initialise the extract files only flag to false if it's not given
	extract_files_only = extract_files_only or false

	-- Initialise the extract behaviour to rename if it's not given
	local extract_behaviour_flag =
		self.extract_behaviour_map[extract_behaviour or ExtractBehaviour.Rename]

	-- Initialise the extraction mode to use.
	-- By default, it extracts the archive with
	-- full paths, which keeps the archive structure.
	local extraction_mode = "x"

	-- If the extract files only flag is passed
	if extract_files_only then

		-- Use the regular extract,
		-- without the full paths, which will move
		-- all files in the archive into the current directory
		-- and ignore the archive folder structure.
		extraction_mode = "e"
	end

	-- Initialise the arguments for the command
	local arguments = {

		-- The extraction mode
		extraction_mode,

		-- Assume yes to all prompts
		"-y",

		-- Use UTF-8 encoding for console input and output
		"-sccUTF-8",

		-- Configure the extraction behaviour
		extract_behaviour_flag,

		-- Pass the password to the command
		"-p" .. self.password,

		-- The archive file to extract
		self.archive_path,

		-- The destination directory path
		"-o" .. self.destination_path,
	}

	-- Return the output of the command
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to extract the archive
---@type Archiver.Extract
function SevenZip:extract(has_only_one_file)

	-- Extract the archive with the extract command
	local result = self:retry_archiver(
		function() return self:extract_command(has_only_one_file) end,
		true
	)

	-- Return the archiver result
	return result
end

-- Function to call the command to add items to an archive
---@private
---@param item_paths string[] The path to the items being added to the archive
---@param password string? The password to encrypt the archive with
---@param encrypt_headers boolean? Whether to encrypt the archive headers
---@return Output? output The output of the command
---@return Error? error The error if any
function SevenZip:archive_command(item_paths, password, encrypt_headers)

	-- Initialise the arguments for the command
	local arguments = {

		-- Add to the archive
		"a",

		-- Use UTF-8 encoding for console input and output
		"-sccUTF-8",
	}

	-- If the password is given, add the password
	if password then table.insert(arguments, "-p" .. password) end

	-- If encrypting headers is wanted,
	-- add the argument to encrypt the headers
	if encrypt_headers then table.insert(arguments, "-mhe") end

	-- Add the archive path and the item paths
	utils.merge_tables(arguments, {
		self.archive_path,
		table.unpack(item_paths),
	})

	-- Return the output of the command
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to add items to an archive
---@type Archiver.Archive
function SevenZip:archive(item_paths, password, encrypt_headers)

	-- Get the output of the command
	local output, error =
		self:archive_command(item_paths, password, encrypt_headers)

	-- If there is no output, return the archiver result
	if not output then
		return {
			successful = false,
			error = tostring(error),
		}
	end

	-- If the output status code is not 0
	-- return the archiver result
	if output.status.code ~= 0 then
		return {
			successful = false,
			error = tostring(output.stderr),
		}
	end

	-- Otherwise, return successful and the archive path
	return {
		successful = true,
		archive_path = self.archive_path,
	}
end

-- Return the 7z archiver
return SevenZip
