unused_args = false
allow_defined_top = true

globals = {
	"ncrafting",
}

read_globals = { -- Read only, writing to them generates a warning
    "DIR_DELIM",
    "minetest", "core",
    "dump", "dump2", "table",
    "vector", "nodeupdate",
    "VoxelManip", "VoxelArea",
    "PseudoRandom", "ItemStack",
    "intllib", "string.split",

    -- from depends in mod.conf
    "minimal", "climate"
}

exclude_files = {".luacheckrc"}
