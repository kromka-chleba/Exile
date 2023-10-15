-- Compost

-- Internationalization
local S = nodes_nature.S

-- Compost
-----------------------------------
local compost_decomposing_time = 12000 -- 10 in-game days
local decomposition_interval = 600 -- every 600s
local dry_speed = 600
local wet_speed = 800

local function start_decomposing(pos)
    local meta = minetest.get_meta(pos)
    local decomposition = meta:get_int("decomposition")
    if decomposition < 1 then
        meta:set_int("decomposition", compost_decomposing_time)
    end
    minetest.get_node_timer(pos):start(decomposition_interval)
end

local function catch_up_timer(elapsed, last_updated, decomposition, speed)
    if elapsed and elapsed - last_updated > decomposition_interval then
        return decomposition - elapsed / decomposition_interval * speed
    end
    return decomposition
end

local function save_to_inventory(pos, digger, undecomposed_name)
    if not digger then return false end
    if minetest.is_protected(pos, digger:get_player_name()) then
        return false
    end
    local meta = minetest.get_meta(pos)
    local decomposition = meta:get_int("decomposition")
    local new_stack = ItemStack(undecomposed_name)
    local stack_meta = new_stack:get_meta()
    stack_meta:set_int("decomposition", decomposition)
    minetest.remove_node(pos)
    local player_inv = digger:get_inventory()
    if player_inv:room_for_item("main", new_stack) then
        player_inv:add_item("main", new_stack)
    else
        minetest.add_item(pos, new_stack)
    end
end

local function restore_from_inventory(pos, itemstack)
    local meta = minetest.get_meta(pos)
    local stack_meta = itemstack:get_meta()
    local decomposition = stack_meta:get_int("decomposition")
    if decomposition < 1 then
        meta:set_int("decomposition", compost_decomposing_time)
    else
        meta:set_int("decomposition", decomposition)
    end
end

local function decompose_compost(pos, decomposed_name, speed, elapsed)
    local meta = minetest.get_meta(pos)
    local decomposition = meta:get_int("decomposition")
    local last_updated = meta:get_int("last_updated")
    if last_updated == 0 then
        meta:set_int("last_updated", elapsed)
    end
    local decomposition = catch_up_timer(elapsed, last_updated, decomposition, speed)
    if decomposition < 1 then
        minetest.swap_node(pos, {name = decomposed_name})
        return false
    else
        meta:set_int("decomposition", decomposition - speed)
        return true
    end
end

local compost =
    sediment.new({name = "compost",
                  description = S("Decomposed Compost"),
                  hardness = sediment.hardness.soft,
                  fertility = 1, sound = sediment.sounds.dirt,
                  sound_wet = sediment.sounds.dirt_wet})
 -- add "compost" group
compost.groups.compost = 1
compost.groups_wet.compost = 1

sediment.register_dry(compost)
sediment.register_wet(compost)
sediment.register_wet_salty(compost)
sediment.register_slab(compost)

local compost_undecomposed =
    sediment.new({name = "compost_undecomposed",
                  description = S("Undecomposed Compost"),
                  hardness = sediment.hardness.soft,
                  fertility = 1, sound = sediment.sounds.dirt,
                  sound_wet = sediment.sounds.dirt_wet})

sediment.register_dry(compost_undecomposed)
sediment.register_wet(compost_undecomposed)
sediment.register_wet_salty(compost_undecomposed)
sediment.register_slab(compost_undecomposed)

local compost_dry_name = sediment.get_dry_name("compost")
local compost_wet_name = sediment.get_wet_name("compost")
local undecomposed_dry_name = sediment.get_dry_name("compost_undecomposed")
local undecomposed_wet_name = sediment.get_wet_name("compost_undecomposed")

minetest.override_item(
    undecomposed_dry_name,
    {
        on_timer = function(pos, elapsed)
            return decompose_compost(pos, compost_dry_name, dry_speed, elapsed)
        end,
        on_construct = function(pos)
            start_decomposing(pos)
        end,
        on_dig = function(pos, node, digger)
            save_to_inventory(pos, digger, undecomposed_dry_name)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            restore_from_inventory(pos, itemstack)
        end
})

minetest.override_item(
    "stairs:slab_compost_undecomposed",
    {
        on_timer = function(pos, elapsed)
            return decompose_compost(pos, "stairs:slab_compost", dry_speed, elapsed)
        end,
        on_construct = function(pos)
            start_decomposing(pos)
        end,
        on_dig = function(pos, node, digger)
            save_to_inventory(pos, digger, "stairs:slab_compost_undecomposed")
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            restore_from_inventory(pos, itemstack)
        end
})

minetest.override_item(
    undecomposed_wet_name,
    {
        on_timer = function(pos, elapsed)
            return decompose_compost(pos, compost_wet_name, wet_speed, elapsed)
        end,
        on_construct = function(pos, wet_speed)
            start_decomposing(pos)
        end,
        on_dig = function(pos, node, digger)
            save_to_inventory(pos, digger, undecomposed_wet_name)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            restore_from_inventory(pos, itemstack)
        end
})

-- fertilize functions
minetest.override_item(
 compost_dry_name,
 {
  _fertilize_replace_with = "stairs:slab_compost",
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type == "node" then
      return ncrafting.fertilize(pointed_thing.under, user, itemstack)
    end
  end
})
minetest.override_item(
  "stairs:slab_compost",
  {
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type == "node" then
      return ncrafting.fertilize(pointed_thing.under, user, itemstack)
    end
  end
})
-- wet fertilize
minetest.override_item(
 compost_wet_name,
 {
  _fertilize_replace_with = "stairs:slab_compost",
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type == "node" then
      ncrafting.water_soil(itemstack, user, pointed_thing,"","")
      return ncrafting.fertilize(pointed_thing.under, user, itemstack)
    end
  end
})
--minetest.override_item(
  --"stairs:slab_compost_wet",
  --{
  --on_use = function(itemstack, user, pointed_thing)
    --if pointed_thing.type == "node" then
      --return ncrafting.fertilize(pointed_thing.under, user, itemstack)
    --end
  --end
--})

crafting.register_recipe({
	type = "shovel_agriculture",
	output = "nodes_nature:compost_undecomposed",
	items = {"group:compostable 16"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "shovel_agriculture",
	output = "stairs:slab_compost_undecomposed",
	items = {"group:compostable 8"},
	level = 1,
	always_known = true,
})
