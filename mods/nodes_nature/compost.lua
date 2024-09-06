-- Compost

sediment = sediment

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

local function save_to_inventory(pos, node, digger)
    if not digger then return false end
    if minetest.is_protected(pos, digger:get_player_name()) then
        return false
    end
    local meta = minetest.get_meta(pos)
    local decomposition = meta:get_int("decomposition")
    local new_stack = ItemStack(node.name)
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

local function decompose_compost(pos, elapsed, dc_name)
    local compdef = minimal.get_nodedef(pos)
    if not compdef then
        return false
    end
    local decomposed_name = string.gsub(compdef.name,"_undecomposed","")
    if dc_name then
        decomposed_name = dc_name
    end
    local speed = dry_speed
    if compdef.groups.undecomposed_compost == 2 then
        speed = wet_speed
    end
    if not minimal.get_nodedef(decomposed_name) then
        return false
    end
    local meta = minetest.get_meta(pos)
    local decomposition = meta:get_int("decomposition")
    local last_updated = meta:get_int("last_updated")
    if last_updated == 0 then
        meta:set_int("last_updated", elapsed)
    end
    decomposition = catch_up_timer(elapsed, last_updated, decomposition, speed)
    if decomposition > 0 then
        decomposition = decomposition - speed
    end
    -- avoid issue of grabbing a undecomposed with a decomposition of 0
    --  and accidentally resetting count
    if decomposition < 1 then
        minetest.set_node(pos, {name = decomposed_name})
        return false
    else
        meta:set_int("decomposition", decomposition)
        return true
    end
end

local base_undecomposed_compost = {
    name = "compost_undecomposed",
    description = S("Undecomposed Compost"),
    groups = {
        crumbly = 3,
        fertility = 1,
        falling_node = 1,
        undecomposed_compost = 1,
    },
    tiles = {"nodes_nature_compost_undecomposed.png"},
    sounds = sediment.sounds.dirt,
    stack_max = minimal.stack_max_bulky,
    _place_tip = S("Set to decompose"),
    on_timer = function(pos, elapsed)
        return decompose_compost(pos, elapsed)
    end,
    on_construct = function(pos)
        start_decomposing(pos)
    end,
    on_dig = function(pos, node, digger)
        save_to_inventory(pos, node, digger)
    end,
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        restore_from_inventory(pos, itemstack)
    end
}
local base_compost = {
    name = "compost",
    description = S("Compost"),
    groups = {
        crumbly = 3,
        falling_node = 1,
        fertility = 3,
        compost = 1,
    },
    tiles = {"nodes_nature_compost.png"},
    sounds = sediment.sounds.dirt,
    stack_max = minimal.stack_max_bulky,
    _fertilize_replace_with = "stairs:slab_compost",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            return ncrafting.fertilize(pointed_thing.under, user, itemstack)
        else
            minimal.item_pickup(user, pointed_thing)
        end
    end,
    _dig_tip = S("Fertilize soil"),
}
-- so lazy that I'd rather somewhat badly automate it
-- decomposed compost
for i = 1, 4 do
    local reg_compost = table.copy(base_compost)
    local name = reg_compost.name
    -- wet definitions
    if (i == 2 or i == 4) then
        reg_compost.tiles = {sediment.get_wet_texture_name(name)}
        name = name.."_wet"
        reg_compost.description = S("Wet Compost")
        reg_compost.sounds = sediment.sounds.dirt_wet
        reg_compost.groups.compost = 2

        reg_compost._dig_tip = S("Fertilize and soak soil")
        reg_compost.on_use = function(itemstack, user, pointed_thing)
            if pointed_thing.type == "node" then
                local return_val = {ncrafting.fertilize(pointed_thing.under,
                                                        user, itemstack)}
                -- only wet the soil if successfully fertilized
                --  (will be true or nil for the 3rd parameter)
                if return_val[3] then
                    ncrafting.water_soil(itemstack, user, pointed_thing,"","")
                end
                return return_val[1]
            else
                minimal.item_pickup(user, pointed_thing)
            end
        end

        if i == 2 then
            reg_compost._fertilize_replace_with = "stairs:slab_compost_wet"
        end
    end

    reg_compost.name = "nodes_nature:"..name
    if i <= 2 then
        minetest.register_node(reg_compost.name,reg_compost)
    else
        reg_compost._fertilize_replace_with = ""
        stairs.register_slab(
            name,
            reg_compost.name,
            {"mixing_spot","soil_mixing"},
            "true",
            {"mixing_spot","soil_mixing"},
            reg_compost.groups,
            reg_compost.tiles,
            S("@1 Slab",reg_compost.description),
            minimal.stack_max_bulky * 2,
            reg_compost.sounds
        )
        minetest.override_item("stairs:slab_"..name,{
                                   _dig_tip = reg_compost._dig_tip,
                                   on_use = reg_compost.on_use,
        })
    end
