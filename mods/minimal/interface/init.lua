local modpath=minetest.get_modpath('minimal').."/interface"

minimal = minimal
dofile(modpath..'/item_names.lua')
dofile(modpath..'/infotext.lua')
dofile(modpath..'/themes.lua')
dofile(modpath..'/hotbar.lua') -- uses themes, keep it below that
dofile(modpath..'/hotbar_slots.lua') -- uses math_clamp from utility/
dofile(modpath..'/tooltips.lua')
dofile(modpath..'/inventory.lua') -- Inventory / Crafting formspec
dofile(modpath..'/playersettings.lua')

function minimal.warn_message(player, message)
    if not minetest.is_player(player) then return end
    local player_name = player:get_player_name()
    local hud = player:hud_add({
            hud_elem = "text",
            text = message,
            position = { x = 0.5, y = 1 },
            number = 0xFFFFFF,
            offset = { x = 0, y = -165 },
    })
    minetest.sound_play("failure", {to_player = player_name})
    minetest.after(
        1, function()
            if not minetest.is_player(player) then return end
            player:hud_remove(hud)
    end)
end
