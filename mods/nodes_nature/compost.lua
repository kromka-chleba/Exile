-- Compost

-- Internationalization
local S = nodes_nature.S

-- Compost
-----------------------------------
local compost_fermenting_time = 18000 -- 15 in-game days

local function start_fermenting(pos)
    local meta = minetest.get_meta(pos)
    local ferment = meta:get_int("ferment")
    if ferment < 1 then
        meta:set_int("ferment", compost_fermenting_time)
    end
    minetest.get_node_timer(pos):start(600) -- every 600 seconds
end

local function save_to_inventory(pos, digger, unfermented_name)
    if not digger then return false end
    if minetest.is_protected(pos, digger:get_player_name()) then
        return false
    end
    local meta = minetest.get_meta(pos)
    local ferment = meta:get_int("ferment")
    local new_stack = ItemStack(unfermented_name)
    local stack_meta = new_stack:get_meta()
    stack_meta:set_int("ferment", ferment)
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
    local ferment = stack_meta:get_int("ferment")
    if ferment < 1 then
        meta:set_int("ferment", compost_fermenting_time)
    else
        meta:set_int("ferment", ferment)
    end
end

local function ferment_compost(pos, fermented_name, speed)
    local meta = minetest.get_meta(pos)
    local ferment = meta:get_int("ferment")
    if ferment < 1 then
        minetest.swap_node(pos, {name = fermented_name})
        return false
    else
        meta:set_int("ferment", ferment - speed)
        return true
    end
end

local compost =
    sediment.new({name = "compost",
                  description = S("Fermented Compost"),
                  hardness = sediment.hardness.soft,
                  fertility = 1, sound = sediment.sounds.dirt,
                  sound_wet = sediment.sounds.dirt_wet})

sediment.register_dry(compost)
sediment.register_wet(compost)
sediment.register_wet_salty(compost)

local compost_unfermented =
    sediment.new({name = "compost_unfermented",
                  description = S("Unfermented Compost"),
                  hardness = sediment.hardness.soft,
                  fertility = 1, sound = sediment.sounds.dirt,
                  sound_wet = sediment.sounds.dirt_wet})

sediment.register_dry(compost_unfermented)
sediment.register_wet(compost_unfermented)
sediment.register_wet_salty(compost_unfermented)

local dry_speed = 600
local wet_speed = 800

minetest.override_item(
    compost_unfermented.dry_node_name,
    {
        on_timer = function(pos, elapsed)
            return ferment_compost(pos, compost.dry_node_name, dry_speed)
        end,
        on_construct = function(pos)
            start_fermenting(pos)
        end,
        on_dig = function(pos, node, digger)
            save_to_inventory(pos, digger, compost_unfermented.dry_node_name)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            restore_from_inventory(pos, itemstack)
        end
})

minetest.override_item(
    compost_unfermented.wet_node_name,
    {
        on_timer = function(pos, elapsed)
            return ferment_compost(pos, compost.wet_node_name, wet_speed)
        end,
        on_construct = function(pos, wet_speed)
            start_fermenting(pos)
        end,
        on_dig = function(pos, node, digger)
            save_to_inventory(pos, digger, compost_unfermented.wet_node_name)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            restore_from_inventory(pos, itemstack)
        end
})
