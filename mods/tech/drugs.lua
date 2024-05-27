------------------------------------
--DRUGS
--medicines etc

-----------------------------------

-- Internationalization
local S = tech.S

local random = math.random

-- Globals
ncrafting = ncrafting

-----------------------------------
--MEDICAL


------------
--Herbal medicine
-- removes energy cost of plants healing effects
--can heal certain health effects (check HEALTH/data_food.lua and HEALTH.cure_table)
--a restorative anti-bacterial/anti-parasitic
minetest.register_craftitem("tech:herbal_medicine", {
	description = S("Herbal Medicine"),
	inventory_image = "tech_herbal_medicine.png",
	stack_max = minimal.stack_max_medium *2,
	groups = {flammable = 1, edible = 1},
  _use_tip = S("Eat"),
})


------------
--Detox?
--for toxins, alcohol, drugs
-- e.g. charcoal? - doesn't work for everything, can itself cause vomiting etc

--[[
How toxins get treated:
Alcohol: wait for it to pass (while helping them not die), pump stomach
Stimulant OD: sedation, wait for it to pass (while helping them not die)
Specific toxins can have anti-toxins (a fairly modern treatment)

]]


-----------------------------------
-----------------------------------
--DRUGS

-----------------------------------
--STIMULANTS


------------
--Tiku
-- stimulant drug
-- gets you high (HEALTH/data_food.lua)
minetest.register_craftitem("tech:tiku", {
	description = S("Tiku (stimulant)"),
	inventory_image = "tech_tiku.png",
	stack_max = minimal.stack_max_medium *2,
	groups = {flammable = 1, drug = 1, edible = 1},
  _use_tip = S("Eat"),
})

