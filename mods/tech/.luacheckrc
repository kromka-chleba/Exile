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
        -- mods, mandatory dependencies for this mod
        "EXILE", "nodes_nature", "stairs", "crafting", "climate",
        "liquid_store", "backpacks", "doors", "ncrafting", "HEALTH",
        "sfinv", "bed_rest", "player_api", "tgcr", "grafitti",
        -- optional dependencies
        "ucsigns"
}


globals = {
    "tech", "lightsource", "lightsource_description",
}
