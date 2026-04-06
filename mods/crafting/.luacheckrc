unused_args = false
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
        "EXILE", "sfinv",
        -- optional dependencies in mod.conf
        "awards",
        -- Runtime globals
        "storage",
        -- Testing
    	"describe",
    	"assert",
}

globals = {"crafting"}
