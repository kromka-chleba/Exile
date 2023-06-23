-- Ocean stuff for deco.lua

-- Globals
deco = deco or {}

-- Import
local path = minetest.get_modpath("mapgen")
local sna = dofile(path.."/soils_and_altitudes.lua")

local sea_weeds = {
    {--[[Oceans:kelp]]
        name = "nodes_nature:kelp",
        deco_type = "simple",
        place_on = "nodes_nature:gravel_wet_salty",
        place_offset_y = -1,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.6000, spread={x=64, y=64, z=64}, seed=82112, octaves=3, persist=0.9},
        y_max = -7,
        y_min = -15,
        decoration = "nodes_nature:kelp",
        flags = "force_placement",
        param2 = 48,
        param2_max = 96,
    },

    {--[[Oceans:seagrass]]
        name = "nodes_nature:seagrass",
        deco_type = "simple",
        place_on = "nodes_nature:sand_wet_salty",
        place_offset_y = -1,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.5000, spread={x=32, y=32, z=32}, seed=11312, octaves=3, persist=0.6},
        y_max = -1,
        y_min = -6,
        decoration = "nodes_nature:seagrass",
        flags = "force_placement",
        param2 = 16,
    },

    {--[[Oceans:sealettuce]]
        name = "nodes_nature:sea_lettuce",
        deco_type = "simple",
        place_on = "nodes_nature:silt_wet_salty",
        place_offset_y = -1,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.5000, spread={x=32, y=32, z=32}, seed=84322, octaves=3, persist=0.6},
        y_max = -1,
        y_min = -7,
        decoration = "nodes_nature:sea_lettuce",
        flags = "force_placement",
        param2 = 16,
    },

    {--[[Oceans:nagaeo]]
        name = "nodes_nature:nagaeo",
        deco_type = "simple",
        place_on = "nodes_nature:silt_wet_salty",
        place_offset_y = -1,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.5000, spread={x=16, y=16, z=16}, seed=99310, octaves=2, persist=0.7},
        y_max = -5,
        y_min = -15,
        decoration = "nodes_nature:nagaeo",
        flags = "force_placement",
        param2 = 16,
    },

    {--[[Oceans:koaeako]]
        name = "nodes_nature:koaeako",
        deco_type = "simple",
        place_on = "nodes_nature:sand_wet_salty",
        place_offset_y = -1,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.5000, spread={x=64, y=64, z=64}, seed=80012, octaves=2, persist=0.7},
        y_max = -3,
        y_min = -10,
        decoration = "nodes_nature:koaeako",
        flags = "force_placement",
        param2 = 16,
    },

    {--[[Oceans:imoaru]]
        name = "nodes_nature:imoaru",
        deco_type = "simple",
        place_on = "nodes_nature:gravel_wet_salty",
        place_offset_y = -1,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.7000, spread={x=16, y=16, z=16}, seed=77512, octaves=2, persist=0.9},
        y_max = -1,
        y_min = -15,
        decoration = "nodes_nature:imoaru",
        flags = "force_placement",
        param2 = 16,
    },
}

return {
    sea_weeds = sea_weeds,
}
