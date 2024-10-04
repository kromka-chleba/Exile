---------------------------------------------------------
--Plants and Mushrooms

-- Internationalization
local S = nodes_nature.S
nodes_nature = nodes_nature
local nn = nodes_nature
local plant = nodes_nature.plant

---------------------------------------------------------

local lambakap_nodebox = {
    {-0.125, -0.5, -0.125, 0.125, -0.375, 0.125},
    {-0.1875, -0.375, -0.1875, 0.1875, -0.1875, 0.1875},
    {-0.1875, -0.1875, -0.1875, -0.0625, 0, 0.1875},
    {0.0625, -0.1875, -0.1875, 0.1875, 0, 0.1875},
    {-0.0625, -0.1875, -0.1875, 0.0625, 0, -0.0625},
    {-0.0625, -0.1875, 0.0625, 0.0625, 0, 0.1875},
}

local reshedaar_nodebox = {
    {-0.125, -0.5, -0.125, 0.125, -0.25, 0.125}, -- NodeBox1
    {-0.0625, -0.5, -0.1875, 0.0625, -0.0625, -0.125}, -- NodeBox2
    {-0.0625, -0.5, 0.125, 0.0625, -0.0625, 0.1875}, -- NodeBox3
    {-0.1875, -0.5, -0.0625, -0.125, -0.0625, 0.0625}, -- NodeBox4
    {0.125, -0.5, -0.0625, 0.1875, -0.0625, 0.0625}, -- NodeBox5
    {-0.125, -0.25, -0.125, -0.0625, 0.4375, -0.0625}, -- NodeBox9
    {-0.125, -0.25, 0.0625, -0.0625, 0.3125, 0.125}, -- NodeBox10
    {0.0625, -0.25, -0.125, 0.125, 0.3125, -0.0625}, -- NodeBox11
    {0.0625, -0.25, 0.0625, 0.125, 0.4375, 0.125}, -- NodeBox12
}

local mahal_nodebox = {
    {-0.125, -0.5, -0.125, 0.125, -0.3125, 0.125}, -- NodeBox1
    {-0.0625, -0.3125, -0.0625, 0.0625, 0.3125, 0.0625}, -- NodeBox2
    {-0.125, 0.375, -0.125, 0.125, 0.5, 0.125}, -- NodeBox3
    {-0.1875, 0.3125, -0.1875, 0.1875, 0.375, 0.1875}, -- NodeBox4
}

local moss_nodebox = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5}


local wrotycz_soil_prefs =
    nn.soil_preferences.new({
            rocky_substrate = {min = 2, max = 2},
            organic_substrate = {min = 2, max = 2},
            density = {min = 4, max = 4},
    })

--[[
    The best ratio for these plant types should be:
    1/3 - edible plants, 1/3 - inedible, 1/3 - slightly toxic
    Inedible means hard/impossible to eat or low nutritional value, e.g. grass
    Rarely we should have plants that are extremely toxic

    The current state (careful, I counted manually):
    29.04.2023

    37 total plants and mushrooms
    12 are edible or are medicines
    3 are extremely toxic
    1 is mildly toxic (wrotycz)
    22 are inedible

    Looks like we need more slightly toxic plants.
    Also edible plants of low nutritional value.
--]]


