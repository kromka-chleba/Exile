----------------------------------------------------------
--WATERWORKING

-- Internationalisaton
local S = tech.S

-- fill pot_name with freshwater (called in on_timer functions)
local function water_pot(pos, pot_name, elapsed)
    local light = minimal.get_daylight({x=pos.x, y=pos.y + 1, z=pos.z}, 0.5)
    --collect rain
    if light == 15 then
        if climate.get_rain(pos, light) or
            climate.time_since_rain(elapsed) > 0 then
            minetest.swap_node(pos, {name = pot_name.."_freshwater"})
            return
        end
    else
        --drain wet sediment into the pot
        --or melt snow and ice
        local posa =        {x = pos.x, y = pos.y+1, z = pos.z}
        local name_a = minetest.get_node(posa).name
        if name_a == "air" then
            return true
        elseif (name_a == "nodes_nature:ice" or
                name_a == "nodes_nature:snow_block" or
                name_a == "nodes_nature:freshwater_source" ) then
            if climate.can_thaw(posa) then
                minetest.swap_node(pos, {name = pot_name.."_freshwater"})
                minetest.remove_node(posa)
                return
            end
        end
    end
    return true
end

-- checks if can drink, and sets player's thirst if can
local function drink_water(player)
    if not minetest.is_player(player) then
        return
    end
    local meta = player:get_meta()
    local thirst = meta:get_int("thirst")
    if thirst < 100 then
        -- only drink when thirsty, return true and set player's thirst if so
        HEALTH.set_int(player,meta,"thirst",100)
        return true
    end
end

-- Global shared datas ---------------------------------------------------------

-- gives matching string for parameters
-- used to avoir translation string looking like "@1 @2"
-- So we can keep using the full string in translation
local to_s = {
    clay = "Clay",
    wooden = "Wooden",
    freshwater = "Freshwater",
    salt_water = "Salt Water",
    water_pot = "Water Pot",
    watering_can = "Watering Can",
    clear = "Clear",
    green = "Green"
}

local mats_def = {
    ["clay"] = {
        texture = "tech_pottery.png",
        sound = tech.node_sound_earthenware_defaults(),
    },
    ["wooden"] = {
        texture = "tech_primitive_wood.png",
        sound = nodes_nature.node_sound_wood_defaults(),
    }
}

function tech.get_stored_liquid_tiles(mat, container, suffix)
    if not mats_def[mat] then
        core.log ("to tech.get_stored_liquid_tiles: "
            .."wrong material given as 1st argument. Got: " .. tostring(mat))
        return
    end
    -- pot by default
    if not container or container == "water_pot" then
        container = "pot"
    end

    local tex = mats_def[mat].texture
    -- empty by default
    local tiles = {tex.."^tech_" .. container .. "_empty.png"}
    -- fill other 5 tiles
    for i = 2, 6 do
        tiles[i] = tex
    end
    -- if suffix, add liquid texture
    if suffix then
        tiles[1] = tiles[1] .. suffix
    end
    return tiles
end

-- Empty Containers ------------------------------------------------------------
--[[
    1) Pots (clay and wooden):
        for collecting water, catching rain water
    2) Watering Can (clay and wooden):
        can turn a block in it's wet variant
        fills itselft with rain
        acts similar to clay_water_pot
]]

