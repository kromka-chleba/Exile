-------------------------------------
--DOORS REGISTER
--and crafts...
------------------------------------

-- Internationalization
local S = tech.S

local c_alpha = EXILE.compat_alpha

--Wattle

doors.register(
    "door_wattle", {
        tiles = {{ name = "tech_door_wattle.png", backface_culling = true }},
        description = S("Wattle Door"),
        inventory_image = "tech_door_wattle_item.png",
        groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 1},
        sounds = nodes_nature.node_sound_wood_defaults(),
})


doors.register_trapdoor(
    "tech:trapdoor_wattle", {
        description = S("Wattle Trapdoor"),
        inventory_image = "tech_trapdoor_wattle.png",
        wield_image = "tech_trapdoor_wattle.png",
        tile_front = "tech_trapdoor_wattle.png",
        tile_side = "tech_trapdoor_wattle_side.png",
        groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 1},
        sounds = nodes_nature.node_sound_wood_defaults(),
})


--------------------------------------


--Wooden

doors.register(
    "door_wooden", {
        tiles = {{ name = "tech_wooden_door.png", backface_culling = true }},
        description = S("Wooden Door"),
        stack_max = EXILE.stack_max_bulky *4,
        inventory_image = "tech_wooden_door_item.png",
        groups = {choppy = 3, oddly_breakable_by_hand = 1, flammable = 1},
        sounds = nodes_nature.node_sound_wood_defaults(),
})


doors.register_trapdoor(
    "tech:trapdoor_wooden", {
        description = S("Wooden Trapdoor"),
        stack_max = EXILE.stack_max_bulky *4,
        inventory_image = "tech_wooden_trapdoor.png",
        wield_image = "tech_wooden_trapdoor.png",
        tile_front = "tech_wooden_trapdoor.png",
        tile_side = "tech_trapdoor_wooden_side.png",
        groups = {choppy = 3, oddly_breakable_by_hand = 1, flammable = 1},
        sounds = nodes_nature.node_sound_wood_defaults(),
})


------------------------------------
-- Iron - nonflammable, good for furnaces

doors.register(
    "door_iron", {
        tiles = {{ name = "tech_iron_door.png", backface_culling = true }},
        description = S("Iron Door"),
        protected = true,
        stack_max = EXILE.stack_max_bulky *2,
        inventory_image = "tech_iron_door_item.png",
        groups = {cracky = 3, oddly_breakable_by_hand = 1},
        sounds = tech.node_sound_metal_hollow_defaults(),
})

doors.register_trapdoor("tech:trapdoor_iron", {
                            description = S("Iron Trapdoor"),
                            protected = true,
                            stack_max = EXILE.stack_max_bulky *2,
                            inventory_image = "tech_trapdoor_iron.png",
                            wield_image = "tech_trapdoor_iron.png",
                            tile_front = "tech_trapdoor_iron.png",
                            tile_side = "tech_trapdoor_iron_side.png",
                            use_texture_alpha = c_alpha.clip,
                            groups = {cracky = 3, oddly_breakable_by_hand = 1},
                            sounds = tech.node_sound_metal_hollow_defaults(),
})

------------------------------------
-- Glass

doors.register("door_glass_green", {
                   tiles = {"tech_door_glass_green.png"},
                   description = S("Glass Door"),
                   protected = true,
                   stack_max = EXILE.stack_max_bulky *2,
                   inventory_image = "tech_door_glass_green_item.png",
                   use_texture_alpha = c_alpha.blend,
                   groups = {cracky = 3, oddly_breakable_by_hand = 1, flammable = 15},
                   sounds = tech.node_sound_glass_defaults(),
                   on_burn = function(pos)
                        minetest.add_item(pos, ItemStack("tech:pane_green 2"))
                        minetest.set_node(pos, {name = 'air'})
                        minetest.check_for_falling(pos)
                   end,
})

