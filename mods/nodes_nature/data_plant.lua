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

trees = {}

trees.tree_base_tree_growth = 31000
trees.tree_base_leaf_growth = 21000
trees.base_fruit_growth = 19000

tree_base_tree_growth = 31000
tree_base_leaf_growth = 21000
tree_base_fruit_growth = 19000

--name, Desc, fruit name, fruit desc, p2 fruit,selbox_fruit, wood hardness, hardwood, dyecandidate, dye
tree_list = {
	--{"maraka", S("Maraka Tree"), "maraka_nut", S("Maraka Nut"), 1, {-0.2, 0.2, -0.2, 0.2, 0.5, 0.2},1, true, 1, "black"},
	--{"tangkal", S("Tangkal Tree"), "tangkal_fruit", S("Tangkal Fruit"), 1, {-0.1, 0.1, -0.1, 0.1, 0.5, 0.1},2, false, 1, "crimson"},
	{"sasaran", S("Sasaran Tree"), "sasaran_cone", S("Sasaran Cone"), 1, {-0.1, -0.5, -0.1, 0.1, -0.1, 0.1},2, false, 1, "yellow"},
	{"jalowiec", S("Jalowiec Shrub"), "jalowiec_cone", S("Jalowiec Cone"), 1, {-0.1, -0.5, -0.1, 0.1, -0.1, 0.1},1, true, 1, "yellow"},
	{"kagum", S("Kagum Tree"), "kagum_pod", S("Kagum Pod"), 1, {-0.1, -0.1, -0.1, 0.1, 0.5, 0.1},2, false, 1},
	--{"panasee", S("Panasee Tree"), "panasee_fruit", S("Panasee Fruit"), 2, {-0.1, -0.2, -0.1, 0.1, 0.5, 0.1},1, true, 1, "yellow"},
	{"amma", S("Amma Tree"), "amma_nut", S("Amma nut"), 1, {-0.2, 0.2, -0.2, 0.2, 0.5, 0.2},2, false, 1, "black"},
	{"daoja", S("Daoja Tree"), "daoja_berry", S("Daoja Berry"), 1, {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},1, true, 1, "crimson"},
}
