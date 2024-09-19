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

-- remove accented characters from strings
-- return an other string
-- https://stackoverflow.com/questions/50459102/replace-accented-characters-in-string-to-standard-with-lua
function minimal.remove_accented (str)
  local tableAccents = {}
    tableAccents["À"] = "A"
    tableAccents["Á"] = "A"
    tableAccents["Â"] = "A"
    tableAccents["Ã"] = "A"
    tableAccents["Ä"] = "A"
    tableAccents["Å"] = "A"
    tableAccents["Æ"] = "AE"
    tableAccents["Ç"] = "C"
    tableAccents["È"] = "E"
    tableAccents["É"] = "E"
    tableAccents["Ê"] = "E"
    tableAccents["Ë"] = "E"
    tableAccents["Ì"] = "I"
    tableAccents["Í"] = "I"
    tableAccents["Î"] = "I"
    tableAccents["Ï"] = "I"
    tableAccents["Ð"] = "D"
    tableAccents["Ñ"] = "N"
    tableAccents["Ò"] = "O"
    tableAccents["Ó"] = "O"
    tableAccents["Ô"] = "O"
    tableAccents["Õ"] = "O"
    tableAccents["Ö"] = "O"
    tableAccents["Ø"] = "O"
    tableAccents["Ù"] = "U"
    tableAccents["Ú"] = "U"
    tableAccents["Û"] = "U"
    tableAccents["Ü"] = "U"
    tableAccents["Ý"] = "Y"
    tableAccents["Þ"] = "P"
    tableAccents["ß"] = "s"
    tableAccents["à"] = "a"
    tableAccents["á"] = "a"
    tableAccents["â"] = "a"
    tableAccents["ã"] = "a"
    tableAccents["ä"] = "a"
    tableAccents["å"] = "a"
    tableAccents["æ"] = "ae"
    tableAccents["ç"] = "c"
    tableAccents["è"] = "e"
    tableAccents["é"] = "e"
    tableAccents["ê"] = "e"
    tableAccents["ë"] = "e"
    tableAccents["ì"] = "i"
    tableAccents["í"] = "i"
    tableAccents["î"] = "i"
    tableAccents["ï"] = "i"
    tableAccents["ð"] = "eth"
    tableAccents["ñ"] = "n"
    tableAccents["ò"] = "o"
    tableAccents["ó"] = "o"
    tableAccents["ô"] = "o"
    tableAccents["õ"] = "o"
    tableAccents["ö"] = "o"
    tableAccents["ø"] = "o"
    tableAccents["ù"] = "u"
    tableAccents["ú"] = "u"
    tableAccents["û"] = "u"
    tableAccents["ü"] = "u"
    tableAccents["ý"] = "y"
    tableAccents["þ"] = "p"
    tableAccents["ÿ"] = "y"

  return str: gsub("[%z\1-\127\194-\244][\128-\191]*", tableAccents)
end

-- return a copy of str with no accent and lower cap
function minimal.make_search_string(str)
    return minimal.remove_accented(str):lower()
end

function minimal.send_message(player_name, message, duration)
    local player = minetest.get_player_by_name(player_name)
    if not minetest.is_player(player) then return end -- just in case of log out?

    local hud = player:hud_add({
            hud_elem = "text",
            text = message,
            position = { x = 0.5, y = 1 },
            number = 0xFFFFFF,
            offset = { x = 0, y = -80 },
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
