-- This file contains quick blocks of code that can be enabled for debugging
--
--
exile = exile
exile.debug = {}
__DEBUG__ = minetest.settings:get("exile_debug") or false

function exile.debug.print(message)
	if __DEBUG__ then
		print (message)
	end
end

function exile.debug.crafting_stations(station)
	for stations,recipes in pairs(crafting.recipes) do
		print ("station: "..stations.."(recipes: "..#recipes..")")
	end
	if station then
		print (dump(crafting.recipes[station]))
	end
end

--[[
if __DEBUG__ then
	minetest.register_on_mods_loaded(function()
		print("--------------------[ Modules Loaded [-----------------------------")
		exile.debug.crafting_stations('axe_mixing')
	end)
end
--]]

function exile.debug.log_to_world(message, filename)
	if __DEBUG__ then
		local wpath = minetest.get_worldpath()
		local wname = wpath:match( "([^/\\]+)$" )
		filename = filename or (wname..'_debug.log')  -- default val
		local filespec = wpath..'/'..filename
		local file, err = io.open( filespec, 'a')
		if (err ~= nil) then
		   return
		end
		file:write( message )
		file:flush()
		file:close()
	end
end

if __DEBUG__ then
   minetest.register_chatcommand("itemmeta", {
    params = "<none>",
    description = "Prints the meta table of the currently wielded item",
    privs = {},
    func = function(name, param)
       local plyr = minetest.get_player_by_name(name)
       local witem = plyr:get_wielded_item()
       print(dump2(witem:get_meta():to_table()))
    end
   })
end
