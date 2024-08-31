-------------------------------------------------------------
--EARTHEN BUILDING
-- construction from loose stones, mud etc

tech = tech
nodes_nature = nodes_nature

-- Internationalization
local S = tech.S

local c_alpha = minimal.compat_alpha

---------------------------------
--DRYSTACK
-- walls made from stacked stones (no mortar, hence dry)
-- made from loose found stones

minetest.register_node("tech:drystack", {
	description = S("Drystack"),
	tiles = {"tech_drystack.png"},
	stack_max = minimal.stack_max_bulky *1.5,
	groups = {cracky = 3, crumbly = 1, falling_node = 1,
		  oddly_breakable_by_hand = 1},
	sounds = nodes_nature.node_sound_stone_defaults(),
})

ncrafting.register_arch("tech:drystack")

-- Stairs and slab for drystack
stairs.register_stair_and_slab(
	"drystack",
	"tech:drystack",
	{"hand_mixing","mixing_spot"},
	"true",
	{"hand_mixing","mixing_spot"},
	{cracky = 3, crumbly = 1, oddly_breakable_by_hand = 1, falling_node = 1},
	{"tech_drystack.png"},
	S("Drystack Stair"),
	S("Drystack Slab"),
	minimal.stack_max_bulky *3,
	nodes_nature.node_sound_stone_defaults()
)


------------------------------------------
--MUDBRICK

minetest.register_node('tech:mudbrick', {
	description = S('Mudbrick'),
	tiles = {"tech_mudbrick.png"},
	drop = "nodes_nature:clay",
	stack_max = minimal.stack_max_bulky *2,
	groups = {crumbly = 2, cracky = 3, oddly_breakable_by_hand = 1,},
	sounds = nodes_nature.node_sound_dirt_defaults(),
})

stairs.register_stair_and_slab(
	"mudbrick",
	"tech:mudbrick",
	{"brick_makers_bench_mixing","mixing_spot"},
	"true",
	{"brick_makers_bench_mixing","mixing_spot"},
	{crumbly = 2, cracky = 3, oddly_breakable_by_hand = 1,},
	{"tech_mudbrick.png"},
	S("Mudbrick Stair"),
	S("Mudbrick Slab"),
	minimal.stack_max_bulky *4,
	nodes_nature.node_sound_dirt_defaults(),
	nil,
	"nodes_nature:clay"
)

------------------------------------------
--RAMMED EARTH

minetest.register_node('tech:rammed_earth', {
	description = S('Rammed Earth'),
	tiles = {
		"tech_rammed_earth.png",
		"tech_rammed_earth_side.png",
		"tech_rammed_earth_side.png",
		"tech_rammed_earth_side.png",
		"tech_rammed_earth_side.png",
		"tech_rammed_earth_side.png"
	},
	stack_max = minimal.stack_max_bulky *1.5,
	groups = {crumbly = 1, cracky = 3, falling_node = 1},
	sounds = nodes_nature.node_sound_dirt_defaults(),
})

ncrafting.register_arch("tech:rammed_earth")

stairs.register_stair_and_slab(
	"rammed_earth",
	"tech:rammed_earth",
	{"brick_makers_bench_mixing","mixing_spot"},
	"true",
	{"brick_makers_bench_mixing","mixing_spot"},
	{crumbly = 1, cracky = 3, falling_node = 1},
	{
		"tech_rammed_earth.png",
		"tech_rammed_earth_side.png",
		"tech_rammed_earth_side.png",
		"tech_rammed_earth_side.png",
		"tech_rammed_earth_side.png",
		"tech_rammed_earth_side.png"
	},
	S("Rammed Earth Stair"),
	S("Rammed Earth Slab"),
	minimal.stack_max_bulky *3,
	nodes_nature.node_sound_dirt_defaults()
)

------------------------------------------
--Wicker well lining

-- Has wet/dry_sediment groups, but not sediment;
--  allows water to permeate, but prevents collapse due to erosion
-- Like wattle, doesn't fall. Should it? Needs play testing

local wickdef =  {
   drawtype = "normal",
   paramtype = "light",
   paramtype2 = "wallmounted",
   use_texture_alpha = c_alpha.clip,
   --inventory_image = "tech_wattle.png",
   --wield_image = "tech_wattle.png",
   stack_max = minimal.stack_max_bulky * 3,
   groups = {choppy = 3, oddly_breakable_by_hand = 1,
   },
   sounds = nodes_nature.node_sound_wood_defaults(),
}

local wwdesc = { S('Wicker well lining'),
		 S('Wet wicker well lining'),
		 S('Salty wet wicker well lining') }

local soiltable = {}
for i = 1, #nodes_nature.sed_list do
   soiltable[i] = nodes_nature.sed_list[i][1]
