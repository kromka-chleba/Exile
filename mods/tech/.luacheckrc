unused_args = false
allow_defined_top = true

globals = {
    "tech"
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
    -- mods, mandatory dependencies for this mod
    "minimal" , "liquid_store", "nodes_nature",
    "crafting", "climate", "liquid_store",
    "backpacks", "doors", "ncrafting",
    "stairs", "HEALTH"
}

exclude_files = {".luacheckrc"}
