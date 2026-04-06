allow_defined_top = true
ignore = {"581"}

read_globals = { -- Read only, writing to them generates a warning
	"DIR_DELIM",
	"minetest", "core",
	"dump", "dump2", "table",
	"vector", "nodeupdate",
	"VoxelManip", "VoxelArea",
	"PseudoRandom", "ItemStack",
	"intllib", "string.split",
	"math.round", "PcgRandom",
        -- dependencies in mod.conf
        "ncrafting", "EXILE", "player_monoids", "sfinv", "climate",
        -- run-time dependencies
        "HEALTH", "triggers", "crafting"
}

globals = {"player_api"}
