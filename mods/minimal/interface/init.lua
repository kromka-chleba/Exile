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

function minimal.send_message(player_name, message, duration)
    local player = minetest.get_player_by_name(player_name)
    if not minetest.is_player(player) then return end -- just in case of log out?

    local hud = player:hud_add({
            hud_elem = "text",
            text = message,
            position = { x = 0.5, y = 1 },
            number = 0xFFFFFF,
            offset = { x = 0, y = -165 },
    })
    minetest.after(duration or 1, function()
                       if not minetest.is_player(player) then return end
                       player:hud_remove(hud)
    end)
end
function minimal.warn_message(player_name, message, duration)
    if not minetest.get_player_by_name(player_name) then return end

    minetest.sound_play("failure", {to_player = player_name})
    minimal.send_message(player_name, message, duration)
end
