-- Edible and toxic plants for deco.lua

-- Globals
minimal = minimal
deco = deco or {}

-- Import
local path = minetest.get_modpath("mapgen")
dofile(path.."/soils.lua")

local edible_plants = {
    {--[[wetland:Galanta]]
        name = "nodes_nature:galanta",
        deco_type = "simple",
        place_on = wetland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0040, spread={x=32, y=32, z=32}, seed=153, octaves=2, persist=0.8},
        y_max = lowland_max,
        y_min = beach_max,
        decoration = "nodes_nature:galanta",
        param2 = 4,
    },

    {--[[forest:Vansano]]
        name = "fr_nn:vansano",
        deco_type = "simple",
        place_on = forest_on,
        sidelen = 80,
        fill_ratio = 0.010000,
        y_max = lowland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:vansano",
        param2 = 2,
    },

    {--[[forest:Momo]]
        name = "fr_nn:momo_fruiting",
        deco_type = "simple",
        place_on = forest_on,
        sidelen = 80,
        fill_ratio = 0.001200,
        y_max = highland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:momo_fruiting",
        param2 = 2,
    },

    {--[[forest:Rzepicha]]
        name = "fr_nn:rzepicha_fruiting",
        deco_type = "simple",
        place_on = forest_on,
        sidelen = 80,
        fill_ratio = 0.000090,
        y_max = highland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:rzepicha_fruiting",
        param2 = 0,
    },

    {--[[forest:Malina]]
        name = "fr_nn:malina_fruiting",
        deco_type = "simple",
        place_on = forest_on,
        sidelen = 80,
        fill_ratio = 0.000700,
        y_max = highland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:malina_fruiting",
        param2 = 3,
    },

    {--[[forest:Yellow Malina]]
        name = "fr_nn:yellow_malina_fruiting",
        deco_type = "simple",
        place_on = forest_on,
        sidelen = 80,
        fill_ratio = 0.000100,
        y_max = highland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:yellow_malina_fruiting",
        param2 = 3,
    },

    {--[[forest:Zufani]]
        name = "fr_nn:zufani",
        deco_type = "simple",
        place_on = forest_on,
        sidelen = 80,
        fill_ratio = 0.000500,
        y_max = highland_max,
        y_min = beach_max,
        decoration = "nodes_nature:zufani",
        param2 = 2,
    },

    {--[[woodland:Vansano]]
        name = "wl_nn:vansano",
        deco_type = "simple",
        place_on = woodland_on,
        sidelen = 80,
        fill_ratio = 0.001000,
        y_max = lowland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:vansano",
        param2 = 2,
    },

    {--[[woodland:Momo]]
        name = "wl_nn:momo_fruiting",
        deco_type = "simple",
        place_on = woodland_on,
        sidelen = 80,
        fill_ratio = 0.001000,
        y_max = highland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:momo_fruiting",
        param2 = 2,
    },

    {--[[woodland:Rzepicha]]
        name = "wl_nn:rzepicha_fruiting",
        deco_type = "simple",
        place_on = woodland_on,
        sidelen = 80,
        fill_ratio = 0.000100,
        y_max = highland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:rzepicha_fruiting",
        param2 = 0,
    },

    {--[[woodland:Malina]]
        name = "wl_nn:malina_fruiting",
        deco_type = "simple",
        place_on = woodland_on,
        sidelen = 80,
        fill_ratio = 0.000100,
        y_max = highland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:malina_fruiting",
        param2 = 3,
    },

    {--[[woodland:Yellow Malina]]
        name = "wl_nn:yellow_malina_fruiting",
        deco_type = "simple",
        place_on = woodland_on,
        sidelen = 80,
        fill_ratio = 0.000400,
        y_max = highland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:yellow_malina_fruiting",
        param2 = 3,
    },

    {--[[woodland:Zufani]]
        name = "wl_nn:zufani",
        deco_type = "simple",
        place_on = woodland_on,
        sidelen = 80,
        fill_ratio = 0.000500,
        y_max = highland_max,
        y_min = beach_max,
        decoration = "nodes_nature:zufani",
        param2 = 2,
    },

    {--[[Grass&Shrub:Ttikusati]]
        name = "nodes_nature:tikusati",
        deco_type = "simple",
        place_on = grass_shrub_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0010, spread={x=100, y=100, z=100}, seed=1002, octaves=2, persist=0.7},
        y_max = highland_max,
        y_min = lowland_max,
        decoration = "nodes_nature:tikusati",
        param2 = 2,
    },

    {--[[Grass&Shrub:Wiha]]
        name = "nodes_nature:wiha_fruiting",
        deco_type = "simple",
        place_on = grass_shrub_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0020, spread={x=32, y=32, z=32}, seed=1003, octaves=2, persist=0.7},
        y_max = highland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:wiha_fruiting",
        param2 = 4,
    },

    {--[[Grass&Shrub:zufani]]
        name = "gs_nn:zufani",
        deco_type = "simple",
        place_on = grass_shrub_on,
        sidelen = 80,
        fill_ratio = 0.001000,
        y_max = highland_max,
        y_min = beach_max,
        decoration = "nodes_nature:zufani",
        param2 = 2,
    },

    {--[[Duneland:anperla]]
        name = "nodes_nature:anperla",
        deco_type = "simple",
        place_on = duneland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0010, spread={x=32, y=32, z=32}, seed=1112, octaves=2, persist=0.8},
        y_max = lowland_max,
        y_min = beach_max,
        decoration = "nodes_nature:anperla",
        param2 = 3,
    },

    {--[[Allbarren:Obesa]]
        name = "nodes_nature:obesa_fruitless",
        deco_type = "simple",
        place_on = barrenland_on,
        sidelen = 80,
        fill_ratio = 0.000300,
        y_max = highland_max,
        y_min = beach_max,
        decoration = "nodes_nature:obesa_fruitless",
        param2 = 0,
    },

    {--[[Allbarren:Tsaplop]]
        name = "nodes_nature:tsaplop",
        deco_type = "simple",
        place_on = barrenland_on,
        sidelen = 80,
        fill_ratio = 0.000500,
        y_max = highland_max,
        y_min = beach_max,
        decoration = "nodes_nature:tsaplop",
        param2 = 0,
    },

    -- End of edible
}

