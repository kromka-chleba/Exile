-- Eggs for deco.lua

-- Globals
deco = deco or {}

-- Import
local path = minetest.get_modpath("mapgen")
local sna = dofile(path.."/soils_and_altitudes.lua")

local eggs = {
   {--[[Animals:gundu]]
      name = "animals:gundu_eggs",
      deco_type = "simple",
      place_on = sna.fish_on,
      sidelen = 80,
      fill_ratio = 0.000500,
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
      fill_ratio = 0.000070,
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
      noise_params = {offset=0.00, scale=0.0015, spread={x=64, y=64, z=64},
                      seed=1882, octaves=2, persist=2},
      y_max = sna.upland_max,
      y_min = sna.beach_max,
      decoration = "animals:pegasun_eggs",
      flags = "all_floors",
   },

   {--[[Animals:pegasun-notbadlands]]
      name = "animals:pegasun_eggs",
      deco_type = "simple",
      place_on = sna.not_badland_soils_on,
      sidelen = 16,
      noise_params = {offset=0.00, scale=0.0030, spread={x=64, y=64, z=64},
                      seed=1882, octaves=2, persist=2},
      y_max = sna.upland_max,
      y_min = sna.beach_max,
      decoration = "animals:pegasun_eggs",
      flags = "all_floors",
   },

   {--[[Animals:sneachan-badlands]]
      name = "animals:sneachan_eggs_badland",
      deco_type = "simple",
      place_on = sna.badland_on,
      sidelen = 80,
      fill_ratio = 0.004000,
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
      fill_ratio = 0.002000,
      y_max = sna.highland_max,
      y_min = sna.beach_max,
      decoration = "animals:sneachan_eggs",
      flags = "all_floors",
   },
}

return {
   eggs = eggs,
}
