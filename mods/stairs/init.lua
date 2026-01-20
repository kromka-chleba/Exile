-- Minetest 0.4 mod: stairs
-- See README.txt for licensing and other information.


-- Global namespace for functions

stairs = {}

local S = minetest.get_translator("stairs")

-- Get setting for replace ABM

local replace = minetest.settings:get_bool("enable_stairs_replace_abm")

local function rotate_and_place(itemstack, placer, pointed_thing)
    local p0 = pointed_thing.under
    local p1 = pointed_thing.above
    local param2 = 0

    if placer then
        local placer_pos = placer:get_pos()
        if placer_pos then
            param2 = minetest.dir_to_facedir(vector.subtract(p1, placer_pos))
        end

        local finepos = minetest.pointed_thing_to_face_pos(placer,
                                                           pointed_thing)
        local fpos = finepos.y % 1

        if p0.y - 1 == p1.y or (fpos > 0 and fpos < 0.5)
            or (fpos < -0.5 and fpos > -0.999999999) then
            param2 = param2 + 20
            if param2 == 21 then
                param2 = 23
            elseif param2 == 23 then
                param2 = 21
            end
        end
    end
    return minetest.item_place(itemstack, placer, pointed_thing, param2)
end

function stairs.register_recipies(recipeitem,craft_station, recycle, recycle_station, subname, prefix)
    if recipeitem then
        local level = 1
        if type(craft_station) == 'string' then
            craft_station={craft_station}
        end
        for _, station in ipairs(craft_station) do
            local space,_ = string.find(station,' ')
            if space then
                level = tonumber(string.sub(station,space+1,-1))
                station = string.sub(station,1,space-1)
            end
            -- Recipes
            crafting.register_recipe({
                    type = station,
                    output = prefix .. "_".. subname.. " 2",
                    items = {recipeitem},
                    level = level,
                    always_known = true,
            })
        end
        -- Recycle recipe
        if recycle == "true" then
            if type(recycle_station) == 'string' then
                recycle_station={recycle_station}
            end
            for _, station in ipairs(recycle_station) do
                crafting.register_recipe({
                        type = station,
                        output = recipeitem,
                        items = {prefix .. "_".. subname.. " 2"},
                        level = level,
                        always_known = true,
                })
            end
        end

    end
end

-- Set backface culling and world-aligned textures
-- backface_culling should be true for stairs
-- nil for slabs
local function set_faces(images, worldaligntex, backface_culling)
    local stair_images = {}
    for i, image in ipairs(images) do
        if type(image) == "string" then
            stair_images[i] = {
                name = image,
                -- set to true if param is present
                backface_culling = backface_culling or nil,
            }
            if worldaligntex then
                stair_images[i].align_style = "world"
            end
        else
            stair_images[i] = table.copy(image)
            if backface_culling then
                if stair_images[i].backface_culling == nil then
                    stair_images[i].backface_culling = true
                end
            end
            if worldaligntex and stair_images[i].align_style == nil then
                stair_images[i].align_style = "world"
            end
        end
    end
    return stair_images
end

-- see `stairs.register_stair_and_slab` for params (table) fields
-- group_type is "stair" or "slab"
local function get_base_def(params, droptype, group_type)
    if type(params[10]) ~= "number" then
                print(dump(params))
    end
    local new_groups = table.copy(params[6]) -- groups
    -- new_groups.stair or new_groups.slab
    new_groups[group_type] = 1
    return {
        drawtype = "nodebox",
        -- 7: images, 12: worldaligntex
        tiles = set_faces(params[7], params[12]),
        stack_max = params[10],
        paramtype = "light",
        paramtype2 = "facedir",
        drop = droptype,
        is_ground_content = false,
        groups = new_groups,
        sounds = params[11],
        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then
                return itemstack
            end

            return rotate_and_place(itemstack, placer, pointed_thing)
        end,
    }
end

-- prefix is for ex: "stairs:stair_outer"
-- use_replace is true if we want to use "replace" parameter
local function register_stairs_or_slabs(params, prefix, def, use_replace)
    -- subname, ex: "sandstone_brick"
    local subname = params[1]
    -- exemple of name: "stairs:stair_outer_sandstone_brick"
    local name = prefix .. "_".. subname
    -- #TODO why the ":" n the front ?
    core.register_node(":" .. name, def)
    -- 2: recipeitem, 3: craft_station, 4: recyle, 5: recycle_station
    stairs.register_recipies(params[2],params[3], params[4], params[5], subname, prefix)

    if use_replace then
        -- for replace ABM
        if replace then
            core.register_node(":" .. name .. "upside_down", {
                    replace_name = name,
                    groups = {slabs_replace = 1},
            })
        end
    end
end


-- Register stair
-- Nodes will be called stairs:stair_<subname> or stairs:slab_<subname>
-- see `stairs.register_stair_and_slab` for params (table) fields
function stairs.register_stair(params, droptype)
    local def = get_base_def(params, droptype, "stair")
    def.description = params[8] -- desc_stair
    def.node_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
            {-0.5, 0.0, 0.0, 0.5, 0.5, 0.5},
        },
    }
    -- use_replace = true: for replace ABM
    register_stairs_or_slabs(params, "stairs:stair", def, true)
end


