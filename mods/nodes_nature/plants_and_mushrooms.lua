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
     mesh_type = 2,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
      seasonal_type = "tuber", roots = 5,
     root_tiles = {"nodes_nature_red_ochre.png"}, winter_fruit = true,
     dry_fruit = true, dye_candidate = true, dominant_color = "yellow",},

    {name = "wrotycz", description = S("Vortecha"),
     mesh_type = 1,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dominant_color = "yellow", dye_candidate = true,
     soil_preferences = wrotycz_soil_prefs,
     seasonal_type = "late", winter_fruit = true,
     dry_fruit = true},

    {name = "wiha", description = S("Wiha"),
     mesh_type = 4,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dominant_color = "red", dye_candidate = true,
     seasonal_type = "early", winter_fruit = true,
     fruit_description = S("Wiha Berries")},

    {name = "momo", description = S("Momo"),
     mesh_type = 2, seasonal_type = "late",
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dominant_color = "red", dye_candidate = true,
     fruit = true, fruit_description = S("Momo Pepper")},

    {name = "galanta", description = S("Galanta"),
     mesh_type = 4,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 0.4,
     dominant_color = "green", dye_candidate = true,
     seasonal_type = "whole_season_seedling",
     edible_seedling = true},

    {name = "vansano", description = S("Vansano"),
     mesh_type = 2,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 1.2,
     dominant_color = "green", dye_candidate = true,
     seasonal_type = "long", dry_fruit = true},

    {name = "anperla", description = S("Anperla"),
     plant_type = "herbaceous_plant", waving = true,
     mesh_type = 3, seasonal_type = "tuber",
     growing_time = nn.plant_base_growing_time * 3,
     dominant_color = "green", dye_candidate = true,
     fruit = true, roots = 8, root_description = S("Anperla tuber")},

    {name = "rzepicha", description = S("Jepiha"),
     plant_type = "herbaceous_plant", waving = true, fruit = true,
     mesh_type = 0, growing_time = nn.plant_base_growing_time * 2,
     dominant_color = "green", dye_candidate = true,
     seasonal_type = "tuber"},

    {name = "hakimi", description = S("Hakimi"),
     waving = true, seasonal_type = "mainly_flower", 
     dye_candidate = true, dominant_color = "blue",
     plant_type = "herbaceous_plant", mesh_type = 3,
     growing_time = nn.plant_base_growing_time * 2,
     dry_fruit = true, winter_fruit = true},

    {name = "ziarnoplon", description = S("Jarno"),
     waving = true, dominant_color = "yellow", dye_candidate = true,
     plant_type = "herbaceous_plant", mesh_type = 3,
     growing_time = nn.plant_base_growing_time * 0.4,
     fruit = true, seasonal_type = "early_flower"},

    {name = "srebroplon", description = S("Serebro"),
     waving = true, dominant_color = "blue", dye_candidate = true,
     plant_type = "herbaceous_plant", mesh_type = 3,
     growing_time = nn.plant_base_growing_time * 0.4,
     fruit = true, seasonal_type = "early_flower",
     bioluminescence = 3},

    {name = "orom", description = S("Orom"),
     mesh_type = 1, dominant_color = "black", dye_candidate = true,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2},

    {name = "veke", description = S("Veke"),
     mesh_type = 0, dominant_color = "black", dye_candidate = true,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2},

    {name = "tikusati", description = S("Tikusati"),
     mesh_type = 2, winter_fruit = true, dry_fruit = true,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dominant_color = "yellow", dye_candidate = true,
     seasonal_type = "medium"},

    {name = "malinka", description = S("Malinka"),
     mesh_type = 1, dominant_color = "green", dye_candidate = true,
     plant_type = "herbaceous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 1.5,
     fruit = true, seasonal_type = "medium"},

    {name = "malina", description = S("Malina"),
     mesh_type = 3, dominant_color = "green", dye_candidate = true,
     plant_type = "woody_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2.5,
     fruit = true, seasonal_type = "long",
     move_resistance = 3, thorns = true},

    {name = "yellow_malina", description = S("Yellow Malina"),
     mesh_type = 2, dominant_color = "green", dye_candidate = true,
     plant_type = "woody_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2.5,
     fruit = true, seasonal_type = "long",
     move_resistance = 3, thorns = true},

    {name = "gevaari", description = S("Gevaari"),
     plant_type = "herbaceous_plant", mesh_type = 1,
     growing_time = nn.plant_base_growing_time * 4, thorns = true,
     dominant_color = "green", dye_candidate = true,
     seasonal_type = "whole_season_seedling", move_resistance = 4},

    {name = "obesa", description = S("Obesa"),
     plant_type = "herbaceous_plant", thorns = true,
     dominant_color = "green", dye_candidate = true,
     mesh_type = 0, growing_time = nn.plant_base_growing_time * 4,
     seasonal_type = "succulent_flowering", fruit = true,
     texture_scale = 1.2, move_resistance = 4},

    {name = "salia", description = S("Salia"),
     mesh_type = 4, dominant_color = "red", dye_candidate = true,
     plant_type = "herbaceous_plant", waving = true,
     fruit = true, seasonal_type = "early"},

    {name = "fretin", description = S("Fretin"),
     plant_type = "herbaceous_plant", waving = true,
     mesh_type = 2, dominant_color = "black",
     dye_candidate = true, edible_seedling = true,
     seasonal_type = "whole_season_seedling"},

    {name = "urimi", description = S("Urimi"),
     plant_type = "herbaceous_plant", waving = true,
     mesh_type = 2, seasonal_type = "whole_season_seedling",
     dominant_color = "black", dye_candidate = true,
     edible_seedling = false},

    -- rhuyas are not dye candidates, do not specify dominant color
    -- Rhuya: Kind of a mix between corn and wheat, corn-like fruit and plant size, wheat-like seed purposes
    -- fruit is toxic (and seeds maintain a bit of fruit toxins), tasting like like pine sap - bitter, and a bit sour
    {name = "rhuya", description = S("Rhuya"),
     waving = true, texture_scale = 1.6,
     plant_type = "herbaceous_plant", mesh_type = 0,
     growing_time = nn.plant_base_growing_time * 3,
     seasonal_type = "late", dry_fruit = true,
     seed_texture = "nodes_nature_rhuya_seed.png"},

    -- Rhuya: Winter Variant
    -- NOT meant to appear in the wild (domesticated only, do not add to mapgen)
    -- Like the regular rhuya, but now with its own antifreeze (sorta)! Still quite toxic
    -- Fruit encased in an insulated harder shell (see about modifying recipes so that a knife is required?);
    -- possibly cacao pod consistency or harder
    {name = "rhuya_wintery", description = S("Hardy Rhuya"),
     waving = false, texture_scale = 1.85,
     plant_type = "herbaceous_plant", mesh_type = 0,
     growing_time = nn.plant_base_growing_time * 3,
     seasonal_type = "wintery", dry_fruit = true,
     seed_texture = "nodes_nature_rhuya_seed.png"},

    -- Mushrooms

    --Lambakap. is also a mushroom.
    -- slow growing food and water source,
    -- main crop for longterm underground living.

    {name = "lambakap", description = S("Lambakap"),
     drawtype = "nodebox", nodebox = lambakap_nodebox,
     lifeform_type = "mushroom", dominant_color = "red", dye_candidate = true,
     growing_time = nn.plant_base_growing_time * 3,
     bioluminescence = 2, extra_groups = {flammable = 6}},

    --Reshedaar.  is also a mushroom.
    -- slow growing fibre mushroom,
    -- main fibre crop for longterm underground living.

    --(can't be bioluminescent or conflicts with recipe)
    {name = "reshedaar", description = S("Reshedaar"),
     drawtype = "nodebox", nodebox = reshedaar_nodebox,
     lifeform_type = "mushroom", plant_type = "fibrous_plant",
     growing_time = nn.plant_base_growing_time * 3,
     dominant_color = "red", dye_candidate = true},

    --Mahal. is also a mushroom.
    -- slow growing woody mushroom,
    -- main stick crop for longterm underground living.

    {name = "mahal", description = S("Mahal"),
     drawtype = "nodebox", nodebox = mahal_nodebox,
     lifeform_type = "mushroom", plant_type = "woody_plant",
     growing_time = nn.plant_base_growing_time * 3,
     dominant_color = "red", dye_candidate = true,
     bioluminescence = 1,},

    {name = "merki", description = S("Merki"),
     bioluminescence = 2, lifeform_type = "mushroom",
     mesh_type = 0, growing_time = nn.plant_base_growing_time * 2},

    {name = "nebiyi", description = S("Nebiyi"),
     lifeform_type = "mushroom", mesh_type = 1,
     growing_time = nn.plant_base_growing_time, seasonal_type = "late_mushroom",
     dye_candidate = true, dominant_color = "indigo"},

    {name = "marbhan", description = S("Marbhan"),
     lifeform_type = "mushroom", mesh_type = 2,
     growing_time = nn.plant_base_growing_time * 2,
     dominant_color = "red", dye_candidate = true,
     seasonal_type = "whole_season_seedling"},

    {name = "zufani", description = S("Zufani"),
     lifeform_type = "mushroom", mesh_type = 2,
     growing_time = nn.plant_base_growing_time * 2,
     dominant_color = "yellow", dye_candidate = true,
     seasonal_type = "late_mushroom", only_dead_fruit = true,
     fruit_description = S("Zufani Amber")},

    -- Woody
    {name = "tsaplop", description = S("Tsaplop"),
     plant_type = "woody_plant", mesh_type = 0, thorns = true,
     growing_time = nn.plant_base_growing_time * 4,
     dominant_color = "green", dye_candidate = true,
     seasonal_type = "whole_season", texture_scale = 1.2,
     move_resistance = 4},

    {name = "jogalan", description = S("Jogalan"),
     plant_type = "woody_plant", waving = true, mesh_type = 0,
     growing_time = nn.plant_base_growing_time * 2,
     dominant_color = "black", dye_candidate = true},

    {name = "gitiri", description = S("Gitiri"),
     plant_type = "woody_plant", waving = true,
     dominant_color = "green", dye_candidate = true,
     mesh_type = 2, growing_time = nn.plant_base_growing_time * 2,
     texture_scale = 1.2, seasonal_type = "whole_season"},

    {name = "badyl", description = S("Badyl"),
     plant_type = "woody_plant", waving = true,
     dominant_color = "red", dye_candidate = true,
     mesh_type = 0, growing_time = nn.plant_base_growing_time * 2,
     texture_scale = 1, seasonal_type = "whole_season"},

    {name = "drapacz", description = S("Drapacho"),
     plant_type = "woody_plant", mesh_type = 0,
     dominant_color = "red", dye_candidate = true,
     waving = false, thorns = true, move_resistance = 4,
     growing_time = nn.plant_base_growing_time * 4,
     texture_scale = 1.2, seasonal_type = "whole_season"},

    {name = "bronach", description = S("Bronach"),
     plant_type = "woody_plant", waving = true, mesh_type = 3,
     growing_time = nn.plant_base_growing_time * 2,
     dominant_color = "crimson", dye_candidate = true,
     texture_scale = 1.2, seasonal_type = "whole_season"},

    -- Grasses
    {name = "sari",
    description = S("Sari"),
    mesh_type = 2,
    plant_type = "fibrous_plant",
    waving = true,
    growing_time = nn.plant_base_growing_time * 0.5,
    dye_candidate = true,
    dominant_color = "yellow",
    seasonal_type = "whole_season_seedling"},

    {name = "tanai", description = S("Tanai"),
     mesh_type = 4, plant_type = "fibrous_plant", waving = true,
     dominant_color = "crimson", dye_candidate = true,
     growing_time = nn.plant_base_growing_time * 1.5,
     seasonal_type = "whole_season_seedling"},

    {name = "thoka", description = S("Thoka"),
     mesh_type = 4, dye_candidate = true,
     plant_type = "fibrous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2},

    {name = "alaf", description = S("Alaf"),
     mesh_type = 4, dominant_color = "yellow", dye_candidate = true,
     plant_type = "fibrous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     seasonal_type = "whole_season_seedling"},

    {name = "muhle", description = S("Muhle"),
     plant_type = "fibrous_plant", mesh_type = 4,  waving = true,
     growing_time = nn.plant_base_growing_time * 2,
     dominant_color = "black", dye_candidate = true,
     move_resistance = 4, seasonal_type = "late", winter_fruit = true,
     fruit_description = S("Muhle Berries")},

    {name = "damo", description = S("Damo"),
     mesh_type = 4, plant_type = "fibrous_plant", waving = true,
     dominant_color = "green", dye_candidate = true,
     edible_seedling = true, seasonal_type = "whole_season_seedling"},

    {name = "tashvish", description = S("Tashvish"),
     mesh_type = 4, dye_candidate = true,
     plant_type = "fibrous_plant", waving = true,
     growing_time = nn.plant_base_growing_time * 1.5,
     seasonal_type = "whole_season_seedling"},

    -- Moss
    {name = "moss", description = S("Moss"),
     drawtype = "nodebox", nodebox = moss_nodebox,
     plant_type = "moss", growing_time = nn.plant_base_growing_time * 3,
     dominant_color = "green", dye_candidate = true},

    -- Canes
    {name = "cana", description = S("Cana"),
     mesh_type = 2, seasonal_type = "whole_season",
     plant_type = "cane", waving = false,
     growing_time = nn.plant_base_growing_time * 2, seed_number = 1,
     extra_groups = {cana = 1}},

    {name = "gemedi", description = S("Gemedi"),
     mesh_type = 2, dominant_color = "yellow", dye_candidate = true,
     plant_type = "cane", waving = false,
     growing_time = nn.plant_base_growing_time * 2,
     seed_number = 1, seasonal_type = "whole_season"},

    -- Bamboos
    {name = "chalin", description = S("Chalin"),
     mesh_type = 2, dominant_color = "yellow", dye_candidate = true,
     plant_type = "bamboo", waving = false, move_resistance = 1,
     growing_time = nn.plant_base_growing_time * 2,
     seed_number = 1, climbable = true, seasonal_type = "whole_season"},

    {name = "tiken", description = S("Tiken"),
     mesh_type = 2, dominant_color = "yellow", dye_candidate = true,
     plant_type = "bamboo", waving = false, thorns = true,
     growing_time = nn.plant_base_growing_time * 2,
     seed_number = 1, seasonal_type = "whole_season"},

    {name = "saguati", description = S("Saguati"),
     plant_type = "bamboo", waving = false,
     growing_time = nn.plant_base_growing_time * 4,
     dominant_color = "green", dye_candidate = true,
     seed_number = 1, thorns = true, seasonal_type = "whole_season"},
}

-- makes all plants in the game
plant.register_all(plant_list)

----------------------------------------------
-- post-plant registration overrides

-- Jepiha (Rzepicha) overrides;

local function set_up_jepiha_on_place(alive)
    alive = type(alive) ~= "boolean" and true or false
    return function(itemstack, placer, pointed_thing)
        local above = minetest.get_node(pointed_thing.above)
        local pos_below = minimal.get_pos_under(pointed_thing.above)
        local sediment = minimal.pos_group(pos_below, "sediment")
        if sediment and above.name == "air" then
            -- place fruitless if alive, seedling5 if dead
            minetest.set_node(pointed_thing.above,
                { name = (alive and "nodes_nature:rzepicha_fruitless" or "nodes_nature:rzepicha_seedling5") })
            plant.set_to_domesticated(pointed_thing.above)
            if not minimal.player_in_creative(placer) then
                itemstack:take_item()
            end
        end
        return itemstack
    end
end

HEALTH.add_food_hooks("nodes_nature:rzepicha_fruitless")
HEALTH.add_food_hooks("nodes_nature:rzepicha_dead")

-- modify fruitless and dead jepiha to show their uprooted variants, plus functionality of prior craftitem variant
minetest.override_item(
    "nodes_nature:rzepicha_fruitless",
    {
        description = S("@1 Root",S("Jepiha")),
        inventory_image = "nodes_nature_rzepicha_root.png",
        wield_image = "nodes_nature_rzepicha_root.png",
        on_place = set_up_jepiha_on_place()
    }
)

minetest.override_item(
    "nodes_nature:rzepicha_dead",
    {
        description = S("@1 Root",S("Jepiha")),
        inventory_image = "nodes_nature_rzepicha_root_winter.png",
        wield_image = "nodes_nature_rzepicha_root_winter.png",
        on_place = set_up_jepiha_on_place(false)
    }
)

minetest.override_item(
    "nodes_nature:rzepicha_fruiting",
    {drop = "nodes_nature:rzepicha_fruitless"}
)

minetest.override_item(
    "nodes_nature:rzepicha_flowering",
    {drop = "nodes_nature:rzepicha_fruitless"}
)

-- on consume overrides

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
