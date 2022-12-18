---------------------------------------------------------
--SEDIMENT DATA
--Nodes and recipes are defined here
--
----------------------------------------------------------

-- Internationalization
local S = nodes_nature.S
---------------------------------------------

-- list of sediments to be used for mapgen
local sediment_list = {
    sand = sediment.new(
        {name = "sand",
         description = S("Sand"), hardness = sediment.hardness.soft,
         id = 4, sound = sediment.sounds.sand,
         sound_wet = sediment.sounds.sand_wet,
         rocky_substrate = 4,
         organic_substrate = 0,
         fertility = 1,
         density = 2,
    }),
    silt = sediment.new(
        {name = "silt",
         description = S("Silt"), hardness = sediment.hardness.soft,
         id = 3, sound = sediment.sounds.dirt,
         sound_wet = sediment.sounds.dirt_wet,
         rocky_substrate = 1,
         organic_substrate = 3,
         fertility = 3,
         density = 3,
    }),
    clay = sediment.new(
        {name = "clay",
         description = S("Clay"), hardness = sediment.hardness.medium,
         id = 2, sound = sediment.sounds.dirt,
         sound_wet = sediment.sounds.dirt_wet,
         rocky_substrate = 2,
         organic_substrate = 2,
         fertility = 2,
         density = 4,
    }),
    gravel = sediment.new(
        {name = "gravel",
         description = S("Gravel"), hardness = sediment.hardness.soft,
         id = 5, sound = sediment.sounds.gravel,
         sound_wet = sediment.sounds.gravel_wet,
         rocky_substrate = 4,
         organic_substrate = 0,
         fertility = 1,
         density = 4,
    }),
    loam = sediment.new(
        {name = "loam",
         description = S("Loam"), hardness = sediment.hardness.soft,
         id = 1, sound = sediment.sounds.dirt,
         sound_wet = sediment.sounds.dirt_wet,
         rocky_substrate = 1,
         organic_substrate = 4,
         fertility = 4,
         density = 1,
    }),
    volcanic_ash = sediment.new(
        {name = "volcanic_ash",
         description = S("Volcanic ash"),
         hardness = sediment.hardness.soft,
         id = 1, sound = sediment.sounds.sand,
         sound_wet = sediment.sounds.sand_wet,
         rocky_substrate = 4,
         organic_substrate = 0,
         fertility = 4,
         density = 1,
    }),
}

-- this is only for paint
local red_ochre = sediment.new(
    {name = "red_ochre",
     description = S("Red Ochre"),
     hardness = sediment.hardness.medium,
     id = 2, sound = sediment.sounds.dirt,
     sound_wet = sediment.sounds.dirt_wet,
     rocky_substrate = 2,
     organic_substrate = 2,
     fertility = 2,
     density = 4,
})
sediment.register_dry(red_ochre)
sediment.register_wet(red_ochre)
sediment.register_wet_salty(red_ochre)
sediment.do_slopes(red_ochre)



local soil_list = {
    --Forest & Woodland
   soil.new({name = "rich_forest_soil",
	     description = S("Rich Forest Soil"),
	     sediment = sediment_list.loam}),
   soil.new({name = "rich_woodland_soil",
	     description = S("Rich Woodland Soil"),
	     sediment = sediment_list.loam}),
   soil.new({name = "forest_soil",
	     description = S("Forest Soil"),
	     sediment = sediment_list.silt}),
   soil.new({name = "woodland_soil",
	     description = S("Woodland Soil"),
	     sediment = sediment_list.silt}),
   soil.new({name = "upland_forest_soil",
	     description = S("Upland Forest Soil"),
	     sediment = sediment_list.clay}),
   soil.new({name = "upland_woodland_soil",
	     description = S("Upland Woodland Soil"),
	     sediment = sediment_list.clay}),

    --Wetlands
   soil.new({name = "marshland_soil",
	     description = S("Marshland Soil"),
	     sediment = sediment_list.silt}),
   soil.new({name = "swamp_forest_soil",
	     description = S("Swamp Forest Soil"),
	     sediment = sediment_list.silt}),

    --Shrubland & Grassland
    soil.new({name = "coastal_shrubland_soil",
	      description = S("Coastal Shrubland Soil"),
	      sediment = sediment_list.silt}),
    soil.new({name = "coastal_grassland_soil",
	      description = S("Coastal Grassland Soil"),
	      sediment = sediment_list.clay}),
    soil.new({name = "grassland_soil", description = S("Grassland Soil"),
	      sediment = sediment_list.clay}),
    soil.new({name = "shrubland_soil", description = S("Shrubland Soil"),
	      sediment = sediment_list.clay}),

    --Barrenland & Duneland
    soil.new({name = "barrenland_soil",
	      description = S("Barren Grassland Soil"),
	      sediment = sediment_list.gravel}),
    soil.new({name = "duneland_soil",
	      description = S("Duneland Soil"),
	      sediment = sediment_list.sand}),

    -- Highland
    soil.new({name = "highland_soil",
	      description = S("Highland Soil"),
	      sediment = sediment_list.gravel}),

    --Legacy
    soil.new({name = "grassland_barren_soil",
	      description = S("Barren Grassland Soil"),
	      sediment = sediment_list.gravel}),
    soil.new({name = "woodland_dry_soil",
	      description = S("Dry Woodland Soil"),
	      sediment = sediment_list.silt}),
}

-- Recipes for loam

crafting.register_recipe({
	type = "mixing_spot",
	output = "nodes_nature:loam 3",
	items = {"nodes_nature:clay 1","nodes_nature:silt 1","nodes_nature:sand 1"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "mixing_spot",
	output = "nodes_nature:loam_wet 3",
	items = {"nodes_nature:clay_wet 1","nodes_nature:silt_wet 1","nodes_nature:sand_wet 1"},
	level = 1,
	always_known = true,
})

-- Actually registers (almost) all soils in the game
-- see red_ochre above
sediment.register_all_sed_derivatives(sediment_list)
sediment.register_soil_variants(soil_list)
