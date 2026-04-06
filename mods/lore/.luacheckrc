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
	"math.round",
        -- dependencies in mod.conf
        "nodes_nature", "player_api", "EXILE", "HEALTH", "sfinv",
        -- optional dependencies in mod.conf
        "rspawn", "tutorial",
        -- runtime dependencies
        "region", "climate"        
}

globals = {"lore"}
