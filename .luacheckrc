unused_args = false
allow_defined_top = true

read_globals = { -- Read only, writing to them generates a warning
	"DIR_DELIM",
	"minetest", "core",
	"dump", "dump2", "table",
	"vector", "nodeupdate",
	"VoxelManip", "VoxelArea",
	"PseudoRandom", "ItemStack",
	"intllib", "string.split",
	"math.round",
}

exclude_files = {".luacheckrc"}

files["mods/animals"] = {
    globals = {"animals"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal", "mobkit", "nodes_nature", "HEALTH", "climate"
    }
}

files["mods/artifacts"] = {
    globals = {"artifacts"},
    read_globals = {
        -- dependencies in mod.conf
        "player_api", "minimal", "climate", "nodes_nature", "doors", "HEALTH", "tech",
        -- optional dependencies in mod.conf
        "creative"
    }
}

files["mods/backpacks"] = {
    globals = {"backpacks"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal"
    }
}

files["mods/bed_rest"] = {
    globals = {"bed_rest"},
    read_globals = {
        -- dependencies in mod.conf
        "player_api", "player_monoids", "minimal"
    }
}

files["mods/bones"] = {
    globals = {"bones"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal"
    }
}

files["mods/canoe"] = {
    globals = {"canoe"},
    read_globals = {
        -- dependencies in mod.conf
        "player_api", "crafting", "nodes_nature"
    }
}

files["mods/climate"] = {
    globals = {"climate"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal", "lightning"
    }
}

files["mods/crafting"] = {
    globals = {"crafting"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal", "sfinv",
        -- optional dependencies in mod.conf
        "awards",
        -- others from Exile
        "minimal", "sfinv",
        -- others from original mod
        "default",
        -- Testing
    	"describe",
    	"assert",
    }
}

files["mods/creative"] = {
    globals = {"creative"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal", "sfinv"
    }
}

files["mods/doors"] = {
    globals = {"doors"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal"
    }
}

files["mods/exile_env_sounds"] = {
    read_globals = {
        -- dependencies in mod.conf
        "minimal", "nodes_nature"
    }
}

files["mods/grafitti"] = {
    read_globals = {
        -- dependencies in mod.conf
        "minimal"
    }
}

files["mods/health"] = {
    globals = {"HEALTH"},
    read_globals = {
        -- dependencies in mod.conf
        "sfinv", "player_monoids", "climate", "bed_rest", "ncrafting", "minimal"
    }
}

files["mods/inferno"] = {
    globals = {"inferno"},
    read_globals = {
        -- dependencies in mod.conf
        "crafting"
    }
}

files["mods/lightning"] = {
    globals = {"lightning"},
}

files["mods/liquid_store"] = {
    globals = {"liquid_store"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal", "nodes_nature"
    }
}

files["mods/lore"] = {
    globals = {"lore"},
    read_globals = {
        -- dependencies in mod.conf
        "nodes_nature", "player_api", "minimal", "HEALTH",
        -- optional dependencies in mod.conf
        "rspawn", "tutorial-exile",
    }
}

files["mods/mapgen"] = {
    globals = {"deco"},
    read_globals = {
        -- dependencies in mod.conf
        "nodes_nature", "stairs", "tech", "animals"
    }
}

files["mods/megamorph"] = {
    globals = {"megamorph"},
    read_globals = {
        -- dependencies in mod.conf
        "nodes_nature", "tech", "artifacts"
    }
}

files["mods/minimal"] = {
    globals = {"minimal", "exile"},
    read_globals = {
        -- dependencies in mod.conf
        "wielded_light", "sfinv"
    }
}

files["mods/mobkit"] = {
    globals = {"mobkit"}
}

files["mods/ncrafting"] = {
    globals = {"ncrafting"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal", "climate"
    }
}

files["mods/nodes_nature"] = {
    globals = {"nodes_nature"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal", "stairs", "crafting", "climate", "naturalslopeslib", "HEALTH", "wielded_light", "tgcr", "mapchunk_shepherd", "ncrafting",
    }
}

files["mods/player_api"] = {
    globals = {"player_api"},
    read_globals = {
        -- dependencies in mod.conf
        "ncrafting", "minimal", "player_monoids", "sfinv", "climate"
    }
}

files["mods/player_monoids"] = {
    globals = {"player_monoids"}
}

files["mods/ring"] = {
    read_globals = {
        -- dependencies in mod.conf
        "nodes_nature", "artifacts"
    }
}

files["mods/ropes"] = {
    globals = {"ropes"},
    read_globals = {
        -- dependencies in mod.conf
        "nodes_nature", "artifacts"
    }
}

files["mods/sfinv"] = {
    globals = {"sfinv"}
}

files["mods/spawnex"] = {
    read_globals = {
        -- dependencies in mod.conf
        "mapchunk_shepherd", "volcano", "minimal"
    }
}

files["mods/spears"] = {
    read_globals = {
        -- optional dependencies in mod.conf
        "default", "minimal", "tech"
    }
}

files["mods/stairs"] = {
    globals = {"stairs"}
}

files["mods/tech"] = {
    globals = {"tech"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal" ,"nodes_nature", "stairs", "crafting",
        "climate", "liquid_store", "backpacks", "doors",
         "ncrafting", "HEALTH",
        -- optional dependencies in mod.conf
        "ucsigns"
    }
}

files["mods/tgcr"] = {
    globals = {"tgcr"},
    read_globals = {
        -- optional dependencies in mod.conf
        "naturalslopeslib"
    }
}

files["mods/tutorial_exile"] = {
    globals = {"tutorial"},
    read_globals = {
        -- dependencies in mod.conf
        "minimal", "ncrafting", "player_api", "HEALTH",
        -- optional dependencies in mod.conf
        "worldedit"
    }
}

files["mods/volcano"] = {
    globals = {"volcano"},
    read_globals = {
        -- dependencies in mod.conf
        "nodes_nature"
    }
}

files["mods/tutorial"] = {
    globals = {"wielded_light"},
    read_globals = {
        -- dependencies in mod.conf
        "default", "hades_core"
    }
}
