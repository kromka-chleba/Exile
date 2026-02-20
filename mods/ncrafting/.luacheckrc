unused_args = false
allow_defined_top = true

globals = {
    "ncrafting"
}

-- Read only, writing to them generates a warning
read_globals = {
    -- for all game as in main .luacheckrc"
	"core",
	"dump", "dump2", "table",
	"vector", "nodeupdate",
	"VoxelManip", "VoxelArea",
	"PseudoRandom", "ItemStack",
	"intllib", "string.split",
    -- mods, mandatory dependencies for this mod
    "minimal", "climate", "sfinv"
}

exclude_files = {".luacheckrc"}
