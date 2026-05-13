-- The module containing the tar archiver

-- Import the utilities module
local utils = require(".utils")

-- Import the constants required
local constants = require(".constants")
local ArchiverName = constants.ArchiverName
local ExtractBehaviour = constants.ExtractBehaviour

-- The Tar archiver
---@class Tar: Archiver
local Tar = {
	name = ArchiverName.Tar,
	commands = { "gtar", "tar" },
	supports_file_permissions = true,

	-- https://www.man7.org/linux/man-pages/man1/tar.1.html
	-- https://ss64.com/mac/tar.html
	extract_behaviour_map = {

		-- Tar overwrites by default
		[ExtractBehaviour.Overwrite] = "",
		[ExtractBehaviour.Rename] = "-k",
	},
}

---@type Archiver.New
function Tar:new(archive_path, config, destination_path)

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

-- Function to list the archive items with the command
---@private
---@type Archiver.Command
function Tar:list_items_command()

	-- Initialise the arguments for the command
	local arguments = {

		-- List the items in the archive
		"-t",

		-- Pass the file
		"-f",

		-- The archive file path
		self.archive_path,
	}

	-- Return the result of the command
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to get the items in the archive
---@type Archiver.GetItems
function Tar:get_items()

	-- Call the function to get the list of items in the archive
	local output, error = self:list_items_command()

	-- Initialise the list of files
	---@type string[]
	local files = {}

	-- Initialise the list of directories
	---@type string[]
	local directories = {}

	-- Initialise whether the archive is a single folder archive
	local is_single_folder_archive = false

	-- If there is no output, return the empty lists and the error
	if not output then
		return files,
			directories,
			is_single_folder_archive,
			{
				successful = false,
				error = tostring(error),
			}
	end

	-- The dictionary of root paths
	local root_paths = {}

	-- Otherwise, split the output into lines and iterate over it
	for _, line in ipairs(utils.string_split(output.stdout, "\n")) do

		-- Get the root of the file path
		local file_root = utils.get_path_root(line)

		-- If the file's root exists, and is not already inside the root path
		if file_root and not root_paths[file_root] then

			-- Add the file's root to the dictionary of root paths
			root_paths[file_root] = true
		end

		-- If the line ends with a slash, it's a directory
		if line:sub(-1) == "/" then

			-- Add the directory without the trailing slash
			-- to the list of directories
			table.insert(directories, line:sub(1, -2))

			-- Continue the loop
			goto continue
		end

		-- Otherwise, the item is a file, so add it to the list of files
		table.insert(files, line)

		-- The label to continue the loop
		::continue::
	end

	-- If the number of root paths is 1,
	-- it is a single folder archive
	if utils.get_dictionary_length(root_paths) == 1 then
		is_single_folder_archive = true
	end

	-- Return the list of files and directories and the error
	return files,
		directories,
		is_single_folder_archive,
		{
			successful = true,
			error = output.stderr,
		}
end

-- Function to extract an archive using the command
---@private
---@param extract_behaviour ExtractBehaviour? The extract behaviour to use
function Tar:extract_command(extract_behaviour)

	-- Initialise the extract behaviour to rename if it is not given
	local extract_behaviour_flag =
		self.extract_behaviour_map[extract_behaviour or ExtractBehaviour.Rename]

	-- Initialise the arguments for the command
	local arguments = {

		-- Extract the archive
		"-x",

		-- Verbose
		"-v",

		-- The extract behaviour flag
		extract_behaviour_flag,

		-- Specify the destination directory
		"-C",

		-- The destination directory path
		self.destination_path,
	}

	-- If keeping permissions is wanted, add the -p flag
	if self.config.preserve_file_permissions then
		table.insert(arguments, "-p")
	end

	-- Add the -f flag and the archive path to the arguments
	table.insert(arguments, "-f")
	table.insert(arguments, self.archive_path)

	-- Create the destination path first.
	--
	-- This is required because tar does not
	-- automatically create the directory
	-- pointed to by the -C flag.
	-- Instead, tar just tries to change
	-- the working directory to the directory
	-- pointed to by the -C flag, which can
	-- fail if the directory does not exist.
	--
	-- GNU tar has a --one-top-level=[DIR] option,
	-- which will automatically create the directory
	-- given, but macOS tar does not have this option.
	--
	-- The error here is ignored because if there
	-- is an error creating the directory,
	-- then the archiver will fail anyway.
	fs.create("dir_all", Url(self.destination_path))

	-- Return the output of the command
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to extract the archive.
--
-- Tar automatically decompresses and extracts the archive
-- in one command, so there's no need to run it twice to
-- extract compressed tarballs.
---@type Archiver.Extract
function Tar:extract()

	-- Call the command to extract the archive
	local output, error = self:extract_command()

	-- If there is no output, return the result
	if not output then
		return {
			successful = false,
			error = tostring(error),
		}
	end

	-- Otherwise, if the status code is not 0,
	-- which means the extraction was not successful,
	-- return the result
	if output.status.code ~= 0 then
		return {
			successful = false,
			output = output.stdout,
			error = output.stderr,
		}
	end

	-- Otherwise, return the successful result
	return {
		successful = true,
		output = output.stdout,
	}
end

-- Function to call the command to add items to an archive
---@private
---@param item_paths string[] The path to the items being added to the archive
function Tar:archive_command(item_paths)

	-- Initialise the arguments to the command
	local arguments = {

		-- Add the items to an archive
		"-rf",

		-- The archive path
		self.archive_path,

		-- The item paths
		table.unpack(item_paths),
	}

	-- Return the output of the command
	return Command(self.command)
		:arg(arguments)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
end

-- Function to add items to an archive
---@type Archiver.Archive
function Tar:archive(item_paths)

	-- Get the output of the command
	local output, error = self:archive_command(item_paths)

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

-- Return the tar archiver
return Tar
