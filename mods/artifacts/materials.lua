------------------------------------
--MATERIALS
--exotic building materials
------------------------------------

minimal = minimal
artifacts = artifacts
nodes_nature = nodes_nature
tech = tech

local c_alpha = minimal.compat_alpha

local S = artifacts.S

------------------------------------
--MOON GLASS
--glowing glass
------------------------------------
local moon_glass = {
    description = S("Moon Glass"),
    drawtype = "glasslike",
    tiles = {"artifacts_moon_glass.png"},
    stack_max = minimal.stack_max_bulky *4,
    light_source = 5,
    paramtype = "light",
    sunlight_propagates  = true,
    use_texture_alpha = c_alpha.blend,
    sounds = nodes_nature.node_sound_glass_defaults(),
    groups = {cracky = 1,},
    after_place_node = minimal.protection_after_place_node,
}
minetest.register_node("artifacts:moon_glass", moon_glass)

------------------------------------
--SUN STONE
-- bright glowing glass, with warming effect
------------------------------------
local sun_stone = {
    description = S("Sun Stone"),
    tiles = {"artifacts_sun_stone.png"},
    stack_max = 1,
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {
            {-0.25, -0.5, -0.25, 0.25, -0.4375, 0.25}, -- NodeBox1
            {-0.0625, -0.5, 0.25, 0.0625, -0.4375, 0.5}, -- NodeBox2
            {-0.0625, -0.5, -0.5, 0.0625, -0.4375, -0.25}, -- NodeBox3
            {0.25, -0.5, -0.0625, 0.5, -0.4375, 0.0625}, -- NodeBox4
            {-0.5, -0.5, -0.0625, -0.25, -0.4375, 0.0625}, -- NodeBox5
            {-0.1875, -0.4375, -0.1875, 0.1875, -0.375, 0.1875}, -- NodeBox6
            {0.25, -0.5, -0.3125, 0.3125, -0.4375, -0.25}, -- NodeBox8
            {0.25, -0.5, 0.25, 0.3125, -0.4375, 0.3125}, -- NodeBox9
            {-0.3125, -0.5, 0.25, -0.25, -0.4375, 0.3125}, -- NodeBox10
            {-0.3125, -0.5, -0.3125, -0.25, -0.4375, -0.25}, -- NodeBox11
        }
    },
    light_source = 13,
    paramtype = "light",
    paramtype2 = "wallmounted",
    is_ground_content = false,
    sunlight_propagates = true,
    use_texture_alpha = c_alpha.clip,
    temp_effect = 4,
    temp_effect_max = 40,
    sounds = nodes_nature.node_sound_glass_defaults(),
    groups = {cracky = 3, oddly_breakable_by_hand = 3,
              attached_node = 1, temp_effect = 1, temp_pass = 1},
    after_place_node = minimal.protection_after_place_node,
}

minetest.register_node("artifacts:sun_stone", sun_stone)

