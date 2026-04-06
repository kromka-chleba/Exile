allow_defined_top = true

globals = {
    "stairs"
}

-- Read only, writing to them generates a warning
read_globals = {
    -- for all game as in main .luacheckrc
	"minetest", "core",
    "DIR_DELIM",
	"minetest", "core",
	"dump", "dump2", "table",
	"vector", "nodeupdate",
	"VoxelManip", "VoxelArea",
	"PseudoRandom", "ItemStack",
	"intllib", "string.split",
	"math.round", "PcgRandom",
        -- mods, mandatory dependencies for this mod
        "minimal", "crafting"
}
