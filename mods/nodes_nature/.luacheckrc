unused_args = false
allow_defined_top = true

globals = {
	"nodes_nature",
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
    "minimal", "stairs", "crafting", "climate", "naturalslopeslib", "HEALTH", "wielded_light", "tgcr", "mapchunk_shepherd", "ncrafting"
}

exclude_files = {".luacheckrc"}
