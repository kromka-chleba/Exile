--------------------------------------------------------------------------
--CRAFTS
--------------------------------------------------------------------------
--[[
    Carcasses:
    Invertebrate,
    Fish,
    Bird,
    (Mammal, Lizard)


    Sizes:
    small, large

    --
    leather, Bone, skin, sinews, feathers?
]]
animals = animals

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor
--------------------------------------------------------------------------
--Carcasses
-------------------------------------------
local box_small_invert = {
    {-0.125, -0.5, -0.1875, 0.125, -0.4375, 0.1875}, -- NodeBox1
    {-0.0625, -0.4375, -0.1875, 0.0625, -0.375, 0.1875}, -- NodeBox2
    {-0.0625, -0.5, -0.25, 0.0625, -0.4375, -0.1875}, -- NodeBox3
    {-0.0625, -0.5, 0.1875, 0.0625, -0.4375, 0.25}, -- NodeBox4
}

local box_large_invert ={
    {-0.1875, -0.5, -0.25, 0.1875, -0.375, 0.25}, -- NodeBox1
    {-0.125, -0.375, -0.25, 0.125, -0.3125, 0.25}, -- NodeBox2
    {-0.0625, -0.5, -0.375, 0.0625, -0.375, -0.25}, -- NodeBox3
    {-0.0625, -0.5, 0.25, 0.0625, -0.375, 0.375}, -- NodeBox4
}

local box_small_bird = {
    {-0.125, -0.5, -0.1875, 0.125, -0.375, 0.125}, -- NodeBox1
    {-0.0625, -0.375, -0.1875, 0.0625, -0.3125, 0.0625}, -- NodeBox2
    {-0.0625, -0.5, -0.3125, 0.0625, -0.375, -0.1875}, -- NodeBox3
    {-0.0625, -0.5, 0.125, 0.0625, -0.4375, 0.25}, -- NodeBox4
    {0.125, -0.5, -0.125, 0.3125, -0.4375, 0}, -- NodeBox5
    {-0.3125, -0.5, -0.125, -0.125, -0.4375, 0}, -- NodeBox6
    {0.125, -0.5, 0.0625, 0.1875, -0.4375, 0.25}, -- NodeBox7
    {-0.1875, -0.5, 0.0625, -0.125, -0.4375, 0.25}, -- NodeBox8
}

local box_small_fish = {
    {-0.125, -0.5, -0.1875, 0.125, -0.4375, 0.1875}, -- NodeBox1
    {-0.0625, -0.4375, -0.1875, 0.0625, -0.375, 0.1875}, -- NodeBox2
    {-0.0625, -0.5, -0.3125, 0.0625, -0.4375, -0.1875}, -- NodeBox3
    {-0.0625, -0.5, 0.1875, 0.0625, -0.4375, 0.375}, -- NodeBox4
    {0.125, -0.5, -0.125, 0.1875, -0.4375, 0.125}, -- NodeBox9
    {-0.1875, -0.5, -0.125, -0.125, -0.4375, 0.125}, -- NodeBox10
}

local box_large_fish = {
    {-0.25, -0.5, -0.3125, 0.25, -0.375, 0.3125}, -- NodeBox1
    {-0.125, -0.375, -0.3125, 0.125, -0.3125, 0.25}, -- NodeBox2
    {-0.125, -0.5, -0.4375, 0.125, -0.375, -0.3125}, -- NodeBox3
    {-0.125, -0.5, 0.3125, 0.125, -0.375, 0.4375}, -- NodeBox4
    {0.25, -0.5, 0, 0.375, -0.4375, 0.25}, -- NodeBox9
    {-0.375, -0.5, 0, -0.25, -0.4375, 0.25}, -- NodeBox10
    {-0.0625, -0.3125, -0.1875, 0.0625, -0.25, 0}, -- NodeBox11
}

local list = {
    {
        "invert_small",
        S("small invertebrate"),
        box_small_invert,
        minimal.stack_max_medium,
        80,
    },
    {
        "invert_large",
        S("large invertebrate"),
        box_large_invert,
        minimal.stack_max_medium/4,
        70,
    },
    {
        "bird_small",
        S("small bird"),
        box_small_bird,
        minimal.stack_max_medium/4,
        70,
    },
    {
        "fish_small",
        S("small fish"),
        box_small_fish,
        minimal.stack_max_medium/4,
        70,
    },
    {
        "fish_large",
        S("large fish"),
        box_large_fish,
        minimal.stack_max_bulky,
        65,
    },
}


for i in ipairs(list) do
    local name = list[i][1]
    local desc = list[i][2]
    local box = list[i][3]
    local stack = list[i][4]
    local heat = list[i][5]

    local carcass = 0
    -- when defining carcass type, add a space of 4 (1 = invert, +4 = bird = 5)
    if (string.match(name,"invert")) then -- arthropods and insects
        carcass = 1
    elseif (string.match(name,"bird")) then
        carcass = 5
    elseif (string.match(name,"fish")) then
        carcass = 9
    elseif (string.match(name,"reptile")) then
        carcass = 13
    elseif (string.match(name,"mammal")) then
        carcass = 17
    end
    if (carcass == 0) then -- unknown carcass type
        carcass = 1000
    end
    -- small would be the base value - 1 for invert, 4 for bird, 7 for fish
    if (string.match(name,"medium")) then
        carcass = carcass + 1
    elseif (string.match(name,"large")) then
        carcass = carcass + 2
    elseif (string.match(name,"gargantuan")) then
        carcass = carcass + 3
    end

    --raw
    minetest.register_node("animals:carcass_"..name, {
                               description = S('@1 Carcass', desc),
                               tiles = {"animals_carcass.png"},
                               drawtype = "nodebox",
                               paramtype = "light",
                               node_box = {
                                   type = "fixed",
                                   fixed = box
                               },
                               stack_max = stack/2,
                               groups = {snappy = 3, dig_immediate = 3,
                                         falling_node = 1, temp_pass = 1,
                                         raw_cooked = 1, heatable = heat,
                                         carcass = carcass, edible = 1},
                               sounds = animals.node_sound_meat_defaults(),
    })

    --cooked
    minetest.register_node("animals:carcass_"..name.. "_cooked", {
                               description = S('Cooked @1', desc),
                               tiles = {"nodes_nature_silt.png"},
                               drawtype = "nodebox",
                               paramtype = "light",
                               node_box = {
                                   type = "fixed",
                                   fixed = box
                               },
                               stack_max = stack,
                               groups = {snappy = 3, dig_immediate = 3,
                                         falling_node = 1, temp_pass = 1,
                                         raw_cooked = 2, carcass = carcass,
                                         edible = 1},
                               sounds = animals.node_sound_meat_cooked_defaults(),
    })

    --burned
    minetest.register_node("animals:carcass_"..name.. "_burned", {
                               description = S('Burned @1', desc),
                               tiles = {"animals_carcass_burned.png"},
                               drawtype = "nodebox",
                               paramtype = "light",
                               node_box = {
                                   type = "fixed",
                                   fixed = box
                               },
                               stack_max = stack,
                               groups = {snappy = 3, dig_immediate = 3,
                                         falling_node = 1, temp_pass = 1,
                                         raw_cooked = 3, carcass = carcass,
                                         edible = 1},
                               sounds = nodes_nature.node_sound_defaults(),
    })

    HEALTH.add_food_hooks("animals:carcass_"..name)
    HEALTH.add_food_hooks("animals:carcass_"..name.. "_cooked")
    HEALTH.add_food_hooks("animals:carcass_"..name.. "_burned")
end
