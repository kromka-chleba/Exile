----------------------------------------------------------
--WATERWORKING

-- Internationalisaton
local S = tech.S

-------------------------------------------------------------------
--#TODO: THIS SHOULD BE MOVED somewhere GENERALIZED to handle non-pottery pots
local function water_pot(pos, pot_name, elapsed)
   local light = minimal.get_daylight({x=pos.x, y=pos.y + 1, z=pos.z}, 0.5)
   --collect rain
   if light == 15 then
      if climate.get_rain(pos, light) or
      climate.time_since_rain(elapsed) > 0 then
        minetest.swap_node(pos, {name = pot_name.."_freshwater"})
        return
      end
  else
    --drain wet sediment into the pot
    --or melt snow and ice
    local posa = 	{x = pos.x, y = pos.y+1, z = pos.z}
    local name_a = minetest.get_node(posa).name
    if name_a == "air" then
      return true
    elseif (name_a == "nodes_nature:ice" or
    name_a == "nodes_nature:snow_block" or
    name_a == "nodes_nature:freshwater_source" ) then
      if climate.can_thaw(posa) then
        minetest.swap_node(pos, {name = pot_name.."_freshwater"})
        minetest.remove_node(posa)
        return
      end
      end
   end
   return true
end

-- checks if can drink, and sets player's thirst if can
local function drink_water(player)
  if not minetest.is_player(player) then
    return
  end
  local meta = player:get_meta()
  local thirst = meta:get_int("thirst")
  if thirst < 100 then
    -- only drink when thirsty, return true and set player's thirst if so
    HEALTH.set_int(meta,"thirst",100)
    return true
  end
end

-----------------------------------------------------------
-- Clay Water pot
--for collecting water, catching rain water
minetest.register_node("tech:clay_water_pot", {
	description = S("Clay Water Pot"),
	tiles = {
		"tech_pottery.png^tech_pot_empty.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png"
	},
	drawtype = "nodebox",
	stack_max = minimal.stack_max_bulky,
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.25, 0.375, -0.25, 0.25, 0.5, 0.25}, -- NodeBox1
			{-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
			{-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
			{-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
			{-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125}, -- NodeBox5
		}
	},
	liquids_pointable = true,
  groups = {dig_immediate = 3, pottery = 1, temp_pass = 1, timer = 45 },
	sounds = nodes_nature.node_sound_stone_defaults(),
	on_use = function(itemstack, user, pointed_thing)
	   return liquid_store.on_use_empty_bucket(itemstack, user,
						   pointed_thing)
	end,
	on_place = function(itemstack, placer, pointed_thing)
	   return liquid_store.on_place(itemstack, placer,
					pointed_thing)
	end,
	--collect rain water
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(30,60))
	end,
	on_timer =function(pos, elapsed)
		return water_pot(pos, "tech:clay_water_pot", elapsed)
	end,
})

-----------------------------------------------
--Register water stores for clay water pot
--source, nodename, nodename_empty, tiles, node_box, desc, groups

