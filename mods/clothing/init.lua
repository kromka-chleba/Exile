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

-- Integration: without this skinsdb crashes
clothing.register_on_update = function() end
--dofile(modpath.."/test_clothing.lua") --bug testing
