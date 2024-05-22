------------------------------------
--DRUGS
--medicines etc

-----------------------------------

-- Internationalization
local S = tech.S

local random = math.random

-- BASIC FUNCTIONALITIES

local ferment_interval = 5

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

--Pot of Tang
liquid_store.register_stored_liquid("tech:tang",{
  source = "tech:tang_liquid",
	empty = "tech:clay_water_pot",
  description = S("Tang"),
	groups = {dig_immediate=2, pottery = 1, temp_pass = 1, drug = 1},
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
	groups = {dig_immediate=2, temp_pass = 1, drug = 1},
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

local function get_ferment_data(name)
  if type(name) == "userdata" and  type(name["get_name"]) == "function" then
    name = name:get_name()
  elseif type(name) == "table" then
    if name.x and name.y and name.z then
      name = minetest.get_node(name)
    end
    name = name.name
  end
  if type(name) ~= "string" then return end
  local def = minetest.registered_nodes[name]
  if not def then return end
  return {
    to = def._ferment_to,
    time = def._ferment_time or {min=300,max=360},
    temp_range = def._ferment_temp_range
  }
end

-- find ferment or create a ferment meta
local function get_or_create_ferment(name,meta)
  local ferment = type(meta) == "userdata" and meta:get_int("ferment") or 0
  if (ferment == 0) then
    ferment = math.random(300,360) -- base to return if error
    local ferment_data = get_ferment_data(name)
    if not ferment_data then return ferment end
    ferment = type(ferment_data.time) == "number" and ferment_data.time
      or type(ferment_data.time) == "table" and math.random(ferment_data.time.min,ferment_data.time.max) or ferment
  end
  return ferment
end

--set saved
local after_place_ferment = function(pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta(pos)
	local stack_meta = itemstack:get_meta()
	local ferment = get_or_create_ferment(itemstack,stack_meta)
	if ferment >0 then
		meta:set_int("ferment", ferment)
	end
end

local on_construct_ferment = function(pos)
  --duration of ferment
  local meta = minetest.get_meta(pos)
  meta:set_int("ferment", get_or_create_ferment(pos))
  --ferment
  minetest.get_node_timer(pos):start(ferment_interval)
end

-- custom function that preserves metadata from a replaced node to an itemstack
local preserve_metadata_ferment = function(pos, oldnode, oldmeta, transferred_stack)
  local imeta = transferred_stack:get_meta()
  imeta:set_int("ferment",get_or_create_ferment(transferred_stack,oldmeta))
end

local on_timer_ferment = function(pos, elapsed)
  local ferment_data = get_ferment_data(pos)
  if not ferment_data then return false end
  local can_ferment = true
  local temp_range = ferment_data.temp_range
  if temp_range then
    --ferment if at right temp
    local temp = climate.get_point_temp(pos)
    if temp >= temp_range.min and temp <= temp_range.max then
      can_ferment = true
    else
      can_ferment = false
    end
  end
  if not can_ferment then return true end
  -- only access meta if can ferment
  local meta = minetest.get_meta(pos)
  local ferment = meta:get_int("ferment")
  -- catchup included
  ferment = ferment - (elapsed >= (ferment_interval*2) and math.floor(elapsed/ferment_interval) or 1)
  if ferment <= 1 then -- prevent possibility of refreshed fermenting at 0
    minetest.swap_node(pos, {name = ferment_data.to})
    return false
  else
    meta:set_int("ferment",ferment)
  end
  return true
end

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
		on_construct_ferment(pos)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		after_place_ferment(pos, placer, itemstack, pointed_thing)
	end,
	on_timer = function(pos, elapsed)
		return on_timer_ferment(pos, elapsed)
	end,
  preserve_metadata = function(pos, oldnode, oldmeta, drops)
    preserve_metadata_ferment(pos, oldnode, minetest.get_meta(pos), drops[1])
  end,
  _preserve_metadata = function(...) -- for liquid store interactions
    preserve_metadata_ferment(...)
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
		on_construct_ferment(pos)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		after_place_ferment(pos, placer, itemstack, pointed_thing)
	end,
	on_timer = function(pos, elapsed)
		return on_timer_ferment(pos,elapsed)
	end,
  preserve_metadata = function(pos, oldnode, oldmeta, drops)
    preserve_metadata_ferment(pos, oldnode, minetest.get_meta(pos), drops[1])
  end,
  _preserve_metadata = function(...) -- for liquid store interactions
    preserve_metadata_ferment(...)
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
