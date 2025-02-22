---------------------------------------------------------
--STONE

-- Internationalization
local S = nodes_nature.S

-- mathy
local ran = math.random
local abs = math.abs
local floor = math.floor

-- Load tables from data_rock.lua
local stone_list = nodes_nature.stone_list
local rock_list  = nodes_nature.rock_list

function cobble_on_place(itemstack, placer, pointed_thing, name)
    local on_click = minimal.on_rightclick(itemstack, placer, pointed_thing)
    if on_click ~= false then
        return on_click
    end
    local cobble_nr = math.random(1,3)
    local param2 = math.random(0,3)
    local place_item = ItemStack("nodes_nature:"..name.."_cobble"..cobble_nr)
    local stack, position =
        minetest.item_place_node(place_item, placer, pointed_thing, param2)
    if position and not (minimal.player_in_creative(placer)) then
        itemstack:take_item(1)
    end
    return itemstack
end



for i in ipairs(stone_list) do
    local name = stone_list[i][1]
    local desc = stone_list[i][2]
    local hardness = stone_list[i][3]
    --local type = stone_list[i][4]
    -- #TODO: what was this for?
    local sediment = stone_list[i][5]
    -- brick and block patterns
    local brickpattern = stone_list[i][6]
    -- default soft pattern, reg for regular, otherwise utilizes what was provided
    brickpattern = brickpattern == "reg" and "nodes_nature_brick_pattern.png" or
      brickpattern == "hard" and "nodes_nature_brick_pattern_hard.png" or brickpattern or
      "nodes_nature_brick_pattern_soft.png"
    local blockpattern = stone_list[i][7]
    blockpattern = blockpattern == "reg" and "nodes_nature_block_pattern.png" or
      blockpattern == "hard" and "nodes_nature_block_pattern_hard.png" or blockpattern or
      "nodes_nature_block_pattern_soft.png"

    -- declare for ease of use
    local raw = core.get_current_modname()..":"..name
    raw = {raw, raw:gsub(":","_")..".png"} -- name, texture
    local block = raw[1].."_block"
    block = {block, raw[2].."^"..blockpattern}
    local brick = raw[1].."_brick"
    brick = {brick, raw[2].."^"..brickpattern}
    -- group
    g = {cracky = hardness, crumbly = 1, soft_stone = 1}
    dropped = { max_items = 1,
                items = {
                    { tools = { "artifacts:antiquorium_chisel" },
                      items = { block[1] } },
                    { items = { sediment } }
                }
    }
    s = nodes_nature.node_sound_gravel_defaults(
        {footstep = {name = "nodes_nature_hard_footstep", gain = 0.25},})

    --register raw
    minetest.register_node(raw[1], {
                               description = desc,
                               tiles = {raw[2]},
                               stack_max = minimal.stack_max_bulky,
                               groups = g,
                               drop = dropped,
                               sounds = s,
    })

    --blocks and bricks
    --drystone construction. (see tech for the mortared version)
    --Bricks are more portable.
    minetest.register_node(brick[1], {
                               description = S("@1 Brick", desc),
                               tiles = {brick[2]},
                               paramtype2 = "facedir",
                               stack_max = minimal.stack_max_bulky *3,
                               groups = {cracky = hardness, falling_node = 1,
                                         oddly_breakable_by_hand = 1,
                                         masonry = 1},
                               sounds = nodes_nature.node_sound_stone_defaults(),
    })

    --block is cut from stone with a chisel, can be masonry'd to brick
    minetest.register_node(block[1], {
                               description = S("@1 Block", desc),
                               tiles = {block[2]},
                               stack_max = minimal.stack_max_bulky *2,
                               groups = {cracky = hardness, falling_node = 1,
                                         oddly_breakable_by_hand = 1,
                                         masonry = 1},
                               sounds = nodes_nature.node_sound_stone_defaults(),
    })

    --brick
    stairs.register_stair_and_slab(
        name.."_brick",
        brick[1],
        "masonry_bench_bricks",
        "true",
        "masonry_bench_bricks",
        {cracky = hardness, falling_node = 1, oddly_breakable_by_hand = 1},
        {brick[2]}, -- tiles
        S("@1 Brick Stair",desc),
        S("@1 Brick Slab",desc),
        minimal.stack_max_bulky * 6,
        nodes_nature.node_sound_stone_defaults()
    )

    crafting.register_recipe({
            type = "masonry_bench_bricks",
            output = brick[1],
            items = {block[1]},
            level = 1,
            always_known = true,
    })
