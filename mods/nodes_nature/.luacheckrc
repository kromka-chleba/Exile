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
        "EXILE", "stairs", "crafting", "climate", "naturalslopeslib",
        "HEALTH", "wielded_light", "tgcr", "mapchunk_shepherd", "ncrafting",
}

globals = {"nodes_nature"}
