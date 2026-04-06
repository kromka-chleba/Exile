------------------------------------
--DRUGS
--medicines etc

-----------------------------------

-- Internationalization
local S = tech.S

local random = math.random

-----------------------------------
--MEDICAL


------------
--Herbal medicine
-- removes energy cost of plants healing effects
--can heal certain health effects (check HEALTH/data_food.lua and HEALTH.cure_table)
--a restorative anti-bacterial/anti-parasitic
minetest.register_craftitem(
    "tech:herbal_medicine", {
        description = S("Herbal Medicine"),
        inventory_image = "tech_herbal_medicine.png",
        stack_max = EXILE.stack_max_medium *2,
        groups = {flammable = 1, edible = 1},
        _use_tip = S("Eat"),
})


------------
--Detox?
--for toxins, alcohol, drugs
-- e.g. charcoal? - doesn't work for everything, can itself cause vomiting etc

--[[
    How toxins get treated:
    Alcohol: wait for it to pass (while helping them not die), pump stomach
    Stimulant OD: sedation, wait for it to pass (while helping them not die)
    Specific toxins can have anti-toxins (a fairly modern treatment)

]]


-----------------------------------
-----------------------------------
--DRUGS

-----------------------------------
--STIMULANTS


------------
--Tiku
-- stimulant drug
-- gets you high (HEALTH/data_food.lua)
minetest.register_craftitem(
    "tech:tiku", {
        description = S("Tiku (stimulant)"),
        inventory_image = "tech_tiku.png",
        stack_max = EXILE.stack_max_medium *2,
        groups = {flammable = 1, drug = 1, edible = 1},
        _use_tip = S("Eat"),
})

-- VINEGAR
crafting.register_group_desc("vinegar", S("Vinegar")) -- TODO dupes ?
crafting.register_group_desc("tang_vinegar", S("Tang Vinegar"))

--Register liquid "tang_vinegar"
liquid_store.register_liquid(
    "tech:tang_vinegar_liquid", -- source
    {
        flowing = false, -- can't be transfered
        force_renew = false, -- source won't be renewed
        groups = {"vinegar", "tang_vinegar"} -- groups list
    }
)

-- Register Tang Vinegar (in wooden or clay pot)
for _, mat in pairs ({"clay", "wooden"}) do
    local def = {
        source = "tech:tang_vinegar_liquid",
        empty = "tech:".. mat .. "_water_pot",
        description = S("Tang Vinegar"),
        groups = {dig_immediate=2, temp_pass = 1},
        -- adds a tile texture to the empty container tiles
        add_liquid_tile = "tech_pot_tang_vinegar.png",
        node_box = "container", -- specific setting:  "use the container one"
    }
    local name
    if mat == "clay" then
        name = "tech:tang_vinegar"
        def.groups["pottery"] = 1
    else
        name = "tech:wooden_tang_vinegar"
    end
    -- register stored liquid
    liquid_store.register_stored_liquid(name, def)
end

