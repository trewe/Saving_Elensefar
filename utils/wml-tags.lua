
-- to make code shorter.
local wml_actions = wesnoth.wml_actions
local helper = wesnoth.require "lua/helper.lua"

--! [store_shroud]
--! melinath

-- Given side= and variable=, stores that side's shroud data in that variable
-- Example:
-- [store_shroud]
--     side=1
--     variable=shroud_data
-- [/store_shroud]

function wml_actions.store_shroud(cfg)
	local side = wesnoth.sides.find( cfg )[1] or wml.error("No matching side found in [store_shroud]")
	local variable = cfg.variable or wml.error("Missing required variable= attribute in [store_shroud].")
	local current_shroud = side.__cfg.shroud_data
	wml.variables[variable] = current_shroud
end

--! [set_shroud]
--! melinath

-- Given shroud data, removes the shroud in the marked places on the map.
-- Example:
-- [set_shroud]
--     side=1
--     shroud_data=$shroud_data # stored with store_shroud, for example!
-- [/set_shroud]

function wml_actions.set_shroud(cfg)
	local side = wesnoth.sides.find( cfg )[1] or wml.error("No matching side found in [set_shroud]")
	local shroud_data = cfg.shroud_data or wml.error("Missing required shroud_data= attribute in [set_shroud]")

	if shroud_data == nil then wml.error("[set_shroud] was passed an empty shroud string")
		-- shroud data can contain only pipes, 0, 1 and newlines
	elseif string.sub(shroud_data,1,1) ~= "|" or string.match(shroud_data,"[^|01\n]") then
		wml.error("[set_shroud] was passed an invalid shroud string")
	else
		-- yes, I prefer long variable names. I think that they make the code more understandable. E_H.
		local width = wesnoth.current.map.playable_width
		local height = wesnoth.current.map.playable_height
		local border = wesnoth.current.map.border_size

		-- you might think that I could've converted this tag to just use wesnoth.sides.place_shroud()
		-- and be done with it.
		-- Think again: the purpose of [set_shroud] is to restore the shroud exactly as it was
		-- stored by [store_shroud], which means also clearing the hexes that didn't have it.

		local to_shroud = {}
		local to_clear = {}
		local shroud_x = ( 1 - border )

		for row in string.gmatch ( shroud_data, "|(%d*)" ) do
			local shroud_y = ( 1 - border )
			for column in string.gmatch ( row, "%d" ) do
				if column == "0" then
					-- I tend to confuse them, so better specify: x are columns and y are rows. E_H.
					table.insert( to_shroud, { shroud_x, shroud_y } )
				elseif column == "1" then
					table.insert( to_clear, { shroud_x, shroud_y } )
				end
				shroud_y = shroud_y + 1
			end
			shroud_x = shroud_x + 1
		end

		if not side.shroud then
			side.shroud = true
		end

		wesnoth.sides.place_shroud( side.side, to_shroud )
		wesnoth.sides.remove_shroud( side.side, to_clear )
	end
end