local nodeboxes = {
    ["water_pot"] = {
        type = "fixed",
        fixed = {
            {-0.25, 0.375, -0.25, 0.25, 0.5, 0.25}, -- NodeBox1
            {-0.375, -0.25, -0.375, 0.375, 0.3125, 0.375}, -- NodeBox2
            {-0.3125, -0.375, -0.3125, 0.3125, -0.25, 0.3125}, -- NodeBox3
            {-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}, -- NodeBox4
            {-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125}, -- NodeBox5
        }
    },
    ["watering_can"] = {
        type = "fixed",
        fixed = {
            -- lid
            {-0.2, 0.2,-0.2, 0.2, 0.3, 0.2},
            -- handle
            {-0.05, 0.05, -0.25, 0.05, 0.15, -0.45}, -- upper
            {-0.05, -0.1, -0.35, 0.05, 0.05, -0.45}, -- mid
            {-0.05, -0.2, -0.25, 0.05, -0.1, -0.45}, -- low
            -- spout
            {-0.1, 0.1, 0.25, 0.1, 0.2, 0.5}, -- upper
            {-0.1, -0.4, 0.25, 0.1, 0.1, 0.4},
            -- body
            {-0.25, -0.4, -0.25, 0.25, 0.2, 0.25},
            -- base
            {-0.3, -0.5,-0.4, 0.3, -0.35, 0.4},
        }
    }
}

-- register empty pots and watering cans (clay and wood)
for _, container in pairs ({"water_pot", "watering_can"}) do
    for mat, _ in pairs (mats_def) do
        local name = "tech:" .. mat .. "_".. container
        local def = {
            description = S("Empty " .. to_s[mat] ..  " " .. to_s[container]),
            -- Appearance
            tiles = tech.get_stored_liquid_tiles(mat, container),
            drawtype = "nodebox",
            node_box = nodeboxes[container],
            paramtype = "light",
            -- max stack
            stack_max = minimal.stack_max_bulky,
            -- behaviors
            sounds = mats_def[mat].sound,

            --collect rain water
            on_construct = function(pos)
                core.get_node_timer(pos):start(math.random(30,60))
            end,
            on_timer = function(pos, elapsed)
                return water_pot(pos, name, elapsed)
            end,
            -- groups
            groups = {
                dig_immediate = 3,
                temp_pass = 1,
            }
        }
        -- list container_groups to be added (=1) and inherited by filled node
        local container_groups = {}
        -- clay are pottery, wood is flammable
        if mat == "wooden" then
            def.groups["flammable"] = 1
        elseif mat == "clay" then
            def.groups["pottery"] = 1
        end
        -- water_pot has additionnal function + unit
        if container == "water_pot" then
            -- I have no idea why it was no present in watering can, maybe an error TODO check
            def.on_place = function(itemstack, placer, pointed_thing)
                return liquid_store.on_place(itemstack, placer, pointed_thing)
            end
            -- adds pot group for recipes
            table.insert(container_groups, "pot")
        end
        -- register node and container in liquid_store
        liquid_store.register_container(name, def, container_groups)
    end
end

-- adding custom group description to be used in crafting recipes
crafting.register_group_desc("pot", S("Water Pot"))

-- Wodden pot recipe
--[[Clay pot/watering_can is cooked, so not registered as recipe
    see pottery.lua for them]]
crafting.register_recipe({
        type = {"chopping_block","axe"},
        output = "tech:wooden_water_pot",
        items = {'group:log 2'},
        level = 1,
        always_known = true,
})

-- Wooden watering_can recipe -- TODO move both in woodworking ?
crafting.register_recipe({
        type = {"carpentry_bench","axe"},
        output = "tech:wooden_watering_can",
        items = {'group:log 2'},
        level = 1,
        always_known = true
})

----Filled Containers----------------------------------------------------------
--Register water stores for water pots and watering cans
--source, nodename, nodename_empty, tiles, node_box, desc, groups

--make freshwater Pot drinkable on click
local function drink(pos, node, clicker, itemstack, pointed_thing)
    if drink_water(clicker) then
        minimal.switch_node(pos, liquid_store.get_empty(node.name))
        minetest.sound_play("nodes_nature_slurp",
                            {pos = pos, max_hear_distance = 3,
                             gain = 0.25})
    end
end

--[[`container` can be "water_pot" or "watering_can"
    `liquid` is "freshwater" or "salt_water"
    `mat` is "clay" or "wooden"
    ]]
