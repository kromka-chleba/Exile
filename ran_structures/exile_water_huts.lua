--Water huts
--huts on stilts
--not clear if this even works!

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
--local S = minetest.get_translator(modname)

local seed = minetest.get_mapgen_setting("seed")
local water_level = minetest.get_mapgen_setting("water_level")
local pr = PseudoRandom(seed)

--schematics by chmodsayshello
local schems = {
	modpath.."/schematics/water_hut1.mts",
}


local c_biomes = {
	"Sandy Beach",
	"Silty Beach",
	"Gravel Beach",
	"Sandy Coast",
	"Silty Coast",
	"Gravel Coast"
}

ran_structures.register_structure("exile_water_huts",{
	place_on = {"group:sediment"},
	spawn_by = {"group:water"},
	num_spawn_by = 3,
	noise_params = {
		offset = 0,
		scale = 1,--0.3,
		spread = {x = 25, y = 25, z = 25},--{x = 250, y = 250, z = 250},
		seed = 3,
		octaves = 3,
		persist = 0.4,--0.001,
		flags = "absvalue",
	},
	sidelen = 7,
	flags = "force_placement",
	biomes = c_biomes,
	y_max = water_level-4,
	y_min = 2,
	filenames = schems,
	y_offset = function(pr) return pr:next(-3,-1) end,
	loot = {
		["tech:clay_storage_pot"] = {
			stacks_min = 3,
			stacks_max = 10,
			items = {
				{ itemstring = "tech:stick", weight = 10, amount_min = 1, amount_max = 12 },
				{ itemstring = "tech:canoe", weight = 1, amount_min = 1, amount_max = 1 },
				{ itemstring = "nodes_nature:kagum_log", weight = 7, amount_min = 1, amount_max = 2 },
				{ itemstring = "tech:thatch", weight = 7, amount_min = 1, amount_max = 4 },
			},
			{
			stacks_min = 2,
			stacks_max = 6,
			items = {
				{ itemstring = "nodes_nature:anperla_seed", weight = 90, amount_min = 1, amount_max = 12 },
				}
			},{
			stacks_min = 3,
			stacks_max = 3,
			items = {
				{ itemstring = "nodes_nature:kagum_pod", weight = 20, amount_min = 1, amount_max = 12 },
				}
			},
		}
	}
})
