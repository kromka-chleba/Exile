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
   minetest.register_chatcommand("nodemeta", {
    params = "<none>",
    description = "Prints the meta table of the currently pointed node",
    privs = {},
    func = function(name, param)
       local pointed_thing = minimal.get_pointed_thing(name)
       if not pointed_thing or not pointed_thing.type == "node" then
	  return
       end
       local nodename = minetest.get_node(pointed_thing.under).name
       local meta = minetest.get_meta(pointed_thing.under)
       print(nodename," - ",dump2(meta:to_table()))
    end
   })
   minetest.register_chatcommand("plyrmeta", {
    params = "<none>",
    description = "Prints the meta table of the pointed player, or yourself",
    privs = {},
    func = function(name, param)
       local myself = minetest.get_player_by_name(name)
       local target
       local pointed_thing = minimal.get_pointed_thing(name,nil,true)
       if ( pointed_thing and pointed_thing.type == "object" ) then
	  if minetest.is_player(pointed_thing.ref) == true then
	     target = pointed_thing.ref
	  end
       else
	  target = myself
       end
       --local nodename = minetest.get_node(pointed_thing.under).name
       --local meta = minetest.get_meta(pointed_thing.under)
       if target then
	  print(dump2(target:get_meta():to_table().fields))
       else
	  return false, "could not get target"
       end
    end
   })
end


