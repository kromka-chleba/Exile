---------------------------------------------------
--Storage
--e.g. for chests, pots etc

-- Internationalization
local S = tech.S

local c_alpha = minimal.compat_alpha
storage = storage

----------------------------------------------------
--Clay pot (see pottery for unfired version)
storage.register_storage(
    "tech:clay_storage_pot",{
        description = S("Clay Storage Pot"),
        tiles = {"tech_pottery.png",
                 "tech_pottery.png",
                 "tech_pottery.png",
                 "tech_pottery.png",
                 "tech_pottery.png"},
        sounds = nodes_nature.node_sound_stone_defaults({
                storage_close = {
                    name = "tech_clay_storage_close",
                    gain = 0.3,
                    max_hear_distance = 14,
                    pitch = {0.9,0.95}
                },
                storage_open = {
                    name = "tech_clay_storage_open",
                    gain = 0.3,
                    max_hear_distance = 14,
                    pitch = {0.9,0.95}
                }
        }),
        groups = {dig_immediate = 3, craftedby = 1, pottery = 1},

        --formspec_width = 8, -- default inv width is 8 (on register)
        --formspec_height = 4, -- default inv height is 4 (on register)
})

----------------------------------------------------
--primitive wooden chest
storage.register_storage(
    "tech:primitive_wooden_chest",{
        description = S("Primitive Wooden Chest"),
        tiles = {"tech_primitive_wood.png"},
        sounds = nodes_nature.node_sound_wood_defaults({
                storage_close = {
                    name = "tech_wooden_storage_close",
                    gain = 0.5,
                    max_hear_distance = 14
                },
                storage_open = {
                    name = "tech_wooden_storage_open",
                    gain = 0.5,
                    max_hear_distance = 14
                }
        }),
        groups = {dig_immediate = 3, craftedby = 1, flammable = 2},
})

----------------------------------------------------
--wicker basket
storage.register_storage(
    "tech:wicker_storage_basket",{
        description = S("Wicker Storage Basket"),
        tiles = {"tech_wicker.png"},
        sounds = nodes_nature.node_sound_leaves_defaults({
                storage_close = {
                    name = "tech_woven_basket_close",
                    gain = 0.6,
                    max_hear_distance = 14,
                    pitch = {0.84,0.9}
                },
                storage_open = {
                    name = "tech_woven_basket_open",
                    gain = 0.6,
                    max_hear_distance = 14,
                    pitch = {0.84,0.9}
                }
        }),
        groups = {dig_immediate = 3, craftedby = 1, flammable = 1},
        burnable = true,
})

----------------------------------------------------
--woven basket
storage.register_storage(
    "tech:woven_storage_basket",{
        description = S("Woven Storage Basket"),
        tiles = {"tech_woven.png"},
        sounds = nodes_nature.node_sound_leaves_defaults({
                storage_close = {
                    name = "tech_woven_basket_close",
                    gain = 0.5,
                    max_hear_distance = 14,
                    pitch = {1,1.12}
                },
                storage_open = {
                    name = "tech_woven_basket_open",
                    gain = 0.5,
                    max_hear_distance = 14,
                    pitch = {1,1.12}
                }
        }),
        groups = {dig_immediate = 3, craftedby = 1, flammable = 1},
        burnable = true,
})

----------------------------------------------------
--Wooden chest
storage.register_storage(
    "tech:wooden_chest",{
        description = S("Wooden Chest"),
        tiles = {"tech_wooden_chest_top.png",
                 "tech_wooden_chest_bottom.png",
                 "tech_wooden_chest_side.png",
                 "tech_wooden_chest_side.png",
                 "tech_wooden_chest_back.png",
                 "tech_wooden_chest_front.png"},
        paramtype2 = "facedir",
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {
                {-0.4375, -0.375, -0.375, 0.4375, 0.375, 0.375}, -- NodeBox1
                {-0.5, 0.375, -0.4375, 0.5, 0.5, 0.4375}, -- NodeBox2
                {0.3125, -0.5, -0.4375, 0.5, -0.375, -0.25}, -- NodeBox3
                {0.3125, -0.5, 0.25, 0.5, -0.375, 0.4375}, -- NodeBox4
                {-0.5, -0.5, 0.25, -0.3125, -0.375, 0.4375}, -- NodeBox5
                {-0.5, -0.5, -0.4375, -0.3125, -0.375, -0.25}, -- NodeBox6
                {0.1875, 0.25, 0.375, 0.3125, 0.375, 0.4375}, -- NodeBox8
                {-0.3125, 0.25, 0.375, -0.1875, 0.375, 0.4375}, -- NodeBox9
                {-0.0625, 0.25, -0.4375, 0.0625, 0.375, -0.375}, -- NodeBox10
            }
        },
        sounds = nodes_nature.node_sound_wood_defaults({
                storage_close = {
                    name = "tech_wooden_storage_close",
                    gain = 0.5,
                    max_hear_distance = 14,
                    pitch = {1.05,1.1}
                },
                storage_open = {
                    name = "tech_wooden_storage_open",
                    gain = 0.5,
                    max_hear_distance = 14,
                    pitch = {1.05,1.1}
                }
        }),
        groups = {dig_immediate = 3, craftedby = 1, flammable = 3},

        -- width already defined in base register_storage
        formspec_height = 8,
})

----------------------------------------------------
--Iron chest
storage.register_storage(
    "tech:iron_chest",{
        description = S("Iron Chest"),
        tiles = {"tech_iron_chest_top.png",
                 "tech_iron_chest_bottom.png",
                 "tech_iron_chest_side.png",
                 "tech_iron_chest_side.png",
                 "tech_iron_chest_back.png",
                 "tech_iron_chest_front.png"},
        paramtype2 = "facedir",
        use_texture_alpha = c_alpha.clip,
        protected = true,
        node_box = {
            type = "fixed",
            fixed = {
                {-0.4375, -0.375, -0.375, 0.4375, 0.375, 0.375}, -- NodeBox1
                {-0.5, 0.375, -0.4375, 0.5, 0.5, 0.4375}, -- NodeBox2
                {0.3125, -0.5, -0.4375, 0.5, -0.375, -0.25}, -- NodeBox3
                {0.3125, -0.5, 0.25, 0.5, -0.375, 0.4375}, -- NodeBox4
                {-0.5, -0.5, 0.25, -0.3125, -0.375, 0.4375}, -- NodeBox5
                {-0.5, -0.5, -0.4375, -0.3125, -0.375, -0.25}, -- NodeBox6
                {0.1875, 0.25, 0.375, 0.3125, 0.375, 0.4375}, -- NodeBox8
                {-0.3125, 0.25, 0.375, -0.1875, 0.375, 0.4375}, -- NodeBox9
                {-0.0625, 0.25, -0.4375, 0.0625, 0.375, -0.375}, -- NodeBox10
            }
        },
        sounds = nodes_nature.node_sound_wood_defaults({
                storage_close = {
                    name = "tech_iron_chest_close",
                    gain = 1.1,
                    max_hear_distance = 14,
                    pitch = {0.95,1.01}
                },
                storage_open = {
                    name = "tech_iron_chest_open",
                    gain = 1.1,
                    max_hear_distance = 14,
                    pitch = {0.95,1.01}
                }
        }),
        groups = {dig_immediate = 3, craftedby = 1},

        formspec_height = 8,
})
