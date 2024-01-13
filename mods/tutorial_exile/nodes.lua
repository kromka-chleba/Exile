--------------------------------------------------------------------------------
-- Tutorial nodes

minetest.register_node("tutorial_exile:invisible_wall", {
        description = "Tutorial boundary wall",
        tiles = {"climate_air.png"},
        drawtype = "airlike",
        paramtype = "light",
        sunlight_propagates = true,
	pointable = false,
        walkable = true,
        buildable_to = false,
        floodable = false,
	wield_image = "tech_trapdoor_wattle_side.png",
	inventory_overlay = "tech_trapdoor_wattle_side.png",
        groups = {temp_pass = 1, not_in_creative_inventory = 1},
	post_effect_color = {a = 5, r = 254, g = 254, b = 254},
	color = {a=0, r=254, g = 254, b = 254},
	use_texture_alpha = "blend",
})

minetest.register_ore({
  ore_type        = "stratum",
  ore             = "tutorial_exile:invisible_wall",
  wherein         = {"air"},
  clust_scarcity  = 1,
  y_max           = 9000,
  y_min           = 9000,
  stratum_thickness = 1,
})

minetest.register_node('tutorial_exile:wall', {
        description = 'Tutorial wall',
        tiles = {
                "tech_rammed_earth.png",
                "tech_rammed_earth_side.png",
        },
	groups = { not_in_creative_inventory = 1 },
})

if minetest.is_creative_enabled() then
   minetest.override_item("tutorial_exile:invisible_wall", {
		drawtype = "glasslike",
		pointable = true,
		diggable = true,
		groups = {crumbly = 1, cracky = 3,
			  temp_pass = 1},
   })
   minetest.override_item('tutorial_exile:wall', {
			     groups = {crumbly = 1, cracky = 3},
   })
end

local lpname = "tut_lighted_path"
local lpdef = {
        description = 'Lighted Path',
        tiles = { {
	   name = lpname,
	   animation = { type = "vertical_frames",
			 aspect_w = 1,
			 aspect_h = 1,
			 length = 3 }
	}},
	groups = { not_in_creative_inventory = 1,
		   oddly_breakable_by_hand = 1},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
	   local name = itemstack:get_name()
	   local pfx = "tutorial_exile:tut_lighted_path"
	   local num = tonumber((name:gsub(pfx,"")))
	   num = num +1 if num == 9 then num = 1 end
	   itemstack:replace(pfx..tostring(num))
	end,
}
if minetest.is_creative_enabled() then lpdef.diggable = true end
for i = 1, 8 do
   local def = table.copy(lpdef)
   local name = lpname..tostring(i)
   def.tiles[1].name = name..".png"
   if i == 1 and minetest.is_creative_enabled() then
      def.groups.not_in_creative_inventory = 0
   end
   minetest.register_node("tutorial_exile:"..name, def)
end



minetest.register_node("tutorial_exile:wet_silt_grass", {
        description = "Wet Woodland Soil",
        tiles = {"nodes_nature_woodland_soil.png^nodes_nature_mud.png",
		 "nodes_nature_silt.png^nodes_nature_mud.png",
		 "nodes_nature_silt.png^"..
		    "nodes_nature_woodland_soil_side.png^"..
		    "nodes_nature_mud.png"
},
	sounds = { footstep = {name = "nodes_nature_mud", gain = 0.4},
		   dug = {name = "nodes_nature_mud", gain = 0.4} },
	groups = { crumbly = 3, falling_node = 1, puts_out_fire = 1,
		   not_in_creative_inventory = 1 }
})

minetest.register_node("tutorial_exile:wet_silt", {
        description = "Wet Silt",
        tiles = {"nodes_nature_silt.png^nodes_nature_mud.png",
		 "nodes_nature_silt.png^nodes_nature_mud.png",
		 "nodes_nature_silt.png^nodes_nature_mud.png"
},
	sounds = { footstep = {name = "nodes_nature_dirt_footstep", gain = 0.4},
		   dig = {name = "nodes_nature_dig_crumbly", gain = 1.0},
		   dug = {name = "nodes_nature_dirt_footstep", gain = 1.0}
	},
	groups = { crumbly = 3, falling_node = 1, puts_out_fire = 1,
		   not_in_creative_inventory = 1 }
})
