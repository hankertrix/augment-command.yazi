-- The module storing the constants for the plugin
local M = {}

-- The plugin name
---@type string
M.PLUGIN_NAME = "augment-command"

-- The enum for which group of items to operate on
---@enum ItemGroup
M.ItemGroup = {
	Hovered = "hovered",
	Selected = "selected",
	None = "none",
	Prompt = "prompt",
}

-- Initialise the enum of components for the theme configuration
---@enum ConfigurableComponents
M.ConfigurableComponents = {

	---@enum BuiltInComponents
	BuiltIn = {
		Create = "create",
		Overwrite = "overwrite",
		Delete = "delete",
	},

	---@enum PluginComponents
	Plugin = {
		ItemGroup = "item-group",
		ExtractPassword = "extract-password",
		Quit = "quit",
		Archive = "archive",
		ArchivePassword = "archive-password",
		Emit = "emit",
	},
}

-- The theme options for the input and confirm prompts
M.INPUT_AND_CONFIRM_OPTIONS = {
	"title",
	"origin",
	"offset",
	"body",
}

-- The table of input options for the prompt
---@type table<ItemGroup, string>
M.INPUT_OPTIONS_TABLE = {
	[M.ItemGroup.Hovered] = "(H/s)",
	[M.ItemGroup.Selected] = "(h/S)",
	[M.ItemGroup.None] = "(h/s)",
}

-- The default input options for this plugin
M.DEFAULT_INPUT_OPTIONS = {
	pos = { "top-center", x = 0, y = 2, w = 50, h = 3 },
}

-- The default confirm options for this plugin
M.DEFAULT_CONFIRM_OPTIONS = {
	pos = { "center", x = 0, y = 0, w = 50, h = 15 },
}

-- The default notification options for this plugin
M.DEFAULT_NOTIFICATION_OPTIONS = {
	title = "Augment Command Plugin",
	timeout = 5,
}

-- The tab preference keys.
-- The values are just dummy values
-- so that I don't have to maintain two
-- different types for the same thing.
---@type tab__Pref
M.TAB_PREFERENCE_KEYS = {
	sort_by = "alphabetical",
	sort_sensitive = false,
	sort_reverse = false,
	sort_dir_first = true,
	sort_translit = false,
	linemode = "none",
	show_hidden = false,
}

-- The list of mime type prefixes to remove
--
-- The prefixes are used in a lua pattern
-- to match on the mime type, so special
-- characters need to be escaped
---@type string[]
M.MIME_TYPE_PREFIXES_TO_REMOVE = {
	"x%-",
	"vnd%.",
}
-- The archiver names
---@enum ArchiverName
M.ArchiverName = {
	SevenZip = "7-Zip",
	Tar = "Tar",
}

-- The extract behaviour flags
---@enum ExtractBehaviour
M.ExtractBehaviour = {
	Overwrite = "overwrite",
	Rename = "rename",
}

-- Return the module table
return M
