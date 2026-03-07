-- Internationalization
local S = nodes_nature.S

nodes_nature = nodes_nature
local nn = nodes_nature
local trees = nn.trees


--Underwater Rooted plants
nodes_nature.searooted_list = {
    ---
    {"kelp",
     S("Riraemu"),
     {-2/16, 0.5, -2/16, 2/16, 3.5, 2/16},
     "seaweed", "nodes_nature:gravel_wet_salty",
     "nodes_nature_gravel.png^nodes_nature_mud.png",
     nodes_nature.node_sound_gravel_defaults(
         { dig = {name = "default_dig_snappy", gain = 0.2},
           dug = {name = "default_grass_footstep", gain = 0.25}, } ),
     4, 6, true
    },
    ---
    {"seagrass",
     S("Opaeko"),
     {-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
     "seaweed", "nodes_nature:sand_wet_salty",
     "nodes_nature_sand.png^nodes_nature_mud.png",
     nodes_nature.node_sound_dirt_defaults(
         { dig = {name = "default_dig_snappy", gain = 0.2},
           dug = {name = "default_grass_footstep", gain = 0.25}, } ),
     1,1, false},
    ---
    {"sea_lettuce",
     S("Aongao"),
     {-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
     "seaweed", "nodes_nature:silt_wet_salty",
     "nodes_nature_silt.png^nodes_nature_mud.png",
     nodes_nature.node_sound_dirt_defaults(
         { dig = {name = "default_dig_snappy", gain = 0.2},
           dug = {name = "default_grass_footstep", gain = 0.25},} ),
     1,1, false},
    ---
    {"nagaeo",
     S("Nagaeo"),
     {-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
     "seaweed", "nodes_nature:silt_wet_salty",
     "nodes_nature_silt.png^nodes_nature_mud.png",
     nodes_nature.node_sound_dirt_defaults(
         { dig = {name = "default_dig_snappy", gain = 0.2},
           dug = {name = "default_grass_footstep", gain = 0.25},} ),
     1,1, false},
    ---
    {"koaeako",
     S("Koaeako"),
     {-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
     "seaweed", "nodes_nature:sand_wet_salty",
     "nodes_nature_sand.png^nodes_nature_mud.png",
     nodes_nature.node_sound_dirt_defaults(
         { dig = {name = "default_dig_snappy", gain = 0.2},
           dug = {name = "default_grass_footstep", gain = 0.25},} ),
     1,1, false},
    ---
    {"imoaru",
     S("Imoaru"),
     {-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
     "seaweed", "nodes_nature:gravel_wet_salty",
     "nodes_nature_gravel.png^nodes_nature_mud.png",
     nodes_nature.node_sound_dirt_defaults(
         { dig = {name = "default_dig_snappy", gain = 0.2},
           dug = {name = "default_grass_footstep", gain = 0.25},} ),
     1,1, false},


}

local tree_list = {
    tangkal = {
        desc = S("Tangkal"),
        fruit_def = {
            groups = {edible = 1},
            selection_box = {-0.1, 0.1, -0.1, 0.1, 0.5, 0.1},
            dyecandidate = true,
            dominantcolor = "crimson",
            --tangkal fruit is good food, but bulky
            stack_max = minimal.stack_max_medium/2
        },
        leaf_def = {}
    },
    maraka = {
        desc = S("Maraka"),
        hardwood = true,
        fruit_def = {
            description = S("Maraka Nut"),
            groups = {edible = 1},
            selection_box = {-0.2, 0.2, -0.2, 0.2, 0.5, 0.2},
            dyecandidate = true,
            dominantcolor = "black"
        },
        -- maraka thorns
        leaf_def = {damage_per_second = 1}
    },
    panasee = {
        desc = S("Panasee"),
        hardwood = true,
        fruit_def = {
            groups = {edible = 1},
            selection_box = {-0.1, -0.2, -0.1, 0.1, 0.5, 0.1},
            place_param2 = 2,
            dyecandidate = true,
            dominantcolor = "yellow"
        },
        leaf_def = {}
    },
    sasaran = {
        desc = S("Sasaran"),
        fruit_def = {
            description = S("Sasaran Cone"),
            groups = {drops_leaves = 0, edible = 1},
            selection_box = {-0.1, -0.5, -0.1, 0.1, -0.1, 0.1},
            dyecandidate = true,
            dominantcolor = "yellow"
        },
        leaf_def = {
            groups = {drops_leaves = 0}
        }
    },
    warungaree = {
        desc = S("Warungaree"),
        hardwood = true,
        fruit_def = {
            description = S("Warungaree Seed"),
            selection_box = {-0.2, 0.2, -0.2, 0.2, 0.5, 0.2},
            dyecandidate = true,
            dominantcolor = "black"
        },
        leaf_def = {}
    },
    jalowiec = {
        desc = S("Yalovy"),
        log_description = S("Yalovy Shrub"),
        hardwood = true,
        fruit_def = {
            description = S("Yalovy Cone"),
            groups = {drops_leaves = 0, edible = 1},
            selection_box = {-0.1, -0.5, -0.1, 0.1, -0.1, 0.1},
            dyecandidate = true,
            dominantcolor = "yellow",
            wield_image = "nodes_nature_jalowiec_cone_wield.png"
        },
        leaf_def = {
            damage_per_second = 1,
            groups = {drops_leaves = 0}
        }
    },
    kagum = {
        desc = S("Kagum"),
        fruit_def = {
            description = S("Kagum Pod"),
            selection_box = {-0.1, -0.1, -0.1, 0.1, 0.5, 0.1},
            dyecandidate = true,
            light_source = 2,
            groups = {bioluminescent=1}
        },
        leaf_def = {}
    },
    amma = {
        desc = S("Amma"),
        fruit_def = {
            description = S("Amma Nut"),
            groups = {edible = 1},
            selection_box = {-0.2, 0.2, -0.2, 0.2, 0.5, 0.2},
            dyecandidate = true,
            dominantcolor = "black"
        },
        leaf_def = {}
    },
    daoja = {
        desc = S("Daoja"),
        hardwood = true,
        fruit_def = {
            description = S("Daoja Berry"),
            groups = {edible = 1},
            selection_box = {-0.1, -0.5, -0.1, 0.1, -0.3, 0.1},
            dyecandidate = true,
            dominantcolor = "crimson"
        },
        leaf_def = {}
    },
    tulatula = {
        desc = S("Tulatula"),
        hardwood = false,
        fruit_def = {
            description = S("Tulatula Pods"),
            groups = { edible = 1 },
            selection_box = {-0.2, 0.2, -0.2, 0.2, 0.5, 0.2},
            dyecandidate = true,
            dominantcolor = "indigo"
        },
        leaf_def = {}
    },
}

for treename,treedef in pairs(tree_list) do
    trees.register_tree(treename, treedef)
end
-- force update of old node names
minetest.register_alias_force("nodes_nature:maraka_nut",
                              "nodes_nature:maraka_fruit")
minetest.register_alias_force("nodes_nature:sasaran_cone",
                              "nodes_nature:sasaran_fruit")
minetest.register_alias_force("nodes_nature:jalowiec_cone",
                              "nodes_nature:jalowiec_fruit")
minetest.register_alias_force("nodes_nature:kagum_pod",
                              "nodes_nature:kagum_fruit")
minetest.register_alias_force("nodes_nature:amma_nut",
                              "nodes_nature:amma_fruit")
minetest.register_alias_force("nodes_nature:daoja_berry",
                              "nodes_nature:daoja_fruit")

-- prior to another fix (I don't know how I didn't notice in testing!!! - TPH)
-- forgot to define drops_leaves as 0 and the evergreens became seasonal!
minetest.register_alias_force("nodes_nature:sasaran_fruit_marker",
                              "nodes_nature:sasaran_fruit")
minetest.register_alias_force("nodes_nature:jalowiec_fruit_marker",
                              "nodes_nature:jalowiec_fruit")
minetest.register_alias_force("nodes_nature:sasaran_leaves_marker",
                              "nodes_nature:sasaran_leaves")
minetest.register_alias_force("nodes_nature:jalowiec_leaves_marker",
                              "nodes_nature:jalowiec_leaves")