-- Register Tang vinegar mother (clay and wooden pot)
for _, mat in pairs ({"clay", "wooden"}) do
    local def = {
        description = S("Tang Vinegar with Mother"),
        stack_max = 1,
        tiles = tech.get_stored_liquid_tiles(mat, "pot",
                                "^tech_pot_tang_vinegar_mother.png"),
        drawtype = "nodebox", -- could be stored once in pots and reused
        node_box = {
            type = "fixed",
            fixed = {
                {-0.25, 0.375, -0.25, 0.25, 0.5, 0.25}, -- NodeBox1
                {-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
                {-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
                {-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
                {-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125}, -- NodeBox5
            }
        },
        groups = {dig_immediate=2, temp_pass = 1},
        sounds = nodes_nature.node_sound_stone_defaults(),
        paramtype = "light"
    }

    local base_name
    if mat == "clay" then
        base_name = "tech:tang_vinegar"
        def.groups["pottery"] = 1
    elseif mat == "wooden" then -- just for code clarity
        base_name = "tech:wooden_tang_vinegar"
    end
    def.drop = {
        items = {
            {rarity = 1,
             items = { base_name, "tech:mother_of_tang"}},
            {rarity = 4,
             items = {"tech:mother_of_tang"}}
        },
    }
    core.register_node(base_name .. "_mother", def)
end

-- "Mother" of Tang
ncrafting.register_spreadable_microbe("mother_of_tang",{
    description = S("Mother of Tang"),
    inventory_image = "tech_mother_of_tang.png",
    groups = {tang_mother=1},
    _place_tip = S("Infect Other Pots"),
    sounds = {infect=false} -- no sound
})




-----------------------------------
--DEPRESSANTS

-----------------
--Tang, alcoholic drink

local function drink_tang(pos, node, clicker, itemstack, pointed_thing, ininv)
    if not minetest.is_player(clicker) then
        return
    end
    local empty = liquid_store.stored_liquids[node.name].nodename_empty
    if not minetest.registered_nodes[empty] then
        -- no empty node, prevent functionality
        return
    end
    --lets skull an entire vat of booze, what could possibly go wrong...
    local meta = clicker:get_meta()
    --only drink if thirsty
    if meta:get_int("thirst") < 100 then
        if not ininv then
            minetest.swap_node(pos, {name = empty})
        else
            pos = clicker:get_pos()
            node.name = itemstack
        end
        minetest.sound_play("nodes_nature_slurp",
                            {pos = pos, max_hear_distance = 3, gain = 0.25})
        return HEALTH.eatdrink(node.name, clicker, pointed_thing)
    end
end

local function mother_infection(_player, pos, _nodedef, _itemstack, idef)
    if not (idef.groups and idef.groups.tang_mother) then return end
    local meta = minetest.get_meta(pos)
    if meta:contains("mothering") then return end -- already infected
    -- INFECT!
    meta:set_int("mothering",1)
    ncrafting.ferment_on_construct(pos)
    return true
end

local function mother_on_timer(pos, elapsed)
    local meta = minetest.get_meta(pos)
    if meta:contains("mothering") then
        return ncrafting.ferment_on_timer(pos, elapsed)
    elseif random() <= 0.05 then
        meta:set_int("mothering",1)
        ncrafting.ferment_on_construct(pos)
        return false
    end
    minetest.get_node_timer(pos):start(random(400,800))
    return false
end

--Register liquid "tang"
liquid_store.register_liquid(
    "tech:tang_liquid", -- source
    {
        flowing = false, -- can't be transfered
        force_renew = false, -- source won't be renewed
        groups = {"tang"} -- groups list
    }
)

--Pot (clay and wooden) of Tang
for _, mat in pairs ({"clay", "wooden"}) do
    local def = {
        source = "tech:tang_liquid",
        empty = "tech:".. mat.."_water_pot",
        description = S("Tang"),
        groups = {dig_immediate=2, temp_pass = 1,
                  drug = 1, timer = 5, edible = 1, no_soup = 1},
        -- adds a tile texture to the empty container tiles
        add_liquid_tile = "tech_pot_tang.png",
        node_box = "container", -- specific setting:  "use the container one"
        _ferment_time = {min=200,max=300},
        _ferment_temp_range = {min=10,max=34},

        on_microbial_infection = mother_infection,
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(ncrafting.ferment_interval)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing, nmeta, imeta)
            imeta = imeta or itemstack:get_meta()
            if imeta:get_int("mothering") ~= 1 then return end
            ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing, nmeta, imeta)
        end,
        on_timer = function(pos, elapsed)
            return mother_on_timer(pos, elapsed)
        end,

        preserve_metadata = function(pos, oldnode, oldmeta, drops, imeta)
            ncrafting.ferment_preserve_metadata(
                pos, oldnode, oldmeta, drops[1], imeta)
        end,
        _preserve_metadata = function(pos, oldnode, oldmeta, transferred_stack)
            -- for liquid store interactions
            ncrafting.ferment_preserve_metadata(
                pos, oldnode, oldmeta, transferred_stack)
        end,
        on_rightclick = function(...)
            drink_tang(...)
        end,
        _use_tip = S("Drink"),

    }

    local name
    if mat == "clay" then
        name = "tech:tang"
        def.groups.pottery = 1
    elseif mat == "wooden" then
        name = "tech:wooden_tang"
    end
    def._ferment_to = name.."_vinegar_mother"
    def._on_use_item = function(player, itemstack, pointed_thing)
        return drink_tang(nil, {["name"] = name}, player, itemstack,
                          pointed_thing, true)
    end
    liquid_store.register_stored_liquid(name, def)
end

-----------------
-- UNFERMENTED TANG

-- Pot (clay and wooden) of new Tang (unfermented),
-- must be left to ferment
for _, mat in pairs ({"clay", "wooden"}) do
    local def = {
        source = "tech:unfermented_tang_liquid",
        empty = "tech:".. mat.."_water_pot",
        description = S("Tang (unfermented)"),
        groups = {dig_immediate=2, temp_pass = 1},
        -- adds a tile texture to the empty container tiles
        add_liquid_tile = "tech_pot_tang_uf.png",
        node_box = "container", -- specific setting:  "use the container one"
        _ferment_time = {min=300,max=360},
        _ferment_temp_range = {min=10,max=34},
        on_construct = function(pos)
            ncrafting.ferment_on_construct(pos)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing, nmeta, imeta)
            ncrafting.ferment_after_place(pos, placer, itemstack, pointed_thing, nmeta, imeta)
        end,
        on_timer = function(pos, elapsed)
            return ncrafting.ferment_on_timer(pos, elapsed)
        end,
        preserve_metadata = function(pos, oldnode, oldmeta, drops, imeta)
            ncrafting.ferment_preserve_metadata(
                pos, oldnode, oldmeta, drops[1], imeta)
        end,
        _preserve_metadata = function(...) -- for liquid store interactions
            ncrafting.ferment_preserve_metadata(...)
        end
    }
    local name

    if mat == "clay" then
        name = "tech:tang_unfermented"
        def._ferment_to = "tech:tang"
        def.groups.pottery = 1
    elseif mat == "wooden" then
        name = "tech:wooden_tang_unfermented"
        def._ferment_to = "tech:wooden_tang"
    end
    liquid_store.register_stored_liquid(name, def)