end

-- rocks unique functions ----------------------
-- should put this into minimal, related to https://codeberg.org/Mantar/Exile/pulls/1112 implementation
local raw_item_drop = function(itemstack, dropper, pos)
    local dropper_is_player = core.is_player(dropper)
    local p = table.copy(pos)
    local cnt = itemstack:get_count()
    p.y = dropper_is_player and p.y + 1.2 or p.y
    local item = itemstack:take_item(cnt)
    local obj = core.add_item(p, item)
    if obj then
        if dropper_is_player then
            local dir = dropper:get_look_dir()
            dir.x = dir.x * 2.9
            dir.y = dir.y * 2.9 + 2
            dir.z = dir.z * 2.9
            obj:set_velocity(dir)
            obj:get_luaentity().dropped_by = dropper:get_player_name()
        end
        -- return object as 2nd parameter
        return itemstack, obj
    end
    -- If we reach this, adding the object to the
    -- environment failed
end


-- true dropper functions

local drops_check_placing -- define prior to be used by self and drops_placing

local function drops_placing_remove(obj, def, pos, count)
    obj:remove()
    if count == 1 then return end -- that was all, folks!
    -- more than one of us in this stack, let's continue
    count = count - 1
    obj = ItemStack(def.name.." "..count)
    obj = core.add_item(minimal.pos_shift(pos,{y=0.5}), obj)
    if not obj then return end -- failure
    -- let's see if we can place us!
    drops_check_placing(obj, def, count)
end

-- function for placing ejection drop on success
local drops_placing -- define prior to be used by self
-- tries - ran twice to see if possible to place
drops_placing = function(obj, def, placepos, count, tries)
    -- couldn't place, leave as is
    if tries and tries > 2 then return end
    placepos.y = tries and placepos.y + 1 or placepos.y -- add to placepos if there's a tries
    local atdef = minimal.get_nodedef(placepos) -- at node definition
    -- remove nil nodes or replace pesky node (not lava source and buildable_to !)
    if not atdef or (atdef.name ~= "nodes_nature:lava_source" and atdef.buildable_to) then
        -- LET'S PLACE THIS
        drops_placing_remove(obj, def, placepos, count) -- remove now that we've placed
        core.set_node(placepos, {name = def.name})
        local place_sound = def.sounds and def.sounds.place
        -- play place sound
        if place_sound then
            core.sound_play(place_sound.name, minimal.merge_tables(place_sound, {pos = placepos}))
        end
        -- check falling
        if def.groups and def.groups.falling_node then
            core.check_single_for_falling(placepos)
        end
    -- keeps trying until limit is reached (3)
    else
        -- add to tries if over 1
        core.after(ran(8,20)/10, drops_placing, obj, def, placepos, count, tries and tries + 1 or 1)
    end
end

-- function for checking position and running drops_placing when stopped moving

-- was0 is to determine how long object has been sitting still
-- count is used to determine if we should run this function with another entity
drops_check_placing = function(obj, def, count, was0)
    local vel = obj:get_velocity()
    if not vector.check(vel) then return end -- we got deletus
    was0 = was0 or 0
    vel = abs(vel.x)+abs(vel.y)+abs(vel.z)
    -- gotta wait til we fully stop moving
    if vel == 0 and was0 > 2 then
        local newpos = obj:get_pos()
        -- convert to node-ready position
        newpos = vector.new(floor(newpos.x + 0.5), floor(newpos.y + 0.5), floor(newpos.z + 0.5))
        return drops_placing(obj, def, newpos, count)
    else
        -- check every 0.3 to 0.6 seconds
        -- set "was0" to 0 if velocity changed, otherwise add to was0 by 1
        return core.after(ran(3,6)/10, drops_check_placing, obj, def, count, vel == 0 and (was0 + 1) or 0)
    end
end

-- should be ran with node's on_drop
-- for cobble and boulders
local function rocks_on_drop(itemstack, dropper, pos, drop, def)
    def = def or itemstack:get_definition()
    -- check if node
    if not core.registered_nodes[def.name] then return end -- can't drop dis
    local count = itemstack:get_count() -- used for determining how many of this to place
    -- only do item_drop function if no "drop" specified
    if not drop then
        itemstack, drop = raw_item_drop(itemstack, dropper, pos)
    end
    -- add delays, 20 seconds if from player
    -- normal delay is 0.8 to 1.8 seconds
    local delay = core.is_player(dropper) and 20 or ran(8,18)/10
    core.after(delay, drops_check_placing, drop, def, count)
    return itemstack or true
