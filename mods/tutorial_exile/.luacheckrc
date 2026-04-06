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
        "EXILE", "ncrafting", "player_api", "HEALTH",
        "climate", "nodes_nature",
        -- optional dependencies in mod.conf
        "worldedit",
        -- runtime dependencies
        "region", "triggers", "zone"
}

globals = {"tutorial"}
