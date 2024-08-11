-- switches.lua

-- Nodes of this type will send an activation signal to a neighbor,
-- running their _on_frob() callback
-- #TODO: add a passthrough node that sends the signal on ahead

ncrafting = ncrafting

local base_def = {
        description = "A switch", -- Default description, should be replaced
        tiles = {"nodes_nature_basalt.png"},
        drawtype = "normal",
        paramtype = "light",
        sunlight_propagates = true,
	move_resistance = 1,
        buildable_to = false,
        floodable = false,
	_switch_sound = "success",
        groups = {temp_pass = 1, switch = 1, crumbly = 1, cracky = 3 },
	use_texture_alpha = "blend",
	_on_use_node = function(player, pointed_node,
				pointed_thing, wielded_item)
	   local pos = pointed_thing.under
	   local this = minetest.registered_nodes[minetest.get_node(pos).name]
	   if this then
	      local params = minimal.merge_tables(
		 { -- User can't set pos, but we can let them override sounds
		    pos=pos, gain = 0.1,
		    max_hear_distance = 6
		 },
		 this._switch_sound_params or {} )
	      minetest.sound_play(this._switch_sound,
				  params, true)
	   end
	   local machines = minetest.find_nodes_in_area(
	      vector.new(pos.x-1, pos.y-1, pos.z-1),
	      vector.new(pos.x+1, pos.y+1, pos.z+1),
	      { "group:frobbable" }, true)
	   for name, allpos in pairs(machines) do
	      local def = minetest.registered_nodes[name]
	      if not def then print("This shouldn't be possible") end
	      for _, fpos in ipairs(allpos) do
		 def._on_frob(fpos, player)
	      end
	   end
	end,
}

function ncrafting.register_switch(name, def_overrides)
   minetest.register_node(name,
			  minimal.merge_tables(base_def, def_overrides))
end