------------------------------------
--MOON STONE
-- glowing glass, with cooling effect
------------------------------------
local moon_stone = {
    description = S("Moon Stone"),
    tiles = {"artifacts_moon_glass.png"},
    stack_max = 1,
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {
            {-0.0625, -0.5, -0.0625, 0.0625, -0.375, 0.0625}, -- NodeBox1
            {0.0625, -0.5, 0.0625, 0.125, -0.375, 0.125}, -- NodeBox2
            {0.0625, -0.5, -0.125, 0.125, -0.375, -0.0625}, -- NodeBox3
            {-0.125, -0.5, -0.125, -0.0625, -0.375, -0.0625}, -- NodeBox4
            {-0.125, -0.5, 0.0625, -0.0625, -0.375, 0.125}, -- NodeBox5
            {0.125, -0.5, -0.125, 0.25, -0.4375, 0.125}, -- NodeBox6
            {-0.25, -0.5, -0.125, -0.125, -0.4375, 0.125}, -- NodeBox7
            {-0.125, -0.5, 0.125, 0.125, -0.4375, 0.25}, -- NodeBox8
            {-0.125, -0.5, -0.25, 0.125, -0.4375, -0.125}, -- NodeBox9
            {0.125, -0.5, -0.375, 0.25, -0.4375, -0.25}, -- NodeBox10
            {0.25, -0.5, -0.25, 0.375, -0.4375, -0.125}, -- NodeBox11
            {0.25, -0.5, 0.125, 0.375, -0.4375, 0.25}, -- NodeBox12
            {0.125, -0.5, 0.25, 0.25, -0.4375, 0.375}, -- NodeBox13
            {-0.25, -0.5, 0.25, -0.125, -0.4375, 0.375}, -- NodeBox14
            {-0.375, -0.5, 0.125, -0.25, -0.4375, 0.25}, -- NodeBox15
            {-0.375, -0.5, -0.25, -0.25, -0.4375, -0.125}, -- NodeBox16
            {-0.25, -0.5, -0.375, -0.125, -0.4375, -0.25}, -- NodeBox17
            {-0.125, -0.5, -0.5, 0.125, -0.4375, -0.375}, -- NodeBox18
            {-0.125, -0.5, 0.375, 0.125, -0.4375, 0.5}, -- NodeBox19
            {-0.5, -0.5, -0.125, -0.375, -0.4375, 0.125}, -- NodeBox20
            {0.375, -0.5, -0.125, 0.5, -0.4375, 0.125}, -- NodeBox21
        }
    },
    light_source = 7,
    paramtype = "light",
    paramtype2 = "wallmounted",
    is_ground_content = false,
    sunlight_propagates = true,
    use_texture_alpha = c_alpha.blend,
    temp_effect = -4,
    temp_effect_max = 0,
    sounds = nodes_nature.node_sound_glass_defaults(),
    groups = {cracky = 3, oddly_breakable_by_hand = 3,
              attached_node = 1, temp_effect = 1, temp_pass = 1},
    after_place_node = minimal.protection_after_place_node,
}
minetest.register_node("artifacts:moon_stone", moon_stone)

------------------------------------
--STAR STONE
--small glowing glass
------------------------------------

local star_stone = {
    description = S("Star Stone"),
    tiles = {"artifacts_moon_glass.png"},
    stack_max = minimal.stack_max_medium * 2,
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {
            {-0.0625, -0.5, -0.0625, 0.0625, -0.4375, 0.0625}, -- NodeBox1
            {0.0625, -0.5, 0.0625, 0.125, -0.4375, 0.125}, -- NodeBox2
            {0.0625, -0.5, -0.125, 0.125, -0.4375, -0.0625}, -- NodeBox3
            {-0.125, -0.5, -0.125, -0.0625, -0.4375, -0.0625}, -- NodeBox4
            {-0.125, -0.5, 0.0625, -0.0625, -0.4375, 0.125}, -- NodeBox5
        }
    },
    light_source = 3,
    paramtype = "light",
    paramtype2 = "wallmounted",
    use_texture_alpha = c_alpha.clip,
    sunlight_propagates = true,
    sounds = nodes_nature.node_sound_glass_defaults(),
    groups = {oddly_breakable_by_hand = 3, attached_node = 1, temp_pass = 1},
    after_place_node = minimal.protection_after_place_node,

}

minetest.register_node("artifacts:star_stone", star_stone)

------------------------------------
--ANTIQUORIUM
--the super material of the ancients
------------------------------------
local antiq = {
    description = S("Antiquorium"),
    tiles = {"artifacts_antiquorium.png"},
    stack_max = minimal.stack_max_bulky *4,
    sounds = nodes_nature.node_sound_glass_defaults(),
    groups = {cracky = 1,},
    after_place_node = minimal.protection_after_place_node,
}
minetest.register_node("artifacts:antiquorium", antiq)

------------------------------------
--ANTIQUORIUM LADDER
------------------------------------

