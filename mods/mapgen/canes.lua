-- Canes for deco.lua

-- Globals
deco = deco or {}

-- Import
local path = minetest.get_modpath("mapgen")
local sna = dofile(path.."/soils_and_altitudes.lua")

-- this needs investigation later
local function trash_encapsulation()
    --Cane schematics
    local canes_list   = { --- Schematics
        -- name                 y  x  z
        {"nodes_nature:gemedi", 7, 1, 1, 255, 245, 190, 190, 156,  60,  28 },
        {"nodes_nature:cana"  , 7, 1, 1, 255, 245, 190, 190, 156,  60,  28 },
        {"nodes_nature:tiken" , 7, 1, 1, 255, 255, 255, 255, 230, 155, 105 },
        {"nodes_nature:chalin", 7, 1, 1 ,255, 255, 255, 255, 230, 155, 105 },
    }

    local canes = {}
    for i in ipairs(canes_list) do --
        local shape = { name = canes_list[i][1], param2 = 2 }
        canes[i]    = {
            size = {y = canes_list[i][2],
                    x = canes_list[i][3],
                    z = canes_list[i][4]},
            data = {shape, shape, shape, shape, shape, shape, shape},
            yslice_prob = {
                {ypos = 0, prob = canes_list[i][05]},
                {ypos = 1, prob = canes_list[i][06]},
                {ypos = 2, prob = canes_list[i][07]},
                {ypos = 3, prob = canes_list[i][08]},
                {ypos = 4, prob = canes_list[i][09]},
                {ypos = 5, prob = canes_list[i][10]},
                {ypos = 6, prob = canes_list[i][11]},
            },
        }
    end

    return canes[1], canes[2], canes[3], canes[4]
end

local gemedi, cana, tiken, chalin = trash_encapsulation()

local cane_list = {
    {--[[wetland:cana]]
        name = "sf_nn:cana",
        deco_type = "schematic",
        place_on = sna.wetland_on,
        sidelen = 80,
        fill_ratio = 0.008000,
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        schematic = cana,
    },

    {--[[Marshland:cana]]
        name = "nodes_nature:cana",
        deco_type = "schematic",
        place_on = sna.marshland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=2.0000, spread={x=16, y=16, z=16},
                        seed=578, octaves=3, persist=0.7},
        y_max = sna.coastal_max+5,
        y_min = sna.beach_max,
        schematic = cana,
    },

    {--[[Grassland:gemedi]]
        name = "nodes_nature:gemedi",
        deco_type = "schematic",
        place_on = sna.grassland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=1.0000, spread={x=128, y=128, z=128},
                        seed=998, octaves=2, persist=0.8},
        y_max = sna.coastal_max,
        y_min = sna.beach_max,
        schematic = gemedi,
    },

    {--[[forestChalin]]
        name = "fr_nn:chalin",
        deco_type = "schematic",
        place_on = sna.forest_on,
        sidelen = 80,
        fill_ratio = 0.008000,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        schematic = chalin,
    },

    {--[[woodlandChalinclumps]]
        name = "wl_nn:chalin",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.1000, spread={x=16, y=16, z=16},
                        seed=1881, octaves=2, persist=1},
        y_max = sna.lowland_max+10,
        y_min = sna.beach_max,
        schematic = chalin,
    },

    {--[[woodlandChalinclumps_rare upland]]
        name = "wl_ul_nn:chalin",
        deco_type = "schematic",
        place_on = sna.woodland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0200, spread={x=16, y=16, z=16},
                        seed=1881, octaves=2, persist=0.7},
        y_max = sna.upland_max-10,
        y_min = sna.lowland_max,
        schematic = chalin,
    },

    {--[[ShrublandChalinclumps]]
        name = "sh_nn:chalin",
        deco_type = "schematic",
        place_on = sna.shrubland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.1000, spread={x=16, y=16, z=16},
                        seed=1881, octaves=3, persist=1},
        y_max = sna.lowland_max,
        y_min = sna.beach_max,
        schematic = chalin,
    },

    {--[[ShrublandChalinclumps_rare upland]]
        name = "sh_ul_nn:chalin",
        deco_type = "schematic",
        place_on = sna.shrubland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0300, spread={x=16, y=16, z=16},
                        seed=1881, octaves=2, persist=0.7},
        y_max = sna.upland_max-10,
        y_min = sna.lowland_max,
        schematic = chalin,
    },

    {--[[Duneland:tiken]]
        name = "nodes_nature:tiken",
        deco_type = "schematic",
        place_on = sna.duneland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=1.0000, spread={x=64, y=64, z=64},
                        seed=998, octaves=2, persist=0.9},
        y_max = sna.beach_max+3,
        y_min = sna.beach_max,
        schematic = tiken,
    },

    {--[[Duneland:Saguati]]
        name = "saguati",
        deco_type = "schematic",
        place_on = sna.duneland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0300, spread={x=64, y=64, z=64},
                        seed=998, octaves=2, persist=0.7},
        y_max = sna.upland_max,
        y_min = sna.beach_max + 1,
        schematic = deco.find_schematic("saguati"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Duneland:Saguati tall]]
        name = "saguati_tall",
        deco_type = "schematic",
        place_on = sna.duneland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0150, spread={x=64, y=64, z=64},
                        seed=997, octaves=2, persist=0.7},
        y_max = sna.upland_max,
        y_min = sna.beach_max + 3,
        schematic = deco.find_schematic("saguati_tall"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Duneland:Saguati short]]
        name = "saguati_short",
        deco_type = "schematic",
        place_on = sna.duneland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0150, spread={x=64, y=64, z=64},
                        seed=996, octaves=2, persist=0.7},
        y_max = sna.upland_max,
        y_min = sna.beach_max + 2,
        schematic = deco.find_schematic("saguati_short"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },


    {--[[Allbarren:Saguati]]
        name = "bl_saguati",
        deco_type = "schematic",
        place_on = sna.barrenland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0003, spread={x=64, y=64, z=64},
                        seed=998, octaves=2, persist=0.7},
        y_max = sna.lowland_max,
        y_min = sna.beach_max + 1,
        schematic = deco.find_schematic("saguati"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Allbarren:Saguati tall]]
        name = "bl_saguati_tall",
        deco_type = "schematic",
        place_on = sna.barrenland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.00015, spread={x=64, y=64, z=64},
                        seed=997, octaves=2, persist=0.7},
        y_max = sna.upland_max,
        y_min = sna.beach_max + 3,
        schematic = deco.find_schematic("saguati_tall"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Allbarren:Saguati short]]
        name = "bl_saguati_short",
        deco_type = "schematic",
        place_on = sna.barrenland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.00015, spread={x=64, y=64, z=64},
                        seed=996, octaves=2, persist=0.7},
        y_max = sna.upland_max,
        y_min = sna.beach_max + 2,
        schematic = deco.find_schematic("saguati_short"),
        flags = "place_center_x, place_center_z",
        rotation = "random",
    },

    {--[[Allbarren:tiken]]
        name = "bl_nn:tiken",
        deco_type = "schematic",
        place_on = sna.barrenland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0020, spread={x=64, y=64, z=64},
                        seed=998, octaves=2, persist=0.9},
        y_max = sna.beach_max+3,
        y_min = sna.beach_max,
        schematic = tiken,
    },

}

return {
    cane_list = cane_list,
}
