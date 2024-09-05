-- Altitudes
return {
   land_max             =    600,
   land_min             =      1,
   highland_max         =    200,
   upland_max           =    100,
   lowland_max          =     50,
   coastal_max          =     10,
   -- Marine Altitudes
   beach_max            =      5,
   beach_min            =    -10,
   shallow_ocean_min    =    -30,

   -- Soils for decorations

   forest_on = {
      "nodes_nature:forest_soil", "nodes_nature:forest_soil_wet",
      "nodes_nature:upland_forest_soil", "nodes_nature:upland_forest_soil_wet",
   },

   woodland_on = {
      "nodes_nature:woodland_soil", "nodes_nature:woodland_soil_wet",
      "nodes_nature:upland_woodland_soil", "nodes_nature:upland_woodland_soil_wet",
   },

   rich_forest_on = {
      "nodes_nature:rich_forest_soil", "nodes_nature:rich_forest_soil_wet",
      "nodes_nature:rich_woodland_soil", "nodes_nature:rich_woodland_soil_wet",
   },

   wetland_on = {
      "nodes_nature:swamp_forest_soil", "nodes_nature:swamp_forest_soil_wet",
      "nodes_nature:marshland_soil", "nodes_nature:marshland_soil_wet",
   },

   swamp_forest_on = {
      "nodes_nature:swamp_forest_soil", "nodes_nature:swamp_forest_soil_wet",
   },

   marshland_on = {
      "nodes_nature:marshland_soil", "nodes_nature:marshland_soil_wet",
   },

   grassland_on = {
      "nodes_nature:coastal_grassland_soil", "nodes_nature:coastal_grassland_soil_wet",
      "nodes_nature:grassland_soil", "nodes_nature:grassland_soil_wet",
      "nodes_nature:upland_grassland_soil", "nodes_nature:upland_grassland_soil_wet",
   },

   shrubland_on = {
      "nodes_nature:coastal_shrubland_soil", "nodes_nature:coastal_shrubland_soil_wet",
      "nodes_nature:shrubland_soil", "nodes_nature:shrubland_soil_wet",
      "nodes_nature:upland_shrubland_soil", "nodes_nature:upland_shrubland_soil_wet"
   },

   grass_shrub_on = {
      "nodes_nature:coastal_grassland_soil", "nodes_nature:coastal_grassland_soil_wet",
      "nodes_nature:grassland_soil", "nodes_nature:grassland_soil_wet",
      "nodes_nature:coastal_shrubland_soil", "nodes_nature:coastal_shrubland_soil_wet",
      "nodes_nature:shrubland_soil", "nodes_nature:shrubland_soil_wet",
      "nodes_nature:upland_grassland_soil", "nodes_nature:upland_grassland_soil_wet",
      "nodes_nature:upland_shrubland_soil", "nodes_nature:upland_shrubland_soil_wet"
   },

   duneland_on = {
      "nodes_nature:coastal_duneland_soil", "nodes_nature:coastal_duneland_soil_wet",
      "nodes_nature:duneland_soil", "nodes_nature:duneland_soil_wet",
      "nodes_nature:upland_duneland_soil", "nodes_nature:upland_duneland_soil_wet"
   },

   barrenland_on = {
      "nodes_nature:coastal_barrenland_soil", "nodes_nature:coastal_barrenland_soil_wet",
      "nodes_nature:barrenland_soil", "nodes_nature:barrenland_soil_wet",
      "nodes_nature:upland_barrenland_soil", "nodes_nature:upland_barrenland_soil_wet"
   },

   highland_on = {
      "nodes_nature:highland_soil", "nodes_nature:highland_soil_wet"
   },

   badland_on = {
      "nodes_nature:coastal_duneland_soil", "nodes_nature:coastal_duneland_soil_wet",
      "nodes_nature:duneland_soil", "nodes_nature:duneland_soil_wet",
      "nodes_nature:upland_duneland_soil", "nodes_nature:upland_duneland_soil_wet",
      "nodes_nature:coastal_barrenland_soil", "nodes_nature:coastal_barrenland_soil_wet",
      "nodes_nature:barrenland_soil", "nodes_nature:barrenland_soil_wet",
      "nodes_nature:upland_barrenland_soil", "nodes_nature:upland_barrenland_soil_wet",
      "nodes_nature:highland_soil", "nodes_nature:highland_soil_wet"
   },

   all_soils_on = {
      "nodes_nature:forest_soil", "nodes_nature:forest_soil_wet",
      "nodes_nature:upland_forest_soil", "nodes_nature:upland_forest_soil_wet",
      "nodes_nature:woodland_soil", "nodes_nature:woodland_soil_wet",
      "nodes_nature:upland_woodland_soil", "nodes_nature:upland_woodland_soil_wet",
      "nodes_nature:rich_forest_soil", "nodes_nature:rich_forest_soil_wet",
      "nodes_nature:rich_woodland_soil", "nodes_nature:rich_woodland_soil_wet",
      "nodes_nature:swamp_forest_soil", "nodes_nature:swamp_forest_soil_wet",
      "nodes_nature:marshland_soil", "nodes_nature:marshland_soil_wet",
      "nodes_nature:coastal_grassland_soil", "nodes_nature:coastal_grassland_soil_wet",
      "nodes_nature:grassland_soil", "nodes_nature:grassland_soil_wet",
      "nodes_nature:upland_grassland_soil", "nodes_nature:upland_grassland_soil_wet",
      "nodes_nature:coastal_shrubland_soil", "nodes_nature:coastal_shrubland_soil_wet",
      "nodes_nature:shrubland_soil", "nodes_nature:shrubland_soil_wet",
      "nodes_nature:upland_shrubland_soil", "nodes_nature:upland_shrubland_soil_wet",
      "nodes_nature:coastal_duneland_soil", "nodes_nature:coastal_duneland_soil_wet",
      "nodes_nature:duneland_soil", "nodes_nature:duneland_soil_wet",
      "nodes_nature:upland_duneland_soil", "nodes_nature:upland_duneland_soil_wet",
      "nodes_nature:coastal_barrenland_soil", "nodes_nature:coastal_barrenland_soil_wet",
      "nodes_nature:barrenland_soil", "nodes_nature:barrenland_soil_wet",
      "nodes_nature:upland_barrenland_soil", "nodes_nature:upland_barrenland_soil_wet",
      "nodes_nature:highland_soil", "nodes_nature:highland_soil_wet",
   },

   not_badland_soils_on = {
      "nodes_nature:forest_soil", "nodes_nature:forest_soil_wet",
      "nodes_nature:upland_forest_soil", "nodes_nature:upland_forest_soil_wet",
      "nodes_nature:woodland_soil", "nodes_nature:woodland_soil_wet",
      "nodes_nature:upland_woodland_soil", "nodes_nature:upland_woodland_soil_wet",
      "nodes_nature:rich_forest_soil", "nodes_nature:rich_forest_soil_wet",
      "nodes_nature:rich_woodland_soil", "nodes_nature:rich_woodland_soil_wet",
      "nodes_nature:swamp_forest_soil", "nodes_nature:swamp_forest_soil_wet",
      "nodes_nature:marshland_soil", "nodes_nature:marshland_soil_wet",
      "nodes_nature:coastal_grassland_soil", "nodes_nature:coastal_grassland_soil_wet",
      "nodes_nature:grassland_soil", "nodes_nature:grassland_soil_wet",
      "nodes_nature:upland_grassland_soil", "nodes_nature:upland_grassland_soil_wet",
      "nodes_nature:coastal_shrubland_soil", "nodes_nature:coastal_shrubland_soil_wet",
      "nodes_nature:shrubland_soil", "nodes_nature:shrubland_soil_wet",
      "nodes_nature:upland_shrubland_soil", "nodes_nature:upland_shrubland_soil_wet"
   },

   glow_worm_on = {
      "nodes_nature:granite", "nodes_nature:gneiss", "nodes_nature:limestone", "nodes_nature:jade",
   },

   gravel_on = {
      "nodes_nature:granite", "nodes_nature:limestone", "nodes_nature:coquina",
      "nodes_nature:gneiss", "nodes_nature:conglomerate",
   },

   sand_on = {
      "nodes_nature:granite", "nodes_nature:limestone", "nodes_nature:coquina",
      "nodes_nature:gneiss", "nodes_nature:sandstone",
   },

   silt_on = {
      "nodes_nature:granite", "nodes_nature:limestone", "nodes_nature:coquina",
      "nodes_nature:gneiss", "nodes_nature:siltstone",
   },

   clay_on = {
      "nodes_nature:granite", "nodes_nature:limestone", "nodes_nature:coquina",
      "nodes_nature:gneiss", "nodes_nature:claystone",
   },

   cave_mushrooms_on = {
      "nodes_nature:silt", "nodes_nature:clay",
      "nodes_nature:sand", "nodes_nature:gravel",
      "nodes_nature:silt_wet", "nodes_nature:clay_wet",
      "nodes_nature:sand_wet", "nodes_nature:gravel_wet",
   },

   fish_on = {
      "nodes_nature:silt_wet_salty", "nodes_nature:sand_wet_salty",
      "nodes_nature:gravel_wet_salty",
   },

   cave_egg_on = {
      "nodes_nature:granite", "nodes_nature:limestone", "nodes_nature:coquina",
      "nodes_nature:ironstone", "nodes_nature:gneiss",
      "nodes_nature:granite_boulder", "nodes_nature:limestone_boulder",
      "nodes_nature:coquina_boulder", "nodes_nature:ironstone_boulder",
      "nodes_nature:gneiss_boulder", "nodes_nature:sandstone",
      "nodes_nature:siltstone", "nodes_nature:claystone",
      "nodes_nature:conglomerate",
   },
}