doors.register_trapdoor("tech:trapdoor_glass_green", {
                            description = S("Glass Trapdoor"),
                            protected = true,
                            stack_max = EXILE.stack_max_bulky *2,
                            inventory_image = "tech_trapdoor_glass_green.png",
                            wield_image = "tech_trapdoor_glass_green.png",
                            tile_front = "tech_trapdoor_glass_green.png",
                            tile_side = "tech_trapdoor_wooden_side.png",
                            use_texture_alpha = c_alpha.blend,
                            groups = {cracky = 3, oddly_breakable_by_hand = 1, flammable = 15},
                            sounds = tech.node_sound_glass_defaults(),
                            on_burn = function(pos)
                                minetest.add_item(pos, ItemStack("tech:pane_green"))
                                minetest.set_node(pos, {name = 'air'})
                                minetest.check_for_falling(pos)
                            end,
})

doors.register("door_glass_clear", {
                   tiles = {"tech_door_glass_clear.png"},
                   description = S("Clear Glass Door"),
                   protected = true,
                   stack_max = EXILE.stack_max_bulky *2,
                   inventory_image = "tech_door_glass_clear_item.png",
                   use_texture_alpha = c_alpha.blend,
                   groups = {cracky = 3, oddly_breakable_by_hand = 1, flammable = 15},
                   sounds = tech.node_sound_glass_defaults(),
                   on_burn = function(pos)
                        minetest.add_item(pos, ItemStack("tech:pane_clear 2"))
                        minetest.set_node(pos, {name = 'air'})
                        minetest.check_for_falling(pos)
                   end,
})

doors.register_trapdoor("tech:trapdoor_glass_clear", {
                            description = S("Clear Glass Trapdoor"),
                            protected = true,
                            stack_max = EXILE.stack_max_bulky *2,
                            inventory_image = "tech_trapdoor_glass_clear.png",
                            wield_image = "tech_trapdoor_glass_clear.png",
                            tile_front = "tech_trapdoor_glass_clear.png",
                            tile_side = "tech_trapdoor_wooden_side.png",
                            use_texture_alpha = c_alpha.blend,
                            groups = {cracky = 3, oddly_breakable_by_hand = 1, flammable = 15},
                            sounds = tech.node_sound_glass_defaults(),
                            on_burn = function(pos)
                                minetest.add_item(pos, ItemStack("tech:pane_clear"))
                                minetest.set_node(pos, {name = 'air'})
                                minetest.check_for_falling(pos)
                            end,
})
------------------------------------
--RECIPES

--wattle panels plus something to tie them on
crafting.register_recipe({
        type = {"knife_wattle"},
        output = "doors:door_wattle",
        items = {"tech:wattle 2", "group:fibrous_plant 2", "tech:stick 2"},
        level = 1,
        always_known = true,
})

--wattle panels plus something to tie them on
crafting.register_recipe({
        type = {"knife_wattle"},
        output = "tech:trapdoor_wattle",
        items = {"tech:wattle", "group:fibrous_plant", "tech:stick"},
        level = 1,
        always_known = true,
})

--------------------
crafting.register_recipe({
        type = "carpentry_bench",
        output = "doors:door_wooden",
        items = {'tech:iron_fittings 2', 'group:log 2', 'tech:vegetable_oil'},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = "carpentry_bench",
        output = "tech:trapdoor_wooden",
        items = {'tech:iron_fittings', 'group:log', 'tech:vegetable_oil'},
        level = 1,
        always_known = true,
})

-- Iron
crafting.register_recipe({
        type = "anvil",
        output = "doors:door_iron",
        items = {'tech:iron_fittings 2', 'tech:iron_ingot 4'},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = "anvil",
        output = "tech:trapdoor_iron",
        items = {'tech:iron_fittings', 'tech:iron_ingot 2'},
        level = 1,
        always_known = true,
})

-- Glass
crafting.register_recipe({
        type = "glass_furnace",
        output = "doors:door_glass_green",
        items = {'tech:iron_fittings 2', 'tech:window_green 2'},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = "glass_furnace",
        output = "tech:trapdoor_glass_green",
        items = {'tech:iron_fittings', 'tech:window_green'},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = "glass_furnace",
        output = "doors:door_glass_clear",
        items = {'tech:iron_fittings 2', 'tech:window_clear 2'},
        level = 1,
        always_known = true,
})

crafting.register_recipe({
        type = "glass_furnace",
        output = "tech:trapdoor_glass_clear",
        items = {'tech:iron_fittings', 'tech:window_clear'},
        level = 1,
        always_known = true,
})
