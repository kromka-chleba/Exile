------------------------------------------------------------
--CLOTHING init
------------------------------------------------------------
clothing = {
	registered_callbacks = {
		on_update = {},
		on_equip = {},
		on_unequip = {},
	},
	player_textures = {}
}

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/api.lua")
--dofile(modpath.."/test_clothing.lua") --bug testing
