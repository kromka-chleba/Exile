local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local ms = mapchunk_shepherd
local nn = nodes_nature

--[[
    Compatibility with v0.3 and older v0.4-beta Exile releases.
    LBMs in this file are responsible for labeling mapchunks
    (mapblocks) that were not labeled by the shepherd's mapgen
    labeling systems (biome finders and deco finders).
--]]

local spring_labels = {
    "spring_soil",
    "seasonal_plants",
}

-- Spring soil compatibility
core.register_lbm({
        name = "nodes_nature:shepherd_spring_soil_lbm",
        label = "Spring soil finder for mapchunk shepherd",
        nodenames = nn.get_seasonal_soil_names(),
        run_at_every_load = true,
        bulk_action = function(pos_list, dtime_s)
            ms.labels_to_position(pos_list[1], spring_labels)
        end,
})

local winter_labels = {
    "winter_soil",
    "seasonal_plants",
}

-- Winter soil compatibility
core.register_lbm({
        name = "nodes_nature:shepherd_winter_soil_lbm",
        label = "Winter soil finder for mapchunk shepherd",
        nodenames = nn.get_winter_soil_names(),
        run_at_every_load = true,
        bulk_action = function(pos_list, dtime_s)
            ms.labels_to_position(pos_list[1], winter_labels)
        end,
})

-- Leaf marker compatibility
core.register_lbm({
        name = "nodes_nature:shepherd_leaf_marker_lbm",
        label = "Leaf marker finder for mapchunk shepherd",
        nodenames = {"group:leaf_marker"},
        run_at_every_load = true,
        bulk_action = function(pos_list, dtime_s)
            ms.labels_to_position(pos_list[1], {"leaves_dropped"})
        end,
})

-- Leaf compatibility
core.register_lbm({
        name = "nodes_nature:shepherd_leaf_lbm",
        label = "Leaf finder for mapchunk shepherd",
        nodenames = {"group:drops_leaves"},
        run_at_every_load = true,
        bulk_action = function(pos_list, dtime_s)
            ms.labels_to_position(pos_list[1], {"leaves"})
        end,
})

-- Wet soil compatibility
core.register_lbm({
        name = "nodes_nature:shepherd_moisture_lbm",
        label = "Wet soil finder for mapchunk shepherd",
        nodenames = {"group:wet_sediment"},
        run_at_every_load = true,
        bulk_action = function(pos_list, dtime_s)
            ms.labels_to_position(pos_list[1], "moisture_spread")
        end,
})

-- Freshwater source compatibility
core.register_lbm({
        name = "nodes_nature:shepherd_freshwater_lbm",
        label = "Freshwater finder for mapchunk shepherd",
        nodenames = {"nodes_nature:freshwater_source"},
        run_at_every_load = true,
        bulk_action = function(pos_list, dtime_s)
            ms.labels_to_position(pos_list[1], "water_gravity")
        end,
})

-- Freezing compatibility
core.register_lbm({
        name = "nodes_nature:shepherd_ice_lbm",
        label = "Ice finder for mapchunk shepherd",
        nodenames = {"nodes_nature:ice", "nodes_nature:sea_ice"},
        run_at_every_load = true,
        bulk_action = function(pos_list, dtime_s)
            ms.labels_to_position(pos_list[1], {"last_freezed"})
        end,
})

-- Snow compatibility
core.register_lbm({
        name = "nodes_nature:shepherd_snow_lbm",
        label = "Snow finder for mapchunk shepherd",
        nodenames = {"nodes_nature:snow", "nodes_nature:snow_block"},
        run_at_every_load = true,
        bulk_action = function(pos_list, dtime_s)
            ms.labels_to_position(pos_list[1], {"last_snow"})
        end,
})

-- Ocean compatibility
core.register_lbm({
        name = "nodes_nature:shepherd_ocean_lbm",
        label = "Ocean finder for mapchunk shepherd",
        nodenames = {"nodes_nature:salt_water_source"},
        run_at_every_load = true,
        bulk_action = function(pos_list, dtime_s)
            ms.labels_to_position(pos_list[1], {"ocean"})
        end,
})
