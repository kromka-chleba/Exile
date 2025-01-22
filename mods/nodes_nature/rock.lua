---------------------------------------------------------
--STONE

-- Internationalization
local S = nodes_nature.S

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


    -- declare for ease of use
    local raw = core.get_current_modname()..":"..name
    raw = {raw, raw:gsub(":","_")..".png"} -- name, texture
    local block = raw[1].."_block"
    block = {block, block:gsub(":","_")..".png"}
    local brick = raw[1].."_brick"
    brick = {brick, raw[2].."^nodes_nature_brick_pattern_soft.png"}
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


for i in ipairs(rock_list) do
    local name = rock_list[i][1]
    local desc = rock_list[i][2]
    local hardness = rock_list[i][3]

    --harder rocks drop boulders
    local g = {cracky = hardness, stone = 1}
    local s = nodes_nature.node_sound_stone_defaults()

    local raw = core.get_current_modname()..":"..name
    local boulder = raw.."_boulder"
    local cobble = raw.."_cobble"
    raw = {raw, raw:gsub(":","_")..".png"} -- name, texture
    local brick = raw[1].."_brick"
    brick = {brick, brick:gsub(":","_")..".png"}
    local block = raw[1].."_block"
    block = {block, block:gsub(":","_")..".png"}

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
                                         oddly_breakable_by_hand = 1,
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
        })
    end

end

------------------------------------------------------------------
--Special features