--clay pot with salt water
liquid_store.register_stored_liquid("tech:clay_water_salt_water",{
  source = "nodes_nature:salt_water_source",
  empty = "tech:clay_water_pot",
  description = S("Clay Water Pot with Salt Water"),
  groups = {dig_immediate=2, pottery = 1},
  sounds = nodes_nature.node_sound_stone_defaults(),
  tiles = {
    "tech_pottery.png^tech_pot_empty.png^tech_pot_water.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png"
  },
  node_box = {
    type = "fixed",
		fixed = {
			{-0.25, 0.375, -0.25, 0.25, 0.5, 0.25}, -- NodeBox1
			{-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
			{-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
			{-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
			{-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125}, -- NodeBox5
		}
  },
})

--clay pot with freshwater
liquid_store.register_stored_liquid("tech:clay_water_pot_freshwater",{
  source = "nodes_nature:freshwater_source",
  empty = "tech:clay_water_pot",
  description = S("Clay Water Pot with Freshwater"),
  groups = {dig_immediate = 2, pottery = 1},
  tiles = {
    "tech_pottery.png^tech_pot_empty.png^tech_pot_water.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png"
  },
  node_box = {
    type = "fixed",
		fixed = {
			{-0.25, 0.375, -0.25, 0.25, 0.5, 0.25}, -- NodeBox1
			{-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
			{-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
			{-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
			{-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125}, -- NodeBox5
		}
  },
  --make freshwater Pot drinkable on click
  on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if drink_water(clicker) then
      minimal.switch_node(pos, {name = "tech:clay_water_pot"})
			minetest.sound_play("nodes_nature_slurp",
      {pos = pos, max_hear_distance = 3, gain = 0.25})
    end
  end,
})

-----------------------------------------------------------
--Wooden Water pot
--for collecting water, catching rain water
minetest.register_node("tech:wooden_water_pot", {
	description = S("Wooden Water Pot"),
  groups = {dig_immediate = 3, flammable = 1, temp_pass = 1},
	sounds = nodes_nature.node_sound_wood_defaults(),
	tiles = {
		"tech_primitive_wood.png^tech_pot_empty.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png"
	},
	drawtype = "nodebox",
	stack_max = minimal.stack_max_bulky,
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.25, 0.375, -0.25, 0.25, 0.5, 0.25}, -- NodeBox1
			{-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
			{-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
			{-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
			{-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125}, -- NodeBox5
		}
	},
	liquids_pointable = true,
	on_use = function(itemstack, user, pointed_thing)
		return liquid_store.on_use_empty_bucket(itemstack, user, pointed_thing)
	end,
  on_place = function(itemstack, placer, pointed_thing)
    return liquid_store.on_place(itemstack, placer, pointed_thing)
  end,
		--collect rain water
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(30,60))
	end,
	on_timer =function(pos, elapsed)
		return water_pot(pos, "tech:wooden_water_pot", elapsed)
	end,
})


crafting.register_recipe({
	type = {"chopping_block","axe"},
	output = "tech:wooden_water_pot",
	items = {'group:log 2'},
	level = 1,
	always_known = true,
})


-----------------------------------------------
--Register water stores for wooden water pots
--source, nodename, nodename_empty, tiles, node_box, desc, groups

-- pot with salt water
liquid_store.register_stored_liquid("tech:wooden_water_pot_salt_water",{
  source = "nodes_nature:salt_water_source",
  empty = "tech:wooden_water_pot",
  description = S("Wooden Water Pot with Salt Water"),
	groups = {dig_immediate = 2},
  tiles = {
		"tech_primitive_wood.png^tech_pot_empty.png^tech_pot_water.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png"
	},
  node_box = {
		type = "fixed",
		fixed = {
			{-0.25, 0.375, -0.25, 0.25, 0.5, 0.25}, -- NodeBox1
			{-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
			{-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
			{-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
			{-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125}, -- NodeBox5
		}
	},
})


--pot with freshwater
liquid_store.register_stored_liquid("tech:wooden_water_pot_freshwater",{
  source = "nodes_nature:freshwater_source",
  empty = "tech:wooden_water_pot",
  description = S("Wooden Water Pot with Freshwater"),
	groups = {dig_immediate = 2},
  tiles = {
		"tech_primitive_wood.png^tech_pot_empty.png^tech_pot_water.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png"
	},
  node_box = {
		type = "fixed",
		fixed = {
			{-0.25, 0.375, -0.25, 0.25, 0.5, 0.25}, -- NodeBox1
			{-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
			{-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
			{-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
			{-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125}, -- NodeBox5
		}
	},
  --make freshwater Pot drinkable on click
  on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if drink_water(clicker) then
      minimal.switch_node(pos, {name = "tech:wooden_water_pot"})
			minetest.sound_play("nodes_nature_slurp",
        {pos = pos, max_hear_distance = 3, gain = 0.25})
    end
	end
})

--------------------------------------
--Watering Can
local watering_can_nodebox = {
	-- lid
	{-0.2, 0.2,-0.2, 0.2, 0.3, 0.2},
	-- handle
    {-0.05, 0.05, -0.25, 0.05, 0.15, -0.45}, -- upper
    {-0.05, -0.1, -0.35, 0.05, 0.05, -0.45}, -- mid
    {-0.05, -0.2, -0.25, 0.05, -0.1, -0.45}, -- low
    -- spout
    {-0.1, 0.1, 0.25, 0.1, 0.2, 0.5}, -- upper
    {-0.1, -0.4, 0.25, 0.1, 0.1, 0.4},
    -- body
    {-0.25, -0.4, -0.25, 0.25, 0.2, 0.25},
    -- base
    {-0.3, -0.5,-0.4, 0.3, -0.35, 0.4},
}

-- clay watering can
-- can turn a block in it's wet variant
-- fills itselft with rain
-- acts similar to clay_water_pot
minetest.register_node("tech:clay_watering_can", {
	description = S("Clay Watering Can"),
	tiles = {
		"tech_pottery.png^tech_watering_can_empty.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png"
	},
	drawtype = "nodebox",
	stack_max = minimal.stack_max_bulky,
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = watering_can_nodebox
	},
	liquids_pointable = true,
	groups = {dig_immediate = 3, pottery = 1, temp_pass = 1, timer = 45},
	sounds = nodes_nature.node_sound_stone_defaults(),
	on_use = function(itemstack, user, pointed_thing)
	   return liquid_store.on_use_empty_bucket(itemstack, user,
						   pointed_thing)
	end,
  --collect rain water
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(30,60))
	end,
	on_timer =function(pos, elapsed)
		return water_pot(pos, "tech:clay_watering_can", elapsed)
	end,

})

--clay watering can with fresh water
liquid_store.register_stored_liquid("tech:clay_watering_can_freshwater",{
  source = "nodes_nature:freshwater_source",
  empty = "tech:clay_watering_can",
  dumpable = false,
  description = S("Clay Watering Can with Freshwater"),
	groups = {dig_immediate = 2, pottery = 1},
  sounds = nodes_nature.node_sound_stone_defaults(),
  tiles = {
		"tech_pottery.png^tech_watering_can_empty.png^tech_pot_water.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png"
	},
  node_box = {
		type = "fixed",
		fixed = watering_can_nodebox
	},
  --make clay watering can able to water a block on click
  on_use = function(itemstack, user, pointed_thing)
    return ncrafting.water_soil(itemstack, user, pointed_thing)
	end,
})
	
--clay watering can with salt water
liquid_store.register_stored_liquid("tech:clay_watering_can_salt_water",{
  source = "nodes_nature:salt_water_source",
  empty = "tech:clay_watering_can",
  dumpable = false,
  description = S("Clay Watering Can with Salt Water"),
	groups = {dig_immediate = 2, pottery = 1},
  sounds = nodes_nature.node_sound_stone_defaults(),
  tiles = {
		"tech_pottery.png^tech_watering_can_empty.png^tech_pot_water.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png"
	},
  node_box = {
		type = "fixed",
		fixed = watering_can_nodebox
	},
  on_use = function(itemstack, user, pointed_thing)
    return ncrafting.water_soil(itemstack, user, pointed_thing, "salty")
	end,
})

-- wooden watering can
minetest.register_node("tech:wooden_watering_can", {
	description = S("Wooden Watering Can"),
	tiles = {
		"tech_primitive_wood.png^tech_watering_can_empty.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png"
	},
	drawtype = "nodebox",
	stack_max = minimal.stack_max_bulky,
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = watering_can_nodebox
	},
	liquids_pointable = true,
	groups = {dig_immediate = 3, flammable = 1, temp_pass = 1, timer = 45},
	sounds = nodes_nature.node_sound_wood_defaults(),
	on_use = function(itemstack, user, pointed_thing)
	   return liquid_store.on_use_empty_bucket(itemstack, user,
						   pointed_thing)
	end,
  --collect rain water
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(30,60))
	end,
	on_timer = function(pos, elapsed)
		return water_pot(pos, "tech:wooden_watering_can", elapsed)
	end
})

crafting.register_recipe({
	type = {"carpentry_bench","axe"},
	output = "tech:wooden_watering_can",
	items = {'group:log 2', 'tech:vegetable_oil'},
	level = 1,
	always_known = true,
})

--wooden watering can with fresh water
liquid_store.register_stored_liquid("tech:wooden_watering_can_freshwater",{
  source = "nodes_nature:freshwater_source",
  empty = "tech:wooden_watering_can",
  dumpable = false,
  description = S("Wooden Watering Can with Freshwater"),
	groups = {dig_immediate = 2},
  tiles = {
		"tech_primitive_wood.png^tech_watering_can_empty.png^tech_pot_water.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png"
	},
  node_box = {
		type = "fixed",
		fixed = watering_can_nodebox
	},
  --make wooden watering can able to water a block on click
  on_use = function(itemstack, user, pointed_thing)
    return ncrafting.water_soil(itemstack, user, pointed_thing)
	end,
})

	
--wooden watering can with salt water
liquid_store.register_stored_liquid("tech:wooden_watering_can_salt_water",{
	source = "nodes_nature:salt_water_source",
	empty = "tech:wooden_watering_can",
  dumpable = false,
  description = S("Wooden Watering Can with Salt Water"),
	groups = {dig_immediate = 2},
	tiles = {
		"tech_primitive_wood.png^tech_watering_can_empty.png^tech_pot_water.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png"
	},
	node_box = {
		type = "fixed",
		fixed = watering_can_nodebox
	},
  on_use = function(itemstack, user, pointed_thing)
    return ncrafting.water_soil(itemstack, user, pointed_thing, "salty")
	end,
})

-----------------------------------------------------------
-- GLASS VESSELS
local c_alpha = minimal.compat_alpha
-- More portable liquid storage than clay pots
-- Need inventory images, otherwise clear glass ones will be invisible
minetest.register_node("tech:glass_bottle_green", {
	description = S("Green Glass Bottle"),
	tiles = {"tech_green_glass.png"},
	inventory_image = "tech_bottle_green_icon.png",
	drawtype = "mesh",
	mesh = "tech_bottle.obj",
	stack_max = minimal.stack_max_bulky * 2,
	paramtype = "light",
	liquids_pointable = true,
	sunlight_prpagates = true,
	on_use = function(itemstack, user, pointed_thing)
		return liquid_store.on_use_empty_bucket(itemstack, user, pointed_thing)
	end,
  on_place = function(itemstack, placer, pointed_thing)
    return liquid_store.on_place(itemstack, placer, pointed_thing)
  end,
	groups = {dig_immediate = 2, temp_pass = 1},
	sounds = nodes_nature.node_sound_stone_defaults(),
	use_texture_alpha = c_alpha.blend,
	selection_box = {
		type='fixed',
		fixed={-0.275, -0.5, -0.225, 0.25, 0.35, 0.275},
	},
})

minetest.register_node("tech:glass_bottle_clear", {
	description = S("Clear Glass Bottle"),
	tiles = {"tech_clear_glass.png"},
	inventory_image = "tech_bottle_clear_icon.png",
	drawtype = "mesh",
	mesh = "tech_bottle.obj",
	stack_max = minimal.stack_max_bulky * 2,
	paramtype = "light",
	liquids_pointable = true,
	sunlight_prpagates = true,
	on_use = function(itemstack, user, pointed_thing)
		return liquid_store.on_use_empty_bucket(itemstack, user, pointed_thing)
	end,
  on_place = function(itemstack, placer, pointed_thing)
    return liquid_store.on_place(itemstack, placer, pointed_thing)
  end,
	groups = {dig_immediate = 2, temp_pass = 1},
	sounds = nodes_nature.node_sound_stone_defaults(),
	use_texture_alpha = c_alpha.blend,
	selection_box = {
		type='fixed',
		fixed={-0.275, -0.5, -0.225, 0.25, 0.35, 0.275},
	},
})

-- Crafting
-- Blown from glass
-- For simplicity, crafts use charcoal as an ingredient, assuming its used for fuel somehow

crafting.register_recipe({
	type = "glass_furnace",
	output = "tech:glass_bottle_green",
	items = {"tech:green_glass_ingot", "tech:charcoal"},
	level = 1,
	always_known = true,
})
crafting.register_recipe({
	type = "glass_furnace",
	output = "tech:glass_bottle_clear",
	items = {"tech:clear_glass_ingot", "tech:charcoal"},
	level = 1,
	always_known = true,
})


-- Water stores for the jars
-- Salt Water (Green + Clear)
liquid_store.register_stored_liquid("tech:glass_bottle_green_saltwater",{
	source = "nodes_nature:salt_water_source",
	empty = "tech:glass_bottle_green",
  description = S("Green Glass Bottle With Salt Water"),
	groups = {dig_immediate = 2},
	tiles  = {"tech_bottle_green_water.png"},
  sounds = nodes_nature.node_sound_stone_defaults(),
  use_texture_alpha = c_alpha.blend,
	sunlight_propagates = true,
	stack_max = minimal.stack_max_bulky * 2,
	drawtype = "mesh",
	mesh = "tech_bottle_liquid.obj",
	selection_box = {
		type='fixed',
		fixed={-0.25, -0.5, -0.25, 0.25, 0.35, 0.25},
	},
	inventory_image = "tech_bottle_icon_water.png^tech_bottle_green_icon.png",
})


liquid_store.register_stored_liquid("tech:glass_bottle_clear_saltwater",{
	source = "nodes_nature:salt_water_source",
	empty = "tech:glass_bottle_clear",
  description = S("Clear Glass Bottle With Salt Water"),
	groups = {dig_immediate = 2},
	tiles = {"tech_bottle_clear_water.png"},
  use_texture_alpha = c_alpha.blend,
	sunlight_propagates = true,
	stack_max = minimal.stack_max_bulky * 2,
	drawtype = "mesh",
	mesh = "tech_bottle_liquid.obj",
	selection_box = {
		type='fixed',
		fixed={-0.25, -0.5, -0.25, 0.25, 0.35, 0.25},
	},
	inventory_image = "tech_bottle_icon_water.png^tech_bottle_clear_icon.png",
})

-- Freshwater Glass Bottles (Green + Clear)
liquid_store.register_stored_liquid("tech:glass_bottle_green_freshwater",{
	source = "nodes_nature:freshwater_source",
	empty = "tech:glass_bottle_green",
	tiles = {"tech_bottle_green_water.png"},
  description = S("Green Glass Bottle With Fresh Water"),
	groups = {dig_immediate = 2},
  drawtype = "mesh",
	mesh = "tech_bottle_liquid.obj",
	use_texture_alpha = c_alpha.blend,
	sunlight_propagates = true,
	stack_max = minimal.stack_max_bulky * 2,
	selection_box = {
		type='fixed',
		fixed={-0.25, -0.5, -0.25, 0.25, 0.35, 0.25},
	},
	inventory_image = "tech_bottle_icon_water.png^tech_bottle_green_icon.png",
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if drink_water(clicker) then
      minimal.switch_node(pos, {name = "tech:glass_bottle_green"})
			minetest.sound_play("nodes_nature_slurp",	{pos = pos, max_hear_distance = 3, gain = 0.25})
    end
	end,
})
liquid_store.register_stored_liquid("tech:glass_bottle_clear_freshwater",{
	source = "nodes_nature:freshwater_source",
	empty = "tech:glass_bottle_clear",
	tiles = {"tech_bottle_clear_water.png"},
  description = S("Clear Glass Bottle With Fresh Water"),
	groups = {dig_immediate = 2},
  drawtype = "mesh",
	mesh = "tech_bottle_liquid.obj",
	use_texture_alpha = c_alpha.blend,
	sunlight_propagates = true,
	stack_max = minimal.stack_max_bulky * 2,
	selection_box = {
		type='fixed',
		fixed={-0.25, -0.5, -0.25, 0.25, 0.35, 0.25},
	},
	inventory_image = "tech_bottle_icon_water.png^tech_bottle_clear_icon.png",
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if drink_water(clicker) then
      minimal.switch_node(pos, {name = "tech:glass_bottle_clear"})
			minetest.sound_play("nodes_nature_slurp",
      {pos = pos, max_hear_distance = 3, gain = 0.25})
    end
	end,
})