end

-----------------------------------
--HALLUCINOGENS



---------------------------------------
--Recipes



--
--mortar and pestle
--


--make herbal_medicine
crafting.register_recipe({
        type = "mortar_and_pestle",
        output = "tech:herbal_medicine",
        items = {'nodes_nature:hakimi_flowering',
                 'nodes_nature:merki', 'nodes_nature:moss'},
        level = 1,
        always_known = true,
})

--make tiku
crafting.register_recipe({
        type = "mortar_and_pestle",
        output = "tech:tiku",
        items = {'nodes_nature:tikusati_seed 12',
                 'nodes_nature:wiha_fruit', "tech:vegetable_oil"},
        level = 1,
        always_known = true,
})

--make tang_unfermented
crafting.register_recipe({
        type = "mortar_and_pestle",
        output = "tech:tang_unfermented",
        items = {'nodes_nature:tangkal_fruit 12',
                 "group:freshwater/pot"},
        replace = function(item_name)
            -- if item is a pot, replace it by correct filled version
            --[[NOTE: we could check "is it a "freshwater pot" using
            -- local gstats = crafting.get_group_stats(grouptag)
            -- then check if
            -- gstats:does_match(item_name, "group:freshwater/pot")
            -- is true
            -- but here I could just check if it is a pot or freshwater.
            --]]
            if core.get_item_group(item_name, "pot") > 0 then
                return liquid_store.replace(item_name,
                                            "tech:unfermented_tang_liquid")
            end
        end,
        -- custom output generation functions may be added as "output_func"
        -- they should return either an output-stack string or nil
        output_func = function() return nil end,
        level = 1,
        always_known = true,
})