end

-- undecomposed compost
for i = 1, 4 do
    local reg_compost = table.copy(base_undecomposed_compost)
    local name = reg_compost.name
    -- wet definitions
    if (i == 2 or i == 4) then
        reg_compost.tiles = {sediment.get_wet_texture_name(name)}
        name = name.."_wet"
        reg_compost.description = S("Wet Undecomposed Compost")
        reg_compost.sounds = sediment.sounds.dirt_wet
        reg_compost.groups.undecomposed_compost = 2
        -- no other use for undecomposed_compost, let's consider number 2 wet
    end

    reg_compost.name = "nodes_nature:"..name
    if i <= 2 then
        minetest.register_node(reg_compost.name,reg_compost)
    else
        stairs.register_slab(
            name,
            reg_compost.name,
            {"mixing_spot","soil_mixing"},
            "true",
            {"mixing_spot","soil_mixing"},
            reg_compost.groups,
            reg_compost.tiles,
            S("@1 Slab",reg_compost.description),
            minimal.stack_max_bulky * 2,
            reg_compost.sounds
        )
        minetest.override_item(
            "stairs:slab_"..name,{
                _place_tip = reg_compost._place_tip,
                on_timer = reg_compost.on_timer,
                on_construct = reg_compost.on_construct,
                on_dig = reg_compost.on_dig,
                after_place_node = reg_compost.after_place_node,
        })
    end
end

-- check roots
-- replace legacy compost
minetest.register_lbm({
        label = "Update decomposed dry compost",
        name = "nodes_nature:legacy_compost_replace",
        nodenames = {
            "nodes_nature:slope_compost",
            "nodes_nature:slope_inner_compost",
            "nodes_nature:slope_outer_compost",
            "nodes_nature:slope_pike_compost",
            "nodes_nature:compost_roots"},
        action = function(pos, node, dtime_s)
            minetest.set_node(pos,{name = "nodes_nature:compost"})
        end
})
minetest.register_lbm({
        label = "Update decomposed wet compost",
        name = "nodes_nature:legacy_compost_replace_2",
        nodenames = {
            "nodes_nature:slope_compost_wet",
            "nodes_nature:slope_inner_compost_wet",
            "nodes_nature:slope_outer_compost_wet",
            "nodes_nature:slope_pike_compost_wet",
            "nodes_nature:compost_wet_roots",
            "nodes_nature:compost_wet_salty",
            "nodes_nature:slope_compost_wet_salty",
            "nodes_nature:slope_inner_compost_wet_salty",
            "nodes_nature:slope_outer_compost_wet_salty",
            "nodes_nature:slope_pike_compost_wet_salty"},
        action = function(pos, node, dtime_s)
            minetest.set_node(pos,{name = "nodes_nature:compost_wet"})
        end
})
-- replace legacy undecomposed compost
minetest.register_lbm({
        label = "Update undecomposed dry compost",
        name = "nodes_nature:legacy_compost_replace_3",
        nodenames = {
            "nodes_nature:slope_compost_undecomposed",
            "nodes_nature:slope_inner_compost_undecomposed",
            "nodes_nature:slope_outer_compost_undecomposed",
            "nodes_nature:slope_pike_compost_undecomposed",
            "nodes_nature:compost_undecomposed_roots"},
        action = function(pos, node, dtime_s)
            minetest.set_node(pos,{name = "nodes_nature:compost_undecomposed"})
        end
})
minetest.register_lbm({
        label = "Update undecomposed wet compost",
        name = "nodes_nature:legacy_compost_replace_4",
        nodenames = {
            "nodes_nature:slope_compost_undecomposed_wet",
            "nodes_nature:slope_inner_compost_undecomposed_wet",
            "nodes_nature:slope_outer_compost_undecomposed_wet",
            "nodes_nature:slope_pike_compost_undecomposed_wet",
            "nodes_nature:compost_undecomposed_wet_roots",
            "nodes_nature:compost_undecomposed_wet_salty",
            "nodes_nature:slope_compost_undecomposed_wet_salty",
            "nodes_nature:slope_inner_compost_undecomposed_wet_salty",
            "nodes_nature:slope_outer_compost_undecomposed_wet_salty",
            "nodes_nature:slope_pike_compost_undecomposed_wet_salty"},
        action = function(pos, node, dtime_s)
            minetest.set_node(pos,
                              {name = "nodes_nature:compost_undecomposed_wet"})
        end
})

crafting.register_recipe({
        type = "shovel_agriculture",
        output = "nodes_nature:compost_undecomposed",
        items = {{"group:compostable 16","group:fruit 32","group:seed 288"}},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = "shovel_agriculture",
        output = "stairs:slab_compost_undecomposed",
        items = {{"group:compostable 8","group:fruit 16","group:seed 144"}},
        level = 1,
        always_known = true,
})
