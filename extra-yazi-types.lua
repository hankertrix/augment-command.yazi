-- The module containing the extra Yazi types needed for the plugin

-- The type for the arguments
---@alias YaziArgs table<string|number, string|boolean>

-- The type of the Yazi plugin set up function
---@alias YaziPluginSetup fun(
---	opts: UserConfiguration,
---): nil

-- The type of the Yazi plugin entry function
---@alias YaziPluginEntry fun(
---	self: self,
---	job: { args: YaziArgs },
---): any

-- The type for the Yazi input options
---@alias YaziInputOptions {
---	title: string,
---	value: string?,
---	obscure: boolean?,
---	pos: AsPos,
---	realtime: boolean?,
---	debounce: number?,
---}

-- The type for the Yazi notification options
---@alias YaziNotificationOptions {
---	title: string,
---	content: string,
---	timeout: number,
---	level: "info"|"warn"|"error"?,
---}

-- The type for the Yazi confirm options
---@alias YaziConfirmOptions { pos: AsPos, title: AsLine, body: AsText }