end

local wtable = { "", "_wet","_wet_salty" }
local bn = 'tech:wicker_lined_'
local c = nodes_nature.replacement_types

for i = 1, #soiltable do
   local wdef = table.copy(wickdef)
   wdef.drop = { max_items = 2,
		 items = {
		    { items = { "nodes_nature:"..soiltable[i] } },
		    { items = {"tech:wattle"} },
		 }
   }
   wdef._dry_name = bn..soiltable[i]
   wdef._wet_name = bn..soiltable[i]..wtable[2]
   wdef._wet_salty_name = bn..soiltable[i]..wtable[3]
   for j = 1, #wtable do
      local wdef2 = table.copy(wdef)
      wdef2.description = wwdesc[j]
      wdef2.groups.wet_sediment = j - 1
      if j == 1 then wdef2.groups.dry_sediment = 1 end
      local tile = "nodes_nature_"..soiltable[i]..".png"
      if j > 1 then tile = tile.."^nodes_nature_mud.png" end
      if j == 3 then tile = tile.."^nodes_nature_mud_salt.png" end
      local wicker = "tech_wattle.png"
      if j > 1 then wicker = wicker.."^nodes_nature_mud.png" end
      wdef2.tiles = {wicker, tile, tile, tile, tile, tile }
      minetest.register_node(bn..soiltable[i]..wtable[j],
			     wdef2)
   end
   tgcr.register_replacement(bn..soiltable[i]..wtable[1],
			     bn..soiltable[i]..wtable[2], c.REPLACEMENT_WET)
   tgcr.register_replacement(bn..soiltable[i]..wtable[1],
			     bn..soiltable[i]..wtable[3], c.REPLACEMENT_SALTY)
   tgcr.register_replacement(bn..soiltable[i]..wtable[2],
			     bn..soiltable[i]..wtable[1], c.REPLACEMENT_DRY)
   tgcr.register_replacement(bn..soiltable[i]..wtable[3],
			     bn..soiltable[i]..wtable[1], c.REPLACEMENT_DRY)
end

local function wellmaker(user,itemstack, pointed_thing)
   if not user or not minetest.is_player(user) then return end
   if not pointed_thing or pointed_thing.type ~= "node" then return end
   local node = minetest.get_node(pointed_thing.under)
   if minetest.get_item_group(node.name, "sediment") == 0 then return end
   local def = minetest.registered_nodes[node.name]
   if not def then return end
   local soil = string.gsub(def.drop or def.name, def.mod_origin..":", "")
   local look = minetest.yaw_to_dir(user:get_look_horizontal())
   local p2 = minetest.dir_to_wallmounted(look)
   minetest.set_node(pointed_thing.under, {name = bn..soil, param2 = p2})
   if minimal.player_in_creative(user) then return end
   itemstack:take_item()
   return itemstack
end

-----------------------------------------------------------
--WATTLE

