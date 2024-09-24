------------------------------------
--ANIMAL CRAFTS
--crafts directly using animal products
--also food processing
-----------------------------------

-- Internationalization
local S = tech.S

local c_alpha = minimal.compat_alpha

------ PLANT PRODUCTS

--bitter maraka flour
-- unusable flour. Requires water treatment.
minetest.register_node(
    'tech:maraka_flour_bitter', {
        description = S('Bitter Maraka Flour'),
        tiles = {"tech_flour_bitter.png"},
        stack_max = minimal.stack_max_bulky * 4,
        paramtype = "light",
        groups = {crumbly = 3, dig_immediate = 3,
                  falling_node = 1, flammable = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        on_construct = function(pos)
            --length(i.e. difficulty of wash), interval for checks (speed)
            ncrafting.start_soak(pos, 60, 10)
        end,
        on_timer = function(pos, elapsed)
            --finished product, length
            return ncrafting.do_soak(pos, "tech:maraka_flour", 10, elapsed)
        end,
})

-- maraka flour
--usable flour.
minetest.register_node(
    'tech:maraka_flour', {
        description = S('Maraka Flour'),
        tiles = {"tech_flour.png"},
        stack_max = minimal.stack_max_bulky * 4,
        paramtype = "light",
        groups = {crumbly = 3, dig_immediate = 3,
                  falling_node = 1, flammable = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
})


--maraka cake, prior to baking
minetest.register_node(
    "tech:maraka_bread", {
        description = S("Unbaked Maraka Cake"),
        tiles = {"tech_flour.png"},
        stack_max = minimal.stack_max_medium,
        paramtype = "light",
        paramtype2 = "wallmounted",
        sunlight_propagates = true,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.3, -0.5, -0.3, 0.3, -0.3, 0.3},
        },
        groups = {crumbly = 3, dig_immediate = 3, temp_pass = 1, heatable = 80},
        sounds = nodes_nature.node_sound_dirt_defaults(),
})

--maraka cake,baked
minetest.register_node(
    "tech:maraka_bread_cooked", {
        description = S("Maraka Cake"),
        tiles = {"tech_flour_strong.png"},
        stack_max = minimal.stack_max_medium * 4,
        paramtype = "light",
        sunlight_propagates = true,
        --paramtype2 = "wallmounted",
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.28, -0.5, -0.28, 0.28, -0.32, 0.28},
        },
        groups = {crumbly = 3, falling_node = 1, dig_immediate = 3,
                  temp_pass = 1, heatable = 80, edible = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        _use_tip = S("Eat"),
})

--maraka cake, burned
minetest.register_node(
    "tech:maraka_bread_burned", {
        description = S("Maraka Cake Burned"),
        tiles = {"tech_flour_burned.png"},
        stack_max = minimal.stack_max_medium * 4,
        paramtype = "light",
        sunlight_propagates = true,
        --paramtype2 = "wallmounted",
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.28, -0.5, -0.28, 0.28, -0.32, 0.28},
        },
        groups = {crumbly = 3, falling_node = 1, dig_immediate = 3,
                  flammable = 1,  temp_pass = 1, edible = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        _use_tip = S("Eat"),
})

-----------
--Anperla
minetest.register_node(
    "tech:peeled_anperla", {
        description = S("Peeled Anperla Tuber"),
        tiles = {"tech_flour.png"},
        stack_max = minimal.stack_max_medium,
        paramtype = "light",
        sunlight_propagates = true,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.15, -0.5, -0.15,  0.15, -0.35, 0.15},
        },
        groups = {snappy = 3, falling_node = 1, dig_immediate = 3,
                  temp_pass = 1, heatable = 70},
        sounds = nodes_nature.node_sound_dirt_defaults(),
})

minetest.register_node(
    "tech:peeled_anperla_burned", {
        description = S("Burned Anperla Tuber"),
        tiles = {"tech_flour_burned.png"},
        stack_max = minimal.stack_max_medium * 2,
        paramtype = "light",
        sunlight_propagates = true,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.15, -0.5, -0.15,  0.15, -0.35, 0.15},
        },
        groups = {crumbly = 3, falling_node = 1, dig_immediate = 3,
                  flammable = 1,  temp_pass = 1, edible = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        _use_tip = S("Eat"),
})

