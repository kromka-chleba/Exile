---------------------------------------------------------
--Plants and Mushrooms

-- Internationalization
local S = nodes_nature.S

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
    soil_preferences.new({
            rocky_substrate = {min = 2, max = 2},
            organic_substrate = {min = 2, max = 2},
            density = {min = 4, max = 4},
    })

local plant_list = {
    -- Herbs
    {name = "wrotycz", description = S("Wrotycz"),
     drawtype = "plantlike", mesh_type = 1,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     soil_preferences = wrotycz_soil_prefs, fruit = true,
     seasonal_type = "late", winter_fruit = true,
     dry_fruit = true},

    {name = "wiha", description = S("Wiha"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "red",
     fruit = true, seasonal_type = "early",
     winter_fruit = true,},

    {name = "momo", description = S("Momo"),
     drawtype = "plantlike", mesh_type = 2,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "red",
     fruit = true, winter_fruit = false,
     seasonal_type = "late"},

    {name = "galanta", description = S("Galanta"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = plant_base_growing_time * 0.4,
     dye_candidate = true, dominant_color = "green",
     seasonal_type = "whole_season",
     edible_seedling = true},

    {name = "vansano", description = S("Vansano"),
     drawtype = "plantlike", mesh_type = 2,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = plant_base_growing_time * 1.2,
     dye_candidate = true, dominant_color = "green",
     fruit = true, seasonal_type = "long", winter_fruit = false,
     dry_fruit = true},

    {name = "anperla", description = S("Anperla"),
     plant_type = "herbaceous_plant", waving = true,
     drawtype = "plantlike", mesh_type = 3,
     growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "green",
     winter_fruit = false, seasonal_type = "tuber",
     fruit = true, roots = 8},

    {name = "hakimi", description = S("Hakimi"),
     drawtype = "plantlike", waving = true,
     plant_type = "herbaceous_plant", mesh_type = 3,
     growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "blue",
     fruit = true, winter_fruit = true,
     seasonal_type = "mainly_flower",
     dry_fruit = true},

    {name = "orom", description = S("Orom"),
     drawtype = "plantlike", mesh_type = 1,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "black"},

    {name = "veke", description = S("Veke"),
     drawtype = "plantlike", mesh_type = 0,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "black"},

    {name = "tikusati", description = S("Tikusati"),
     drawtype = "plantlike", mesh_type = 2,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     fruit = true, seasonal_type = "medium",
     winter_fruit = true, dry_fruit = true},

    -- Mushrooms

    --lambakap. is also a mushroom.
    --slow growing food and water source, main crop for longterm underground living.
    {name = "lambakap", description = S("Lambakap"),
     drawtype = "nodebox", nodebox = lambakap_nodebox,
     lifeform_type = "mushroom", plant_type = "mushroom",
     growing_time = plant_base_growing_time * 3,
     dye_candidate = true, dominant_color = "red",
     bioluminescence = 2, extra_groups = {flammable = 6}},

    --reshedaar.  is also a mushroom.
    --slow growing fibre mushroom, main fibre crop for longterm underground living.
    --(can't be bioluminescent or conflicts with recipe)
    {name = "reshedaar", description = S("Reshedaar"),
     drawtype = "nodebox", nodebox = reshedaar_nodebox,
     lifeform_type = "mushroom", plant_type = "fibrous_plant",
     growing_time = plant_base_growing_time * 3,
     dye_candidate = true, dominant_color = "red",},

    --Mahal. is also a mushroom.
    --slow growing woody mushroom, main stick crop for longterm underground living.
    {name = "mahal", description = S("Mahal"),
     drawtype = "nodebox", nodebox = mahal_nodebox,
     lifeform_type = "mushroom", plant_type = "woody_plant",
     growing_time = plant_base_growing_time * 3,
     dye_candidate = true, dominant_color = "red",
     bioluminescence = 1,},

    {name = "merki", description = S("Merki"),
     drawtype = "plantlike",
     lifeform_type = "mushroom", plant_type = "mushroom",
     mesh_type = 0, growing_time = plant_base_growing_time * 2},

    {name = "nebiyi", description = S("Nebiyi"),
     drawtype = "plantlike",
     lifeform_type = "mushroom", plant_type = "mushroom",
     mesh_type = 1, growing_time = plant_base_growing_time,
     dye_candidate = true, dominant_color = "indigo",
     seasonal_type = "late_mushroom"},

    {name = "marbhan", description = S("Marbhan"),
     drawtype = "plantlike",
     lifeform_type = "mushroom", plant_type = "mushroom",
     mesh_type = 2, growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "red",
     seasonal_type = "late_mushroom"},

    {name = "zufani", description = S("Zufani"),
     drawtype = "plantlike",
     lifeform_type = "mushroom", plant_type = "mushroom",
     mesh_type = 2, growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     seasonal_type = "late_mushroom", fruit = true,
     only_dead_fruit = true, winter_fruit = true},

    -- Woody
    {name = "tsaplop", description = S("Tsaplop"),
     drawtype = "plantlike", plant_type = "woody_plant",
     mesh_type = 0, growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "green",
     visual_scale = 1.2},

    {name = "jogalan", description = S("Jogalan"),
     drawtype = "plantlike", plant_type = "woody_plant",
     waving = true,
     mesh_type = 0, growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "black"},

    {name = "gitiri", description = S("Gitiri"),
     drawtype = "plantlike", plant_type = "woody_plant",
     waving = true,
     mesh_type = 2, growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "green",
     visual_scale = 1.2, seasonal_type = "whole_season_woody"},

    {name = "bronach", description = S("Bronach"),
     drawtype = "plantlike", plant_type = "woody_plant",
     waving = true,
     mesh_type = 3, growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "crimson",
     visual_scale = 1.5, seasonal_type = "whole_season_woody"},
    
    -- Grasses
    {name = "sari", description = S("Sari"),
     drawtype = "plantlike", mesh_type = 2,
     plant_type = "fibrous_plant", waving = true,
     growing_time = plant_base_growing_time * 0.5,
     dye_candidate = true, dominant_color = "yellow",
     seasonal_type = "whole_season"},

    {name = "tanai", description = S("Tanai"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "fibrous_plant", waving = true,
     growing_time = plant_base_growing_time * 1.5,
     dye_candidate = true, dominant_color = "crimson",
     seasonal_type = "whole_season"},

    {name = "thoka", description = S("Thoka"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "fibrous_plant", waving = true,
     dye_candidate = true,
     growing_time = plant_base_growing_time * 2},

    {name = "alaf", description = S("Alaf"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "fibrous_plant", waving = true,
     growing_time = plant_base_growing_time * 2,
     dye_candidate = true, dominant_color = "yellow",
     seasonal_type = "whole_season"},

    {name = "damo", description = S("Damo"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "fibrous_plant", waving = true,
     growing_time = plant_base_growing_time,
     dye_candidate = true, dominant_color = "green",
     seasonal_type = "whole_season", edible_seedling = true},

    {name = "tashvish", description = S("Tashvish"),
     drawtype = "plantlike", mesh_type = 4,
     plant_type = "fibrous_plant", waving = true,
     dye_candidate = true,
     growing_time = plant_base_growing_time * 1.5,
     seasonal_type = "whole_season"},

    -- Moss
    {name = "moss", description = S("Moss"),
     drawtype = "nodebox", nodebox = moss_nodebox,
     plant_type = "moss", growing_time = plant_base_growing_time * 3,
     dye_candidate = true, dominant_color = "green",},

    -- Canes
    {name = "cana", description = S("Cana"),
     drawtype = "plantlike", plant_type = "cane", waving = false,
     growing_time = plant_base_growing_time * 2, seed_number = 1},

    {name = "gemedi", description = S("Gemedi"),
     drawtype = "plantlike", plant_type = "cane", waving = false,
     growing_time = plant_base_growing_time * 2, dye_candidate = true, dominant_color = "yellow",
     seed_number = 1, seasonal_type = "cane"},

    -- Bamboos
    {name = "chalin", description = S("Chalin"),
     drawtype = "plantlike", plant_type = "bamboo", waving = false,
     growing_time = plant_base_growing_time * 2, dye_candidate = true, dominant_color = "yellow",
     seed_number = 1, climbable = true, seasonal_type = "whole_season_woody"},

    {name = "tiken", description = S("Tiken"),
     drawtype = "plantlike", plant_type = "bamboo", waving = false,
     growing_time = plant_base_growing_time * 2, dye_candidate = true, dominant_color = "yellow",
     seed_number = 1, thorns = true, seasonal_type = "whole_season_woody"},
}

-- makes all plants in the game
plant.register_all(plant_list)

----------------------------------------------
--Name overrides

minetest.override_item(
    "nodes_nature:zufani_fruit", {
        description = S("Zufani amber"),
})

minetest.override_item(
    "nodes_nature:momo_fruit", {
        description = S("Momo pepper"),
})

----------------------------------------------
--Extra effects

--glowing mushroom
minetest.override_item(
    "nodes_nature:merki",{
        light_source = 2,
        groups = {snappy = 3, attached_node = 1, flammable = 3, mushroom = 1, temp_pass = 1, bioluminescent= 1}
})


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

--marbhan has a Neurotoxin
minetest.override_item(
    "nodes_nature:marbhan",{
        on_use = function(itemstack, user, pointed_thing)
            --Similar to hemlock, which tastes musty or like mouse urine
            minetest.chat_send_player(user:get_player_name(),
                                      "This plant has a foul musty flavor.")
            --food poisoning
            if math.random() < 0.001 then
                HEALTH.add_new_effect(user, {"Food Poisoning", 1})
            end

            --toxin
            if math.random() < 0.75 then
                HEALTH.add_new_effect(user, {"Neurotoxicity", math.floor(math.random(1,4))})
            end

            --hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item
            return HEALTH.use_item(itemstack, user, 0, 0, 1, -10, 0)
        end,
})


--nebiyi has a Hepatotoxin
minetest.override_item(
    "nodes_nature:nebiyi",{
        on_use = function(itemstack, user, pointed_thing)
            --Flowers look a bit like oleander; it causes intense stomach pain
            minetest.chat_send_player(user:get_player_name(),
                                      "Your stomach hurts terribly.")
            --food poisoning
            if math.random() < 0.001 then
                HEALTH.add_new_effect(user, {"Food Poisoning", 1})
            end

            --toxin
            if math.random() < 0.75 then
                HEALTH.add_new_effect(user, {"Hepatotoxicity", math.floor(math.random(1,4))})
            end

            --hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item
            return HEALTH.use_item(itemstack, user, 0, 0, 1, -10, 0)
        end,
})


--hakimi is antibacterial, antifungal
minetest.override_item(
    "nodes_nature:hakimi",{
        on_use = function(itemstack, user, pointed_thing)

            --only cure mild
            if math.random()<0.75 then
                HEALTH.remove_new_effect(user, {"Food Poisoning", 1})
                HEALTH.remove_new_effect(user, {"Fungal Infection", 1})
                HEALTH.remove_new_effect(user, {"Dust Fever", 1})
            end

            --hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item
            return HEALTH.use_item(itemstack, user, 1, 0, 0, -10, 0)
        end,
})

--merki is anti-parasitic
minetest.override_item(
    "nodes_nature:merki",{
        on_use = function(itemstack, user, pointed_thing)

            if math.random()<0.15 then
                HEALTH.remove_new_effect(user, {"Intestinal Parasites"})
            end


            --hp_change, thirst_change, hunger_change, energy_change, temp_change, replace_with_item
            return HEALTH.use_item(itemstack, user, 1, 0, 0, -10, 0)
        end,
})
