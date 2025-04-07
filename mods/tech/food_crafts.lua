------------------------------------
--ANIMAL CRAFTS
--crafts directly using animal products
--also food processing
-----------------------------------

-- Internationalization
local S = tech.S

local c_alpha = minimal.compat_alpha


------ MINERAL PRODUCTS

-- sea salt
minetest.register_node("tech:salt_sea", {
    description = S("Sea Salt"),
    tiles = {"tech_salt_refined.png"},
    inventory_image = "tech_salt_refined_icon.png",
    wield_image = "tech_salt_refined_icon.png",
    stack_max = minimal.stack_max_medium * 3,
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {
            {-2/16, -0.5, -2/16, 2/16, -7.5/16, 2/16},
            {-1.5/16, -7.5/16, -1.5/16, 1.5/16, -7/16, 1.5/16},
            {-1/16, -7/16, -1/16, 1/16, -6.5/16, 1/16},
            {-0.5/16, -6.5/16, -0.5/16, 0.5/16, -6/16, 0.5/16},
        },
    },
    groups = {dig_immediate = 3, falling_node = 1, edible = 1},
    sounds = tech.node_sound_powder_defaults(),
    paramtype = "light"
})

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
        groups = {crumbly = 3, dig_immediate = 3, temp_pass = 1, heatable = 80, cake_flour = 1},
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
        tiles = {"tech_tuber_cooked.png"},
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
        tiles = {"tech_tuber_cooked.png"},
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
minetest.register_node(
    "tech:rhuya_flour", {
        description = S("Raw Rhuya Flour"),
        tiles = {"tech_rhuya_flour.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-6/16, -0.5, -6/16, 6/16, -0.3, 6/16},
        },
        groups = {dig_immediate = 3, falling_node=1, flour=1, heatable = 60},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light"
})