minetest.register_node(
    "tech:peeled_anperla_cooked", {
        description = S("Cooked Anperla Tuber"),
        tiles = {"tech_flour_bitter.png"},
        stack_max = minimal.stack_max_medium * 2,
        paramtype = "light",
        sunlight_propagates = true,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-0.15, -0.5, -0.15,  0.15, -0.35, 0.15},
        },
        groups = {crumbly = 3, falling_node = 1, dig_immediate = 3,
                  heatable = 70,  temp_pass = 1, edible = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        _use_tip = S("Eat"),
})

--mash (a way to bulk cook tubers - 6 at once)
minetest.register_node(
    "tech:mashed_anperla", {
        description = S("Mashed Anperla (uncooked)"),
        tiles = {"tech_flour.png"},
        stack_max = minimal.stack_max_medium/6,
        paramtype = "light",
        --sunlight_propagates = true,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-6/16, -0.5, -6/16, 6/16, 1/16, 6/16},
        },
        groups = {snappy = 3, falling_node = 1, dig_immediate = 3,
                  temp_pass = 1, heatable = 70},
        sounds = nodes_nature.node_sound_dirt_defaults(),
})

minetest.register_node(
    "tech:mashed_anperla_cooked", {
        description = S("Mashed Anperla"),
        tiles = {"tech_flour_bitter.png"},
        stack_max = minimal.stack_max_medium/3,
        paramtype = "light",
        --sunlight_propagates = true,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-5/16, -0.5, -5/16, 5/16, -1/16, 5/16},
        },
        groups = {crumbly = 3, falling_node = 1, dig_immediate = 3,
                  heatable = 70,  temp_pass = 1, edible = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        _use_tip = S("Eat"),
})

minetest.register_node(
    "tech:mashed_anperla_burned", {
        description = S("Burned Anperla"),
        tiles = {"tech_flour_burned.png"},
        stack_max = minimal.stack_max_medium/3,
        paramtype = "light",
        --sunlight_propagates = true,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {-5/16, -0.5, -5/16, 5/16, -1/16, 5/16},
        },
        groups = {crumbly = 3, falling_node = 1, dig_immediate = 3,
                  flammable = 1,  temp_pass = 1, edible = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        _use_tip = S("Eat"),
})

-- rhuya flour (RAW)
-- needs to be cooked to purify toxins
minetest.register_node("tech:rhuya_flour",{
  description = S("Raw Rhuya Flour"),
  tiles = {"tech_rhuya_flour.png"},
  stack_max = minimal.stack_max_medium * 2,
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {-6/16, -0.5, -6/16, 6/16, -0.3, 6/16},
  },
  groups = {dig_immediate = 3, falling_node=1, flour=1},
  sounds = nodes_nature.node_sound_dirt_defaults()
})

-- purified rhuya flour
minetest.register_node("tech:rhuya_flour_cooked",{
  description = S("Rhuya Flour"),
  tiles = {"tech_flour.png"},
  stack_max = minimal.stack_max_medium * 2,
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {-6/16, -0.5, -6/16, 6/16, -0.3, 6/16},
  },
  groups = {dig_immediate = 3, falling_node=1, flour=1},
  sounds = nodes_nature.node_sound_dirt_defaults()
})

-- oops, you burnt it!
minetest.register_node("tech:rhuya_flour_burned",{
  description = S("Burnt Rhuya Flour"),
  tiles = {"tech_flour_burned.png"},
  stack_max = minimal.stack_max_medium * 3,
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {-7/16, -0.5, -7/16, 7/16, -0.42, 7/16},
  },
  groups = {dig_immediate = 3, falling_node=1, compostable=1},
  sounds = nodes_nature.node_sound_dirt_defaults()
})

---- plant-based recipes

--
-- knife crafts
--

--ib crafting.register_recipe({
--ib    type = {"mortar_and_pestle", "knife"},
--ib    output = "tech:peeled_anperla 6",
--ib    items = {"nodes_nature:anperla_root 6"},
--ib    level = 1,
--ib    always_known = true,
--ib })
--ib crafting.register_recipe({
--ib    type = {"mortar_and_pestle", "knife"},
--ib    output = "tech:peeled_anperla 36",
--ib    items = {"nodes_nature:anperla_root 36"},
--ib    level = 1,
--ib    always_known = true,
--ib })