local plant_list = {
    -- Herbs
    {name = "barszcz", description = S("Barshocha"),
     drawtype = "plantlike", mesh_type = 2,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     fruit = true, seasonal_type = "tuber",
     roots = 5,
     winter_fruit = true, dry_fruit = true},

    {name = "wrotycz", description = S("Vortecha"),
     drawtype = "plantlike", mesh_type = 1,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     soil_preferences = wrotycz_soil_prefs, fruit = true,
     seasonal_type = "late", winter_fruit = true,
     dry_fruit = true},

    {name = "wiha", description = S("Wiha"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "red",
     fruit = true, seasonal_type = "early",
     winter_fruit = true,},

    {name = "momo", description = S("Momo"),
     drawtype = "plantlike", mesh_type = 2,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "red",
     fruit = true, winter_fruit = false,
     seasonal_type = "late"},

    {name = "galanta", description = S("Galanta"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 0.4,
     dye_candidate = true, dominant_color = "green",
     seasonal_type = "whole_season",
     edible_seedling = true},

    {name = "vansano", description = S("Vansano"),
     drawtype = "plantlike", mesh_type = 2,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 1.2,
     dye_candidate = true, dominant_color = "green",
     fruit = true, seasonal_type = "long", winter_fruit = false,
     dry_fruit = true},

    {name = "anperla", description = S("Anperla"),
     plant_type = "herbaceous_plant", waving = true,
     drawtype = "plantlike", mesh_type = 3,
     growing_time = nn.plant_base_growing_time * 3,
     dye_candidate = true, dominant_color = "green",
     winter_fruit = false, seasonal_type = "tuber",
     fruit = true, roots = 8},

    {name = "rzepicha", description = S("Jepiha"),
     plant_type = "herbaceous_plant", waving = true,
     drawtype = "plantlike", mesh_type = 0,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "green",
     winter_fruit = false, seasonal_type = "tuber",
     fruit = true},

    {name = "hakimi", description = S("Hakimi"),
     drawtype = "plantlike", waving = true,
     plant_type = "herbaceous_plant", mesh_type = 3,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "blue",
     fruit = true, winter_fruit = true,
     seasonal_type = "mainly_flower",
     dry_fruit = true},

    {name = "ziarnoplon", description = S("Jarno"),
     drawtype = "plantlike", waving = true,
     plant_type = "herbaceous_plant", mesh_type = 3,
     growing_time = nn.plant_base_growing_time * 0.4,
     dye_candidate = true, dominant_color = "yellow",
     fruit = true, seasonal_type = "early_flower"},

    {name = "srebroplon", description = S("Serebro"),
     drawtype = "plantlike", waving = true,
     plant_type = "herbaceous_plant", mesh_type = 3,
     growing_time = nn.plant_base_growing_time * 0.4,
     dye_candidate = true, dominant_color = "blue",
     fruit = true, seasonal_type = "early_flower",
     bioluminescence = 3},

    {name = "orom", description = S("Orom"),
     drawtype = "plantlike", mesh_type = 1,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "black"},

    {name = "veke", description = S("Veke"),
     drawtype = "plantlike", mesh_type = 0,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "black"},

    {name = "tikusati", description = S("Tikusati"),
     drawtype = "plantlike", mesh_type = 2,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     fruit = true, seasonal_type = "medium",
     winter_fruit = true, dry_fruit = true},

    {name = "malinka", description = S("Malinka"),
     drawtype = "plantlike", mesh_type = 1,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 1.5,
     dye_candidate = true, dominant_color = "green",
     fruit = true, seasonal_type = "medium", winter_fruit = false},

    {name = "malina", description = S("Malina"),
     drawtype = "plantlike", mesh_type = 3,
     plant_type = "woody_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2.5,
     dye_candidate = true, dominant_color = "green",
     fruit = true, seasonal_type = "long", winter_fruit = false,
     move_resistance = 3, thorns = true},

    {name = "yellow_malina", description = S("Yellow Malina"),
     drawtype = "plantlike", mesh_type = 2,
     plant_type = "woody_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2.5,
     dye_candidate = true, dominant_color = "green",
     fruit = true, seasonal_type = "long", winter_fruit = false,
     move_resistance = 3, thorns = true},

    {name = "gevaari", description = S("Gevaari"),
     drawtype = "plantlike", plant_type = "herbaceous_plant",
     mesh_type = 1, growing_time = nn.plant_base_growing_time * 4,
     dye_candidate = true, dominant_color = "green",
     seasonal_type = "whole_season", thorns = true, move_resistance = 4},

    {name = "obesa", description = S("Obesa"),
     drawtype = "plantlike", plant_type = "herbaceous_plant",
     mesh_type = 0, growing_time = nn.plant_base_growing_time * 4,
     dye_candidate = true, dominant_color = "green",
     seasonal_type = "succulent_flowering", fruit = true,
     texture_scale = 1.2, thorns = true, move_resistance = 4},

    {name = "salia", description = S("Salia"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time,
     dye_candidate = true, dominant_color = "red",
     fruit = true, seasonal_type = "early"},

    {name = "fretin", description = S("Fretin"),
     drawtype = "plantlike", plant_type = "herbaceous_plant",
     waving = true,
     mesh_type = 2, growing_time = nn.plant_base_growing_time,
     dye_candidate = true, dominant_color = "black",
     seasonal_type = "whole_season",
     edible_seedling = true},

    {name = "urimi", description = S("Urimi"),
     drawtype = "plantlike", plant_type = "herbaceous_plant",
     waving = true,
     mesh_type = 2, growing_time = nn.plant_base_growing_time,
     dye_candidate = true, dominant_color = "black",
     seasonal_type = "whole_season",
     edible_seedling = false},

    -- Rhuya: Kind of a mix between corn and wheat, corn-like fruit and plant size, wheat-like seed purposes
    -- fruit is toxic (and seeds maintain a bit of fruit toxins), tasting like like pine sap - bitter, and a bit sour
    {name = "rhuya", description = S("Rhuya"),
     drawtype = "plantlike", waving = true,
     plant_type = "herbaceous_plant", mesh_type = 0,
     growing_time = nn.plant_base_growing_time * 3,
     dye_candidate = false, texture_scale = 1.6,
     fruit = true, seasonal_type = "late", dry_fruit = true},

    -- Rhuya: Winter Variant
    -- NOT meant to appear in the wild (domesticated only, do not add to mapgen)
    -- Like the regular rhuya, but now with its own antifreeze (sorta)! Still quite toxic
    -- Fruit encased in an insulated harder shell (see about modifying recipes so that a knife is required?);
    -- possibly cacao pod consistency or harder
    {name = "rhuya_wintery", description = S("Hardy Rhuya"),
     drawtype = "plantlike", waving = false,
     plant_type = "herbaceous_plant", mesh_type = 0,
     growing_time = nn.plant_base_growing_time * 3,
     dye_candidate = false, texture_scale = 1.85,
     fruit = true, seasonal_type = "wintery", dry_fruit = true},

    -- Mushrooms

    --Lambakap. is also a mushroom.
    -- slow growing food and water source,
    -- main crop for longterm underground living.

    {name = "lambakap", description = S("Lambakap"),
     drawtype = "nodebox", nodebox = lambakap_nodebox,
     lifeform_type = "mushroom", plant_type = "mushroom",
     growing_time = nn.plant_base_growing_time * 3,
     dye_candidate = true, dominant_color = "red",
     bioluminescence = 2, extra_groups = {flammable = 6}},

    --Reshedaar.  is also a mushroom.
    -- slow growing fibre mushroom,
    -- main fibre crop for longterm underground living.

    --(can't be bioluminescent or conflicts with recipe)
    {name = "reshedaar", description = S("Reshedaar"),
     drawtype = "nodebox", nodebox = reshedaar_nodebox,
     lifeform_type = "mushroom", plant_type = "fibrous_plant",
     growing_time = nn.plant_base_growing_time * 3,
     dye_candidate = true, dominant_color = "red",},

    --Mahal. is also a mushroom.
    -- slow growing woody mushroom,
    -- main stick crop for longterm underground living.

    {name = "mahal", description = S("Mahal"),
     drawtype = "nodebox", nodebox = mahal_nodebox,
     lifeform_type = "mushroom", plant_type = "woody_plant",
     growing_time = nn.plant_base_growing_time * 3,
     dye_candidate = true, dominant_color = "red",
     bioluminescence = 1,},

    {name = "merki", description = S("Merki"),
     drawtype = "plantlike", bioluminescence = 2,
     lifeform_type = "mushroom", plant_type = "mushroom",
     mesh_type = 0, growing_time = nn.plant_base_growing_time * 2},

    {name = "nebiyi", description = S("Nebiyi"),
     drawtype = "plantlike",
     lifeform_type = "mushroom", plant_type = "mushroom",
     mesh_type = 1, growing_time = nn.plant_base_growing_time,
     dye_candidate = true, dominant_color = "indigo",
     seasonal_type = "late_mushroom"},

    {name = "marbhan", description = S("Marbhan"),
     drawtype = "plantlike",
     lifeform_type = "mushroom", plant_type = "mushroom",
     mesh_type = 2, growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "red",
     seasonal_type = "whole_season"},

    {name = "zufani", description = S("Zufani"),
     drawtype = "plantlike",
     lifeform_type = "mushroom", plant_type = "mushroom",
     mesh_type = 2, growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     seasonal_type = "late_mushroom", fruit = true,
     only_dead_fruit = true, winter_fruit = true},

    -- Woody
    {name = "tsaplop", description = S("Tsaplop"),
     drawtype = "plantlike", plant_type = "woody_plant",
     mesh_type = 0, growing_time = nn.plant_base_growing_time * 4,
     dye_candidate = true, dominant_color = "green",
     seasonal_type = "whole_season_woody",
     texture_scale = 1.2, thorns = true, move_resistance = 4},

    {name = "jogalan", description = S("Jogalan"),
     drawtype = "plantlike", plant_type = "woody_plant",
     waving = true,
     mesh_type = 0, growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "black"},

    {name = "gitiri", description = S("Gitiri"),
     drawtype = "plantlike", plant_type = "woody_plant",
     waving = true,
     mesh_type = 2, growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "green",
     texture_scale = 1.2, seasonal_type = "whole_season_woody"},

    {name = "badyl", description = S("Badyl"),
     drawtype = "plantlike", plant_type = "woody_plant",
     waving = true,
     mesh_type = 0, growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "red",
     texture_scale = 1, seasonal_type = "whole_season_woody"},

    {name = "drapacz", description = S("Drapacho"),
     drawtype = "plantlike", plant_type = "woody_plant",
     waving = false, thorns = true, move_resistance = 4,
     mesh_type = 0, growing_time = nn.plant_base_growing_time * 4,
     dye_candidate = true, dominant_color = "red",
     texture_scale = 1.2, seasonal_type = "whole_season_woody"},

    {name = "bronach", description = S("Bronach"),
     drawtype = "plantlike", plant_type = "woody_plant",
     waving = true,
     mesh_type = 3, growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "crimson",
     texture_scale = 1.2, seasonal_type = "whole_season_woody"},

    -- Grasses
    {name = "sari",
    description = S("Sari"),
    drawtype = "plantlike",
    mesh_type = 2,
    plant_type = "fibrous_plant",
    waving = true,
    growing_time = nn.plant_base_growing_time * 0.5,
    dye_candidate = true,
    dominant_color = "yellow",
    seasonal_type = "whole_season"},

    {name = "tanai", description = S("Tanai"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "fibrous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 1.5,
     dye_candidate = true, dominant_color = "crimson",
     seasonal_type = "whole_season"},

    {name = "thoka", description = S("Thoka"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "fibrous_plant", waving = true,
     dye_candidate = true,
     growing_time = nn.plant_base_growing_time * 2},

    {name = "alaf", description = S("Alaf"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "fibrous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     seasonal_type = "whole_season"},

    {name = "muhle", description = S("Muhle"),
     drawtype = "plantlike", plant_type = "fibrous_plant",
     mesh_type = 4,  waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "black",
     seasonal_type = "late", fruit = true, winter_fruit = true,
     move_resistance = 4},

    {name = "damo", description = S("Damo"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "fibrous_plant", waving = true,
     growing_time = nn.plant_base_growing_time,
     dye_candidate = true, dominant_color = "green",
     seasonal_type = "whole_season", edible_seedling = true},

    {name = "tashvish", description = S("Tashvish"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "fibrous_plant", waving = true,
     dye_candidate = true,
     growing_time = nn.plant_base_growing_time * 1.5,
     seasonal_type = "whole_season"},

    -- Moss
    {name = "moss", description = S("Moss"),
     drawtype = "nodebox", nodebox = moss_nodebox,
     plant_type = "moss", growing_time = nn.plant_base_growing_time * 3,
     dye_candidate = true, dominant_color = "green",},

    -- Canes
    {name = "cana", description = S("Cana"),
     mesh_type = 2, seasonal_type = "cane",
     drawtype = "plantlike", plant_type = "cane", waving = false,
     growing_time = nn.plant_base_growing_time * 2, seed_number = 1,
     extra_groups = {cana = 1}},

    {name = "gemedi", description = S("Gemedi"),
     mesh_type = 2,
     drawtype = "plantlike", plant_type = "cane", waving = false,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     seed_number = 1, seasonal_type = "cane"},

    -- Bamboos
    {name = "chalin", description = S("Chalin"),
     mesh_type = 2,
     drawtype = "plantlike", plant_type = "bamboo", waving = false,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     seed_number = 1, climbable = true, seasonal_type = "whole_season_woody",
     move_resistance = 1},

    {name = "tiken", description = S("Tiken"),
     mesh_type = 2,
     drawtype = "plantlike", plant_type = "bamboo", waving = false,
     growing_time = nn.plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     seed_number = 1, thorns = true, seasonal_type = "whole_season_woody"},

    {name = "saguati", description = S("Saguati"),
     drawtype = "plantlike", plant_type = "bamboo", waving = false,
     growing_time = nn.plant_base_growing_time * 4,
     dye_candidate = true, dominant_color = "green",
     seed_number = 1, thorns = true, seasonal_type = "whole_season_woody"},
}

-- makes all plants in the game
plant.register_all(plant_list)

----------------------------------------------
--Name overrides

minetest.override_item(
    "nodes_nature:zufani_fruit", {
        description = S("Zufani Amber"),
})

minetest.override_item(
    "nodes_nature:momo_fruit", {
        description = S("Momo Pepper"),
})

minetest.override_item(
    "nodes_nature:wiha_fruit", {
        description = S("Wiha Berries"),
})

minetest.override_item(
    "nodes_nature:muhle_fruit", {
        description = S("Muhle Berries"),
})


----------------------------------------------
--Extra effects

-- tuber
minetest.override_item(
    "nodes_nature:anperla_root",{
        tiles = {"nodes_nature_silt.png"},
        description = S("Anperla tuber"),
        wield_image = "nodes_nature_tuber.png",
        inventory_image = "nodes_nature_tuber.png",
        node_box = {
            type = "fixed",
            fixed = {-0.15, -0.5, -0.15,  0.15, -0.35, 0.15},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.15, -0.5, -0.15,  0.15, -0.35, 0.15},
        },
        stack_max = minimal.stack_max_medium,
        walkable = true,
})

minetest.override_item(
    "nodes_nature:barszcz_root",{
        tiles = {"nodes_nature_red_ochre.png"},
        description = S("Barshocha root"),
        wield_image = "nodes_nature_barszcz_root.png",
        inventory_image = "nodes_nature_barszcz_root.png",
        node_box = {
            type = "fixed",
            fixed = {-0.15, -0.5, -0.15,  0.15, -0.35, 0.15},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.15, -0.5, -0.15,  0.15, -0.35, 0.15},
        },
        stack_max = minimal.stack_max_medium,
        walkable = true,
})

minetest.register_craftitem(
    "nodes_nature:rzepicha_root",
    {
        description = S("Jepiha root"),
        inventory_image = "nodes_nature_rzepicha_root.png",
        wield_image = "nodes_nature_rzepicha_root.png",
        stack_max = minimal.stack_max_medium,
        groups = {},
        on_place = function(itemstack, placer, pointed_thing)
            local above = minetest.get_node(pointed_thing.above)
            local pos_below = minimal.get_pos_under(pointed_thing.above)
            local sediment = minimal.pos_group(pos_below, "sediment")
            if sediment and above.name == "air" then
                minetest.set_node(pointed_thing.above,
                                  { name = "nodes_nature:rzepicha_fruitless" })
                plant.set_to_domesticated(pointed_thing.above)
                if not minimal.player_in_creative(placer) then
                    itemstack:take_item()
                end
            end
            return itemstack
        end,
    }
)

minetest.register_craftitem(
    "nodes_nature:rzepicha_root_winter",
    {
        description = S("Jepiha root"),
        inventory_image = "nodes_nature_rzepicha_root_winter.png",
        wield_image = "nodes_nature_rzepicha_root_winter.png",
        stack_max = minimal.stack_max_medium,
        groups = {},
        on_place = function(itemstack, placer, pointed_thing)
            local above = minetest.get_node(pointed_thing.above)
            local pos_below = minimal.get_pos_under(pointed_thing.above)
            local sediment = minimal.pos_group(pos_below, "sediment")
            if sediment and above.name == "air" then
                minetest.set_node(pointed_thing.above,
                                  { name = "nodes_nature:rzepicha_seedling5" })
                plant.set_to_domesticated(pointed_thing.above)
                if not minimal.player_in_creative(placer) then
                    itemstack:take_item()
                end
            end
            return itemstack
        end,
    }
)

HEALTH.add_food_hooks("nodes_nature:rzepicha_root")
HEALTH.add_food_hooks("nodes_nature:rzepicha_root_winter")

minetest.override_item(
    "nodes_nature:rzepicha_fruitless",
    {drop = "nodes_nature:rzepicha_root"}
)

minetest.override_item(
    "nodes_nature:rzepicha_fruiting",
    {drop = "nodes_nature:rzepicha_root"}
)

minetest.override_item(
    "nodes_nature:rzepicha_flowering",
    {drop = "nodes_nature:rzepicha_root"}
)

minetest.override_item(
    "nodes_nature:rzepicha_dead",
    {drop = "nodes_nature:rzepicha_root_winter"}
)

--marbhan has a Neurotoxin
minetest.override_item(
    "nodes_nature:marbhan",{
        _on_consume = function(user, itemstack, pointed_thing)
            --Similar to hemlock, which tastes musty or like mouse urine
            minetest.chat_send_player(user:get_player_name(),
                                      S("This plant has a foul musty flavor."))

            return HEALTH.eatdrink(itemstack, user, pointed_thing)
        end,
})


--nebiyi has a Hepatotoxin
minetest.override_item(
    "nodes_nature:nebiyi",{
        _on_consume = function(user, itemstack, pointed_thing)
            --Flowers look a bit like oleander; it causes intense stomach pain
            minetest.chat_send_player(user:get_player_name(),
                                      S("Your stomach hurts terribly."))

            return HEALTH.eatdrink(itemstack, user, pointed_thing)
        end,
})

-- rhuya overrides
-- override textures and rendering for rhuya seeds
do -- local scope to prevent global access
    for _,rhuya in pairs({"","_wintery"}) do
        local seed_name = "nodes_nature:rhuya"..rhuya.."_seed"
        local seed_on_place = minetest.registered_nodes[seed_name].on_place
        minetest.override_item(
            seed_name,  {
                inventory_image = "nodes_nature_rhuya_seed.png",
                wield_image = "nodes_nature_rhuya_seed.png",
                tiles = {"nodes_nature_rhuya_seed.png"},
                node_box = {
                    type = "fixed",
                    fixed = {-0.45, -0.5, -0.45,  0.45, -0.48, 0.45},
                },
                selection_box = {
                    type = "fixed",
                    fixed = {-0.45, -0.5, -0.45,  0.45, -0.48, 0.45},
                },
                -- functionality for normal rhuya seeds turning to wintery, or wintery becoming normal
                on_place = function(itemstack, placer, pointed_thing)
                    if not pointed_thing then return seed_on_place(itemstack, placer, pointed_thing) end
                    local itemdef = itemstack:get_definition()
                    itemstack = seed_on_place(itemstack, placer, pointed_thing)
                    local pos = pointed_thing.above
                    if minetest.get_node(pos).name ~= itemdef.name then return itemstack end
                    -- winter variant (3% chance to return to normal)
                    if #itemdef.name == 31 then
                        if math.random() > 0.03 then return end
                        -- convert to normal after 4 seconds
                        minetest.after(4, function()
                            local node = minetest.get_node(pos)
                            if node.name ~= itemdef.name then return end
                            node.name = node.name:gsub("_wintery","")
                            -- only if node still exists
                            minetest.swap_node(pos, node)
                        end)
                    -- non-winter variant (95% chance to check if should be wintery)
                    elseif math.random() < 0.95 then
                        local temp = climate.get_point_temp(pos)
                        local convert = temp < 7 and 0.1 or nil -- convert (chance) 10% or nil
                        if convert then
                          -- 30%, 50%, 70%, 99%
                          convert = temp < 3 and 0.3 or convert
                          convert = temp < 0 and 0.5 or convert
                          convert = temp < -4 and 0.7 or convert
                          convert = temp < -9 and 0.99 or convert
                          if math.random() < convert then
                              -- convert after 4 seconds
                              minetest.after(4, function()
                                  local node = minetest.get_node(pos)
                                  if node.name ~= itemdef.name then return end
                                  node.name = node.name:gsub("rhuya","rhuya_wintery")
                                  minetest.swap_node(pos, node)
                              end)
                          end
                        end
                    end
                    return itemstack -- return changes
                end
        })
        -- override fruit stack size
        minetest.override_item(
            "nodes_nature:rhuya"..rhuya.."_fruit",  {
                stack_max = minimal.stack_max_medium/2
        })
    end

    -- override on_timer for seedling1 and 2, for regular rhuya (convert to wintery)
    for i = 1, 2 do
        local name = "nodes_nature:rhuya_seedling"..i
        local old_on_timer = minetest.registered_nodes[name].on_timer
        minetest.override_item(name,  {
            on_timer = function(pos, ...)
                -- have a chance of becoming wintery
                -- 1: 20% chance, 2: 10% chance to check
                if math.random() < (0.2/i) then
                    local temp = climate.get_point_temp(pos)
                    local convert = temp < 8 and 0.05 or nil -- convert chance (5% or nil)
                    if convert then
                        convert = temp < 6 and 0.3 or convert
                        convert = temp < 1 and 0.8 or convert
                        convert = temp < -1 and 0.99 or convert
                        if math.random() < convert then
                            -- convert to wintery
                            local node = minetest.get_node(pos)
                            if node.name ~= name then return end
                            node.name = node.name:gsub("rhuya","rhuya_wintery")
                            minetest.swap_node(pos, node)
                            return true
                        end
                    end
                end
                -- just do regular timer stuff if we don't do the above successfully
                return old_on_timer(pos, ...)
            end
        })
    end

    minetest.override_item(
        "nodes_nature:rhuya_wintery_dead", {
            inventory_image = "nodes_nature_rhuya_dead.png",
            wield_image = "nodes_nature_rhuya_dead.png",
            tiles = {"nodes_nature_rhuya_dead.png"}
    })
end
