-- Eggs for deco.lua

-- Globals
deco = deco or {}

-- Import
local path = minetest.get_modpath("mapgen")
local sna = dofile(path.."/soils_and_altitudes.lua")

-- MAPGEN SPECIFIC EGG BUNCHES
-- pegasun
animals.register_egg({
  name = "mapgen:pegasun_bunch",
  egg_hatching = {
    ["animals:pegasun"] = 0.8,
    "animals:pegasun_male"
  },
  egg_time = 5,
  young_per_egg = {3,5},
  energy_egg = 20000, -- will be divided by 3 or 5 give or take
  groups = {timer = 2}
})

-- chichasa
animals.register_egg({
    name = "mapgen:chichasa_bunch",
    egg_hatching = {
      ["animals:chichasa"] = 0.8,
      "animals:chichasa_male"
    },
    egg_time = 5,
    young_per_egg = {3,5},
    energy_egg = 20000, -- will be divided by 3 or 5 give or take
    groups = {timer = 2}
  })
  

local eggs = {
    {--[[Animals:gundu]]
        name = "animals:gundu_eggs",
        deco_type = "simple",
        place_on = sna.fish_on,
        sidelen = 80,
        fill_ratio = 0.000400,
        y_max = -3,
        y_min = -25,
        decoration = "animals:gundu_eggs",
        flags = "force_placement",
    },

    {--[[Animals:sarkamos]]
        name = "animals:sarkamos_eggs",
        deco_type = "simple",
        place_on = sna.fish_on,
        sidelen = 80,
        fill_ratio = 0.000060,
        y_max = -5,
        y_min = -35,
        decoration = "animals:sarkamos_eggs",
        flags = "force_placement",
    },

    {--[[Animals:impethu]]
        name = "animals:impethu_eggs",
        deco_type = "simple",
        place_on = sna.cave_egg_on,
        sidelen = 80,
        fill_ratio = 0.005000,
        y_max = sna.lowland_max,
        y_min = -950,
        decoration = "animals:impethu_eggs",
        flags = "all_floors",
    },

    {--[[Animals:kubwakubwa]]
        name = "animals:kubwakubwa_eggs",
        deco_type = "simple",
        place_on = sna.cave_egg_on,
        sidelen = 80,
        fill_ratio = 0.001500,
        y_max = sna.lowland_max,
        y_min = -150,
        decoration = "animals:kubwakubwa_eggs",
        flags = "all_floors",
    },

    {--[[Animals:kubwakubwabarrenland]]
        name = "animals:kubwakubwa_eggs_barren",
        deco_type = "simple",
        place_on = sna.barrenland_on,
        sidelen = 80,
        fill_ratio = 0.000500,
        y_max = sna.highland_max,
        y_min = sna.coastal_max,
        decoration = "animals:kubwakubwa_eggs",
        flags = "all_floors",
    },

    {--[[Animals:kubwakubwaforest]]
        name = "animals:kubwakubwa_eggs_forest",
        deco_type = "simple",
        place_on = sna.forest_on,
        sidelen = 80,
        fill_ratio = 0.000500,
        y_max = sna.highland_max,
        y_min = sna.coastal_max,
        decoration = "animals:kubwakubwa_eggs",
        flags = "all_floors",
    },

    {--[[Animals:darkasthaan]]
        name = "animals:darkasthaan_eggs",
        deco_type = "simple",
        place_on = sna.cave_egg_on,
        sidelen = 80,
        fill_ratio = 0.002000,
        y_max = -130,
        y_min = -950,
        decoration = "animals:darkasthaan_eggs",
        flags = "all_floors",
    },

    {--[[Animals:pegasun-badlands]]
        name = "animals:pegasun_eggs_badland",
        deco_type = "simple",
        place_on = sna.badland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0008, spread={x=64, y=64, z=64},
                        seed=1882, octaves=1, persist=1},
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        decoration = "mapgen:pegasun_bunch",
        flags = "all_floors",
    },

    {--[[Animals:pegasun-notbadlands]]
        name = "animals:pegasun_eggs",
        deco_type = "simple",
        place_on = sna.not_badland_soils_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0016, spread={x=64, y=64, z=64},
                        seed=1882, octaves=1, persist=1},
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        decoration = "mapgen:pegasun_bunch",
        flags = "all_floors",
    },

        {--[[Animals:chichasa-badlands]]
        name = "animals:chichasa_eggs_badland",
        deco_type = "simple",
        place_on = sna.badland_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0008, spread={x=64, y=64, z=64},
                        seed=1080, octaves=1, persist=1},
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        decoration = "mapgen:chichasa_bunch",
        flags = "all_floors",
    },

    {--[[Animals:chichasa-notbadlands]]
        name = "animals:chichasa_eggs",
        deco_type = "simple",
        place_on = sna.not_badland_soils_on,
        sidelen = 16,
        noise_params = {offset=0.00, scale=0.0016, spread={x=64, y=64, z=64},
                        seed=1080, octaves=1, persist=1},
        y_max = sna.upland_max,
        y_min = sna.beach_max,
        decoration = "mapgen:chichasa_bunch",
        flags = "all_floors",
    },

    {--[[Animals:sneachan-badlands]]
        name = "animals:sneachan_eggs_badland",
        deco_type = "simple",
        place_on = sna.badland_on,
        sidelen = 80,
        fill_ratio = 0.001000,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "animals:sneachan_eggs",
        flags = "all_floors",
    },

    {--[[Animals:sneachan-notbadlands]]
        name = "animals:sneachan_eggs",
        deco_type = "simple",
        place_on = sna.not_badland_soils_on,
        sidelen = 80,
        fill_ratio = 0.001500,
        y_max = sna.highland_max,
        y_min = sna.beach_max,
        decoration = "animals:sneachan_eggs",
        flags = "all_floors",
    },
}

return {
    eggs = eggs,
}