--peel tubers
crafting.register_recipe({
        type = {"crafting_spot","knife", "mortar_and_pestle"},
        output = "tech:peeled_anperla",
        items = {"nodes_nature:anperla_root"},
        level = 1,
        always_known = true,
})

--
-- mortar and pestle
--

--mash
crafting.register_recipe({
        type = "mortar_and_pestle",
        output = "tech:mashed_anperla",
        items = {"tech:peeled_anperla 6"},
        level = 1,
        always_known = true,
})
--IB --bulk mash
--IB crafting.register_recipe({
--IB    type = "mortar_and_pestle",
--IB    output = "tech:mashed_anperla 6",
--IB    items = {"tech:peeled_anperla 36"},
--IB    level = 1,
--IB    always_known = true,
--IB })


--grind maraka flour
crafting.register_recipe({
        type = "mortar_and_pestle",
        output = "tech:maraka_flour_bitter",
        items = {'nodes_nature:maraka_nut 12'},
        level = 1,
        always_known = true,
})
--IB --bulk maraka flour
--IB crafting.register_recipe({
--IB    type = "mortar_and_pestle",
--IB    output = "tech:maraka_flour_bitter 4",
--IB    items = {'nodes_nature:maraka_nut 48'},
--IB    level = 1,
--IB    always_known = true,
--IB })

--make maraka cakes
crafting.register_recipe({
        type = "mortar_and_pestle",
        output = "tech:maraka_bread 6",
        items = {'tech:maraka_flour'},
        level = 1,
        always_known = true,
})
--IB --bulk maraka cakes
--IB crafting.register_recipe({
--IB    type = "mortar_and_pestle",
--IB    output = "tech:maraka_bread 24",
--IB    items = {'tech:maraka_flour 4'},
--IB    level = 1,
--IB    always_known = true,
--IB })

-- grind rhuya flour

crafting.register_recipe({
    type = "mortar_and_pestle",
    output = "tech:rhuya_flour",
    items = {'nodes_nature:rhuya_seed 12'},
    level = 1,
    always_known = true,
})

-- ANIMAL PRODUCTS

-- cracked egg
minetest.register_node(
    "tech:yolk_and_albumen",{
        description = S("Cracked Egg"),
        tiles = {"tech_yolkandalbumen.png"},
        inventory_image = "tech_yolkandalbumen_icon.png",
        groups = {dig_immediate=3, falling_node=1, heatable=60},
        stack_max = math.floor(minimal.stack_max_medium*1.5),
        drawtype = "mesh",
        mesh = "yolkalbumen.obj",
        selection_box = {
            type = "fixed",
            fixed = {-3/16, -0.5, -3/16, 3/16, -6/16, 3/16},
        },
        collision_box = {
            type = "fixed",
            fixed = {-3/16, -0.5, -3/16, 3/16, -6/16, 3/16},
        },
        use_texture_alpha = c_alpha.blend,
        sunlight_propagates = true,
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light"
})

-- cooked da egg
minetest.register_node(
    "tech:yolk_and_albumen_cooked",{
        description = S("Fried Egg"),
        tiles = {"tech_fried_egg.png"},
        inventory_image = "tech_fried_egg_icon.png",
        groups = {dig_immediate=3, falling_node=1, heatable=110, edible=1},
        stack_max = minimal.stack_max_medium*2,
        drawtype = "mesh",
        mesh = "yolkalbumen.obj",
        selection_box = {
            type = "fixed",
            fixed = {-3/16, -0.5, -3/16, 3/16, -6/16, 3/16},
        },
        collision_box = {
            type = "fixed",
            fixed = {-3/16, -0.5, -3/16, 3/16, -6/16, 3/16},
        },
        use_texture_alpha = c_alpha.blend,
        sunlight_propagates = true,
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light"
})

-- recipes
-- cracked egg recipes
crafting.register_recipe({
        type = "hand",
        output = "tech:yolk_and_albumen",
        items = {'animals:pegasun_eggs'},
        level = 1,
        always_known = true,
})
crafting.register_recipe({
        type = "mortar_and_pestle",
        output = "tech:yolk_and_albumen",
        items = {{'animals:pegasun_eggs','animals:kubwakubwa_eggs 2','animals:darkasthaan_eggs 2'}},
        level = 1,
        always_known = true,
})
