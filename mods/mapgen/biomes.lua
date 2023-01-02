--[[ Register Biomes ]]--
--[[ Local Variables ]]--

	--- Range Limits
		local upper_limit      =  31000
		local lower_limit      = -31000
	--- Terrestrial Altitudes
		local highland_max     =    200
		local highland_min	  =    101	
		local upland_max       =    100
		local upland_min       =     51
		local lowland_max      =     50
		local lowland_min      =     11
		local coastal_max      =     10
		local coastal_min      =      5
		local tidal_max        =      4 	-- prev: beach_max
		local tidal_min        =      1 
	--- Marine Altitudes
		local littoral_max	  =      0 
		local littoral_min     =    -10 	-- prev: beach_min
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
		local x_high           =     90 	-- 95
		local high             =     74 	-- 75
		local mid_high         =     62
		local middle           =     50 	-- 50
      local mid_low          =     38
		local low              =     26 	-- 25
		local x_low            =     10 	--  5
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
		local c_shland         = "nodes_nature:coastal_shrubland_soil"
		local shland           = "nodes_nature:shrubland_soil"
		local shland_wet       = "nodes_nature:shrubland_soil_wet"
		local barren           = "nodes_nature:barrenland_soil"
		local dune             = "nodes_nature:duneland_soil"
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
	--                                                                                                node  depth  node                  depth
	--                                     node           node  depth      node  depth   node         water water  river           node  river   cave        vert                                     heat        humidity     amidst colors  
	--             name                    dust            top  top      filler  filler  stone        top   top    water       riverbed  bed     liquid     blend     y_max           y_min           point       point         r    g    b 
	
	--Forests & Woodland
		--[[01]]  { "Coastal Forest"     ,  nil,        forest,  1,        silt,  3,      limestone,   nil,  nil,   air,       silt_wet,  2,      {potable},     5,    coastal_max,    coastal_min,    x_low,      high,      {	 75, 114,  72 } },
		--[[02]]  { "Coastal Woodland"   ,  nil,         woodl,  1,        silt,  2,      limestone,   nil,  nil,   air,       silt_wet,  2,      {potable},     5,    coastal_max,    coastal_min,    high,       high,      {	 85,  84,  32 } },
		--[[03]]  { "Lowland Forest"     ,  nil,        forest,  1,        silt,  3,      limestone,   nil,  nil,   air,     forest_wet,  1,      {potable},     5,    lowland_max,    lowland_min,    x_low,      x_high,    {	 85, 104,  62 } },
		--[[04]]  { "Lowland Woodland"   ,  nil,         woodl,  1,        silt,  2,      limestone,   nil,  nil,   air,      woodl_wet,  1,      {potable},     5,    lowland_max,    lowland_min,    middle,     x_high,    {	 95,  74,  22 } },
		--[[05]]  { "Upland Forest"      ,  nil,     up_forest,  1,        clay,  2,      limestone,   nil,  nil,   air,  up_forest_wet,  1,      {potable},    25,    upland_max,     upland_min,     x_low,      x_high,    {	 95,  94,  62 } },
		--[[06]]  { "Upland Woodland"    ,  nil,      up_woodl,  1,        clay,  2,      limestone,   nil,  nil,   air,   up_woodl_wet,  1,      {potable},    25,    upland_max,     upland_min,     middle,     x_high,    {	105,  64,  22 } },

	--Wetlands
		--[[07]]  { "Swamp Forest"       ,  nil, sw_forest_wet,  1,    silt_wet,  3,      limestone,   nil,  nil,   air,       clay_wet,  3,      {potable},     5,    coastal_max+5,  coastal_min,    x_low,      x_high+5,  {	110,  73,  42 } },
		--[[08]]  { "Marshland"          ,  nil,     marsh_wet,  1,    silt_wet,  3,      limestone,   nil,  nil,   air,       clay_wet,  3,      {potable},     5,    coastal_max+8,  coastal_min,    middle,     x_high+5,  {	130,  63,  32 } },

	--Shrublands & Grasslands
		--[[09]]  { "Coastal Shrubland"  ,  nil,      c_shland,  1,        silt,  2,      limestone,   nil,  nil,   air,       gravel_w,  2,      {potable},     5,    coastal_max,    coastal_min,    low,        middle,    {	163, 160,  84 } },
		--[[10]]  { "Coastal Grassland"  ,  nil,      c_grland,  1,        clay,  2,      limestone,   nil,  nil,   air,       gravel_w,  2,      {potable},     5,    coastal_max,    coastal_min,    high,       middle,    {	173, 140,  74 } },
		--[[11]]  { "Lowland Shrubland"  ,  nil,        shland,  1,        clay,  3,      limestone,   nil,  nil,   air,         shland,  1,      {potable},     5,    lowland_max,    lowland_min,    low,        middle,    {	173, 150,  74 } },
		--[[12]]  { "Lowland Grassland"  ,  nil,        grland,  1,        clay,  2,      limestone,   nil,  nil,   air,         grland,  1,      {potable},     5,    lowland_max,    lowland_min,    high,       middle,    {	183, 130,  64 } },
		--[[13]]  { "Upland Shrubland"   ,  nil,        shland,  1,        clay,  2,      limestone,   nil,  nil,   air,         gravel,  1,      {potable},    25,    upland_max,     upland_min,     low,        middle,    {	183, 140,  64 } },
		--[[14]]  { "Upland Grassland"   ,  nil,        grland,  1,        clay,  1,      limestone,   nil,  nil,   air,         gravel,  1,      {potable},    25,    upland_max,     upland_min,     high,       middle,    {	193, 120,  54 } },

	--Barrenlands & Dunelands
		--[[15]]  { "Coastal Barrenland" ,  nil,        barren,  1,      gravel,  2,      limestone,   nil,  nil,   air,       gravel_w,  2,      {potable},     5,    coastal_max,    coastal_min,    mid_low,    x_low,     {	252, 226, 180 } },
		--[[16]]  { "Coastal Duneland"   ,  nil,          dune,  1,        sand,  2,      limestone,   nil,  nil,   air,       gravel_w,  2,      {potable},     5,    coastal_max,    coastal_min,    mid_high,   x_low,     {	245, 123,  36 } },
		--[[17]]  { "Lowland Barrenland" ,  nil,        barren,  1,      gravel,  3,      limestone,   nil,  nil,   air,         gravel,  1,      {potable},     5,    lowland_max,    lowland_min,    mid_low,    x_low,     {	222, 216, 170 } },
		--[[18]]  { "Lowland Duneland"   ,  nil,          dune,  1,        sand,  3,      limestone,   nil,  nil,   air,         gravel,  1,      {potable},     5,    lowland_max,    lowland_min,    mid_high,   x_low,     {	215, 113,  46 } },
		--[[19]]  { "Upland Barrenland"  ,  nil,        barren,  1,      gravel,  1,      limestone,   nil,  nil,   air,         gravel,  1,      {potable},    25,    upland_max,     upland_min,     mid_low,    x_low,     {	215, 216, 160 } },
		--[[20]]  { "Upland Duneland"    ,  nil,          dune,  1,        sand,  1,      limestone,   nil,  nil,   air,         gravel,  1,      {potable},    25,    upland_max,     upland_min,     mid_high,   x_low,     {	205, 103,  36 } },

	--Highland
		--[[21]]  { "Highland"           ,  nil,         hland,  1,      gravel,  1,      limestone,   nil,  nil,   air,         gravel,  1,      {potable},    25,    highland_max,   highland_min,   middle,     middle,    {	 76,  61,  54 } },
		--[[22]]  { "Highland Scree"     ,  nil,        gravel,  1,        silt,  1,      limestone,   nil,  nil,   air,         gravel,  1,      {potable},    25,    upper_limit,    highland_min,   x_low,      low,       {	 70,  70,  70 } },
		--[[23]]  { "Highland Rock"      ,  nil,           air,  1,      gravel,  2,      limestone,   nil,  nil,   air,         gravel,  1,      {potable},    25,    upper_limit,    highland_min,   x_high,     low,       {	 90,  90,  90 } },

	--Coasts
		--[[24]]  { "Sandy Beach"        ,  nil,          sand,  3,     sand_ws,  1,      limestone,   nil,  nil,   air,        sand_ws,  2,      {potable},     1,    tidal_max,      tidal_min,      high,       middle,    {	144, 141, 118 } },
		--[[25]]  { "Silty Beach"        ,  nil,          silt,  3,     silt_ws,  1,      limestone,   nil,  nil,   air,        silt_ws,  2,      {potable},     1,    tidal_max,      tidal_min,      middle,     high,      {	108,  85,  66 } },
		--[[26]]  { "Gravel Beach"       ,  nil,        gravel,  3,   gravel_ws,  1,      limestone,   nil,  nil,   air,      gravel_ws,  2,      {potable},     1,    tidal_max,      tidal_min,      low,        middle,    {	103, 101,  93 } },
		--[[27]]  { "Sandy Coast"        ,  nil,       sand_ws,  1,     sand_ws,  2,      limestone,   nil,  nil,   air,        sand_ws,  3,      {potable},     2,    littoral_max,   littoral_min,   high,       low,       {	144, 141, 128 } },
		--[[28]]  { "Silty Coast"        ,  nil,       silt_ws,  1,     silt_ws,  2,      limestone,   nil,  nil,   air,        silt_ws,  3,      {potable},     2,    littoral_max,   littoral_min,   middle,     high,      {	108,  85,  76 } },
		--[[29]]  { "Gravel Coast"       ,  nil,     gravel_ws,  1,   gravel_ws,  2,      limestone,   nil,  nil,   air,      gravel_ws,  3,      {potable},     2,    littoral_max,   littoral_min,   low,        low,       {	103, 101, 103 } },

	--Depths
		--[[30]]  { "Shallow Water"      ,  nil,       sand_ws,  1,     sand_ws,  3,      limestone,   nil,  nil,   nil,        sand_ws,  2,      {potable},     1,    neritic_max,    neritic_min,    middle,     middle,    {	 33,  55,  75 } },
		--[[31]]  { "Deep Water"         ,  nil,       silt_ws,  1,     silt_ws,  3,      granite,     nil,  nil,   nil,        sand_ws,  2,      {potable},    10,    oceanic_max,    oceanic_min,    middle,     middle,    {	 18,  25,  59 } },
		--[[32]]  { "Underground"        ,  nil,           nil,  nil,       nil,  nil,    granite,     nil,  nil,   nil,            nil,  nil,    {potable},    20,    abyssal_max,    abyssal_min,    middle,     middle,    {	 15,  15,  15 } },
		--[[33]]  { "Deep Underground"   ,  nil,           nil,  nil,       nil,  nil,    gneiss,      nil,  nil,   nil,            nil,  nil,    {lava},      100,    bedrock_max,    bedrock_min,    middle,     middle,    {	  5,   5,   5 } },
		--[[34]]  { "Mantle"             ,  nil,           nil,  nil,       nil,  nil,    lava,        nil,  nil,   nil,            nil,  nil,    {lava},      100,    mantle_max,     lower_limit,    middle,     middle,    {	105,   5,   5 } },

	}



