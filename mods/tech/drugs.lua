------------------------------------
--DRUGS
--medicines etc

-----------------------------------

-- Internationalization
local S = tech.S

local random = math.random

-----------------------------------
--MEDICAL


------------
--Herbal medicine
-- removes energy cost of plants healing effects
--can heal certain health effects
--a restorative anti-bacterial/anti-parasitic
minetest.register_craftitem("tech:herbal_medicine", {
	description = S("Herbal Medicine"),
	inventory_image = "tech_herbal_medicine.png",
	stack_max = minimal.stack_max_medium *2,
	groups = {flammable = 1},
	_use_tip = "Eat",

  _on_use_item = function(user, itemstack, pointed_thing)

    --remove parasites
    if random()<0.33 then
		HEALTH.remove_new_effect(user, {"Intestinal Parasites"})
	end

    --cure/reduce food poisoning and infections
    --see how effective the dose is
    local cfp = random()
    if cfp <0.25 then
      --cure up to severe
      HEALTH.remove_new_effect(user, {"Food Poisoning", 3})
			HEALTH.remove_new_effect(user, {"Fungal Infection", 3})
			HEALTH.remove_new_effect(user, {"Dust Fever", 3})
    elseif cfp < 0.5 then
      --cure up to moderate
      HEALTH.remove_new_effect(user, {"Food Poisoning", 2})
			HEALTH.remove_new_effect(user, {"Fungal Infection", 2})
			HEALTH.remove_new_effect(user, {"Dust Fever", 2})
    elseif cfp < 0.75 then
      --only cure mild
      HEALTH.remove_new_effect(user, {"Food Poisoning", 1})
			HEALTH.remove_new_effect(user, {"Fungal Infection", 1})
			HEALTH.remove_new_effect(user, {"Dust Fever", 1})
    end


    --hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item
    return HEALTH.use_item(itemstack, user, 5, 0, 0, 0, 0)
  end,
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
-- gets you high
minetest.register_craftitem("tech:tiku", {
	description = S("Tiku (stimulant)"),
	inventory_image = "tech_tiku.png",
	stack_max = minimal.stack_max_medium *2,
	groups = {flammable = 1, drug = 1},
	_use_tip = "Eat",

	_on_use_item = function(user, itemstack, pointed_thing)

	   --begin the bender
	   HEALTH.add_new_effect(user, {"Tiku High", 1})

	   --hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item
	   return HEALTH.use_item(itemstack, user, 0, 0, -24, 96, 0)
	end,
})



-----------------------------------
--DEPRESSANTS


-----------------
--Tang, alcoholic drink

local function drink_tang(pos, node, clicker, itemstack, pointed_thing)
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
  local thirst = meta:get_int("thirst")
  --only drink if thirsty
  if thirst < 100 then
    --you're skulling a whole bucket
    HEALTH.modify_int(meta, "thirst", 100)
    --all energy and half food equivalent of the fruit
    --gets given as energy
    HEALTH.modify_int(meta, "energy", 180)
    HEALTH.modify_int(meta, "hunger", 60)

    --drunkness
    if random() < 0.75 then
      HEALTH.add_new_effect(clicker, {"Drunk", 1})
    end

    minetest.swap_node(pos, {name = empty})
    minetest.sound_play("nodes_nature_slurp",	{pos = pos, max_hear_distance = 3, gain = 0.25})
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
  end
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
  end
})

-----------------
-- UNFERMENTED TANG

-- find ferment or create a ferment meta
local function get_or_create_ferment(meta)
  local ferment = meta:get_int("ferment")
  if (ferment == 0) then
    ferment = math.random(300,360)
  end
  return ferment
end

--save usage into inventory, to prevent infinite supply (removed the on_dig_tang function, keeping note)
--[[
local on_dig_tang = function(pos, node, digger, pot_type)
  if not minetest.is_player(digger) or minetest.is_protected(pos, digger) then
    return false
  end
  if (type(pot_type) == "string") then
    pot_type = string.lower(pot_type)
  else
    pot_type = ""
  end
	local meta = minetest.get_meta(pos)
	local ferment = get_or_create_ferment(meta)
	local new_stack = ItemStack("tech:tang_unfermented")
  if (string.match(pot_type,"wooden")) then
    new_stack = ItemStack("tech:wooden_tang_unfermented")
  end
	local stack_meta = new_stack:get_meta()
	stack_meta:set_int("ferment", ferment)

	local digger_inv = digger:get_inventory()
	if digger_inv:room_for_item("main", new_stack) then
		digger_inv:add_item("main", new_stack)
		minetest.remove_node(pos)
	elseif not minimal.stop_on_inv_full(digger) then
	   minetest.add_item(pos, new_stack)
	   minetest.remove_node(pos)
	end
end
--]]

--set saved
local after_place_tang = function(pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta(pos)
	local stack_meta = itemstack:get_meta()
	local ferment = get_or_create_ferment(stack_meta)
	if ferment >0 then
		meta:set_int("ferment", ferment)
	end
end

local on_construct_tang = function(pos)
  --duration of ferment
		local meta = minetest.get_meta(pos)
    meta:set_int("ferment", math.random(300,360))
		--ferment
		minetest.get_node_timer(pos):start(5)
end

-- custom function that preserves metadata from a replaced node to an itemstack
local preserve_metadata_tang = function(pos, oldnode, oldmeta, transferred_stack)
  local imeta = transferred_stack:get_meta()
  imeta:set_int("ferment",get_or_create_ferment(oldmeta))
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
  on_construct = function(pos)
		on_construct_tang(pos)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		after_place_tang(pos, placer, itemstack, pointed_thing)
	end,
	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local ferment = meta:get_int("ferment")
		if ferment <= 1 then -- prevent possibility of refreshed fermenting at 0
			minetest.swap_node(pos, {name = "tech:tang"})
			return false
		else
      --ferment if at right temp
      local temp = climate.get_point_temp(pos)
      if temp >= 10 and temp <= 34 then
        meta:set_int("ferment", ferment - 1)
      end
			return true
		end
	end,
  preserve_metadata = function(pos, oldnode, oldmeta, drops)
    preserve_metadata_tang(pos, oldnode, minetest.get_meta(pos), drops[1])
  end,
  _preserve_metadata = function(...) -- for liquid store interactions
    preserve_metadata_tang(...)
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
  on_construct = function(pos)
		on_construct_tang(pos)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		after_place_tang(pos, placer, itemstack, pointed_thing)
	end,
	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local ferment = meta:get_int("ferment")
		if ferment <= 1 then -- prevent possibility of refreshed fermenting at 0
			minetest.swap_node(pos, {name = "tech:wooden_tang"})
			return false
		else
      --ferment if at right temp
      local temp = climate.get_point_temp(pos)
      if temp >= 10 and temp <= 34 then
        meta:set_int("ferment", ferment - 1)
      end
			return true
		end
	end,
  preserve_metadata = function(pos, oldnode, oldmeta, drops)
    preserve_metadata_tang(pos, oldnode, minetest.get_meta(pos), drops[1])
  end,
  _preserve_metadata = function(...) -- for liquid store interactions
    preserve_metadata_tang(...)
  end,
})


--[[
-- function overrides for unfermented tang
minetest.override_item("tech:tang_unfermented",{
  on_dig = function(pos, node, digger)
		on_dig_tang(pos, node, digger)
	end,
})
--]]

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