-- purified rhuya flour
minetest.register_node(
    "tech:rhuya_flour_cooked",  {
        description = S("Rhuya Flour"),
        tiles = {"tech_flour.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-6/16, -0.5, -6/16, 6/16, -0.3, 6/16},
        },
        groups = {dig_immediate = 3, falling_node=1, flour=1, cake_flour = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light"
})

-- HARDY rhuya flour (RAW)
-- needs to be cooked also

minetest.register_node(
    "tech:rhuya_wintery_flour", {
        description = S("Raw Hardy Rhuya Flour"),
        tiles = {"tech_rhuya_flour_wintery.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-6/16, -0.5, -6/16, 6/16, -0.3, 6/16},
        },
        groups = {dig_immediate = 3, falling_node=1, flour=1,
                  heatable = 80, temp_pass = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light"
})

-- purified wintery rhuya flour
minetest.register_node(
    "tech:rhuya_wintery_flour_cooked",  {
        description = S("Hardy Rhuya Flour"),
        tiles = {"tech_flour_strong.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-6/16, -0.5, -6/16, 6/16, -0.3, 6/16},
        },
        groups = {dig_immediate = 3, falling_node=1, flour=1,
                  bread_flour = 1, temp_pass = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light"
})

-- better standardize node names
minetest.register_alias_force("tech:rhuya_flour_wintery", "tech:rhuya_wintery_flour")
minetest.register_alias_force("tech:rhuya_flour_wintery_cooked",  "tech:rhuya_wintery_flour_cooked")

-- oops, you burnt it!
minetest.register_node(
    "tech:rhuya_flour_burned",  {
        description = S("Burnt Rhuya Flour"),
        tiles = {"tech_flour_burned.png"},
        stack_max = minimal.stack_max_medium * 3,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-7/16, -0.5, -7/16, 7/16, -0.42, 7/16},
        },
        groups = {dig_immediate = 3, falling_node=1, compostable=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light"
})

-- all-purpose flour
minetest.register_node(
    "tech:all_flour",  {
        description = S("All-Purpose Flour"),
        -- texture should always be an equal mix of cake flour and bread flour (tech_flour vs tech_flour_strong)
        tiles = {"tech_flour_all.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-6/16, -0.5, -6/16, 6/16, -0.3, 6/16},
        },
        groups = {dig_immediate = 3, falling_node=1, flour=1, temp_pass = 1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light"
})

-- BARSHOCHA FLOUR
-- needs to be treated with lye (potash solution) to remove toxins
minetest.register_node(
    "tech:barszcz_flour_raw", {
        description = S("Uncured Barshocha Flour"),
        tiles = {"tech_flour_bitter.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-6/16, -0.5, -6/16, 6/16, -0.3, 6/16},
        },
        groups = {dig_immediate = 3, falling_node=1, flour=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        on_construct = function(pos)
            ncrafting.start_soak(pos, 100, 10)
        end,
        on_timer = function(pos, elapsed)
            -- requires lye to cure
            return ncrafting.do_soak(pos, "tech:barszcz_flour", 10, elapsed, function(above)
                above = core.get_node(above)
                if above.name == "tech:potash_flowing" or above.name == "tech:potash_source" then
                    return true
                end
            end)
        end
})

-- bready flour
minetest.register_node(
    "tech:barszcz_flour", {
        description = S("Cured Barshocha Flour"),
        tiles = {"tech_flour_strong.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-6/16, -0.5, -6/16, 6/16, -0.3, 6/16},
        },
        groups = {dig_immediate = 3, falling_node=1, flour=1, bread_flour=1, lye_flour=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light"
})

---- DOUGHS

-- dough fermentation mechanics
local dough_yeast_temp_range = {min=15, max=40}

-- TODO: better system for fermentation + baking mechanics
local function get_dough_on_timer(chance)
    chance = chance or 0.01 -- provided chance or 1%
    -- provide function return to run
    return function(pos, elapsed, ch) -- ch is chance override
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)
        -- unleavened bread baking mechanics
        local baking_data = HEALTH.bake_table[node.name] -- check if we can bake
        local temp -- declare here to reuse in later if statement
        if baking_data then
            temp = climate.get_point_temp(pos)
            -- we're actually cooking! (natural temps can't go over 70 anyways)
            if temp >= 70 then
                if not meta:contains("baking") then
                    -- remove any fermentation
                    local metat = meta:to_table() or {}
                    metat.fields = {}
                    -- add baking int
                    metat.fields.baking = baking_data.time
                    meta:from_table(metat)
                    -- reset timer to be cooking
                    minetest.get_node_timer(pos):start(ncrafting.cook_rate)
                    return false
                end
            end
        end
        -- WE BAKING!! (if we can bake)
        if baking_data and meta:contains("baking") then
            return ncrafting.do_bake(pos, elapsed,
                                 baking_data.temp, baking_data.time,
                                 baking_data.cooked, baking_data.burned)
        end

        ch = ch or chance
        if meta:get_int("ferment") ~= 0 then -- we're fermentin'
            -- we're done fermenting!
            if not ncrafting.ferment_on_timer(pos, elapsed) then
                node = minetest.get_node(pos)
                local metat = meta:to_table()
                metat.fields = {}
                -- set baking data if we're a bakeable
                baking_data = HEALTH.bake_table[node.name]
                if baking_data then
                  metat.fields.baking = baking_data.time
                end
                meta = meta:from_table(metat)
                node.param2 = 1 -- set param2 to 1 for "fresh batch"
                minetest.swap_node(pos,node)
                return false
            end
            -- otherwise continue fermenting
            return true
        -- let's try fermenting
        elseif math.random() <= chance then
            -- check for temp_range first before trying to ferment
            local nodedef = minetest.registered_nodes[node.name]
            local temp_range = nodedef._ferment_temp_range
            if temp_range then
                local temp = temp or climate.get_point_temp(pos)
                if temp <= temp_range.min or temp >= temp_range.max then
                    -- loop again if conditions not right
                    return true
                end
            end
            -- chance and temp successful, ferment!
            ncrafting.get_or_create_ferment(pos,meta)
            ncrafting.ferment_on_construct(pos)
            return false
        end
        -- check again later (40sec to 85sec)
        minetest.get_node_timer(pos):start(math.random(40,85))
        return false
    end
end

local function dough_preserve_metadata(pos, oldnode, oldmeta, drops)
    oldmeta = oldmeta or {} -- purify
    if not oldmeta.ferment then return end -- not fermenting
    oldmeta.baking = nil -- remove baking value
    -- set description if not set
    oldmeta.description = oldmeta.description or S("Fermenting @1",drops[1]:get_description())
    ncrafting.ferment_preserve_metadata(pos, oldnode, oldmeta, drops[1])
end

local dough_after_place_node = function(pos, placer, itemstack, pointed_thing)
    -- not fermenting, return
    if itemstack:get_meta():get_int("ferment") == 0 then return end
    -- we're fermenting, run ferment after_place
    ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing)
end

local dough_infection = function(player, pos, nodedef, itemstack, idef)
    idef = idef or itemstack and itemstack:get_definition()
    if not (idef and idef.groups and idef.groups.infect_dough) then return end
    local meta = core.get_meta(pos)
    if meta:contains("ferment") then return end -- already infected
    -- successful infection
    ncrafting.ferment_on_construct(pos)
    return true
end

minetest.register_node(
    "tech:maraka_dough",  {
        description = S("Maraka Dough"),
        tiles = {"tech_dough_strong.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-4/16, -0.5, -4/16, 4/16, -4/16, 4/16},
        },
        groups = {dig_immediate = 3, falling_node=1, dough=1, cake_dough=1,
              heatable=75, temp_pass=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        _ferment_time = {min=15,max=36},
        _ferment_temp_range = dough_yeast_temp_range,
        _ferment_to = "tech:maraka_dough_fermented",
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(ncrafting.ferment_interval)
        end,
        on_microbial_infection = dough_infection,
        on_timer = get_dough_on_timer(),
        preserve_metadata = dough_preserve_metadata,
        after_place_node = dough_after_place_node
})

minetest.register_node(
    "tech:rhuya_dough",  {
        description = S("Rhuya Dough"),
        tiles = {"tech_dough.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-5/16, -0.5, -5/16, 5/16, -4/16, 5/16},
        },
        groups = {dig_immediate = 3, falling_node=1, dough=1, cake_dough=1,
            heatable=75, temp_pass=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        _ferment_time = {min=12,max=30},
        _ferment_temp_range = dough_yeast_temp_range,
        _ferment_to = "tech:rhuya_dough_fermented",
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(ncrafting.ferment_interval)
        end,
        on_microbial_infection = dough_infection,
        on_timer = get_dough_on_timer(),
        preserve_metadata = dough_preserve_metadata,
        after_place_node = dough_after_place_node
})

minetest.register_node(
    "tech:rhuya_wintery_dough",  {
        description = S("Hardy Rhuya Dough"),
        tiles = {"tech_dough_strong.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-5/16, -0.5, -5/16, 5/16, -4/16, 5/16},
        },
        groups = {dig_immediate = 3, falling_node=1, dough=1, bread_dough=1,
            heatable=75, temp_pass=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        _ferment_time = {min=20,max=46},
        _ferment_temp_range = dough_yeast_temp_range,
        _ferment_to = "tech:rhuya_wintery_dough_fermented",
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(ncrafting.ferment_interval)
        end,
        on_microbial_infection = dough_infection,
        on_timer = get_dough_on_timer(0.03), -- 3% chance
        preserve_metadata = dough_preserve_metadata,
        after_place_node = dough_after_place_node
})

minetest.register_node(
    "tech:all_dough",  {
        description = S("All-Purpose Dough"),
        -- likewise to all-purpose flour, texture must be a mix of regular and strong dough
        tiles = {"tech_dough_all.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-5/16, -0.5, -5/16, 5/16, -4/16, 5/16},
        },
        groups = {dig_immediate = 3, falling_node=1, dough=1,
            heatable=75, temp_pass=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        _ferment_time = {min=14,max=40},
        _ferment_temp_range = dough_yeast_temp_range,
        _ferment_to = "tech:all_dough_fermented",
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(ncrafting.ferment_interval)
        end,
        on_microbial_infection = dough_infection,
        on_timer = get_dough_on_timer(0.02), -- 2% chance
        preserve_metadata = dough_preserve_metadata,
        after_place_node = dough_after_place_node
})

minetest.register_node(
    "tech:barszcz_dough",  {
        description = S("Barshocha Dough"),
        tiles = {"tech_dough_strong.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-5/16, -0.5, -5/16, 5/16, -4/16, 5/16},
        },
        groups = {dig_immediate = 3, falling_node=1, dough=1, bread_dough=1,
            heatable=80, temp_pass=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        _ferment_time = {min=15,max=40},
        _ferment_temp_range = dough_yeast_temp_range,
        _ferment_to = "tech:barszcz_dough_fermented",
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(ncrafting.ferment_interval)
        end,
        on_microbial_infection = dough_infection,
        on_timer = get_dough_on_timer(0.005), -- 0.5% chance
        preserve_metadata = dough_preserve_metadata,
        after_place_node = dough_after_place_node
})

-- YEASTS

ncrafting.register_spreadable_microbe("yeast_dough",{
    description = S("Ikippe Yeast"),
    _place_tip = S("Infect Dough"),
    groups = {infect_dough = 1}
})

---- FERMENTED DOUGHS

local function ferm_dough_preserve_metadata(pos, oldnode, oldmeta, drops)
    -- can't get yeast from this, not a fresh batch
    if not oldnode then return end
    if oldnode.param2 ~= 1 then return end
    local nodedef = minetest.registered_nodes[oldnode.name]
    local get_microbes = nodedef.breads_get_microbes or
      function()
          return math.random(1,3)
      end
    -- get fresh batch catchable microbes
    local microbes = get_microbes(pos, oldnode, nodedef)
    if not microbes then return end
    microbes = type(microbes) ~= "table" and {microbes}
    for _,item in pairs(microbes) do
        if type(item) == "number" then
            item = "tech:yeast_dough "..item
        end
        if type(item) == "string" then
          drops[#drops + 1] = item
        end
    end
end

minetest.register_node(
    "tech:maraka_dough_fermented",  {
        description = S("Fermented @1",S("Maraka Dough")),
        tiles = {"tech_dough_strong.png^tech_dough_aerated_mask.png^tech_yeast_dough_overlay.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-4/16, -0.5, -4/16, 4/16, -3/16, 4/16},
        },
        groups = {dig_immediate = 3, falling_node=1, fermented_dough=1,
            fermented_cake_dough=1, heatable=85, temp_pass=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        preserve_metadata = ferm_dough_preserve_metadata
})

minetest.register_node(
    "tech:rhuya_dough_fermented",  {
        description = S("Fermented @1",S("Rhuya Dough")),
        tiles = {"tech_dough.png^tech_dough_aerated_mask.png^tech_yeast_dough_overlay.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-5/16, -0.5, -5/16, 5/16, -3/16, 5/16},
        },
        groups = {dig_immediate = 3, falling_node=1, fermented_dough=1,
            fermented_cake_dough=1, heatable=85, temp_pass=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        preserve_metadata = ferm_dough_preserve_metadata
})

minetest.register_node(
    "tech:rhuya_wintery_dough_fermented",  {
        description = S("Fermented @1",S("Hardy Rhuya Dough")),
        tiles = {"tech_dough_strong.png^tech_dough_aerated_mask.png^tech_yeast_dough_overlay.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-5/16, -0.5, -5/16, 5/16, -3/16, 5/16},
        },
        groups = {dig_immediate = 3, falling_node=1, fermented_dough=1,
            fermented_bread_dough=1, heatable=85, temp_pass=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        preserve_metadata = ferm_dough_preserve_metadata,
        breads_get_microbes = function(pos, oldnode, nodedef)
            return math.random(2,5)
        end
})

minetest.register_node(
    "tech:barszcz_dough_fermented",  {
        description = S("Fermented @1",S("Barshocha Dough")),
        tiles = {"tech_dough_strong.png^tech_dough_aerated_mask.png^tech_yeast_dough_overlay.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-5/16, -0.5, -5/16, 5/16, -3/16, 5/16},
        },
        groups = {dig_immediate = 3, falling_node=1, fermented_dough=1,
            fermented_bread_dough=1, lye_dough=1, gummy_dough=1, heatable=80, temp_pass=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        preserve_metadata = ferm_dough_preserve_metadata,
        breads_get_microbes = function(pos, oldnode, nodedef)
            return math.random(1,6)
        end
})

minetest.register_node(
    "tech:all_dough_fermented",  {
        description = S("Fermented @1",S("All-Purpose Dough")),
        tiles = {"tech_dough_all.png^tech_dough_aerated_mask.png^tech_yeast_dough_overlay.png"},
        stack_max = minimal.stack_max_medium * 2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-5/16, -0.5, -5/16, 5/16, -3/16, 5/16},
        },
        groups = {dig_immediate = 3, falling_node=1, fermented_dough=1, heatable=85, temp_pass=1},
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
        preserve_metadata = ferm_dough_preserve_metadata,
        breads_get_microbes = function(pos, oldnode, nodedef)
            return math.random(2,4)
        end
})

---- BREADS

-- peasant's bread, not much flavour, just basic bread
minetest.register_node(
    "tech:bread_black", {
        description = S("Black Bread"),
        groups = {dig_immediate = 3, falling_node=1, baked_bread=1},
        tiles = {"tech_bread_black.png"},
        stack_max = minimal.stack_max_medium*2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {
            {-5/16, -0.5, -5/16, 5/16, -7/16, 5/16}, -- bottom
            {-6/16, -7/16, -6/16, 6/16, -1/16, 6/16}, -- main
            {-5/16, -3/16, -5/16, 5/16, 0, 5/16} -- top
          }
        },
        sounds = tech.node_sound_bread_defaults(),
        paramtype = "light",
})

-- cakey type of bread, moist and soft
minetest.register_node(
    "tech:bread_crumbly", {
        description = S("Crumbly Bread"),
        groups = {dig_immediate = 3, falling_node=1, crumbly_bread=1},
        tiles = {"tech_bread_crumbly.png"},
        stack_max = minimal.stack_max_medium*2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {
            {-5/16, -0.5, -5/16, 5/16, -2/16, 5/16}, -- main
            {-4/16, -2/16, -4/16, 4/16, -1/16, 4/16} -- top
          }
        },
        sounds = tech.node_sound_bread_defaults(),
        paramtype = "light",
})

-- basically a type of flatbread
minetest.register_node(
    "tech:bread_unleavened",  {
        description = S("Unleavened Bread"),
        tiles = {"tech_bread_unleavened.png"},
        stack_max = minimal.stack_max_medium*3,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-4.5/16, -0.5, -4.5/16, 4.5/16, -5/16, 4.5/16},
        },
        groups = {dig_immediate = 3, falling_node=1, crumbly_bread=1},
        sounds = tech.node_sound_bread_unleavened_defaults(),
        paramtype = "light",
})

-- likely similar texture to say a muffin, very cakey
minetest.register_node(
    "tech:bread_unleavened_crumbly",  {
        description = S("Fluffy Unleavened Bread"),
        tiles = {"tech_bread_unleavened_crumbly.png"},
        stack_max = minimal.stack_max_medium*3,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-4.5/16, -0.5, -4.5/16, 4.5/16, -5/16, 4.5/16},
        },
        groups = {dig_immediate = 3, falling_node=1, crumbly_bread=1},
        sounds = tech.node_sound_bread_unleavened_defaults(),
        paramtype = "light",
})

-- all-purpose breads
-- reference: https://www.allrecipes.com/recipe/241680/unleavened-bread-for-communion/
minetest.register_node(
    "tech:bread_unleavened_all",  {
        description = S("Basic Crackerbread"),
        tiles = {"tech_bread_unleavened_all.png"},
        stack_max = minimal.stack_max_medium*3,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {-4/16, -0.5, -4/16, 4/16, -6/16, 4/16},
        },
        groups = {dig_immediate = 3, falling_node=1, crumbly_bread=1},
        sounds = nodes_nature.node_sound_defaults(),--tech.node_sound_bread_unleavened_defaults(),
        paramtype = "light",
})

-- all-purpose dough baked (not sure what it'd exactly be, but I imagine soft? - TPH)
minetest.register_node(
    "tech:bread_all", {
        description = S("Soft Bread"),
        groups = {dig_immediate = 3, falling_node=1, baked_bread=1},
        tiles = {"tech_bread_all.png"},
        stack_max = minimal.stack_max_medium*2,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {
            {-5.5/16, -0.5, -5.5/16, 5.5/16, -2/16, 5.5/16}, -- main
            {-4/16, -2/16, -4/16, 4/16, -1/16, 4/16}, -- 2nd
            {-2/16, -1/16, -2/16, 2/16, -0.5/16, 2/16} -- top
          }
        },
        sounds = tech.node_sound_bread_defaults(),
        paramtype = "light",
})

-- yuck! can't eat this!
minetest.register_node(
    "tech:bread_burned",  {
        description = S("Burned Bread"),
        groups = {dig_immediate = 3, falling_node=1, compostable=1},
        tiles = {"tech_flour_burned.png"},
        stack_max = minimal.stack_max_medium*4,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = {
            {-4/16, -0.5, -4/16, 4/16, -2/16, 4/16}, -- main
          }
        },
        sounds = nodes_nature.node_sound_dirt_defaults(),
        paramtype = "light",
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
        sound = {name = "mortar_and_pestle_craft_seed", gain = {1, 2}, pitch = {0.7, 0.95}}
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
        items = {'nodes_nature:maraka_fruit 12'},
        level = 1,
        always_known = true,
        sound = {name = "mortar_and_pestle_craft_seed", gain = {1, 2}, pitch = {0.88, 1.1}}
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
    sound = {name = "mortar_and_pestle_craft_seed", gain = {1, 2}, pitch = {0.82, 1.05}}
})

crafting.register_recipe({
    type = "mortar_and_pestle",
    output = "tech:rhuya_flour_wintery",
    items = {'nodes_nature:rhuya_wintery_seed 12'},
    level = 1,
    always_known = true,
    sound = {name = "mortar_and_pestle_craft_seed", gain = {1, 2}, pitch = {0.82, 1.05}}
})

-- grind barshocha roots into flour

crafting.register_recipe({
    type = {"mortar_and_pestle"},
    output = "tech:barszcz_flour_raw",
    items = {"nodes_nature:barszcz_root 6"},
    level = 1,
    always_known = true,
    sound = {name = "mortar_and_pestle_craft_seed", gain = {1, 2}, pitch = {0.7, 0.95}}
})

-- mix bready flours into all-purpose

crafting.register_recipe({
    type = "breadmaking",
    output = "tech:all_flour 2",
    items = {'group:bread_flour', 'group:cake_flour'},
    level = 1,
    always_known = true,
})

-- wet flours for doughs

for dough,flour in pairs(
  {["tech:maraka_dough"] = "tech:maraka_bread_cooked 12",
  ["tech:rhuya_dough"] = "tech:rhuya_flour_cooked", ["tech:rhuya_wintery_dough"] = "tech:rhuya_wintery_flour_cooked",
  ["tech:all_dough"] = "tech:all_flour", ["tech:barszcz_dough"] = "tech:barszcz_flour"}) do
    -- get count from itemstring
    local count = tonumber(flour:match"%s%d+") -- "%s" checks for a space behind any that fits "%d" - number, "+" gets all numbers
    if not count then
        -- otherwise set one and add it to flour
        count = 8
        flour = flour.." "..count
    end
    -- iterate through every empty water pot
    for _,water_pot in pairs({"tech:clay_water_pot", "tech:wooden_water_pot"}) do
        crafting.register_recipe({
            type = "breadmaking",
            output = dough.." "..count,
            -- only the freshwater variant
            items = {flour, water_pot.."_freshwater"},
            replace = water_pot,
            level = 1,
            always_known = true
        })
    end
end

-- ANIMAL PRODUCTS

-- cracked egg
minetest.register_node(
    "tech:yolk_and_albumen",{
        description = S("Cracked Egg"),
        tiles = {"tech_yolkandalbumen.png"},
        inventory_image = "tech_yolkandalbumen_icon.png",
        groups = {dig_immediate=3, falling_node=1, heatable=60, edible = 1},
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
        items = {{'animals:pegasun_eggs', 'animals:chichasa_eggs'}},
        level = 1,
        always_known = true,
        sound = "animals_hatch_egg"
})
crafting.register_recipe({
        type = "mortar_and_pestle",
        output = "tech:yolk_and_albumen",
        items = {
            {'animals:pegasun_eggs',
            'animals:chichasa_eggs',
            'animals:kubwakubwa_eggs 2',
            'animals:darkasthaan_eggs 2'
            }
        },
        level = 1,
        always_known = true,
        sound = "animals_hatch_egg"
})