local kind_of_edible_plants = {
    {--[[richforest:merki]]
        name = "rf_nn:merki",
        deco_type = "simple",
        place_on = rich_forest_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0200, spread={x=32, y=32, z=32}, seed=1112, octaves=2, persist=0.7},
        y_max = highland_max,
        y_min = lowland_max,
        decoration = "nodes_nature:merki",
        param2 = 2,
    },

    {--[[forest:merki]]
        name = "fr_nn:merki",
        deco_type = "simple",
        place_on = forest_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0200, spread={x=32, y=32, z=32}, seed=1112, octaves=2, persist=0.7},
        y_max = highland_max,
        y_min = lowland_max,
        decoration = "nodes_nature:merki",
        param2 = 2,
    },

    {--[[woodland:ziarnoplon]]
        name = "wl_nn:ziarnoplon",
        deco_type = "simple",
        place_on = woodland_on,
        sidelen = 80,
        fill_ratio = 0.030000,
        y_max = lowland_max,
        y_min = beach_max,
        decoration = "nodes_nature:ziarnoplon",
        param2 = 3,
    },

    {--[[woodland:hakimi]]
        name = "wl_nn:hakimi",
        deco_type = "simple",
        place_on = woodland_on,
        sidelen = 80,
        fill_ratio = 0.001000,
        y_max = lowland_max,
        y_min = beach_max,
        decoration = "nodes_nature:hakimi",
        param2 = 3,
    },

    {--[[Grass&Shrub:hakimi]]
        name = "gs_nn:hakimi",
        deco_type = "simple",
        place_on = grass_shrub_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0010, spread={x=100, y=100, z=100}, seed=1004, octaves=2, persist=0.8},
        y_max = lowland_max,
        y_min = beach_max,
        decoration = "nodes_nature:hakimi",
        param2 = 3,
    },

    -- End of kind_of_edible
}

local toxic_plants = {
    {--[[wetland:marbhan]]
        name = "nodes_nature:marbhan",
        deco_type = "simple",
        place_on = wetland_on,
        sidelen = 80,
        fill_ratio = 0.001500,
        y_max = lowland_max,
        y_ min =beach_max,
        decoration = "nodes_ nature:marbhan",
        param2 = 2,
    },

    {--[[woodland:nebiyi]]
        name = "wl_nn:nebiyi",
        deco_type = "simple",
        place_on = woodland_on,
        sidelen = 80,
        fill_ratio = 0.001000,
        y_max = highland_max,
        y_min = lowland_max,
        decoration = "nodes_nature:nebiyi",
        param2 = 1,
    },

    {--[[Grassland:wrotycz]]
        name = "nodes_nature:wrotycz_flowering",
        deco_type = "simple",
        place_on = grassland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0020, spread={x=32, y=32, z=32}, seed=1003, octaves=2, persist=0.7},
        y_max = highland_max,
        y_min = beach_max,
        decoration = "nodes_nature:wrotycz_flowering",
        param2 = 1,
    },

    {--[[shrubland:nebiyi]]
        name = "sh_nn:nebiyi",
        deco_type = "simple",
        place_on = shrubland_on,
        sidelen = 80,
        fill_ratio = 0.001000,
        y_max = highland_max,
        y_min = coastal_max,
        decoration = "nodes_nature:nebiyi",
        param2 = 1,
    },

    {--[[Allbarren:Gevaari]]
        name = "nodes_nature:gevaari",
        deco_type = "simple",
        place_on = barrenland_on,
        sidelen = 80,
        fill_ratio = 0.004000,
        y_max = highland_max,
        y_min = beach_max,
        decoration = "nodes_nature:gevaari",
        param2 = 1,
    },
    -- End of toxic
}
