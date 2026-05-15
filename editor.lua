--- @since 26.5.6

-- The module to handle the editor command

-- Import the utilities module
local utils = require(".utils")

-- The module table
local M = {}

-- Function to handle the editor command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- Get the editor environment variable
	local editor = os.getenv("EDITOR")

	-- If the editor not set, exit the function
	if not editor then return end

	-- Initialise the shell command
	local shell_command = editor .. " %s"

	-- Get the cha object of the hovered file
	local hovered_item_cha = fs.cha(
		Url(utils.get_path_of_hovered_item() or ""),
		false
	) or {}

	-- If the user ID of the file is root,
	-- and sudo edit is supported,
	-- set the shell command to "sudo -e"
	if config.sudo_edit_supported and hovered_item_cha.uid == 0 then
		shell_command = "sudo -e %s"
	end

	-- Call the handle shell function
	-- with the shell command to open the editor
	require(".utils-shell").handle(
		utils.merge_tables({
			shell_command,
			block = true,
			exit_if_dir = true,
		}, args),
		config
	)
end

-- Return the module table
return M
