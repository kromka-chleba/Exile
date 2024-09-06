--[[ Register Biomes ]]--
--[[ Local Variables ]]--

--- Range Limits
local upper_limit      =  31000
local lower_limit      = -31000
--- Terrestrial Altitudes
local highland_max     =    200
local highland_min     =    101
local upland_max       =    100
local upland_min       =     51
local lowland_max      =     50
local lowland_min      =     11
local coastal_max      =     10
local coastal_min      =      5
local tidal_max        =      4         -- prev: beach_max
local tidal_min        =      1
--- Marine Altitudes
local littoral_max     =      0
local littoral_min     =    -10         -- prev: beach_min
local neritic_max      =    -11  -- prev: shallow_ocean_max
local neritic_min      =    -30  -- prev: shallow_ocean_min
local oceanic_max      =    -31  -- prev: deep_ocean_max
local oceanic_min      =   -120  -- prev: deep_ocean_min
local abyssal_max      =   -121  -- prev: undercity_max
local abyssal_min      =  -1500  -- prev: undercity_min
local bedrock_max      =  -1501
local bedrock_min      = -28000
local mantle_max       = -28001  -- prev: crust_max
--- Climate Ranges
local x_high           =     90         -- 95
local high             =     74         -- 75
local mid_high         =     62
local middle           =     50         -- 50
local mid_low          =     38
local low              =     26         -- 25
local x_low            =     10         --  5
--- Misc Nodes
local air              = "air"
local potable          = "nodes_nature:freshwater_source"
local lava             = "nodes_nature:lava_source"
---Top Soil Nodes
local forest           = "nodes_nature:forest_soil"
local forest_wet       = "nodes_nature:forest_soil_wet"
local woodl            = "nodes_nature:woodland_soil"
local woodl_wet        = "nodes_nature:woodland_soil_wet"
local up_forest        = "nodes_nature:upland_forest_soil"
local up_forest_wet    = "nodes_nature:upland_forest_soil_wet"
local up_woodl         = "nodes_nature:upland_woodland_soil"
local up_woodl_wet     = "nodes_nature:upland_woodland_soil_wet"
local marsh_wet        = "nodes_nature:marshland_soil_wet"
local sw_forest_wet    = "nodes_nature:swamp_forest_soil_wet"
local c_grland         = "nodes_nature:coastal_grassland_soil"
local grland           = "nodes_nature:grassland_soil"
local grland_wet       = "nodes_nature:grassland_soil_wet"
local up_grland        = "nodes_nature:upland_grassland_soil"
local c_shland         = "nodes_nature:coastal_shrubland_soil"
local shland           = "nodes_nature:shrubland_soil"
local shland_wet       = "nodes_nature:shrubland_soil_wet"
local up_shland        = "nodes_nature:upland_shrubland_soil"
local c_barren         = "nodes_nature:coastal_barrenland_soil"
local barren           = "nodes_nature:barrenland_soil"
local up_barren        = "nodes_nature:upland_barrenland_soil"
local c_dune           = "nodes_nature:coastal_duneland_soil"
local dune             = "nodes_nature:duneland_soil"
local up_dune          = "nodes_nature:upland_duneland_soil"
local hland            = "nodes_nature:highland_soil"
---Soil Nodes
local sand             = "nodes_nature:sand"
local sand_wet         = "nodes_nature:sand_wet"
local sand_ws          = "nodes_nature:sand_wet_salty"
local silt             = "nodes_nature:silt"
local silt_wet         = "nodes_nature:silt_wet"
local silt_ws          = "nodes_nature:silt_wet_salty"
local loam             = "nodes_nature:loam"
local gravel           = "nodes_nature:gravel"
local gravel_w         = "nodes_nature:gravel_wet"
local gravel_ws        = "nodes_nature:gravel_wet_salty"
local clay             = "nodes_nature:clay"
local clay_wet         = "nodes_nature:clay_wet"
---Stone
local coquina          = "nodes_nature:coquina"
local limestone        = "nodes_nature:limestone"
local granite          = "nodes_nature:granite"
local gneiss           = "nodes_nature:gneiss"

