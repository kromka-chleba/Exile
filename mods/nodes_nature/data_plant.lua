-- Internationalization
local S = nodes_nature.S


--Underwater Rooted plants
searooted_list = {
	---
	{"kelp",
		S("Riraemu"),
		{-2/16, 0.5, -2/16, 2/16, 3.5, 2/16},
		"seaweed", "nodes_nature:gravel_wet_salty",
		"nodes_nature_gravel.png^nodes_nature_mud.png",
		nodes_nature.node_sound_gravel_defaults({	dig = {name = "default_dig_snappy", gain = 0.2}, dug = {name = "default_grass_footstep", gain = 0.25},}),
		4,6, true},
	 ---
	{"seagrass",
		S("Opaeko"),
		{-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
		"seaweed", "nodes_nature:sand_wet_salty",
		"nodes_nature_sand.png^nodes_nature_mud.png",
		nodes_nature.node_sound_dirt_defaults({	dig = {name = "default_dig_snappy", gain = 0.2}, dug = {name = "default_grass_footstep", gain = 0.25},}),
		1,1, false},
	 ---
	{"sea_lettuce",
		S("Aongao"),
		{-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
		"seaweed", "nodes_nature:silt_wet_salty",
		"nodes_nature_silt.png^nodes_nature_mud.png",
		nodes_nature.node_sound_dirt_defaults({	dig = {name = "default_dig_snappy", gain = 0.2}, dug = {name = "default_grass_footstep", gain = 0.25},}),
		1,1, false},
	 ---
	{"nagaeo",
		S("Nagaeo"),
		{-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
		"seaweed", "nodes_nature:silt_wet_salty",
		"nodes_nature_silt.png^nodes_nature_mud.png",
		nodes_nature.node_sound_dirt_defaults({	dig = {name = "default_dig_snappy", gain = 0.2}, dug = {name = "default_grass_footstep", gain = 0.25},}),
		1,1, false},
	 ---
	{"koaeako",
		S("Koaeako"),
		{-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
		"seaweed", "nodes_nature:sand_wet_salty",
		"nodes_nature_sand.png^nodes_nature_mud.png",
		nodes_nature.node_sound_dirt_defaults({	dig = {name = "default_dig_snappy", gain = 0.2}, dug = {name = "default_grass_footstep", gain = 0.25},}),
		1,1, false},
		---
	{"imoaru",
		S("Imoaru"),
		{-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
		"seaweed", "nodes_nature:gravel_wet_salty",
		"nodes_nature_gravel.png^nodes_nature_mud.png",
		nodes_nature.node_sound_dirt_defaults({	dig = {name = "default_dig_snappy", gain = 0.2}, dug = {name = "default_grass_footstep", gain = 0.25},}),
		1,1, false},


}