-- Register slab
-- Node will be called stairs:slab_<subname>
function stairs.register_slab(params, droptype)
    local slab_def = get_base_def(params, droptype, "slab")
    slab_def.description = params[9] -- desc_slab
    slab_def.node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    }
    slab_def.on_place = function(itemstack, placer, pointed_thing)
        local under = minetest.get_node(pointed_thing.under)

        local def = minetest.registered_nodes[under.name]
        if def.on_rightclick then
            return def.on_rightclick(pointed_thing.under, under,
                                     placer, itemstack, pointed_thing)
        end
        if under and under.name:find("^stairs:slab_") then
            -- place slab using under node orientation
            local dir = minetest.dir_to_facedir(vector.subtract(
                                                   pointed_thing.above, pointed_thing.under),
                                                true)

            local p2 = under.param2

            -- Placing a slab on an upside down slab should make it right-side up.
            if p2 >= 20 and dir == 8 then
                p2 = p2 - 20
                -- same for the opposite case: slab below normal slab
            elseif p2 <= 3 and dir == 4 then
                p2 = p2 + 20
            end

            -- else attempt to place node with proper param2
            if minimal.player_in_creative(placer) then
                minetest.item_place_node(itemstack, placer, pointed_thing, p2)
                return itemstack
            end
            return minetest.item_place_node(itemstack, placer, pointed_thing, p2)
        else
            return rotate_and_place(itemstack, placer, pointed_thing)
        end
    end

    -- use_replace = true: for replace ABM
    register_stairs_or_slabs(params, "stairs:slab", slab_def, true)
end


-- Optionally replace old "upside_down" nodes with new param2 versions.
-- Disabled by default.
-- currently activated for normal stair and slab, registered above
if replace then
    minetest.register_abm({
            label = "Slab replace",
            nodenames = {"group:slabs_replace"},
            interval = 16,
            chance = 1,
            action = function(pos, node)
                node.name = minetest.registered_nodes[node.name].replace_name
                node.param2 = node.param2 + 20
                if node.param2 == 21 then
                    node.param2 = 23
                elseif node.param2 == 23 then
                    node.param2 = 21
                end
                minetest.set_node(pos, node)
            end,
    })
end


-- Register inner stair
-- Node will be called stairs:stair_inner_<subname>
-- see `stairs.register_stair_and_slab` for params (table) fields
function stairs.register_stair_inner(params, droptype)
    local def = get_base_def(params, droptype, "stair")
    def.description = S("Inner @1",  params[8]) -- desc_stair
    def.node_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
            {-0.5, 0.0, 0.0, 0.5, 0.5, 0.5},
            {-0.5, 0.0, -0.5, 0.0, 0.5, 0.0},
        },
    }
    register_stairs_or_slabs(params, "stairs:stair_inner", def)
end


-- Register outer stair
-- Node will be called stairs:stair_outer_<subname>
-- see `stairs.register_stair_and_slab` for params (table) fields
function stairs.register_stair_outer(params, droptype)
    local def = get_base_def(params, droptype, "stair")
    --#TODO being able to split description for translation would be great
    -- Outer clay stairs could be "stairs + outer + clay" in French
    def.description = S("Outer @1",  params[8]) -- desc_stair
    def.node_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
            {-0.5, 0.0, 0.0, 0.0, 0.5, 0.5},
        },
    }
    register_stairs_or_slabs(params, "stairs:stair_outer", def)
end


-- Stair/slab registration function.
-- Nodes will be called stairs:{stair,slab}_<subname>
--[[params being a table with following fields:
    {
        [1] = subname, -- ex: "sandstone_brick"
        [2] = recipeitem, -- full name for the recpipe
                          -- ex: "nodes_nature:sandstone_brick"
        [3] = craft_station, -- where to craft it, ex: "masonry_bench_bricks"
        [4] = recyle, -- can be recycle ? (boolean)
        [5] = recyle_station, -- where to recycle it, ex: "masonry_bench_bricks"
        [6] = groups, -- ex: {cracky = hardness, falling_node = 1}
        [7] = images, -- for tiles, ex: {brick[2]}
        [8] = desc_stair, -- desc for stairs, ex: S("@1 Brick Stair",desc)
        [9] = desc_slab, -- desc for stairs, ex: S("@1 Brick Slab",desc)
        [10] = stack_size, -- ex: minimal.stack_max_bulky * 6
        [11] = sounds, - ex: nodes_nature.node_sound_stone_defaults()
        [12] = worldaligntex,
        [13] = droptypemain
    }
--]]
function stairs.register_stair_and_slab(params)
    local droptype = nil
    local droptypesub = ""
    local droptypemain = params[13]
    if droptypemain ~= nil then
        -- 50% chance to drop the whole node if no stair/slabs exist
        droptype = { max_items = 1,items = {
                         {rarity = 2, items = {droptypemain} }
                   }}
        --Else remove the modname so we can build the stairs names if they do
        droptypesub = string.split(droptypemain,":")[2]
    end
    -- do stairs exist ?
    local stexist = minetest.registered_nodes["stairs:stair_"..droptypesub]

    -- register stairs
    local func
    for _, subtype in ipairs({"", "_inner", "_outer"}) do
        if stexist then -- else, default droptype above
            -- get matching name
            droptype = "stairs:stair" .. subtype .."_" ..droptypesub
        end
        -- get matching registration function
        -- ex: stairs.register_stair_inner
        func = stairs["register_stair" .. subtype]
        -- register this type of stair
        func(params, droptype)
    end

    -- registr slabs
    if stexist then droptype = "stairs:slab_"..droptypesub end
    stairs.register_slab(params, droptype)
end
