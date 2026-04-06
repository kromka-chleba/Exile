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
}

exclude_files = {".luacheckrc"}

files["mods/mobkit"] = {
    globals = {"mobkit"}
}

files["mods/tgcr"] = {
    globals = {"tgcr"},
    read_globals = {
        -- optional dependencies in mod.conf
        "naturalslopeslib"
    }
}
