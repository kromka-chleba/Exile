------------------------------------
--ANIMAL CRAFTS
--crafts directly using animal products
--also food processing
-----------------------------------

-- Internationalization
local S = tech.S

local c_alpha = minimal.compat_alpha

--Craft items

-- cracked egg
minetest.register_node("tech:yolk_and_albumen",{
  description = S("Cracked Egg"),
  tiles = {"tech_yolkandalbumen.png"},
  inventory_image = "tech_yolkandalbumen_icon.png",
  groups = {dig_immediate=3, falling_node=1, heatable=60},
  stack_max = math.floor(minimal.stack_max_medium*1.5),
  drawtype = "mesh",
  mesh = "yolkalbumen.obj",
  selection_box = {
    type = "fixed",
    fixed = {-3/16, -0.5, -3/16, 3/16, -6/16, 3/16},
  },
  collision_box = {
    type = "fixed",
    fixed = {-3/16, -0.5, -3/16, 3/16, -6/16, 3/16},
  },
  use_texture_alpha = c_alpha.blend,
	sunlight_propagates = true,
  sounds = nodes_nature.node_sound_dirt_defaults(),
  paramtype = "light"
})

-- cooked da egg
minetest.register_node("tech:yolk_and_albumen_cooked",{
  description = S("Fried Egg"),
  tiles = {"tech_fried_egg.png"},
  inventory_image = "tech_fried_egg_icon.png",
  groups = {dig_immediate=3, falling_node=1, heatable=110, edible=1},
  stack_max = minimal.stack_max_medium*2,
  drawtype = "mesh",
  mesh = "yolkalbumen.obj",
  selection_box = {
    type = "fixed",
    fixed = {-3/16, -0.5, -3/16, 3/16, -6/16, 3/16},
  },
  collision_box = {
    type = "fixed",
    fixed = {-3/16, -0.5, -3/16, 3/16, -6/16, 3/16},
  },
  use_texture_alpha = c_alpha.blend,
	sunlight_propagates = true,
  sounds = nodes_nature.node_sound_dirt_defaults(),
  paramtype = "light"
})

-- recipes
-- cracked egg recipes
crafting.register_recipe({
	type = "hand",
	output = "tech:yolk_and_albumen",
	items = {'animals:pegasun_eggs'},
	level = 1,
	always_known = true,
})
crafting.register_recipe({
	type = "mortar_and_pestle",
	output = "tech:yolk_and_albumen",
	items = {{'animals:pegasun_eggs','animals:kubwakubwa_eggs 2','animals:darkasthaan_eggs 2'}},
	level = 1,
	always_known = true,
})