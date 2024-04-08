-- Bones for deco.lua
-- Globals
local _EXILE_DEBUG = minetest.settings:get("exile_debug") == "true"

loot_table = {
   -- #TODO: break this out into a general treasure system, in prep for
   -- ruined huts and other sites; move it somewhere

   -- Table for lone exiles found dead in the wilderness ------
   -- No entry will be used more than once, but stacks can happen
   -- If we need to extend this table type later, it should probably be
   -- converted into key/value pairs

   -- { name, approximate cost/value, max amount found }

   -- Tools
   -- if max amount is nil and the item is a tool, wear will be applied
   -- max of 1 or more will give a stack of unused tools (wear would split them)
   {"tech:digging_stick", 2 },
   {"tech:stone_chopper", 2},
   {"tech:adze_granite", 6},
   {"artifacts:spyglass", 8, 1},
   {"spears:spear_stone", 2 },
   {"tech:paint_lime_white", 2 },
   {"tech:paint_glow_paint", 2 },
   {"inferno:fire_sticks", 1 },
   -- Materials
   {"nodes_nature:clay", 1, 2 },
   {"nodes_nature:silt", 1, 2 },
   {"nodes_nature:loam", 1, 2 },
   {"nodes_nature:sand", 1, 2 },
   {"tech:rammed_earth", 1, 3 },
   {"tech:charcoal", 2, 4 },
   {"tech:thatch", 2, 8 },
   {"tech:stick", 1, 18 },
   -- Items
   {"tech:torch", 1, 8 }, -- TODO: support fuel values perhaps?
   {"tech:small_wood_fire_unlit", 1, 2 },
   {"tech:clay_oil_lamp_unlit", 2 },
   {"tech:clay_oil_lamp_unfired", 1 },
   {"doors:door_wattle", 2, 4 }, -- They can't resist
   {"tech:wattle", 1, 6 },
   {"tech:wattle_loose", 1, 6 },
   {"tech:clay_water_pot_unfired", 1, 2},
   {"tech:clay_water_pot", 5, 2},
   {"backpacks:backpack_wicker_bag", 4 },
   {"tech:sleeping_mat_bottom", 1, 3 },
   {"ropes:ropeladder_top", 3, 5 },
   {"nodes_nature:lambakap_seed", 3, 24 },
   -- Edible but not rotten?
   {"nodes_nature:sasaran_cone", 1, 16 },
   {"nodes_nature:vansano_seed", 1, 36 },
   {"nodes_nature:merki", 2, 6 },
   {"tech:herbal_medicine", 3, 3},
   {"tech:tiku", 2, 4},
   {"tech:vegetable_oil", 1, 6},
   {"tech:maraka_bread_cooked", 3, 4},
   {"tech:maraka_bread_burned", 1, 4},
}
local bones_formspec = -- #TODO: get the bones mod to set this?
	"size[8,9]" ..
	"list[current_name;main;0,0.3;8,4;]" ..
	"list[current_player;main;0,4.85;8,1;]" ..
	"list[current_player;main;0,6.08;8,3;8]" ..
	"listring[current_name;main]" ..
	"listring[current_player;main]"

local counts = { light = 0, dark = 0 }

function replace(pos)
   local light = minimal.get_daylight(pos)
   if _EXILE_DEBUG then
      minetest.log("action", "EXILED BONES LOOT "..
		   minetest.pos_to_string(pos)..
		   " light: " .. tostring(light))
      if light > 0 then
	 counts.light = counts.light + 1
      else
	 counts.dark = counts.dark + 1
      end
   end
   minetest.set_node(pos, { name = "bones:bones" })
   local meta = minetest.get_meta(pos)
   local inv = meta:get_inventory()
   inv:set_size("main", 8 * 4)
   local total = math.random(0,10) -- how much this guy's stuff is worth
   -- #TODO: make total increase at high and low y levels, for the
   --        more daring of the dead exiles
   if total == 0 then return end
   local loot = table.copy(loot_table)
   repeat
      local roll = math.random(1, #loot)
      local pick = loot[roll]
      if pick[2] <= total then
	 local tooldef = minetest.registered_tools[pick[1]]
	 local pcount = math.random(1, pick[3] or 1)
	 local IS = ItemStack(pick[1].." "..tostring(pcount))
	 if not pick[3] and tooldef then
	    IS:set_wear(math.random(0,49152)) -- 75% max
	 end
	 inv:add_item("main", IS)
	 total = total - pick[2]
	 table.remove(loot, roll)
      end
   until total <= 0 or #loot == 0
   meta:set_string("infotext", "Bones of a long-dead exile")
   meta:set_string("formspec", bones_formspec)
end

minetest.register_lbm({
      label = "exiled bones loot",
      name="mapgen:exile_bones",
      nodenames = {"mapgen:exile_bones"},
      run_at_every_load = true,
      action = replace
})

-- Placeholder node, replaced at runtime with bones:bones, filled with loot
minetest.register_node("mapgen:exile_bones", {
	description = "Bones of a long-dead exile",
	inventory_image = "bones_inv.png",
	wield_image = "bones_inv.png",
	drop = "bones:bones",
	tiles = {"bones_bone.png"},
	stack_max = minimal.stack_max_bulky,
	drawtype = "nodebox",
	node_box = minimal.nodebox["bones"],
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	walkable = true,
	groups = {not_in_creative_inventory = 1},
	sounds = nodes_nature.node_sound_gravel_defaults(),
	on_punch = replace
})

if _EXILE_DEBUG then
   minetest.register_on_shutdown(function()
	 minetest.log("action", "Bones generated: "..
		      tostring(counts.light).."/"..tostring(counts.dark)..
		      " - Total: "..tostring(counts.dark + counts.light))
   end)
end

-- Import
local path = minetest.get_modpath("mapgen")

local on = {
      "nodes_nature:silt" ,
      "nodes_nature:clay",
      "nodes_nature:sand",
      "nodes_nature:gravel",
      "nodes_nature:granite",
      "nodes_nature:limestone",
      "nodes_nature:gneiss",
      "nodes_nature:claystone",
      "nodes_nature:marshland_soil", "nodes_nature:marshland_soil_wet",
      "nodes_nature:grassland_soil", "nodes_nature:grassland_soil_wet",
      "nodes_nature:highland_soil",  "nodes_nature:highland_soil_wet" ,
      "nodes_nature:duneland_soil",  "nodes_nature:duneland_soil_wet" ,
      "nodes_nature:woodland_soil",  "nodes_nature:woodland_soil_wet" ,
}

local bones = {
    {
        name = "mapgen:exile_bones",
        deco_type = "simple",
        place_on = on,
        sidelen = 80,
        fill_ratio = 0.000100,
        y_min = -200, -- caves
        y_max = 300, -- and mountains
        decoration = "mapgen:exile_bones",
    },
}

return { bones = bones }
