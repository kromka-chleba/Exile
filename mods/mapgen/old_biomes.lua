--[[ Register Biomes ]]--
--[[ Local Variables ]]--
        --- Range Limits
                local upper_limit          =  31000
                local lower_limit          = -31000
        --- Promontory Altitudes
                local mountain_min         =    170
                local alpine_min           =    140
                local highland_min         =    100
                local upland_min           =     90
                local lowland_max          =      9
        --- Marine Altitudes
                local beach_max            =      5
                local beach_min            =    -10
                local shallow_ocean_min    =    -30
                local deep_ocean_min       =   -120
        --- Climate Ranges
                local extreme_high         =     95
                local high                 =     75
                local middle               =     50
                local low                  =     25
                local extreme_low          =      5
        --- Nodes
                local air       = "air"
                local alpine    = "nodes_nature:highland_soil"
                local basalt    = "nodes_nature:basalt"
                local brick_gr  = "nodes_nature:granite_brick"
                local brick_ls  = "nodes_nature:limestone_brick"
                local clay      = "nodes_nature:clay"
                local clay_wet  = "nodes_nature:clay_wet"
                local drystack  = "tech:drystack"
                local duff      = "nodes_nature:woodland_soil"
                local duff_dry  = "nodes_nature:woodland_dry_soil"
                local duff_wet  = "nodes_nature:woodland_soil_wet"
                local dune      = "nodes_nature:duneland_soil"
                local gneiss    = "nodes_nature:gneiss"
                local granite   = "nodes_nature:granite"
                local grass_bar = "nodes_nature:grassland_barren_soil"
                local grass_wet = "nodes_nature:grassland_soil_wet"
                local gravel    = "nodes_nature:gravel"
                local gravel_w  = "nodes_nature:gravel_wet"
                local gravel_ws = "nodes_nature:gravel_wet_salty"
                local ice       = "nodes_nature:ice"
                local lava      = "nodes_nature:lava_source"
                local limestone = "nodes_nature:limestone"
                local loam      = "nodes_nature:loam"
                local marsh_wet = "nodes_nature:marshland_soil_wet"
                local potable   = "nodes_nature:freshwater_source"
                local prairie   = "nodes_nature:grassland_soil"
                local sand      = "nodes_nature:sand"
                local sand_wet  = "nodes_nature:sand_wet"
                local sand_ws   = "nodes_nature:sand_wet_salty"
                local silt      = "nodes_nature:silt"
                local silt_wet  = "nodes_nature:silt_wet"
                local silt_ws   = "nodes_nature:silt_wet_salty"
                local snow      = "nodes_nature:snow"
                local snow_b    = "nodes_nature:snow_block"
                local stair_ds  = "stairs:stair_drystack"
                local stair_gr  = "stairs:stair_granite_block"
                local stair_ls  = "stairs:stair_limestone_block"
--[[ Biome Descriptions ]]--[[
        01.     Grassland: clay, open, yellow
        02.     Upland Grassland
        03.     Marshland: silt, dense reeds, red
        04.     Highland: gravel, dense grasses, purple
        05.     Duneland: sand, barren, orange
        06.     Woodland: loam, trees, green
        07.     Mountain Snowcaps: frozen places up high
        08.     Coasts and Oceans: Silty Beach
        09.     Lower Silty Beach
        10.     Sandy Beach
        11.     Lower Sandy Beach
        12.     Gravel Beach
        13.     Lower Gravel Beach
        14.     Shallow Ocean
        15.     Deep Ocean
        16.     Underground
        17.     Deep Underground
]]