local function get_base_def(mat, container, liquid)
    local def = {
        source = "nodes_nature:".. liquid .."_source",
        empty = "tech:".. mat .. "_" .. container,
        -- TODO make translation ! maybe a cleared function for translators :D
        description = S(to_s[mat] ..  " " .. to_s[container]
                                  .. " with " .. to_s[liquid]),
        groups = {dig_immediate = 2},
        tiles = tech.get_stored_liquid_tiles(mat, container, "^tech_pot_water.png"),
        node_box = nodeboxes[container]
    }
    -- Material specific settings
    if mat == "clay" then
        def.groups.pottery = 1 -- TODO should I inherit groups from container ?
        -- but then I need to think to override the flammable for woods so
        -- I need to delete that inheritance
    end
    return def
end

-- Water Pots ---------------------------------------------------------

-- Filled with Freshwater
-- We can drink from freshwater pots
for mat, _ in pairs (mats_def) do
    local def = get_base_def(mat, "water_pot", "freshwater")
    -- make water drinkable on right click
    def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            drink(pos, node, clicker, itemstack, pointed_thing)
        end
    -- register stored liquid and node
    liquid_store.register_stored_liquid(def.empty .. "_freshwater", def)
end

-- Filled with Salt Water
-- Clay Water Pot with Salt Water can be cooked to give Salt
for mat, _ in pairs (mats_def) do
    local def = get_base_def(mat, "water_pot", "salt_water")
    local filled_name = def.empty .. "_salt_water"
    -- We can get salt from pot + walt water + clay
    if mat == "clay" then
        -- different name format
        filled_name = "tech:clay_water_salt_water"
        -- adding heatable to default pottery = 1
        def.groups.heatable = 60
        -- roasting to get salt
        def.on_construct = function(pos)
            -- roast of 5, checking every 10 seconds
            return ncrafting.set_roast(pos, 5, 10)
        end
        def.on_timer = function(pos, elapsed)
            local name = minetest.get_node(pos).name
            -- temp of 102C
            -- change name from clay_water_salt_water to clay_water_pot_dry_salt
            if not ncrafting.roast(pos, name, name:sub(1,#name-10).."pot_dry_salt", nil, 102) then
                -- complete, play boil sound
                minimal.sound_play(pos, {
                    name = "tech_boil", max_hear_distance = 10, gain = 0.8, pitch = {0.95, 1.2}
                })
                return false
            end
            return true
        end
    end
    -- register filled storage
    liquid_store.register_stored_liquid(filled_name, def)
end

-- pot with collectable salt
minetest.register_node("tech:clay_water_pot_dry_salt",{
    description = S("Salty Clay Water Pot"),
    tiles = {
        "tech_pottery.png^tech_pot_empty.png",
        "tech_pottery.png",
        "tech_pottery.png"
    },
    groups = {dig_immediate=2, pottery = 1, temp_pass = 1},
    sounds = tech.node_sound_earthenware_defaults(),
    drop = {
      -- chance of getting 6 salt at most, 1 at least
      items = {
        {items = {"tech:clay_water_pot"}},
        {items = {"tech:salt_sea 1"}},
        {rarity=2,items = {"tech:salt_sea"}},
        {rarity=2,items = {"tech:salt_sea"}},
        {rarity=3,items = {"tech:salt_sea"}},
        {rarity=4,items = {"tech:salt_sea"}},
        {rarity=6,items = {"tech:salt_sea"}}
      }
    },
    drawtype = "nodebox",
    node_box = nodeboxes["water_pot"],
    stack_max = minimal.stack_max_bulky,
    paramtype = "light",
})

-- Watering cans ---------------------------------------------------------
-- We can't dump liquid from them
-- We can water a block with watering can
for mat, _ in pairs (mats_def) do
    for _, liquid in pairs({"freshwater", "salt_water"}) do
        local def = get_base_def(mat, "watering_can", liquid)
        -- not able to dump liquid
        def.dumpable = false
        --make watering can able to water a block on click
        def.on_use = function(itemstack, user, pointed_thing)
            local salty = (liquid == "salt_water")
            return ncrafting.water_soil(itemstack, user, pointed_thing, salty)
        end
        -- register filled storage
        liquid_store.register_stored_liquid(def.empty .. "_" .. liquid, def)
    end
end

-- GLASS VESSELS ---------------------------------------------------------------
local c_alpha = minimal.compat_alpha
-- More portable liquid storage than clay pots
-- Need inventory images, otherwise clear glass ones will be invisible

local bottle_base_properties = {
    drawtype = "mesh",
    mesh = "tech_bottle.obj",
    use_texture_alpha = c_alpha.blend,
    selection_box = {
        type='fixed',
        fixed={-0.3, -0.5, -0.3, 0.3, 0.38, 0.3},
    },
    sunlight_propagates = true,

    stack_max = minimal.stack_max_bulky * 2,
}
-- glass_type = clear or green
-- TODO add green/clear translation and maybe functions to make them easier
for _, glass in pairs ({"green", "clear"}) do
    local empty_def = {
        description = S(to_s[glass] .. " Glass Bottle"),
        tiles = {"tech_bottle_".. glass .. ".png"},
        inventory_image = "tech_bottle_".. glass .. "_icon.png",
        paramtype = "light",
        groups = {
            dig_immediate = 2,
            temp_pass = 1,
        },
        sounds = tech.node_sound_glass_defaults(),

        on_place = function(itemstack, placer, pointed_thing)
            return liquid_store.on_place(itemstack, placer, pointed_thing)
        end
    }

    -- copy (or link if table) basic properties for bottles
    for param, value in pairs(bottle_base_properties) do
        empty_def[param] = value
    end

    -- #TODO: add bottle group for future recipes ?
    -- or use "container" or "unit" group with number (like 1 = pot, 2 = bottle, etc... 2 could be for 2 bottle = 1 pot)

    -- register empty container node and container in liquid_store
    liquid_store.register_container("tech:glass_bottle_" .. glass, empty_def)

    -- Crafting
    -- Blown from glass
    -- For simplicity, crafts use charcoal as an ingredient, assuming its used for fuel somehow
    crafting.register_recipe({
            type = "glass_furnace",
            output = "tech:glass_bottle_" .. glass,
            items = {"tech:" .. glass.."_glass_ingot", "tech:charcoal"},
            level = 1,
            always_known = true
    })

    -- Water stores for the jars (Salt Water and Freshwater)
    --[[TODO could probably be concatene even more
    since liquid_store function already takes missing things from container ?]]
    for _, liquid in pairs({"salt_water", "freshwater"}) do
        local tile = "tech_bottle_".. glass ..".png"
                    .. "^(tech_bottle_liquid_blank.png"
                    .. "^[colorize:#17453c^tech_bottle_liquid_pattern.png"
        if glass == "clear" or liquid == "freshwater" then
            tile = tile .. "^[opacity:220)"
        else
            tile = tile .. ")"
        end
        local filled_def = {
            source = "nodes_nature:".. liquid .."_source",
            empty = "tech:glass_bottle_" .. glass,
            description = S(to_s[glass]
                            .. " Glass Bottle With "
                            ..to_s[liquid]),
            groups = {dig_immediate = 2},
            tiles  = {tile},
            inventory_image = "tech_bottle_icon_water.png"
                                    .. "^tech_bottle_".. glass .."_icon.png"
        }
        -- copy (or link if table) basic properties for bottles
        for param, value in pairs(bottle_base_properties) do
            filled_def[param] = value
        end
        -- differences between liquids
        local name = "tech:glass_bottle_".. glass .."_" -- different suffix format

        if liquid == "salt_water" then
            name = name .. "saltwater"

        elseif liquid == "freshwater" then
            name = name .. "freshwater"
            -- can drink from it if freshwater only
            filled_def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
                drink(pos, node, clicker, itemstack, pointed_thing)
            end
        end

        -- register
        liquid_store.register_stored_liquid(name, filled_def)
    end
end
