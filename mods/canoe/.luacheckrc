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
        "EXILE","player_api", "crafting",
        -- runtime globals
        "mobkit"
}

globals = {"canoe"}
