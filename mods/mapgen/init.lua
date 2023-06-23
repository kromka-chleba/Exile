-- Load files
local path = minetest.get_modpath("mapgen")

-- Globals
deco = deco or {}

minetest.set_mapgen_setting("mg_flags", "caves, nodungeons, light, decorations, biomes", true)
minetest.set_mapgen_setting("mgvalleys_spflags", "altitude_chill, humid_rivers, vary_river_depth, altitude_dry", true)





--
-- Aliases for map generators
--

-- ESSENTIAL node aliases
-- Basic nodes

minetest.register_alias("mapgen_stone", "nodes_nature:conglomerate")
minetest.register_alias("mapgen_water_source", "nodes_nature:salt_water_source")
minetest.register_alias("mapgen_river_water_source", "nodes_nature:freshwater_source")

local enable_v4_biomes
local biome_default = true


--Get experimental biome settings
--"use_exile_v4_biomes" is world-specific; it uses a separate name from
--the global UI setting "exile_v4_biomes" to any avoid possible conflicts
local biomes_enable = minetest.get_mapgen_setting("use_exile_v4_biomes")
local wp = minetest.get_worldpath()
if io.open(wp.."/env_meta.txt", "r") == nil then
   -- This is a hack to see if it's a new world; if so, apply global setting
   biomes_enable = minetest.settings:get_bool("exile_v4_biomes", biome_default)
   minetest.set_mapgen_setting("use_exile_v4_biomes",
			       tostring(biomes_enable), true)
elseif biomes_enable == nil then -- pre-existing world, but with no setting?
   biomes_enable = biome_default -- assume old world, & set to false, then
   minetest.set_mapgen_setting("use_exile_v4_biomes", tostring(false), true)
else                           -- get_mapgen_settings gives us a string, so:
   biomes_enable = biomes_enable == "true" -- convert it to a boolean
 end
if biomes_enable == true then
   minetest.log("action","Exile v4 biomes enabled")
   enable_v4_biomes = true
elseif biomes_enable == false then
   minetest.log("action","Exile v4 biomes disabled")
else
   minetest.log("action","v4 biomes setting is invalid!")
end

function deco.find_schematic(object)
    return minetest.get_modpath("mapgen").."/schematics/"..object..".mts"
end

if enable_v4_biomes then
   dofile(path.."/biomes.lua")
   dofile(path.."/ores.lua")
   dofile(path.."/deco.lua")
else
   dofile(path.."/old_biomes.lua")
   dofile(path.."/ores.lua")
   dofile(path.."/old_deco.lua")
end

---------------------------------------------

--[[

minetest.register_alias("mapgen_dirt", "nodes_nature:silt")
minetest.register_alias("mapgen_dirt_with_grass", "nodes_nature:grassland_soil")
minetest.register_alias("mapgen_sand", "nodes_nature:sand")

minetest.register_alias("mapgen_water_source", "nodes_nature:salt_water_source")
--minetest.register_alias("mapgen_river_water_source", "nodes_nature:freshwater_source")
minetest.register_alias("mapgen_river_water_source", "air")


minetest.register_alias("mapgen_lava_source", "nodes_nature:lava_source")
minetest.register_alias("mapgen_gravel", "nodes_nature:gravel")
minetest.register_alias("mapgen_desert_stone", "nodes_nature:siltstone")
minetest.register_alias("mapgen_desert_sand", "nodes_nature:sand")
minetest.register_alias("mapgen_dirt_with_snow", "nodes_nature:highland_soil")
minetest.register_alias("mapgen_snowblock", "nodes_nature:snow_block")
minetest.register_alias("mapgen_snow", "nodes_nature:snow")
minetest.register_alias("mapgen_ice", "nodes_nature:ice")
minetest.register_alias("mapgen_sandstone", "nodes_nature:sandstone")



-- Flora

minetest.register_alias("mapgen_tree", "nodes_nature:tangkal_tree")
minetest.register_alias("mapgen_leaves", "nodes_nature:tangkal_leaves")
minetest.register_alias("mapgen_apple", "nodes_nature:tangkal_fruit")
minetest.register_alias("mapgen_jungletree", "nodes_nature:tangkal_tree")
minetest.register_alias("mapgen_jungleleaves", "nodes_nature:tangkal_leaves")
minetest.register_alias("mapgen_junglegrass", "nodes_nature:damo")
minetest.register_alias("mapgen_pine_tree", "nodes_nature:tangkal_tree")
minetest.register_alias("mapgen_pine_needles", "nodes_nature:tangkal_leaves")

-- Dungeons


minetest.register_alias("mapgen_cobble", "nodes_nature:limestone_brick")
minetest.register_alias("mapgen_stair_cobble", "stairs:stair_limestone_block")

minetest.register_alias("mapgen_mossycobble", "nodes_nature:limestone_brick")
minetest.register_alias("mapgen_stair_desert_stone", "stairs:stair_limestone_block")
minetest.register_alias("mapgen_sandstonebrick", "nodes_nature:limestone_brick")
minetest.register_alias("mapgen_stair_sandstone_block", "stairs:stair_limestone_block")
]]
