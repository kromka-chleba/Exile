-- Cave life and sediments for deco.lua

-- Globals
deco = deco or {}

-- Import
local path = minetest.get_modpath("mapgen")
dofile(path.."/soils.lua")

local cave_life = {
    {--[[Mushrooms:lambakap(foodandwater)]]
        name = "nodes_nature:lambakap",
        deco_type = "simple",
        place_on = cave_mushrooms_on,
        sidelen = 80,
        fill_ratio = 0.010000,
        y_max = -80,
        y_min = -950,
        decoration = "nodes_nature:lambakap",
        flags = "all_floors",
    },

    {--[[Mushrooms:reshedaar(woodsource)]]
        name = "nodes_nature:reshedaar",
        deco_type = "simple",
        place_on = cave_mushrooms_on,
        sidelen = 80,
        fill_ratio = 0.010000,
        y_max = -80,
        y_min = -950,
        decoration = "nodes_nature:reshedaar",
        flags = "all_floors",
    },

    {--[[Mushrooms:mahal(fibresource)]]
        name = "nodes_nature:mahal",
        deco_type = "simple",
        place_on = cave_mushrooms_on,
        sidelen = 80,
        fill_ratio = 0.010000,
        y_max = -80,
        y_min = -950,
        decoration = "nodes_nature:mahal",
        flags = "all_floors",
    },

    {--[[Underground:Cave worms on cave roof]]
        name = "nodes_nature:glow_worm",
        deco_type = "simple",
        place_on = glow_worm_on,
        sidelen = 16,
        noise_params = {offset=-0.04, scale=0.4000, spread={x=64, y=64, z=64}, seed=11002, octaves=2, persist=0.9},
        y_max = -15,
        y_min = -1000,
        decoration = "nodes_nature:glow_worm",
        flags = "all_ceilings",
        param2 = 3,
    },
}

local cave_sediments = {
    {--[[Sediments:cavegravel]]
        name = "cave_gravel",
        deco_type = "simple",
        place_on = gravel_on,
        place_offset_y = -1,
        sidelen = 04,
        noise_params = {offset=-0.50, scale=3.0000, spread={x=32, y=32, z=32}, seed=873515, octaves=2, persist=0.9},
        y_max = 31000,
        y_min = -31000,
        decoration = "nodes_nature:gravel",
        flags = "all_floors, force_placement",
    },

    {--[[Sediments:cavesand]]
        name = "cave_sand",
        deco_type = "simple",
        place_on = sand_on,
        place_offset_y = -1,
        sidelen = 04,
        noise_params = {offset=-0.50, scale=3.0000, spread={x=32, y=32, z=32}, seed=795515, octaves=2, persist=0.9},
        y_max = 31000,
        y_min = -31000,
        decoration = "nodes_nature:sand",
        flags = "all_floors, force_placement",
    },

    {--[[Sediments:caveclay]]
        name = "cave_clay",
        deco_type = "simple",
        place_on = clay_on,
        place_offset_y = -1,
        sidelen = 04,
        noise_params = {offset=-0.50, scale=3.0000, spread={x=32, y=32, z=32}, seed=87005, octaves=2, persist=0.9},
        y_max = 31000,
        y_min = -31000,
        decoration = "nodes_nature:clay",
        flags = "all_floors, force_placement",
    },

    {--[[Sediments:cavesilt]]
        name = "cave_silt",
        deco_type = "simple",
        place_on = silt_on,
        place_offset_y = -1,
        sidelen = 04,
        noise_params = {offset=-0.50, scale=3.0000, spread={x=32, y=32, z=32}, seed=87005, octaves=2, persist=0.9},
        y_max = 31000,
        y_min = -31000,
        decoration = "nodes_nature:silt",
        flags = "all_floors, force_placement",
    },

    {--[[Sediments:cavegravelwet]]
        name = "cave_gravel_w",
        deco_type = "simple",
        place_on = gravel_on,
        place_offset_y = -1,
        sidelen = 04,
        noise_params = {offset=-0.70, scale=3.0000, spread={x=32, y=32, z=32}, seed=174415, octaves=2, persist=0.9},
        y_max = 31000,
        y_min = -31000,
        decoration = "nodes_nature:gravel_wet",
        flags = "all_floors, force_placement",
    },

    {--[[Sediments:cavesandwet]]
        name = "cave_sand_w",
        deco_type = "simple",
        place_on = sand_on,
        place_offset_y = -1,
        sidelen = 04,
        noise_params = {offset=-0.70, scale=3.0000, spread={x=32, y=32, z=32}, seed=796565, octaves=2, persist=0.9},
        y_max = 31000,
        y_min = -31000,
        decoration = "nodes_nature:sand_wet",
        flags = "all_floors, force_placement",
    },

    {--[[Sediments:caveclaywet]]
        name = "cave_clay_w",
        deco_type = "simple",
        place_on = clay_on,
        place_offset_y = -1,
        sidelen = 04,
        noise_params = {offset=-0.70, scale=3.0000, spread={x=32, y=32, z=32}, seed=87005, octaves=2, persist=0.9},
        y_max = 31000,
        y_min = -31000,
        decoration = "nodes_nature:clay_wet",
        flags = "all_floors, force_placement",
    },

    {--[[Sediments:cavesiltwet]]
        name = "cave_silt_w",
        deco_type = "simple",
        place_on = silt_on,
        place_offset_y = -1,
        sidelen = 04,
        noise_params = {offset=-0.70, scale=3.0000, spread={x=32, y=32, z=32}, seed=85025, octaves=2, persist=0.9},
        y_max = 31000,
        y_min = -31000,
        decoration = "nodes_nature:silt_wet",
        flags = "all_floors, force_placement",
    },
}

