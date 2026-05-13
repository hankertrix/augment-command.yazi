--- @since 26.5.6

-- The module to handle the first file command

-- Import the utilities module
local utils = require(".utils")

-- The module table
local M = {}

-- Function to execute the first file command
---@type fun(): nil
local exec = ya.sync(function()

	-- Get the current working directory
	local current = cx.active.current

	-- Get the files in the current working directory
	local files = current.files

	-- Initialise the index of the first file
	local first_file_index = nil

	-- Iterate over the files
	for index, file in ipairs(files) do

		-- If the file isn't a directory,
		if not file.cha.is_dir then

			-- Set the first file index
			first_file_index = index

			-- Break out of the loop
			break
		end
	end

	-- Get the amount to move the cursor by.
	--
	-- The cursor index needs to be increased by 1
	-- because the cursor index is 0-indexed
	-- while Lua tables are 1-indexed.
	local move_by = first_file_index - (current.cursor + 1)

	-- Emit the augmented arrow command
	utils.emit_augmented_command("arrow", { move_by })
end)

-- Function to handle the first file command
---@type YaziPluginEntry
function M:entry()

	-- Call the function to execute the first file command
	exec()
end

-- Return the module table
return M
