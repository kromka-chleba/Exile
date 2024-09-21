-- regroups old player_api/clots.lua + old "clothing" mod
-- #TODO : add dev and licesne info (Dokimi etc) from old mod

-----------------------------------------------------------
--CLOTHING init
------------------------------------------------------------
-- unused except in test_clothing file as archive
-- registered cllabacks are all empty
clothing = {
	registered_callbacks = {
		on_update = {},
		on_equip = {},
		on_unequip = {},
	},
}

local modpath = minetest.get_modpath("player_api")

player_api = player_api

-- where cloths inventory and registration function are defined
dofile(modpath .. "/clothing/cloth_definitions.lua")
-- cloth composing on model
dofile(modpath .. "/clothing/cloth_composing.lua")
-- cloth effet other than visual (temperature)
dofile(modpath .. "/clothing/cloth_effects.lua")
-- clothing_tab and equip/unequip functions
dofile(modpath .. "/clothing/equip.lua")

-- update texture, temp and armor effects, and clothing tab formspec
function player_api.update_player(player)
    if not minetest.is_player(player) then
        return
    end
    -- update texture
    player_api.set_texture(player)
    -- update effects and clothing formspec
    player_api.update_equipment_effects(player)

	-- #TODO to remove when Mantar is done with testing
	-- Following is to copy each change to old cloth inventory (deprecitated)
	do
		local pinv = player:get_inventory()
		for i,group in ipairs(player_api.get_groups()) do
			pinv:set_stack("cloths",i, pinv:get_stack(group["name"],1))
	    end
	end
end
