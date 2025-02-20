-- Rocks and soils for deco.lua

-- Globals
deco = deco or {}
nodes_nature = nodes_nature

-- Import
local path = minetest.get_modpath("mapgen")
local sna = dofile(path.."/soils_and_altitudes.lua")

local boulders = {
    {--[[Boulders:granite boulder]]
        name = "nodes_nature:granite_boulder",
        deco_type = "simple",
        place_on = "nodes_nature:granite",
        sidelen = 80,
        fill_ratio = 0.050000,
        y_max = 9000,
        y_min = -31000,
        decoration = "nodes_nature:granite_boulder",
        flags = "all_floors",
    },

    {--[[Boulders:limestone boulder]]
        name = "nodes_nature:limestone_boulder",
        deco_type = "simple",
        place_on = "nodes_nature:limestone",
        sidelen = 80,
        fill_ratio = 0.050000,
        y_max = 9000,
        y_min = -31000,
        decoration = "nodes_nature:limestone_boulder",
        flags = "all_floors",
    },

    {--[[Boulders:coquina boulder]]
        name = "nodes_nature:coquina_boulder",
        deco_type = "simple",
        place_on = "nodes_nature:coquina",
        sidelen = 80,
        fill_ratio = 0.050000,
        y_max = 9000,
        y_min = -31000,
        decoration = "nodes_nature:coquina_boulder",
        flags = "all_floors",
    },

    {--[[Boulders:basalt boulder]]
        name = "nodes_nature:basalt_boulder",
        deco_type = "simple",
        place_on = "nodes_nature:basalt",
        sidelen = 80,
        fill_ratio = 0.050000,
        y_max = 9000,
        y_min = -31000,
        decoration = "nodes_nature:basalt_boulder",
        flags = "all_floors",
    },

    {--[[Boulders:scoria boulder]]
        name = "nodes_nature:scoria_boulder",
        deco_type = "simple",
        place_on = "nodes_nature:scoria",
        sidelen = 80,
        fill_ratio = 0.050000,
        y_max = 9000,
        y_min = -31000,
        decoration = "nodes_nature:scoria_boulder",
        flags = "all_floors",
    },

    {--[[Boulders:ironstone, dense on deposits]]
        name = "nodes_nature:ironstone_boulder",
        deco_type = "simple",
        place_on = "nodes_nature:ironstone",
        sidelen = 80,
        fill_ratio = 0.600000,
        y_max = 9000,
        y_min = -31000,
        decoration = "nodes_nature:ironstone_boulder",
        flags = "all_floors",
    },

    {--[[Boulders:gneiss boulder]]
        name = "nodes_nature:gneiss_boulder",
        deco_type = "simple",
        place_on = "nodes_nature:gneiss",
        sidelen = 80,
        fill_ratio = 0.050000,
        y_max = 9000,
        y_min = -31000,
        decoration = "nodes_nature:gneiss_boulder",
        flags = "all_floors",
    },

    {--[[Boulders:jade boulder]]
        name = "nodes_nature:jade_boulder",
        deco_type = "simple",
        place_on = "nodes_nature:jade",
        sidelen = 80,
        fill_ratio = 0.400000,
        y_max = 9000,
        y_min = -31000,
        decoration = "nodes_nature:jade_boulder",
        flags = "all_floors",
    },
}

local extra_soils = {
    ----Forests&Woodlands
    {--[[topsoilintrusions:rich]]
        name = "nodes_nature:rich_forest_soil",
        deco_type = "simple",
        place_on = sna.forest_on,
        place_offset_y = -1,
        sidelen = 04,
        noise_params = {offset=-0.60, scale=1.0000, spread={x=32, y=32, z=32},
                        seed=1995, octaves=2, persist=1.0},
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:rich_forest_soil",
        flags = "force_placement",
    },

    {--[[topsoilintrusions:rich]]
        name = "nodes_nature:rich_woodland_soil",
        deco_type = "simple",
        place_on = sna.woodland_on,
        place_offset_y = -1,
        sidelen = 04,
        noise_params = {offset=-0.60, scale=1.0000, spread={x=32, y=32, z=32},
                        seed=1995, octaves=2, persist=1.0},
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:rich_woodland_soil",
        flags = "force_placement",
    },
}

local cobble_cave_fill_ratio = 0.05
local cobble_beach_fill_ratio = 0.001
local cobble_gravel_fill_ratio = 0.001
local cobble_soil_fill_ratio = 0.0005

local beach_cobble_on = {
    "nodes_nature:silt_wet_salty",
    "nodes_nature:silt_wet",
    "nodes_nature:sand_wet_salty",
    "nodes_nature:sand_wet",
    "nodes_nature:sand",
    "nodes_nature:gravel_wet_salty",
    "nodes_nature:gravel_wet",
    "nodes_nature:loam",
    "nodes_nature:loam_wet",
    "nodes_nature:clay",
    "nodes_nature:clay_wet",
}

local gravel_cobble_on = {
    "nodes_nature:gravel",
}

----Cobbles----
-- name must be unique to satisfy the mapgen
-- fill_ratio is the spawn frequency
-- place_on is a list of nodes, if empty the procedure
-- places cobbles only on their mother rock
function generate_cobbles(name, fill_ratio, place_on)
    local new_list = {}
    for i in ipairs(nodes_nature.rock_list) do
        local rock_name = nodes_nature.rock_list[i][1]
        local cobble_on = { "nodes_nature:" .. rock_name }
        local cobble_fill_ratio = fill_ratio
        local y_max = 31000
        if next(place_on) then
            -- table is not empty, overwriting
            cobble_on = place_on
            -- make basalt on beaches rarer
            if (rock_name == "basalt") then
                cobble_fill_ratio = fill_ratio * 0.3
            end
            if (rock_name == "ironstone") then
                cobble_fill_ratio = fill_ratio * 0.5
            end
        end
        -- don't place deep rock cobbles on the surface
        if (rock_name == "jade" or
            rock_name == "gneiss" or
            rock_name == "granite") then
            y_max = -40
        end
        -- no peridot!
        if not (rock_name == "basalt_with_peridot" or rock_name == "peridot") then
            -- for each type of cobble
            for j = 1, 3 do
                local deco = {
                    name = name.."_nn:"..rock_name.."_cobble"..j,
                    deco_type = "simple",
                    place_on = cobble_on,
                    sidelen =  80,
                    fill_ratio = cobble_fill_ratio,
                    y_max = y_max,
                    y_min = -31000,
                    decoration = "nodes_nature:"..rock_name.."_cobble"..j,
                    flags = "all_floors",
                    rotation = "random",
                    param2 = 0,
                    param2_max = 3,
                }
                table.insert(new_list, deco)
            end
        end
    end
    return new_list
end

-- This thing goes to deco.lua
local cobbles = minimal.concat_tables(
    {
        generate_cobbles("cave", cobble_cave_fill_ratio, {}),
        generate_cobbles("beach", cobble_beach_fill_ratio, beach_cobble_on),
        generate_cobbles("gravel", cobble_gravel_fill_ratio, gravel_cobble_on),
        generate_cobbles("soil", cobble_soil_fill_ratio, sna.all_soils_on),
    }
)

return {
    boulders = boulders,
    cobbles = cobbles,
    extra_soils = extra_soils,
}
