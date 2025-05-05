-- Fibrous and woody plants for deco.lua

-- Globals
minimal = minimal
deco = deco or {}

-- Import
local path = minetest.get_modpath("mapgen")
local sna = dofile(path.."/soils_and_altitudes.lua")

local fibrous_plants = {
    {--[[wetland:tanai]]
        name = "nodes_nature:tanai",
        deco_type = "simple",
        place_on = sna.wetland_on,
        sidelen = 80,
        fill_ratio = 0.650000,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:tanai",
        param2 = 4,
    },

    {--[[wetland:cantapo]]
        name = "nodes_nature:cantapo",
        deco_type = "simple",
        place_on = sna.wetland_on,
        sidelen = 80,
        fill_ratio = 0.650000,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:cantapo",
        param2 = 4,
    },

    {--[[richforest:damo]]
        name = "nodes_nature:damo",
        deco_type = "simple",
        place_on = sna.rich_forest_on,
        sidelen = 80,
        fill_ratio = 0.650000,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:damo",
        param2 = 4,
    },

    {--[[richforest:jalakin]]
        name = "rfr_nn:jalakin",
        deco_type = "simple",
        place_on = sna.rich_forest_on,
        sidelen = 80,
        fill_ratio = 0.650000,
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:jalakin",
        param2 = 2,
    },

    {--[[forest:damo]]
        name = "fr_nn:damo",
        deco_type = "simple",
        place_on = sna.forest_on,
        sidelen = 80,
        fill_ratio = 0.030000,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:damo",
        param2 = 4,
    },

    {--[[forest:jalakin]]
        name = "fr_nn:jalakin",
        deco_type = "simple",
        place_on = sna.forest_on,
        sidelen = 80,
        fill_ratio = 0.030000,
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:jalakin",
        param2 = 2,
    },

    {--[[woodland:damo]]
        name = "wl_nn:damo",
        deco_type = "simple",
        place_on = sna.woodland_on,
        sidelen = 80,
        fill_ratio = 0.300000,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:damo",
        param2 = 4,
    },

    {--[[woodland:jalakin]]
        name = "wl_nn:jalakin",
        deco_type = "simple",
        place_on = sna.woodland_on,
        sidelen = 80,
        fill_ratio = 0.300000,
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:jalakin",
        param2 = 2,
    },

    {--[[woodland:damo upland]]
        name = "wl_ul_nn:damo",
        deco_type = "simple",
        place_on = sna.woodland_on,
        sidelen = 80,
        fill_ratio = 0.050000,
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:damo",
        param2 = 4,
    },

    {--[[woodland:sari]]
        name = "wl_nn:sari",
        deco_type = "simple",
        place_on = sna.woodland_on,
        sidelen = 80,
        fill_ratio = 0.200000,
        y_max = sna.highland_max,
        y_min = sna.lowland_max,
        decoration = "nodes_nature:sari",
        param2 = 2,
    },

    {--[[Grassland:sari]]
        name = "gr_nn:sari",
        deco_type = "simple",
        place_on = sna.grassland_on,
        sidelen = 80,
        fill_ratio = 0.500000,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:sari",
        param2 = 2,
    },

    {--[[Grassland:kemta]]
        name = "gr_nn:kemta",
        deco_type = "simple",
        place_on = sna.grassland_on,
        sidelen = 80,
        fill_ratio = 0.500000,
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:kemta",
        param2 = 3,
    },

    {--[[Shrubland:kemta]]
        name = "sh_nn:kemta",
        deco_type = "simple",
        place_on = sna.shrubland_on,
        sidelen = 80,
        fill_ratio = 0.200000,
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:kemta",
        param2 = 3,
    },

    {--[[Shrubland:sari]]
        name = "sh_nn:sari",
        deco_type = "simple",
        place_on = sna.shrubland_on,
        sidelen = 80,
        fill_ratio = 0.250000,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:sari",
        param2 = 2,
    },

    {--[[shrubland:damo]]
        name = "sh_nn:damo",
        deco_type = "simple",
        place_on = sna.shrubland_on,
        sidelen = 80,
        fill_ratio = 0.100000,
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:damo",
        param2 = 4,
    },

    {--[[shrubland:jalakin]]
        name = "sh_nn:jalakin",
        deco_type = "simple",
        place_on = sna.shrubland_on,
        sidelen = 80,
        fill_ratio = 0.100000,
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:jalakin",
        param2 = 2,
    },

    {--[[Duneland:alaf-highland]]
        name = "hl_nn:alaf",
        deco_type = "simple",
        place_on = sna.duneland_on,
        sidelen = 80,
        fill_ratio = 0.050000,
        y_max = sna.highland_max,
        y_min = sna.upland_max,
        decoration = "nodes_nature:alaf",
        param2 = 4,
    },

    {--[[Duneland:alaf]]
        name = "nodes_nature:alaf",
        deco_type = "simple",
        place_on = sna.duneland_on,
        sidelen = 80,
        fill_ratio = 0.100000,
        y_max = sna.upland_max,
        y_min = sna.land_min,
        decoration = "nodes_nature:alaf",
        param2 = 4,
    },

    {--[[Allbarren:Tashvish]]
        name = "nodes_nature:tashvish",
        deco_type = "simple",
        place_on = sna.barrenland_on,
        sidelen = 80,
        fill_ratio = 0.110000,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:tashvish",
        param2 = 4,
    },

    {--[[Highland:thoka]]
        name = "nodes_nature:thoka",
        deco_type = "simple",
        place_on = sna.highland_on,
        sidelen = 80,
        fill_ratio = 0.300000,
        y_max = 31000,
        y_min = sna.upland_max,
        decoration = "nodes_nature:thoka",
        param2 = 4,
    },
    -- End of fibrous_plants
}

