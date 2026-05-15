--- @since 26.5.6

-- The module to handle the arrow command

-- Import the utilities module
local utils = require(".utils")

-- The module table
local M = {}

-- Function to do the wraparound for the arrow command
---@param args ParsedArgs -- The arguments passed to the plugin
---@return nil
local function wraparound_arrow(args)

	-- Get the number of steps from the arguments given
	local steps = table.remove(args, 1) or 1

	-- If the number of steps isn't a number,
	-- immediately emit the arrow command
	-- and exit the function
	if type(steps) ~= "number" then
		return ya.emit("arrow", utils.merge_tables({ steps }, args))
	end

	-- Initialise the arrow command to use
	local arrow_command = "next"

	-- If the number of steps is negative,
	if steps < 0 then

		-- Change the number of steps to positive
		steps = -steps

		-- Set the arrow command to "prev"
		arrow_command = "prev"
	end

	-- Iterate over the number of steps
	for _ = 1, steps do

		-- Emit the arrow command
		ya.emit("arrow", utils.merge_tables({ arrow_command }, args))
	end
end

-- Function to handle the arrow command
---@type YaziPluginEntry
function M:entry(job)

	-- Get the arguments and the configuration
	local args, config = require("augment-command").parse_args_and_init(job)

	-- If smooth scrolling is wanted,
	if config.smooth_scrolling then

		-- Get the number of steps from the arguments given
		local steps = table.remove(args, 1) or 1

		-- If the number of steps isn't a number,
		-- immediately emit the arrow command
		-- and exit the function
		if type(steps) ~= "number" then
			return ya.emit("arrow", utils.merge_tables({ steps }, args))
		end

		-- Initialise the function to the regular arrow command
		local function scroll_func(step)
			ya.emit("arrow", utils.merge_tables({ step }, args))
		end

		-- If wraparound file navigation is wanted
		-- and the no_wrap argument isn't passed
		if
			config.wraparound_file_navigation
			and not utils.table_pop(args, "no_wrap", false)
		then

			-- Use the wraparound arrow function
			function scroll_func(step)
				wraparound_arrow(utils.merge_tables({ step }, args))
			end
		end

		-- Call the smoothly scroll function and exit the function
		return utils.smoothly_scroll(steps, config.scroll_delay, scroll_func)
	end

	-- Otherwise, if smooth scrolling is not wanted,
	-- and wraparound file navigation is wanted,
	-- and the no_wrap argument isn't passed,
	-- call the wraparound arrow function
	-- and exit the function
	if
		config.wraparound_file_navigation
		and not utils.table_pop(args, "no_wrap", false)
	then
		return wraparound_arrow(args)
	end

	-- Otherwise, emit the regular arrow command
	ya.emit("arrow", args)
end

-- Return the module table
return M
