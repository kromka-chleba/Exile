unused_args = false
allow_defined_top = true

globals = {
	"crafting",
}

read_globals = { -- Read only, writing to them generates a warning
	"minetest", "core",
	"dump", "dump2", "table",
	"vector", "default",

    -- other exile's mods
	"minimal",
	"sfinv",
	"ItemStack", "awards",

	-- Testing
	"describe",
	"assert",
}

exclude_files = {".luacheckrc"}
