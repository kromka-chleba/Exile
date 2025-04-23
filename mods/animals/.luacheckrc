unused_args = false
allow_defined_top = true

globals = {
    "animals"
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
    "minimal", "mobkit", "nodes_nature", "HEALTH", "climate"
}

exclude_files = {".luacheckrc"}