local ladder = {
    description = S("@1 Ladder",S("Antiquorium")),
    drawtype = "nodebox",
    stack_max = minimal.stack_max_medium,
    tiles = {
        "artifacts_antiquorium_ladder.png",
        "artifacts_antiquorium_ladder.png^[colorize:#505050",
    },
    inventory_image = "artifacts_antiquorium_ladder.png",
    wield_image = "artifacts_antiquorium_ladder.png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = true,
    climbable = true,
    is_ground_content = false,
    use_texture_alpha = c_alpha.clip,
    node_box = {
        type = "fixed",
        fixed = {-0.4,-0.5, -0.5,
                 0.4,-0.48,  0.5},
    },
    sounds = nodes_nature.node_sound_glass_defaults(),
    groups = {cracky = 2},
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local itemname = itemstack:get_name()
        if  itemname == 'artifacts:antiquorium_ladder' then
            local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
            local under = minetest.get_node(pos_under)
            if under.name == "air" then
                minetest.set_node(pos_under, {name = itemname,
                                              param1 = node.param1,
                                              param2 = node.param2
                })
                if not (minimal.player_in_creative(clicker)) then
                    itemstack:take_item()
                end
            else
                local pos_over =  {x = pos.x, y = pos.y + 1, z = pos.z}
                local over = minetest.get_node(pos_over)
                if over.name == 'air' then
                    minetest.set_node(pos_over, {name = itemname,
                                                 param1 = node.param1,
                                                 param2 = node.param2
                    })
                    if not (minimal.player_in_creative(clicker)) then
                        itemstack:take_item()
                    end
                end
            end
        else
            if itemstack:get_definition().type == "node" then
                return minetest.item_place_node(itemstack, clicker,
                                                pointed_thing)
            end
        end
    end
}
minetest.register_node("artifacts:antiquorium_ladder", ladder)

------------------------------------
--ANTIQUORIUM DOOR
------------------------------------
local door = {
    tiles = {{ name = "artifacts_antiquorium_door.png",
               backface_culling = true }},
    description = S("@1 Door",S("Antiquorium")),
    inventory_image = "artifacts_antiquorium_door_item.png",
    groups = {cracky = 2},
    sounds = tech.node_sound_metal_hollow_defaults(),
}


local trapdoor = {
    description = S("@1 Trapdoor",S("Antiquorium")),
    inventory_image = "artifacts_antiquorium_chest_top.png",
    wield_image = "artifacts_antiquorium_chest_top.png",
    tile_front = "artifacts_antiquorium_chest_top.png",
    tile_side = "artifacts_antiquorium_chest_top.png",
    groups = {cracky = 2},
    sounds = tech.node_sound_metal_hollow_defaults(),
}
doors.register("door_antiquorium", door)
doors.register_trapdoor("artifacts:trapdoor_antiquorium", trapdoor)

------------------------------------
--TRAMPOLINE
------------------------------------
local trampoline = {
    description = S('Trampoline'),
    tiles = {'artifacts_antiquorium_chest_top.png'},
    stack_max = minimal.stack_max_bulky,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "wallmounted",
    node_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, -0.3125, 0.5}, -- NodeBox1
            {-0.5, 0.3125, -0.5, 0.5, 0.5, 0.5}, -- NodeBox2
            {-0.1875, -0.3125, -0.1875, 0.1875, -0.1875, 0.1875}, -- NodeBox3
            {-0.1875, 0.1875, -0.1875, 0.1875, 0.3125, 0.1875}, -- NodeBox4
            {-0.125, 0.0625, -0.125, 0.125, 0.1875, 0.125}, -- NodeBox5
            {-0.125, -0.1875, -0.125, 0.125, -0.0625, 0.125}, -- NodeBox6
            {-0.1875, -0.0625, -0.1875, 0.1875, 0.0625001, 0.1875}, -- NodeBox7
        }
    },
    groups = {fall_damage_add_percent=-70, bouncy=85,
              oddly_breakable_by_hand = 3, temp_pass = 1},
    sounds = nodes_nature.node_sound_defaults(
        {footstep = {name="artifacts_bouncy", gain=0.8}}),
    after_place_node = minimal.protection_after_place_node,
}
minetest.register_node('artifacts:trampoline', trampoline)

------------------------------------
--CONVEYOR
------------------------------------
local conveyor = {
    description = S('Conveyor'),
    tiles = {'artifacts_antiquorium_chest_top.png'},
    stack_max = minimal.stack_max_medium *2,
    drawtype = "nodebox",
    light_source = 2,
    paramtype = "light",
    node_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5}, -- NodeBox1
        }
    },
    groups = {slippery = 1000, oddly_breakable_by_hand = 3, temp_pass = 1},
    sounds = nodes_nature.node_sound_defaults(
        {footstep = {name="artifacts_transport_fail", gain=0.5}}),
    after_place_node = minimal.protection_after_place_node,
}
minetest.register_node('artifacts:conveyor', conveyor)
