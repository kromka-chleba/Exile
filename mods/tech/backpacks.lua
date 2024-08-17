------------------------------------
--BACK PACKS
--registered with backpacks
--put backpack in the name if wish to prevent infinite stack
-----------------------------------

-- Internationalization
local S = tech.S

---------------------------------------
--Register


-- Woven
backpacks.register_backpack("woven_bag",{
  description = S("Woven Bag"),
  texture = "tech_woven.png",
  width = 8,
  height = 2,
  groups = {snappy = 3, temp_pass = 1, craftedby = 1, flammable = 1},
  sounds = nodes_nature.node_sound_leaves_defaults({
    storage_close = {
      name = "tech_woven_basket_close",
      gain = 0.3,
      max_hear_distance = 14,
      pitch = {1,1.12}
    },
    storage_open = {
      name = "tech_woven_basket_open",
      gain = 0.3,
      max_hear_distance = 14,
      pitch = {1,1.12}
    }
  }),
})

-- Wicker
backpacks.register_backpack("wicker_bag",{
  description = S("Wicker Bag"),
  texture = "tech_wicker.png",
  width = 8,
  height = 2,
  groups = {snappy = 3, temp_pass = 1, craftedby = 1, flammable = 1},
  sounds = nodes_nature.node_sound_leaves_defaults({
    storage_close = {
      name = "tech_woven_basket_close",
      gain = 0.4,
      max_hear_distance = 14,
      pitch = {0.84,0.9}
    },
    storage_open = {
      name = "tech_woven_basket_open",
      gain = 0.4,
      max_hear_distance = 14,
      pitch = {0.84,0.9}
    }
  }),
})


-- fabric
backpacks.register_backpack("fabric_bag",{
  description = S("Fabric Bag"),
  empty_name = S("Empty Fabric Bag"),
  full_name = S("Full Fabric Bag"),
  texture = "tech_coarse_fabric.png",
  width = 8,
  height = 4,
  groups = {snappy = 3, temp_pass = 1, craftedby = 1, flammable = 1},
  sounds = nodes_nature.node_sound_leaves_defaults()
})


---------------------------------------
--Recipes

--
--Hand crafts (crafting_spot)
--

----woven from fibrous_plant
crafting.register_recipe({
	type = "weaving_frame",
	output = "backpacks:backpack_woven_bag",
	items = {"group:fibrous_plant 48"},
	level = 1,
	always_known = true,
})

----wicker from sticks
crafting.register_recipe({
	type = "weaving_frame",
	output = "backpacks:backpack_wicker_bag",
	items = {"tech:stick 48"},
	level = 1,
	always_known = true,
})


--
--loom
--

----fabric from...fabric
crafting.register_recipe({
	type = "loom",
	output = "backpacks:backpack_fabric_bag",
	items = {"tech:coarse_fabric 6"},
	level = 1,
	always_known = true,
})
