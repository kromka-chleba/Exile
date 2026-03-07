-- Trees for deco.lua

-- Globals
minimal = minimal
deco = deco or {}

-- Import
local path = minetest.get_modpath("mapgen")
local sna = dofile(path.."/soils_and_altitudes.lua")

local tree_list = {
    -- this is empty
    -- trees are added at the bottom of the file!
    -- list names:
    -- daoja_swamp_trees, forest_trees, woodland_trees
    -- open_woodland_trees
    -- grassland_trees, shrubland_trees, water_trees
}

------------------------------------------

local daoja_swamp_trees = {
    {--[[Trees:daoja forest upland]]
        name = "swamp_daoja",
        deco_type = "schematic",
        place_on = sna.swamp_forest_on,
        place_offset_y = -2,
        sidelen = 80,
        fill_ratio = 0.012000,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("daoja"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },
}

local forest_trees = {
    {--[[Trees:dominant coastal amma forest]]
        name = "amma_forest_coast",
        deco_type = "schematic",
        place_on = sna.forest_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.007000,
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("amma"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:dominant tulatula forest]]
        name = "tulatula_forest_ll",
        deco_type = "schematic",
        place_on = sna.forest_on,
        place_offset_y = -6,
        sidelen = 80,
        fill_ratio = 0.019000,
        y_max = sna.lowland_max,
        y_min = sna.coastal_max,
        --large schematic size causes issues maybe?
        --has unusual gaps for some reason?
        schematic = deco.find_schematic("tulatula"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:dominant tulatula young forest]]
        name = "tulatula_forest_ll_young",
        deco_type = "schematic",
        place_on = sna.forest_on,
        place_offset_y = -3,
        sidelen = 80,
        fill_ratio = 0.015000,
        y_max = sna.lowland_max + 2,
        y_min = sna.coastal_max - 2,
        schematic = deco.find_schematic("tulatula_young"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:understory lowland amma forest]]
        name = "amma_forest_ll",
        deco_type = "schematic",
        place_on = sna.forest_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.001000,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("amma"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:dominant amma forest upland]]
        name = "amma_forest_upl",
        deco_type = "schematic",
        place_on = sna.forest_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.006000,
        y_max = sna.upland_max,
        y_min = sna.lowland_max,
        schematic = deco.find_schematic("amma"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare sasaran in forest]]
        name = "sasaran_f_lland",
        deco_type = "schematic",
        place_on = sna.forest_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.000500,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("sasaran1"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:common panasee in forest]]
        name = "panasee_forest",
        deco_type = "schematic",
        place_on = sna.forest_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000800,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("panasee"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

}

local woodland_trees = {
    {--[[Trees:rare amma woodland]]
        name = "amma_w_lland",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.000600,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("amma"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:dominant sasaran in woodland]]
        name = "sasaran_w_lland",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.005500,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("sasaran1"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare panasee in woodland]]
        name = "panasee_woodland",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000100,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("panasee"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare Jalowiec in woodland]]
        name = "jalowiec1_woodland",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000150,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("jalowiec1"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare Jalowiec in woodland]]
        name = "jalowiec2_woodland",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000150,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("jalowiec2"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare Jalowiec in woodland]]
        name = "jalowiec3_woodland",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000200,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("jalowiec3"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare Jalowiec in woodland]]
        name = "jalowiec4_woodland",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000200,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("jalowiec4"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare tulatula in woodland]]
        name = "tulatula_woodland",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        place_offset_y = -6,
        sidelen = 80,
        fill_ratio = 0.000020,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("tulatula"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare young tulatula in woodland]]
        name = "tulatula_woodland_young",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        place_offset_y = -3,
        sidelen = 80,
        fill_ratio = 0.000020,
        y_max = sna.lowland_max +5,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("tulatula_young"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },
}

