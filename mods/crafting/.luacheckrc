unused_args = false
allow_defined_top = true

globals = {
	"crafting",
}

read_globals = { -- Read only, writing to them generates a warning
	"minetest", "core",
	"dump", "dump2", "table",
	"vector", "default",

	"minimal",
	"sfinv",
	"ItemStack", "awards",

	-- Testing
	"describe",
	"it",
	"assert",
}

exclude_files = {".luacheckrc"}