-- VINEGAR
liquid_store.register_stored_liquid("tech:tang_vinegar",{
  source = "tech:tang_vinegar",
	empty = "tech:clay_water_pot",
  description = S("Tang Vinegar"),
	groups = {dig_immediate=2, pottery = 1, temp_pass = 1, vinegar=1},
	tiles = {
		"tech_pottery.png^tech_pot_empty.png^tech_pot_tang_vinegar.png",
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
minetest.register_node("tech:tang_vinegar_mother",{
  description = S("Tang Vinegar with Mother"),
  stack_max = 1,
	tiles = {
		"tech_pottery.png^tech_pot_empty.png^tech_pot_tang_vinegar_mother.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png",
		"tech_pottery.png"
	},
  drawtype = "nodebox",
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
  groups = {dig_immediate=2, pottery = 1, temp_pass = 1},
  sounds = nodes_nature.node_sound_stone_defaults(),
  drop = {
    items = {
      {rarity=1,items={"tech:tang_vinegar","tech:mother_of_tang"}},
      {rarity=4,items={"tech:mother_of_tang"}}
    },
  },
  paramtype = "light"
})

liquid_store.register_stored_liquid("tech:wooden_tang_vinegar",{
  source = "tech:tang_vinegar",
	empty = "tech:wooden_water_pot",
  description = S("Tang Vinegar"),
	groups = {dig_immediate=2, temp_pass = 1, vinegar=1},
	tiles = {
		"tech_primitive_wood.png^tech_pot_empty.png^tech_pot_tang_vinegar.png",
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
minetest.register_node("tech:wooden_tang_vinegar_mother",{
  description = S("Tang Vinegar with Mother"),
  stack_max = 1,
	tiles = {
		"tech_primitive_wood.png^tech_pot_empty.png^tech_pot_tang_vinegar_mother.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png",
		"tech_primitive_wood.png"
	},
  drawtype = "nodebox",
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
  groups = {dig_immediate=2, temp_pass = 1},
  sounds = nodes_nature.node_sound_stone_defaults(),
  drop = {
    items = {
      {rarity=1,items={"tech:wooden_tang_vinegar","tech:mother_of_tang"}},
      {rarity=4,items={"tech:mother_of_tang"}}
    },
  },
  paramtype = "light"
})
-- "Mother" of Tang
minetest.register_craftitem("tech:mother_of_tang",{
  description = S("Mother of Tang"),
  inventory_image = "tech_mother_of_tang.png",
  stack_max = minimal.stack_max_medium,
  groups = {mother_growth=1, tang_mother=1},
  _place_tip = S("Infect Other Pots"),
  on_place = function(itemstack, player, pointed_thing)
    if not pointed_thing or pointed_thing.type ~= "node" then
      return
    end
    local pos = pointed_thing.under
    local storedlq = liquid_store.stored_liquids[minetest.get_node(pos).name]
    if not storedlq or storedlq.source ~= "tech:tang_liquid" then
      return
    end
    local meta = minetest.get_meta(pos)
    if meta:contains("mothering") then return end
    -- INFECT!
    meta:set_int("mothering",1)
    ncrafting.ferment_on_construct(pos)
    if not minimal.player_in_creative(player) then
      return itemstack:take_item()
    end
  end,
})




-----------------------------------
--DEPRESSANTS

-----------------
--Tang, alcoholic drink

local function drink_tang(pos, node, clicker, itemstack, pointed_thing, ininv)
  if not minetest.is_player(clicker) then -- avoid potential errors, player only
    return
  end
  local empty = liquid_store.stored_liquids[node.name].nodename_empty
  if not minetest.registered_nodes[empty] then
    -- no empty node, prevent functionality
    return
  end
  --lets skull an entire vat of booze, what could possibly go wrong...
  local meta = clicker:get_meta()
  --only drink if thirsty
  if meta:get_int("thirst") < 100 then
    if not ininv then
      minetest.swap_node(pos, {name = empty})
    else
      pos = clicker:get_pos()
      node.name = itemstack
    end
    minetest.sound_play("nodes_nature_slurp",	{pos = pos, max_hear_distance = 3, gain = 0.25})
    return HEALTH.eatdrink(node.name, clicker, pointed_thing)
  end
end

local function mother_on_timer(pos, elapsed)
  local meta = minetest.get_meta(pos)
  if meta:contains("mothering") then
    return ncrafting.ferment_on_timer(pos, elapsed)
  elseif random() <= 0.05 then
    meta:set_int("mothering",1)
    ncrafting.ferment_on_construct(pos)
    return false
  end
  minetest.get_node_timer(pos):start(random(400,800))
  return false
end

--Pot of Tang
liquid_store.register_stored_liquid("tech:tang",{
  source = "tech:tang_liquid",
	empty = "tech:clay_water_pot",
  description = S("Tang"),
	groups = {dig_immediate=2, pottery = 1, temp_pass = 1, drug = 1, timer = 5},
	tiles = {
		"tech_pottery.png^tech_pot_empty.png^tech_pot_tang.png",
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
  _ferment_time = {min=200,max=300},
  _ferment_temp_range = {min=10,max=34},
  _ferment_to = "tech:tang_vinegar_mother",
  on_construct = function(pos)
		minetest.get_node_timer(pos):start(ncrafting.ferment_interval)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
    if not itemstack:get_meta():get_int("mothering") ~= 0 then return end
    ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing)
	end,
	on_timer = function(pos, elapsed)
    return mother_on_timer(pos, elapsed)
	end,
  preserve_metadata = function(pos, oldnode, oldmeta, drops)
    ncrafting.ferment_preserve_metadata(pos, oldnode, minetest.get_meta(pos), drops[1])
  end,
  _preserve_metadata = function(pos, oldnode, oldmeta, transferred_stack) -- for liquid store interactions
    ncrafting.ferment_preserve_metadata(pos, oldnode, oldmeta, transferred_stack)
  end,
  on_rightclick = function(...)
    drink_tang(...)
  end,
  _use_tip = S("Drink"),
  _on_use_item = function(player, itemstack, pointed_thing)
    return drink_tang(nil, {name="tech:tang"}, player, itemstack, pointed_thing, true)
  end,
})
liquid_store.register_stored_liquid("tech:wooden_tang",{
  source = "tech:tang_liquid",
	empty = "tech:wooden_water_pot",
  description = S("Tang"),
	groups = {dig_immediate=2, temp_pass = 1, drug = 1, timer = 5},
	tiles = {
		"tech_primitive_wood.png^tech_pot_empty.png^tech_pot_tang.png",
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
  _ferment_time = {min=200,max=300},
  _ferment_temp_range = {min=10,max=34},
  _ferment_to = "tech:wooden_tang_vinegar_mother",
  on_construct = function(pos)
		minetest.get_node_timer(pos):start(ncrafting.ferment_interval)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
    if not itemstack:get_meta():get_int("mothering") ~= 0 then return end
    ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing)
	end,
	on_timer = function(pos, elapsed)
    return mother_on_timer(pos, elapsed)
	end,
  preserve_metadata = function(pos, oldnode, oldmeta, drops)
    ncrafting.ferment_preserve_metadata(pos, oldnode, minetest.get_meta(pos), drops[1])
  end,
  _preserve_metadata = function(pos, oldnode, oldmeta, transferred_stack) -- for liquid store interactions
    ncrafting.ferment_preserve_metadata(pos, oldnode, oldmeta, transferred_stack)
  end,
  on_rightclick = function(...)
    drink_tang(...)
  end,
  _use_tip = S("Drink"),
  _on_use_item = function(player, itemstack, pointed_thing)
    return drink_tang(nil, {name="tech:wooden_tang"}, player, itemstack, pointed_thing, true)
  end,
})

-----------------
-- UNFERMENTED TANG

-- Pot of new Tang (unfermented), must be left to ferment
liquid_store.register_stored_liquid("tech:tang_unfermented",{
  source = "tech:unfermented_tang_liquid",
	empty = "tech:clay_water_pot",
  description = S("Tang (unfermented)"),
	groups = {dig_immediate=2, pottery = 1, temp_pass = 1},
	tiles = {
		"tech_pottery.png^tech_pot_empty.png^tech_pot_tang_uf.png",
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
  _ferment_time = {min=300,max=360},
  _ferment_temp_range = {min=10,max=34},
  _ferment_to = "tech:tang",
  on_construct = function(pos)
		ncrafting.ferment_on_construct(pos)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing)
	end,
	on_timer = function(pos, elapsed)
		return ncrafting.ferment_on_timer(pos, elapsed)
	end,
  preserve_metadata = function(pos, oldnode, oldmeta, drops)
    ncrafting.ferment_preserve_metadata(pos, oldnode, minetest.get_meta(pos), drops[1])
  end,
  _preserve_metadata = function(...) -- for liquid store interactions
    ncrafting.ferment_preserve_metadata(...)
  end,
})
-- wooden pot of unfermented tang
liquid_store.register_stored_liquid("tech:wooden_tang_unfermented",{
  source = "tech:unfermented_tang_liquid",
	empty = "tech:wooden_water_pot",
  description = S("Tang (unfermented)"),
	groups = {dig_immediate=2, temp_pass = 1},
	tiles = {
		"tech_primitive_wood.png^tech_pot_empty.png^tech_pot_tang_uf.png",
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
  _ferment_time = {min=300,max=360},
  _ferment_temp_range = {min=10,max=34},
  _ferment_to = "tech:wooden_tang",
  on_construct = function(pos)
		ncrafting.ferment_on_construct(pos)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing)
	end,
	on_timer = function(pos, elapsed)
		return ncrafting.ferment_on_timer(pos, elapsed)
	end,
  preserve_metadata = function(pos, oldnode, oldmeta, drops)
    ncrafting.ferment_preserve_metadata(pos, oldnode, minetest.get_meta(pos), drops[1])
  end,
  _preserve_metadata = function(...) -- for liquid store interactions
    ncrafting.ferment_preserve_metadata(...)
  end,
})

-----------------------------------
--HALLUCINOGENS



---------------------------------------
--Recipes



--
--mortar and pestle
--


--make herbal_medicine
crafting.register_recipe({
	type = "mortar_and_pestle",
	output = "tech:herbal_medicine",
	items = {'nodes_nature:hakimi_flowering', 'nodes_nature:merki', 'nodes_nature:moss'},
	level = 1,
	always_known = true,
})

--make tiku
crafting.register_recipe({
	type = "mortar_and_pestle",
	output = "tech:tiku",
	items = {'nodes_nature:tikusati_seed 12', 'nodes_nature:wiha_fruit', "tech:vegetable_oil"},
	level = 1,
	always_known = true,
})

--make tang_unfermented
crafting.register_recipe({
	type = "mortar_and_pestle",
	output = "tech:tang_unfermented",
	items = {'nodes_nature:tangkal_fruit 12', "tech:clay_water_pot_freshwater"},
	level = 1,
	always_known = true,
})
-- make tang unfermented in wooden pot
crafting.register_recipe({
	type = "mortar_and_pestle",
	output = "tech:wooden_tang_unfermented",
	items = {'nodes_nature:tangkal_fruit 12', "tech:wooden_water_pot_freshwater"},
	level = 1,
	always_known = true,
})
