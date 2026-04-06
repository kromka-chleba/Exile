allow_defined_top = true
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
         "EXILE", "climate", "nodes_nature", "doors", "HEALTH", "tech", "sfinv",
         "mobkit",
        -- optional dependencies in mod.conf
        "creative"
}
globals = {"artifacts", "player_api",}