end


for i in ipairs(rock_list) do
    local name = rock_list[i][1]
    local desc = rock_list[i][2]
    local hardness = rock_list[i][3]
    -- brick and block patterns
    local brickpattern = rock_list[i][4]
    -- default reg pattern, soft for soft, otherwise utilizes what was provided
    brickpattern = brickpattern == "soft" and "nodes_nature_brick_pattern_soft.png" or
      brickpattern == "hard" and "nodes_nature_brick_pattern_hard.png" or brickpattern or
      "nodes_nature_brick_pattern.png"
    local blockpattern = rock_list[i][5]
    blockpattern = blockpattern == "soft" and "nodes_nature_block_pattern_soft.png" or
      blockpattern == "hard" and "nodes_nature_block_pattern_hard.png" or blockpattern or
      "nodes_nature_block_pattern.png"

    --harder rocks drop boulders
    local g = {cracky = hardness, stone = 1}
    local s = nodes_nature.node_sound_stone_defaults()

    local raw = core.get_current_modname()..":"..name
    local boulder = raw.."_boulder"
    local cobble = raw.."_cobble"
    raw = {raw, raw:gsub(":","_")..".png"} -- name, texture
    -- unique condition for mixes
    if raw[2]:match("_with_") then -- we're two different textures!!!
        raw[2] = raw[2]:split("_with_") -- split into components
        -- recombine (should only be 2 parameters)
        -- add .png^ to first component, then add mod name and "_part_" to second component
        raw[2] = raw[2][1]..".png^"..core.get_current_modname().."_part_"..raw[2][2]
    end
    local brick = raw[1].."_brick"
    brick = {brick, raw[2].."^"..brickpattern}
    local block = raw[1].."_block"
    block = {block, raw[2].."^"..blockpattern}

    --register raw
    minetest.register_node(raw[1], {
                               description = desc,
                               tiles = {raw[2]},
                               stack_max = minimal.stack_max_bulky,
                               groups = g,
                               drop = boulder,
                               sounds = s,
    })

    --boulder
    minetest.register_node(boulder,{
                               description = S("@1 Boulder", desc),
                               exile_crafting = {
                                   material = name,
                               },
                               drawtype = "mesh",
                               mesh = "nodes_nature_boulder.obj",
                               tiles = {raw[2]},
                               stack_max = minimal.stack_max_bulky,
                               paramtype = "light",
                               paramtype2 = "facedir",
                               groups = {cracky = hardness, falling_node = 1,
                                         oddly_breakable_by_hand = 3,
                                         boulder = 1},
                               selection_box = {
                                   type = "fixed",
                                   fixed =
                                       {-7/16, -8/16, -7/16, 7/16, 7/16, 7/16},
                               },
                               collision_box = {
                                   type = "fixed",
                                   fixed =
                                       {-7/16, -8/16, -7/16, 7/16, 7/16, 7/16},
                               },
                               sounds = nodes_nature.node_sound_stone_defaults(),
                               on_drop = rocks_on_drop
    })


    --blocks and bricks
    --drystone construction. (see tech for the mortared version)
    --Bricks are more portable.
    minetest.register_node(brick[1], {
                               description = S("@1 Brick", desc),
                               tiles = {brick[2]},
                               paramtype2 = "facedir",
                               stack_max = minimal.stack_max_bulky *3,
                               groups = {cracky = hardness, falling_node = 1,
                                         oddly_breakable_by_hand = 1,
                                         masonry = 1},
                               sounds = nodes_nature.node_sound_stone_defaults(),
    })

    --block is a shaped boulder, so has similar properties
    minetest.register_node(block[1], {
                               description = S("@1 Block", desc),
                               tiles = {block[2]},
                               --drawtype = "nodebox",
                               --paramtype = "light",
                               --[[...fancy block
                                   node_box = {
                                   type = "fixed",
                                   fixed = {
                                   {-0.375, -0.5, -0.375, 0.375, 0.5, 0.375},
                                   {-0.375, -0.5, 0.375, 0.375, 0.5, 0.5},
                                   {-0.375, -0.5, -0.5, 0.375, 0.5, -0.375},
                                   {0.375, -0.5, -0.375, 0.5, 0.5, 0.375},
                                   {-0.5, -0.5, -0.375, -0.375, 0.5, 0.375},
                                   {-0.5, -0.375, -0.5, -0.375, 0.375, -0.375},
                                   {0.375, -0.375, -0.5, 0.5, 0.375, -0.375},
                                   {0.375, -0.375, 0.375, 0.5, 0.375, 0.5},
                                   {-0.5, -0.375, 0.375, -0.375, 0.375, 0.5},
                                   }
                                   },]]
                               stack_max = minimal.stack_max_bulky *2,
                               groups = {cracky = hardness, falling_node = 1,
                                         oddly_breakable_by_hand = 1,
                                         masonry = 1},
                               sounds = nodes_nature.node_sound_stone_defaults(),
    })

    --hammer out blocks etc from boulder
    crafting.register_recipe({
            type = {"masonry_bench","hammer","hammering_block"},
            output = block[1],
            items = {boulder},
            level = 1,
            always_known = true,
    })

    crafting.register_recipe({
            type = {"hammer","hammering_block"},
            output = cobble.."1 8",
            items = {boulder},
            level = 1,
            always_known = true,
    })

    crafting.register_recipe({
            type = "masonry_bench",
            output = brick[1],
            items = {cobble.."1 8"},
            level = 1,
            always_known = true,
    })

    --recycle block (e.g. so can get iron ore)
    crafting.register_recipe({
            type = {"hammer_mixing","mixing_spot"},
            output = boulder,
            items = {block[1]},
            level = 1,
            always_known = true,
    })
    crafting.register_recipe({
            type = {"hammer_mixing","mixing_spot"},
            output = cobble.."1 8",
            items = {brick[1]},
            level = 1,
            always_known = true,
    })


    --stairs and slabs

    --brick
    stairs.register_stair_and_slab(
        name.."_brick",
        brick[1],
        "masonry_bench_bricks",
        "true",
        "masonry_bench_mixing",
        {cracky = hardness, falling_node = 1, oddly_breakable_by_hand = 1},
        {brick[2]},
        S("@1 Brick Stair", desc),
        S("@1 Brick Slab", desc),
        minimal.stack_max_bulky * 6,
        nodes_nature.node_sound_stone_defaults()
    )

    --block
    stairs.register_stair_and_slab(
        name.."_block",
        block[1],
        "masonry_bench_blocks",
        "false",
        "masonry_bench_mixing",
        {cracky = hardness, falling_node = 1, oddly_breakable_by_hand = 1},
        {block[2]},
        S("@1 Block Stair", desc),
        S("@1 Block Slab", desc),
        minimal.stack_max_bulky * 4,
        nodes_nature.node_sound_stone_defaults()
    )

    local cobble_groups = {cracky = hardness,
                           falling_node = 1,
                           oddly_breakable_by_hand = 3,
                           temp_pass = 1, temp_flow = 1
    }
    cobble_groups[name.."_cobble"] = 1

    -- cobbles
    for cobble_nr = 1, 3 do
        minetest.register_node(
            cobble..cobble_nr,{
                description = S("@1 Cobble", desc),
                exile_crafting = {
                    material = name,
                },
                drawtype = "mesh",
                mesh = "nodes_nature_cobble"..cobble_nr..".obj",
                tiles = {raw[2]},
                stack_max = minimal.stack_max_bulky * 8,
                paramtype = "light",
                paramtype2 = "facedir",
                groups = cobble_groups,
                drop = cobble.."1",
                on_place = function(itemstack, placer, pointed_thing)
                    return cobble_on_place(itemstack, placer,
                                           pointed_thing, name)
                end,
                selection_box = {
                    type = "fixed",
                    fixed = {-5/16, -8/16, -5/16, 5/16, -4/16, 5/16},
                },
                collision_box = {
                    type = "fixed",
                    fixed = {-5/16, -8/16, -5/16, 5/16, -4/16, 5/16},
                },
                sounds = nodes_nature.node_sound_stone_defaults(),
                on_drop = rocks_on_drop
        })
    end

end

------------------------------------------------------------------
--Special features

-- peridot from peridot in basalt
crafting.register_recipe({
    type = "hammer",
    output = "nodes_nature:peridot_cobble1 4",
    replace = "nodes_nature:basalt_cobble1 4",
    items = {"group:basalt_with_peridot_cobble 8"}
})