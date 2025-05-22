unused_args = false
allow_defined_top = true

globals = {
    "HEALTH"
}

read_globals = { -- Read only, writing to them generates a warning
	"DIR_DELIM",
	"minetest", "core",
	"dump", "dump2", "table",
	"vector", "nodeupdate",
	"VoxelManip", "VoxelArea",
	"PseudoRandom", "ItemStack",
	"intllib", "string.split",
    -- dependencies in mod.conf
    "sfinv", "player_monoids", "climate", "bed_rest", "ncrafting", "minimal"
}

exclude_files = {".luacheckrc"}
