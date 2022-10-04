--terrible little failed shelters

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
--local peaceful = minetest.settings:get_bool("only_peaceful_mobs", false)

ran_structures.register_structure("exile_hovels",{
	place_on = {
		--"nodes_nature:grassland_soil", "coastal_grassland_soil",
	--	"nodes_nature:shrubland_soil", "coastal_shrubland_soil",
		"group:sediment"
	},
	--spawn_by = {"nodes_nature:gravel"},
	--num_spawn_by = 2,
	fill_ratio = 0.06,--0.01,
	flags = "place_center_x, place_center_z",
	--not_near = { "exile_hut" },
	solid_ground = true,
	make_foundation = true,
	chunk_probability = 800,
	--y_offset = -1,
	y_max = 100,
	y_min = 1,
	biomes = {
		"Coastal Grassland", "Lowland Grassland", "Upland Grassland",
		"Coastal Shrubland", "Lowland Shrubland", "Upland Shrubland",
	},
	sidelen = 5,
	filenames = {
		modpath.."/schematics/drystack_ruin1.mts",
		modpath.."/schematics/burnt_hovel.mts"
	},
	--construct_nodes = {"tech:clay_storage_pot"},
--[[
	loot = {["tech:clay_storage_pot" ] ={
		{
			stacks_min = 3,
			stacks_max = 3,
			items = {
				{ itemstring = "tech:stick", weight = 10, amount_min = 1, amount_max=12 },
				{ itemstring = "tech:thatch", weight = 10, amount_min = 1, amount_max = 8 },
			}
		},
	}}
	]]
})
