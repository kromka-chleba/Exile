-- This file contains quick blocks of code that can be enabled for debugging
--
--
exile = exile
exile.debug = exile.debug or {
}

local __DEBUG__ = minetest.settings:get("exile_debug") == "true"

function exile.debug.print(message)
	if __DEBUG__ then
		minetest.log('warning', message)
	end
end

function exile.debug.crafting_stations(station)
	for _,recipes in pairs(crafting.recipes) do
	   minetest.log('warning', "station: "..station..
			"(recipes: "..#recipes..")")
	end
	if station then
		minetest.log('warning', dump(crafting.recipes[station]))
	end
end

function exile.debug.dump_nodedef_params(params, filter)
	if type(params) == 'string' then
		params = { params }
	end
	for node,def in pairs(minetest.registered_nodes) do
	   if string.find(node,filter,1) then
	      for _,param in ipairs(params) do
		 minetest.log('warning', "Node: "..node.."  "..param..": "
			      ..dump(def[param]))
	      end
	   end
	end
end


minetest.register_on_mods_loaded(function()
      if __DEBUG__ ==  true then
	 minetest.log('warning',
		      "--------------------[ Modules Loaded "..
		      "[--------------------")
--	 exile.debug.crafting_stations('axe_mixing')
--	 exile.debug.dump_nodedef_params('groups','depleted')
      else
	 -- Funky debug command from naturalslopeslib, get rid of it
	 minetest.unregister_chatcommand("updshape")
	 -- Unneeded from player_monoids
	 minetest.unregister_chatcommand("test_monoids")
	 -- Debugging for volcano modding
	 minetest.unregister_chatcommand("findvolcano")
      end
end)