---Alternate settings for Carpathian mapgen
if minetest.get_mapgen_setting("mg_name") == "carpathian" then
    coastal_min = 3
    tidal_max   = 2
    minetest.log("info", "using alternate biome settings for carpathan mapgen")
end

--[[ Biomes ]]--[[
    01. Coastal Forest
    02. Coastal Woodland
    03. Lowland Forest
    04. Lowland Woodland
    05. Upland Forest
    06. Upland Woodland
    07. Swamp Forest
    08. Marshland
    09. Coastal Shrubland
    10. Coastal Grassland
    11. Lowland Shrubland
    12. Lowland Grassland
    13. Upland Shrubland
    14. Upland Grassland
    15. Coastal Barrenland
    16. Coastal Duneland
    17. Lowland Barrenland
    18. Lowland Duneland
    19. Upland Barrenland
    20. Upland Duneland
    21. Highland
    22. Highland Scree
    23. Highland Rock
    24. Sandy Beach
    25. Silty Beach
    26. Gravel Beach
    27. Sandy Coast
    28. Silty Coast
    29. Gravel Coast
    30. Shallow Water
    31. Deep Water
    32. Underground
    33. Deep Underground
    34. Mantle
]]

--[[Define Biomes Table]]--
local biome_list = {
    --Forests & Woodland
    --[[01]]
    {
        name = "Coastal Forest",
        node_top = forest,
        depth_top = 1,
        node_filler = silt,
        depth_filler = 3,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = silt_wet,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = coastal_max,
        y_min = coastal_min,
        heat_point = x_low,
        humidity_point = high,
        _color = {r = 75, g = 114, b = 72},
    },

    --[[02]]
    {
        name = "Coastal Woodland",
        node_top = woodl,
        depth_top = 1,
        node_filler = silt,
        depth_filler = 2,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = silt_wet,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = coastal_max,
        y_min = coastal_min,
        heat_point = high,
        humidity_point = high,
        _color = {r = 85, g = 84, b = 32},
    },

    --[[03]]
    {
        name = "Lowland Forest",
        node_top = forest,
        depth_top = 1,
        node_filler = silt,
        depth_filler = 3,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = forest_wet,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = lowland_max,
        y_min = lowland_min,
        heat_point = x_low,
        humidity_point = x_high,
        _color = {r = 85, g = 104, b = 62},
    },

    --[[04]]
    {
        name = "Lowland Woodland",
        node_top = woodl,
        depth_top = 1,
        node_filler = silt,
        depth_filler = 2,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = woodl_wet,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = lowland_max,
        y_min = lowland_min,
        heat_point = middle,
        humidity_point = x_high,
        _color = {r = 95, g = 74, b = 22},
    },

    --[[05]]
    {
        name = "Upland Forest",
        node_top = up_forest,
        depth_top = 1,
        node_filler = clay,
        depth_filler = 2,
        node_stone = coquina,
        node_river_water = air,
        node_riverbed = up_forest_wet,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  25,
        y_max = upland_max,
        y_min = upland_min,
        heat_point = x_low,
        humidity_point = x_high,
        _color = {r = 95, g = 94, b = 62},
    },

    --[[06]]
    {
        name = "Upland Woodland",
        node_top = up_woodl,
        depth_top = 1,
        node_filler = clay,
        depth_filler = 2,
        node_stone = coquina,
        node_river_water = air,
        node_riverbed = up_woodl_wet,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  25,
        y_max = upland_max,
        y_min = upland_min,
        heat_point = middle,
        humidity_point = x_high,
        _color = {r = 105, g = 64, b = 22},
    },

    --Wetlands
    --[[07]]
    {
        name = "Swamp Forest",
        node_top = sw_forest_wet,
        depth_top = 1,
        node_filler = silt_wet,
        depth_filler = 3,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = clay_wet,
        depth_riverbed = 3,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = coastal_max+5,
        y_min = coastal_min,
        heat_point = x_low,
        humidity_point = x_high+5,
        _color = {r = 110, g = 73, b = 42},
    },

    --[[08]]
    {
        name = "Marshland",
        node_top = marsh_wet,
        depth_top = 1,
        node_filler = silt_wet,
        depth_filler = 3,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = clay_wet,
        depth_riverbed = 3,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = coastal_max+8,
        y_min = coastal_min,
        heat_point = middle,
        humidity_point = x_high+5,
        _color = {r = 130, g = 63, b = 32},
    },

    --Shrublands & Grasslands
    --[[09]]
    {
        name = "Coastal Shrubland",
        node_top = c_shland,
        depth_top = 1,
        node_filler = silt,
        depth_filler = 2,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = gravel_w,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = coastal_max,
        y_min = coastal_min,
        heat_point = low,
        humidity_point = middle,
        _color = {r = 163, g = 160, b = 84},
    },

    --[[10]]
    {
        name = "Coastal Grassland",
        node_top = c_grland,
        depth_top = 1,
        node_filler = clay,
        depth_filler = 2,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = gravel_w,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = coastal_max,
        y_min = coastal_min,
        heat_point = high,
        humidity_point = middle,
        _color = {r = 173, g = 140, b = 74},
    },

    --[[11]]
    {
        name = "Lowland Shrubland",
        node_top = shland,
        depth_top = 1,
        node_filler = clay,
        depth_filler = 3,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = shland,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = lowland_max,
        y_min = lowland_min,
        heat_point = low,
        humidity_point = middle,
        _color = {r = 173, g = 150, b = 74},
    },

    --[[12]]
    {
        name = "Lowland Grassland",
        node_top = grland,
        depth_top = 1,
        node_filler = clay,
        depth_filler = 2,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = grland,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = lowland_max,
        y_min = lowland_min,
        heat_point = high,
        humidity_point = middle,
        _color = {r = 183, g = 130, b = 64},
    },

    --[[13]]
    {
        name = "Upland Shrubland",
        node_top = up_shland,
        depth_top = 1,
        node_filler = clay,
        depth_filler = 2,
        node_stone = coquina,
        node_river_water = air,
        node_riverbed = gravel,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  25,
        y_max = upland_max,
        y_min = upland_min,
        heat_point = low,
        humidity_point = middle,
        _color = {r = 183, g = 140, b = 64},
    },

    --[[14]]
    {
        name = "Upland Grassland",
        node_top = up_grland,
        depth_top = 1,
        node_filler = clay,
        depth_filler = 1,
        node_stone = coquina,
        node_river_water = air,
        node_riverbed = gravel,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  25,
        y_max = upland_max,
        y_min = upland_min,
        heat_point = high,
        humidity_point = middle,
        _color = {r = 193, g = 120, b = 54},
    },


    --Barrenlands & Dunelands
    --[[15]]
    {
        name = "Coastal Barrenland",
        node_top = c_barren,
        depth_top = 1,
        node_filler = gravel,
        depth_filler = 2,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = gravel_w,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = coastal_max,
        y_min = coastal_min,
        heat_point = mid_low,
        humidity_point = x_low,
        _color = {r = 252, g = 226, b = 180},
    },

    --[[16]]
    {
        name = "Coastal Duneland",
        node_top = c_dune,
        depth_top = 1,
        node_filler = sand,
        depth_filler = 2,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = gravel_w,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = coastal_max,
        y_min = coastal_min,
        heat_point = mid_high,
        humidity_point = x_low,
        _color = {r = 245, g = 123, b = 36},
    },

    --[[17]]
    {
        name = "Lowland Barrenland",
        node_top = barren,
        depth_top = 1,
        node_filler = gravel,
        depth_filler = 3,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = gravel,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = lowland_max,
        y_min = lowland_min,
        heat_point = mid_low,
        humidity_point = x_low,
        _color = {r = 222, g = 216, b = 170},
    },

    --[[18]]
    {
        name = "Lowland Duneland",
        node_top = dune,
        depth_top = 1,
        node_filler = sand,
        depth_filler = 3,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = gravel,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  5,
        y_max = lowland_max,
        y_min = lowland_min,
        heat_point = mid_high,
        humidity_point = x_low,
        _color = {r = 215, g = 113, b = 46},
    },

    --[[19]]
    {
        name = "Upland Barrenland",
        node_top = up_barren,
        depth_top = 1,
        node_filler = gravel,
        depth_filler = 1,
        node_stone = coquina,
        node_river_water = air,
        node_riverbed = gravel,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  25,
        y_max = upland_max,
        y_min = upland_min,
        heat_point = mid_low,
        humidity_point = x_low,
        _color = {r = 215, g = 216, b = 160},
    },

    --[[20]]
    {
        name = "Upland Duneland",
        node_top = up_dune,
        depth_top = 1,
        node_filler = sand,
        depth_filler = 1,
        node_stone = coquina,
        node_river_water = air,
        node_riverbed = gravel,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  25,
        y_max = upland_max,
        y_min = upland_min,
        heat_point = mid_high,
        humidity_point = x_low,
        _color = {r = 205, g = 103, b = 36},
    },


    --Highland
    --[[21]]
    {
        name = "Highland",
        node_top = hland,
        depth_top = 1,
        node_filler = gravel,
        depth_filler = 1,
        node_stone = coquina,
        node_river_water = air,
        node_riverbed = gravel,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  25,
        y_max = highland_max,
        y_min = highland_min,
        heat_point = middle,
        humidity_point = middle,
        _color = {r = 76, g = 61, b = 54},
    },

    --[[22]]
    {
        name = "Highland Scree",
        node_top = gravel,
        depth_top = 1,
        node_filler = silt,
        depth_filler = 1,
        node_stone = coquina,
        node_river_water = air,
        node_riverbed = gravel,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  25,
        y_max = upper_limit,
        y_min = highland_min,
        heat_point = x_low,
        humidity_point = low,
        _color = {r = 70, g = 70, b = 70},
    },

    --[[23]]
    {
        name = "Highland Rock",
        node_top = air,
        depth_top = 1,
        node_filler = gravel,
        depth_filler = 2,
        node_stone = coquina,
        node_river_water = air,
        node_riverbed = gravel,
        depth_riverbed = 1,
        node_cave_liquid = {potable},
        vertical_blend =  25,
        y_max = upper_limit,
        y_min = highland_min,
        heat_point = x_high,
        humidity_point = low,
        _color = {r = 90, g = 90, b = 90},
    },

    --Coasts
    --[[24]]
    {
        name = "Sandy Beach",
        node_top = sand,
        depth_top = 3,
        node_filler = sand_ws,
        depth_filler = 1,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = sand_ws,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  1,
        y_max = tidal_max,
        y_min = tidal_min,
        heat_point = high,
        humidity_point = middle,
        _color = {r = 144, g = 141, b = 118},
    },

    --[[25]]
    {
        name = "Silty Beach",
        node_top = silt,
        depth_top = 3,
        node_filler = silt_ws,
        depth_filler = 1,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = silt_ws,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  1,
        y_max = tidal_max,
        y_min = tidal_min,
        heat_point = middle,
        humidity_point = high,
        _color = {r = 108, g = 85, b = 66},
    },

    --[[26]]
    {
        name = "Gravel Beach",
        node_top = gravel,
        depth_top = 3,
        node_filler = gravel_ws,
        depth_filler = 1,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = gravel_ws,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  1,
        y_max = tidal_max,
        y_min = tidal_min,
        heat_point = low,
        humidity_point = middle,
        _color = {r = 103, g = 101, b = 93},
    },

    --[[27]]
    {
        name = "Sandy Coast",
        node_top = sand_ws,
        depth_top = 1,
        node_filler = sand_ws,
        depth_filler = 2,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = sand_ws,
        depth_riverbed = 3,
        node_cave_liquid = {potable},
        vertical_blend =  2,
        y_max = littoral_max,
        y_min = littoral_min,
        heat_point = high,
        humidity_point = low,
        _color = {r = 144, g = 141, b = 128},
    },

    --[[28]]
    {
        name = "Silty Coast",
        node_top = silt_ws,
        depth_top = 1,
        node_filler = silt_ws,
        depth_filler = 2,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = silt_ws,
        depth_riverbed = 3,
        node_cave_liquid = {potable},
        vertical_blend =  2,
        y_max = littoral_max,
        y_min = littoral_min,
        heat_point = middle,
        humidity_point = high,
        _color = {r = 108, g = 85, b = 76},
    },

    --[[29]]
    {
        name = "Gravel Coast",
        node_top = gravel_ws,
        depth_top = 1,
        node_filler = gravel_ws,
        depth_filler = 2,
        node_stone = limestone,
        node_river_water = air,
        node_riverbed = gravel_ws,
        depth_riverbed = 3,
        node_cave_liquid = {potable},
        vertical_blend =  2,
        y_max = littoral_max,
        y_min = littoral_min,
        heat_point = low,
        humidity_point = low,
        _color = {r = 103, g = 101, b = 103},
    },

    --Depths
    --[[30]]
    {
        name = "Shallow Water",
        node_top = sand_ws,
        depth_top = 1,
        node_filler = sand_ws,
        depth_filler = 3,
        node_stone = limestone,
        node_riverbed = sand_ws,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  1,
        y_max = neritic_max,
        y_min = neritic_min,
        heat_point = middle,
        humidity_point = middle,
        _color = {r = 33, g = 55, b = 75},
    },

    --[[31]]
    {
        name = "Deep Water",
        node_top = silt_ws,
        depth_top = 1,
        node_filler = silt_ws,
        depth_filler = 3,
        node_stone = granite,
        node_riverbed = sand_ws,
        depth_riverbed = 2,
        node_cave_liquid = {potable},
        vertical_blend =  10,
        y_max = oceanic_max,
        y_min = oceanic_min,
        heat_point = middle,
        humidity_point = middle,
        _color = {r = 18, g = 25, b = 59},
    },

    --[[32]]
    {
        name = "Underground",
        node_stone = granite,
        node_cave_liquid = {potable},
        vertical_blend =  20,
        y_max = abyssal_max,
        y_min = abyssal_min,
        heat_point = middle,
        humidity_point = middle,
        _color = {r = 15, g = 15, b = 15},
    },

    --[[33]]
    {
        name = "Deep Underground",
        node_stone = gneiss,
        node_cave_liquid = {lava},
        vertical_blend =  100,
        y_max = bedrock_max,
        y_min = bedrock_min,
        heat_point = middle,
        humidity_point = middle,
        _color = {r = 5, g = 5, b = 5},
    },

    --[[34]]
    {
        name = "Mantle",
        node_stone = lava,
        node_cave_liquid = {lava},
        vertical_blend =  100,
        y_max = mantle_max,
        y_min = lower_limit,
        heat_point = middle,
        humidity_point = middle,
        _color = {r = 105, g = 5, b = 5},
    },
}

--[[Loop to Iterate for Registrations]]--
for i in pairs(biome_list) do
    minetest.register_biome(biome_list[i])
end

local function export_amidst_file()
    local wpath = minetest.get_worldpath()
    local wname = wpath:match( "([^/\\]+)$" )

    local filespec = wpath..'/amidst_biomes.mt'
    local file, err = io.open( filespec, 'w')

    if (err ~= nil) then
        return
    end

    local str = string.format( '{ "name":"Exile v4 (%s)", "biomeList":[\n\n',
                               wname )
    file:write( str )

    for _, biome in pairs(biome_list) do
        str = string.format(
            '   { "name":%-24s, "color":{ "r":%3d, "g":%3d, "b":%3d },  '..
            '"y_min":%6d,  "y_max":%6d,  '..
            '"heat_point":%6.2f,  "humidity_point":%6.2f  },\n',
            '"'..biome.name..'"', biome._color.r, biome._color.g, biome._color.b,
            biome.y_min, biome.y_max,
            biome.heat_point, biome.humidity_point)
        file:write( str )
    end

    file:write( '\n] }\n' )

    file:flush()
    file:close()
end

--export_amidst_file()
