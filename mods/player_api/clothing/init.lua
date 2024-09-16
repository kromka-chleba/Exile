-- regroups old player_api/clots.lua + old "clothing" mod
-- #TODO : add dev and licesne info (Dokimi etc) from old mod

local modpath = minetest.get_modpath("player_api")

-- where cloths inventory and registration function are defined
dofile(modpath .. "/clothing/cloth_definitions.lua")
-- cloth composing on model
dofile(modpath .. "/clothing/cloth_composing.lua")
-- cloth effet other than visual (temperature)
dofile(modpath .. "/clothing/cloth_effects.lua")
-- clothing_tab and equip/unequip functions
dofile(modpath .. "/clothing/equip.lua")

function player_api.update_player(player)
    if not minetest.is_player(player) then
        return
    end
    player_api.set_texture(player)
    player_api.update_temp(player)
end