local woody_plants = {
    {--[[Marshland:bronach]]
        name = "nodes_nature:bronach",
        deco_type = "simple",
        place_on = sna.marshland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0700, spread={x=16, y=16, z=16},
                        seed=1707, octaves=2, persist=0.9},
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:bronach",
        param2 = 3,
    },

    {--[[woodland:badyl]]
        name = "wl_nn:badyl",
        deco_type = "simple",
        place_on = sna.woodland_on,
        sidelen = 80,
        fill_ratio = 0.010000,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:badyl",
        param2 = 0,
    },

    {--[[Grassland:gitiri]]
        name = "gr_nn:gitiri",
        deco_type = "simple",
        place_on = sna.grassland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0500, spread={x=32, y=32, z=32},
                        seed=1001, octaves=2, persist=0.6},
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:gitiri",
        param2 = 2,
    },

    {--[[Grassland:orylsar]]
        name = "gr_nn:orylsar",
        deco_type = "simple",
        place_on = sna.grassland_on,
        sidelen = 80,
        fill_ratio = 0.000100,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:orylsar",
        param2 = 3,
    },

    {--[[Shrubland:gitiri]]
        name = "sh_nn:gitiri",
        deco_type = "simple",
        place_on = sna.shrubland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.2000, spread={x=32, y=32, z=32},
                        seed=1001, octaves=2, persist=0.6},
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:gitiri",
        param2 = 2,
    },

    {--[[Shrubland:orylsar]]
        name = "sh_nn:orylsar",
        deco_type = "simple",
        place_on = sna.shrubland_on,
        sidelen = 80,
        fill_ratio = 0.050000,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:orylsar",
        param2 = 3,
    },


    {--[[Duneland:Drapacz]]
        name = "dl_nn:drapacz",
        deco_type = "simple",
        place_on = sna.duneland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0200, spread={x=16, y=16, z=16},
                        seed=1377, octaves=2, persist=0.7},
        y_max = sna.lowland_max,
        y_min = sna.beach_max + 3,
        decoration = "nodes_nature:drapacz",
        param2 = 0,
    },

    {--[[Allbarren:Jogalan]]
        name = "bl_nn:jogalan",
        deco_type = "simple",
        sidelen = 16,
        place_on = sna.barrenland_on,
        noise_params = {offset=0.00, scale=0.0250, spread={x=16, y=16, z=16},
                        seed=7777, octaves=2, persist=0.75},
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:jogalan",
        param2 = 0,
    },
    -- End of woody_plants
}

local moss_and_stuff = {
    {--[[wetland:denser moss in marsh]]
        name = "wl_nn:moss",
        deco_type = "simple",
        place_on = sna.wetland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.4000, spread={x=16, y=16, z=16},
                        seed=1640, octaves=2, persist=0.8},
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:moss",
    },

    {--[[forest:denser moss]]
        name = "fr_nn:moss",
        deco_type = "simple",
        place_on = sna.forest_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.6000, spread={x=16, y=16, z=16},
                        seed=1640, octaves=2, persist=0.7},
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:moss",
    },

    {--[[forest:urimi]]
        name = "fr_nn:urimi",
        deco_type = "simple",
        place_on = sna.forest_on,
        sidelen = 80,
        fill_ratio = 0.100000,
        y_max = sna.lowland_max,
        y_min = sna.coastal_max,
        decoration = "nodes_nature:urimi",
        param2 = 2,
    },

    {--[[all:moss]]
        name = "all_nn:moss",
        deco_type = "simple",
        place_on = sna.not_badland_soils_on,
        sidelen = 80,
        fill_ratio = 0.001000,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:moss",
    },

    {--[[all:moss]]
        name = "bl_nn:moss",
        deco_type = "simple",
        place_on = sna.badland_on,
        sidelen = 80,
        fill_ratio = 0.000300,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:moss",
    },

    {--[[Allbarren:Orom]]
        name = "nodes_nature:orom",
        deco_type = "simple",
        place_on = sna.barrenland_on,
        sidelen = 80,
        fill_ratio = 0.000100,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        decoration = "nodes_nature:orom",
        param2 = 1,
    },

    {--[[Allbarren:Veke]]
        name = "nodes_nature:veke",
        deco_type = "simple",
        place_on = sna.barrenland_on,
        sidelen = 80,
        fill_ratio = 0.000100,
        y_max = 31000,
        y_min = sna.lowland_max,
        decoration = "nodes_nature:veke",
        param2 = 0,
    },
}

return {
    fibrous_plants = fibrous_plants,
    woody_plants = woody_plants,
    moss_and_stuff = moss_and_stuff,
}