minetest.register_node('tech:wattle', {
	description = S('Wattle'),
	drawtype = "nodebox",
	node_box = {
		type = "connected",
		fixed = {{-1/8, -1/2, -1/8, 1/8, 1/2, 1/8}},
		-- connect_bottom =
		connect_front = {{-1/8, -1/2, -1/2,  1/8, 1/2, -1/8}},
		connect_left = {{-1/2, -1/2, -1/8, -1/8, 1/2,  1/8}},
		connect_back = {{-1/8, -1/2,  1/8,  1/8, 1/2,  1/2}},
		connect_right = {{ 1/8, -1/2, -1/8,  1/2, 1/2,  1/8}},
	},
	connects_to = {
		"group:sediment",
		"group:tree",
		"group:log",
		"group:stone",
		"group:masonry",
		"group:soft_stone",
		'tech:drystack',
		'tech:mudbrick',
		'tech:rammed_earth',
		'tech:wattle_loose',
		'tech:wattle_door_frame',
		'tech:wattle',
		'tech:thatch'
	},
	paramtype = "light",
	use_texture_alpha = c_alpha.clip,
	tiles = {"tech_wattle_top.png",
		 "tech_wattle_top.png",
		 "tech_wattle.png",
		 "tech_wattle.png",
		 "tech_wattle.png",
		 "tech_wattle.png" },
	inventory_image = "tech_wattle.png",
	wield_image = "tech_wattle.png",
	stack_max = minimal.stack_max_bulky * 3,
	groups = {choppy = 3, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = nodes_nature.node_sound_wood_defaults(),
	_use_tip = S("Reinforce a well wall"),
	_on_use_item = wellmaker,
})

--a crude window... or for resource saving
minetest.register_node('tech:wattle_loose', {
	description = S('Loose Wattle'),
	drawtype = "nodebox",
	node_box = {
		type = "connected",
		fixed = {{-1/8, -1/2, -1/8, 1/8, 1/2, 1/8}},
		-- connect_bottom =
		connect_front = {{-1/8, -1/2, -1/2,  1/8, 1/2, -1/8}},
		connect_left = {{-1/2, -1/2, -1/8, -1/8, 1/2,  1/8}},
		connect_back = {{-1/8, -1/2,  1/8,  1/8, 1/2,  1/2}},
		connect_right = {{ 1/8, -1/2, -1/8,  1/2, 1/2,  1/8}},
	},
	connects_to = {
		"group:sediment",
		"group:tree",
		"group:log",
		"group:stone",
		"group:masonry",
		"group:soft_stone",
		'tech:drystack',
		'tech:mudbrick',
		'tech:rammed_earth',
		'tech:wattle_loose',
		'tech:wattle_door_frame',
		'tech:wattle',
		'tech:thatch'
	},
	paramtype = "light",
	use_texture_alpha = c_alpha.clip,
	tiles = {"tech_wattle_top.png",
		 "tech_wattle_top.png",
		 "tech_wattle_loose.png",
		 "tech_wattle_loose.png",
		 "tech_wattle_loose.png",
		 "tech_wattle_loose.png" },
	inventory_image = "tech_wattle_loose.png",
	wield_image = "tech_wattle_loose.png",
	stack_max = minimal.stack_max_bulky * 3,
	groups = {choppy = 3, oddly_breakable_by_hand = 1, flammable = 2, temp_pass = 1},
	sounds = nodes_nature.node_sound_wood_defaults(),
})

--A frame to let wattle walls connect to wattle doors
--TODO: Make it detect wattle or doors and rotate itself to match

local function wdf_connect_to_door(pos)
   local pnode = minetest.get_node(pos)
   local door = minetest.find_nodes_in_area(
      {x = pos.x - 1, y = pos.y - 2, z = pos.z - 1},
      {x = pos.x + 1, y = pos.y + 2, z = pos.z + 1},
      {"group:door"}  )
   if #door > 0 then
      local vec = vector.round(vector.direction(pos, door[1]))
      local dnode = minetest.get_node(door[1])
      if vec.x == 1 then --east
	 if dnode.param2 == 2 then pnode.param2 = 20 end
	 if dnode.param2 == 0 then pnode.param2 = 2  end
      elseif vec.x == -1 then --west
	 if dnode.param2 == 2 then pnode.param2 = 0  end
	 if dnode.param2 == 0 then pnode.param2 = 22 end
      elseif vec.z == 1 then --north
	 if dnode.param2 == 3 then pnode.param2 = 1  end
	 if dnode.param2 == 1 then pnode.param2 = 21 end
      elseif vec.z == -1 then --south
	 if dnode.param2 == 1 then pnode.param2 = 3  end
	 if dnode.param2 == 3 then pnode.param2 = 23 end
      elseif vec.y == -1 then --straight down
	 if dnode.param2 == 2 then pnode.param2 = 16 end
	 if dnode.param2 == 0 then pnode.param2 = 14 end
	 if dnode.param2 == 3 then pnode.param2 = 5  end
	 if dnode.param2 == 1 then pnode.param2 = 11 end
      elseif vec.y == 1 then --straight up
	 if dnode.param2 == 2 then pnode.param2 = 12 end
	 if dnode.param2 == 0 then pnode.param2 = 18 end
	 if dnode.param2 == 3 then pnode.param2 = 9  end
	 if dnode.param2 == 1 then pnode.param2 = 7  end
      end
   minetest.swap_node(pos, {name = "tech:wattle_door_frame",
			   param1 = pnode.param1,
			   param2 = pnode.param2})
   end
end

minetest.register_node('tech:wattle_door_frame', {
	description = S('Wattle Door Frame'),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {{-1/2, -1/2, -1/8,  1/2, 1/2, 1/8},
		         {-4/8, -1/2, 1/8,  -3/8, 1/2, 1/2}},
	},
	paramtype = "light",
	paramtype2 = "facedir",
	use_texture_alpha = c_alpha.clip,
	tiles = {"tech_wattle_top.png",
		 "tech_wattle_top.png",
		 "tech_wattle.png",
		 "tech_wattle.png",
		 "tech_wattle.png",
		 "tech_wattle.png",
},
	inventory_image = "tech_wattle_door_frame.png",
	wield_image = "tech_wattle_door_frame.png",
	stack_max = minimal.stack_max_bulky * 3,
	groups = {choppy = 3, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = nodes_nature.node_sound_wood_defaults(),
	on_construct = wdf_connect_to_door,
})


------------------------------------------
--THATCH

minetest.register_node('tech:thatch', {
	description = S('Thatch'),
	tiles = {"tech_thatch.png"},
	stack_max = minimal.stack_max_bulky * 4,
	groups = {snappy=3, flammable=1, fall_damage_add_percent = -30},
	sounds = nodes_nature.node_sound_leaves_defaults(),
	_splits_by_hand = "stairs:slab_thatch",
	_on_use_node = minimal.slabs_split_hand,
	on_burn = function(pos)
		if math.random()<0.5 then
			minimal.switch_node(pos, {name = "tech:small_wood_fire"})
			minetest.check_for_falling(pos)
		else
			minetest.remove_node(pos)
		end
	end,
})

stairs.register_stair_and_slab(
	"thatch",
	"tech:thatch",
	"hand_mixing",
	"true",
	"hand_mixing",
	{snappy=3, flammable=1, fall_damage_add_percent = -15},
	{"tech_thatch.png"},
	S("Thatch Stair"),
	S("Thatch Slab"),
	minimal.stack_max_bulky * 8,
	nodes_nature.node_sound_leaves_defaults()
)

minetest.override_item("stairs:slab_thatch", {
	_use_tip = S("Combine with another slab"),
	_on_use_item = function(player, wielded_item, pointed_thing)
	   return minimal.slabs_combine(player, wielded_item,
					pointed_thing, "tech:thatch")
	end,
})

---------------------------------------
--Recipes

--
--Hand crafts (Crafting spot)
--

----craft drystack from gravel
crafting.register_recipe({
	type = {"crafting_spot","hand"},
	output = "tech:drystack 2",
	items = {"nodes_nature:gravel 3"},
	level = 1,
	always_known = true,
})

--recycle drystack with some loss
crafting.register_recipe({
	type = {"mixing_spot","hand_mixing"},
	output = "nodes_nature:gravel",
	items = {"tech:drystack"},
	level = 1,
	always_known = true,
})


----mudbrick from clay and fibre
crafting.register_recipe({
	type = "brick_makers_bench",
	output = "tech:mudbrick",
	items = {"nodes_nature:clay_wet", "group:fibrous_plant"},
	level = 1,
	always_known = true,
})

----Rammed earth by compacting clay
crafting.register_recipe({
	type = "brick_makers_bench",
	output = "tech:rammed_earth 2",
	items = {"nodes_nature:clay 3"},
	level = 1,
	always_known = true,
})

--recycle rammed_earth with some loss
crafting.register_recipe({
	type = "brick_makers_bench_mixing",
	output = "nodes_nature:clay",
	items = {"tech:rammed_earth"},
	level = 1,
	always_known = true,
})


----Wattle from sticks or converting from loose wattle or door_wattle
crafting.register_recipe({
	type = {"crafting_spot","hand",'knife_wattle'},
	output = "tech:wattle",
	items = {{"tech:stick 6","tech:wattle_loose 2","tech:wattle_door_frame","doors:door_wattle","tech:trapdoor_wattle"}},
	level = 1,
	always_known = true,
})

--recycle wattle with some loss
crafting.register_recipe({
	type = {"mixing_spot",'knife_wattle'},
	output = "tech:stick 4",
	items = {"tech:wattle"},
	level = 1,
	always_known = true,
})

----Loose Wattle from sticks or converting from wattle
crafting.register_recipe({
	type = {"crafting_spot","hand",'knife_wattle'},
	output = "tech:wattle_loose 2",
	items = {{"tech:stick 6","tech:wattle"}},
	level = 1,
	always_known = true,
})

--recycle loose wattle with some loss
crafting.register_recipe({
	type = {"mixing_spot",'knife_wattle'},
	output = "tech:stick 2",
	items = {"tech:wattle_loose"},
	level = 1,
	always_known = true,
})

----Wattle door frame from sticks or convert from wattle
crafting.register_recipe({
	type = {"crafting_spot","hand",'knife_wattle'},
	output = "tech:wattle_door_frame",
	items = {{"tech:stick 6","tech:wattle"}},
	level = 1,
	always_known = true,
})

----Thatch from  fibre
crafting.register_recipe({
	type = "hand",
	output = "tech:thatch",
	items = {"group:fibrous_plant 8"},
	level = 1,
	always_known = true,
})

----Wicker basket from sticks
crafting.register_recipe({
	type = "weaving_frame",
	output = "tech:wicker_storage_basket",
	items = {"tech:stick 96"},
	level = 1,
	always_known = true,
})

----woven basket from fibrous_plant
crafting.register_recipe({
	type = "weaving_frame",
	output = "tech:woven_storage_basket",
	items = {"group:fibrous_plant 96"},
	level = 1,
	always_known = true,
})