local open_woodland_trees = {
    {--[[Trees:dominant clumped warungaree in open woodland]]
        name = "warungaree_tree_ow_lland",
        deco_type = "schematic",
        place_on = sna.open_woodland_on,
        place_offset_y = -3,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0095, spread={x=50, y=50, z=50}, seed=772, octaves=2, persist=0.6},
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("warungaree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:dominant scattered warungaree in open woodland]]
        name = "warungaree_tree_ow_lland_scat",
        deco_type = "schematic",
        place_on = sna.open_woodland_on,
        place_offset_y = -3,
        sidelen = 80,
        fill_ratio = 0.002250,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("warungaree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare amma open woodland]]
        name = "amma_ow_lland",
        deco_type = "schematic",
        place_on = sna.open_woodland_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.000100,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("amma"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare sasaran in open woodland]]
        name = "sasaran_ow_lland",
        deco_type = "schematic",
        place_on = sna.open_woodland_on,
        place_offset_y = -4,
        sidelen = 80,
        fill_ratio = 0.000200,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("sasaran1"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:common clumped maraka in open woodland]]
        name = "maraka_tree_ow_lland",
        deco_type = "schematic",
        place_on = sna.open_woodland_on,
        place_offset_y = -3,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0020, spread={x=250, y=250, z=250}, seed=902, octaves=2, persist=0.6},
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("maraka_tree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:scattered maraka in open woodland]]
        name = "maraka_tree_ow_lland_scat",
        deco_type = "schematic",
        place_on = sna.open_woodland_on,
        place_offset_y = -3,
        sidelen = 80,
        fill_ratio = 0.000500,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("maraka_tree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:rare panasee in open woodland]]
        name = "panasee_open_woodland",
        deco_type = "schematic",
        place_on = sna.open_woodland_on,
        place_offset_y = -1,
        sidelen = 80,
        fill_ratio = 0.000020,
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("panasee"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

}


local grassland_trees = {
    {--[[Trees:old tangkal in grassland]]
        name = "grass_tangkal_tree_old",
        deco_type = "schematic",
        place_on = sna.grassland_on,
        place_offset_y = -5,
        sidelen = 80,
        fill_ratio = 0.000010,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("tangkal_old"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:adult tangkal in grassland]]
        name = "grass_tangkal_tree",
        deco_type = "schematic",
        place_on = sna.grassland_on,
        place_offset_y = -5,
        sidelen = 80,
        fill_ratio = 0.000020,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("tangkal_tree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:young tangkal in grassland]]
        name = "grass_tangkal_tree_young",
        deco_type = "schematic",
        place_on = sna.grassland_on,
        place_offset_y = -3,
        sidelen = 80,
        fill_ratio = 0.000010,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("tangkal_young"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:maraka in grassland]]
        name = "grass_maraka_tree",
        deco_type = "schematic",
        place_on = sna.grassland_on,
        place_offset_y = -3,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0005, spread={x=250, y=250, z=250}, seed=222, octaves=2, persist=0.8},
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("maraka_tree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

}

local shrubland_trees = {
    {--[[Trees:old tangkal in shrubland]]
        name = "shrub_tangkal_tree_old",
        deco_type = "schematic",
        place_on = sna.shrubland_on,
        place_offset_y = -5,
        sidelen = 80,
        fill_ratio = 0.000015,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("tangkal_old"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:adult tangkal in shrubland]]
        name = "shrub_tangkal_tree",
        deco_type = "schematic",
        place_on = sna.shrubland_on,
        place_offset_y = -5,
        sidelen = 80,
        fill_ratio = 0.000025,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("tangkal_tree"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:young tangkal in shrubland]]
        name = "shrub_tangkal_tree_young",
        deco_type = "schematic",
        place_on = sna.shrubland_on,
        place_offset_y = -3,
        sidelen = 80,
        fill_ratio = 0.000015,
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("tangkal_young"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Trees:maraka in shrubland]]
        name = "shrub_maraka_tree",
        deco_type = "schematic",
        place_on = sna.shrubland_on,
        place_offset_y = -3,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0009, spread={x=250, y=250, z=250}, seed=222, octaves=2, persist=0.6},
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("maraka_tree"),
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

local barrenland_trees = {

    {--[[Trees:very rare maraka in barrenland]]
        name = "bl_maraka_tree",
        deco_type = "schematic",
        place_on = sna.barrenland_on,
        place_offset_y = -3,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.00025, spread={x=250, y=250, z=250}, seed=222, octaves=2, persist=0.6},
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = deco.find_schematic("maraka_tree"),
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
            open_woodland_trees,
            grassland_trees,
            shrubland_trees,
            water_trees,
            barrenland_trees,
    })

return {
    tree_list = tree_list,
}