--[[Loop to Iterate for Registrations]]--
for i in pairs(biome_list) do

   minetest.register_biome({
	 name               = biome_list[i][01],
	 node_dust          = biome_list[i][02],
	 node_top           = biome_list[i][03],
	 depth_top          = biome_list[i][04],
	 node_filler        = biome_list[i][05],
	 depth_filler       = biome_list[i][06],
	 node_stone         = biome_list[i][07],
	 node_water_top     = biome_list[i][08],
	 depth_water_top    = biome_list[i][09],
	 node_river_water   = biome_list[i][10],
	 node_riverbed      = biome_list[i][11],
	 depth_riverbed     = biome_list[i][12],
	 node_cave_liquid   = biome_list[i][13],
	 vertical_blend     = biome_list[i][14],
	 y_max              = biome_list[i][15],
	 y_min              = biome_list[i][16],
	 heat_point         = biome_list[i][17],
	 humidity_point     = biome_list[i][18],
   })
end


--[[Write .mt file for Amidst]]--

local function export_amidst_file()
	local wpath = minetest.get_worldpath()
	local wname = wpath:match( "([^/\\]+)$" )

	local filespec = wpath..'/amidst_biomes.mt'
	local file, err = io.open( filespec, 'w')

	if (err ~= nil) then
	   return
	end

	local str = string.format( '{ "name":"Exile v4 (%s)", "biomeList":[\n\n', wname )
	file:write( str )

	for k, v in pairs(biome_list) do
		str = string.format(
			'   { "name":%-24s, "color":{ "r":%3d, "g":%3d, "b":%3d },  "y_min":%6d,  "y_max":%6d,  "heat_point":%6.2f,  "humidity_point":%6.2f  },\n',
		   '"'..v[01]..'"', v[19][1], v[19][2], v[19][3], v[16], v[15], v[17],v[18] )
		file:write( str )
	end

   file:write( '\n] }\n' )

   file:flush()
   file:close()
end


if true then
	export_amidst_file()
end