--[[Define Biomes Table]]--
local biome_list = {
        --                                                                                               node   depth  node                 depth
        --                                      node   node       depth  node        depth   node        water  water  river    node        river  cave        node       dungeon    vert                                           heat                humidity
        --          name                        dust   top        top    filler      filler  stone       top    top    water    riverbed    bed    liquid      dungeon    stair      blend  y_max               y_min               point               point
        --[[01]]  { "grassland"              ,   nil,  prairie  ,    1,  clay     ,     2,   limestone,   nil,   nil,  air   ,  duff_wet ,    1,   {potable},  drystack,  stair_ds,    5,   upland_min       ,  beach_max        ,  middle           ,  middle          ,  },
        --[[02]]  { "upland_grassland"       ,  snow,  prairie  ,    1,  clay     ,     2,   limestone,   nil,   nil,  air   ,  grass_wet,    1,   {potable},  drystack,  stair_ds,    5,   highland_min     ,  upland_min       ,  middle           ,  middle          ,  },
        --[[03]]  { "marshland"              ,   nil,  marsh_wet,    1,  silt_wet ,     6,   limestone,   nil,   nil,  air   ,  silt_wet ,    5,   {potable},  drystack,  stair_ds,    2,   lowland_max      ,  beach_max        ,  high             ,  extreme_high    ,  },
        --[[04]]  { "highland"               ,  snow,  alpine   ,    1,  gravel   ,     1,   limestone,   nil,   nil,  snow_b,  gravel_w ,    3,   {potable},  drystack,  stair_ds,    5,   mountain_min     ,  highland_min     ,  low + 10         ,  high - 10       ,  },
        --[[05]]  { "duneland"               ,   nil,  dune     ,    1,  sand     ,     5,   limestone,   nil,   nil,  air   ,  grass_wet,    1,   {potable},  drystack,  stair_ds,    2,   lowland_max + 10 ,  beach_max        ,  middle           ,  extreme_low     ,  },
        --[[06]]  { "woodland"               ,   nil,  duff     ,    1,  loam     ,     3,   limestone,   nil,   nil,  air   ,  marsh_wet,    1,   {potable},  drystack,  stair_ds,    2,   lowland_max + 20 ,  beach_max        ,  low              ,  high            ,  },
        --[[07]]  { "snowcap"                ,  snow,  snow_b   ,    2,  gravel   ,     2,   limestone,   ice,     2,  ice   ,  gravel   ,    2,   {potable},  drystack,  stair_ds,    5,   upper_limit      ,  mountain_min     ,  low              ,  high            ,  },
        --[[08]]  { "silty_beach"            ,   nil,  silt     ,    1,  silt_ws  ,     2,   limestone,   nil,   nil,  air   ,  silt_wet ,    4,   {potable},  brick_ls,  stair_ls,    1,   beach_max        ,  1                ,  middle           ,  high            ,  },
        --[[09]]  { "silty_beach_lower"      ,   nil,  silt_ws  ,    1,  silt_ws  ,     2,   limestone,   nil,   nil,  air   ,  silt_wet ,    4,   {potable},  brick_ls,  stair_ls,    1,   2                ,  beach_min        ,  middle           ,  high            ,  },
        --[[10]]  { "sandy_beach"            ,   nil,  sand     ,    1,  sand_ws  ,     2,   limestone,   nil,   nil,  air   ,  sand_wet ,    4,   {potable},  brick_ls,  stair_ls,    1,   beach_max        ,  1                ,  middle           ,  middle          ,  },
        --[[11]]  { "sandy_beach_lower"      ,   nil,  sand_ws  ,    1,  sand_ws  ,     2,   limestone,   nil,   nil,  air   ,  sand_wet ,    4,   {potable},  brick_ls,  stair_ls,    1,   2                ,  beach_min        ,  middle           ,  middle          ,  },
        --[[12]]  { "gravel_beach"           ,   nil,  gravel   ,    1,  gravel_ws,     2,   limestone,   nil,   nil,  air   ,  gravel_w ,    4,   {potable},  brick_ls,  stair_ls,    1,   beach_max        ,  1                ,  extreme_low      ,  middle          ,  },
        --[[13]]  { "gravel_beach_lower"     ,   nil,  gravel_ws,    1,  gravel_ws,     2,   limestone,   nil,   nil,  air   ,  gravel_w ,    4,   {potable},  brick_ls,  stair_ls,    1,   2                ,  beach_min        ,  extreme_low      ,  middle          ,  },
        --[[14]]  { "shallow_ocean"          ,   nil,  sand_ws  ,    1,  sand_ws  ,     3,   limestone,   nil,   nil,  air   ,  sand_ws  ,    2,   {potable},  brick_ls,  stair_ls,    1,   beach_min        ,  shallow_ocean_min,  middle           ,  middle          ,  },
        --[[15]]  { "deep_ocean"             ,   nil,  silt_ws  ,    1,  silt_ws  ,     3,   granite  ,   nil,   nil,  air   ,  sand_ws  ,    2,   {potable},  brick_gr,  stair_gr,   10,   shallow_ocean_min,  deep_ocean_min   ,  middle           ,  middle          ,  },
        --[[16]]  { "underground"            ,   nil,  nil      ,  nil,  nil      ,   nil,   granite  ,   nil,   nil,  nil   ,  nil      ,  nil,   {potable},  brick_gr,  stair_gr,   20,   deep_ocean_min   ,  -1500            ,  middle           ,  middle          ,  },
        --[[17]]  { "deep_underground"       ,   nil,  nil      ,  nil,  nil      ,   nil,   gneiss   ,   nil,   nil,  nil   ,  nil      ,  nil,   {lava   },  nil     ,  nil     ,  100,   -1500            ,  lower_limit      ,  middle           ,  middle          ,  },
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
         node_dungeon       = biome_list[i][14],
         node_dungeon_stair = biome_list[i][15],
         vertical_blend     = biome_list[i][16],
         y_max              = biome_list[i][17],
         y_min              = biome_list[i][18],
         heat_point         = biome_list[i][19],
         humidity_point     = biome_list[i][20],
   })
end
