-- Trees for deco.lua

-- Globals
minimal = minimal
deco = deco or {}

-- Import
local path = minetest.get_modpath("mapgen")
dofile(path.."/soils_and_altitudes.lua")

local tree_list = {
    -- this is empty
    -- trees are added at the bottom of the file!
    -- list names:
    -- daoja_swamp_trees, forest_trees, woodland_trees
    -- grassland_trees, shrubland_trees, water_trees
}

------------------------------------------

local daoja_swamp_trees = {
    {--[[Trees:daoja forest upland]]
        name = "swamp_daoja",
        deco_type = "schematic",
        place_on = swamp_forest_on,
        place_offset_y = -2,
        sidelen = 80,
        fill_ratio = 0.012000,
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("daoja"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },
}

local forest_trees = {
    {--[[Trees:dominant amma forest]]
        name = "amma_forest_ll",
        deco_type = "schematic",
        place_on = forest_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.007000,
        y_max = lowland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("amma"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:dominant amma forest upland]]
        name = "amma_forest_upl",
        deco_type = "schematic",
        place_on = forest_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.006000,
        y_max = upland_max,
        y_min = lowland_max,
        schematic = deco.find_schematic("amma"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare sasaran in forest]]
        name = "sasaran_f_lland",
        deco_type = "schematic",
        place_on = forest_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.000500,
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("sasaran1"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },
    
    {--[[Trees:common panasee in forest]]
        name = "panasee_forest",
        deco_type = "schematic",
        place_on = forest_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000800,
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("panasee"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

}

local woodland_trees = {
    {--[[Trees:rare amma woodland]]
        name = "amma_w_lland",
        deco_type = "schematic",
        place_on = woodland_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.000600,
        y_max = lowland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("amma"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:dominant sasaran in woodland]]
        name = "sasaran_w_lland",
        deco_type = "schematic",
        place_on = woodland_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.005500,
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("sasaran1"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare panasee in woodland]]
        name = "panasee_woodland",
        deco_type = "schematic",
        place_on = woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000100,
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("panasee"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare Jalowiec in woodland]]
        name = "jalowiec1_woodland",
        deco_type = "schematic",
        place_on = woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000150,
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("jalowiec1"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare Jalowiec in woodland]]
        name = "jalowiec2_woodland",
        deco_type = "schematic",
        place_on = woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000150,
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("jalowiec2"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare Jalowiec in woodland]]
        name = "jalowiec3_woodland",
        deco_type = "schematic",
        place_on = woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000200,
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("jalowiec3"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare Jalowiec in woodland]]
        name = "jalowiec4_woodland",
        deco_type = "schematic",
        place_on = woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000200,
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("jalowiec4"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },
}

local grassland_trees = {
    {--[[Trees:old tangkal in grassland]]
        name = "grass_tangkal_tree_old",
        deco_type = "schematic",
        place_on = grassland_on,
        place_offset_y = -5,
        sidelen = 80,
        fill_ratio = 0.000010,
        y_max = lowland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("tangkal_old"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:adult tangkal in grassland]]
        name = "grass_tangkal_tree",
        deco_type = "schematic",
        place_on = grassland_on,
        place_offset_y = -5,
        sidelen = 80,
        fill_ratio = 0.000020,
        y_max = lowland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("tangkal_tree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:young tangkal in grassland]]
        name = "grass_tangkal_tree_young",
        deco_type = "schematic",
        place_on = grassland_on,
        place_offset_y = -3,
        sidelen = 80,
        fill_ratio = 0.000010,
        y_max = lowland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("tangkal_young"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:maraka in grassland]]
        name = "grass_maraka_tree",
        deco_type = "schematic",
        place_on = grassland_on,
        place_offset_y = -3,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0005, spread={x=250, y=250, z=250}, seed=222, octaves=2, persist=0.8},
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("maraka_tree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },
}

local shrubland_trees = {
    {--[[Trees:old tangkal in shrubland]]
        name = "shrub_tangkal_tree_old",
        deco_type = "schematic",
        place_on = shrubland_on,
        place_offset_y = -5,
        sidelen = 80,
        fill_ratio = 0.000030,
        y_max = lowland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("tangkal_old"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:adult tangkal in shrubland]]
        name = "shrub_tangkal_tree",
        deco_type = "schematic",
        place_on = shrubland_on,
        place_offset_y = -5,
        sidelen = 80,
        fill_ratio = 0.000050,
        y_max = lowland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("tangkal_tree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:young tangkal in shrubland]]
        name = "shrub_tangkal_tree_young",
        deco_type = "schematic",
        place_on = shrubland_on,
        place_offset_y = -3,
        sidelen = 80,
        fill_ratio = 0.000030,
        y_max = lowland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("tangkal_young"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:maraka in shrubland]]
        name = "shrub_maraka_tree",
        deco_type = "schematic",
        place_on = shrubland_on,
        place_offset_y = -3,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0009, spread={x=250, y=250, z=250}, seed=222, octaves=2, persist=0.6},
        y_max = upland_max,
        y_min = beach_max,
        schematic = deco.find_schematic("maraka_tree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare panasee in shrubland]]
        name = "panasee_shrubland",
        deco_type = "schematic",
        place_on = shrubland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000030,
        y_max = coastal_max,
        y_min = beach_max,
        schematic = deco.find_schematic("panasee"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },
}

local water_trees = {
    {--[[Trees:kagum on salty silt]]
        name = "nodes_nature:kagum_tree",
        deco_type = "schematic",
        place_on = "nodes_nature:silt_wet_salty",
        place_offset_y = 0,
        sidelen = 80,
        noise_params = {offset=0.00, scale=0.0450, spread={x=128, y=128, z=128}, seed=51122, octaves=3, persist=0.6},
        y_max = 1,
        y_min = -1,
        schematic = deco.find_schematic("kagum1"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },
}

-----------------------------------------------------------

-- All together
-- this gets imported in 
tree_list =
    minimal.concat_tables({
            daoja_swamp_trees,
            forest_trees,
            woodland_trees,
            grassland_trees
            shrubland_trees,
            water_trees,
    })
