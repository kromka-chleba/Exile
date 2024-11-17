local modpath=minetest.get_modpath('minimal').."/interface"

minimal = minimal
dofile(modpath..'/item_names.lua')
dofile(modpath..'/infotext.lua')
dofile(modpath..'/themes.lua')
dofile(modpath..'/hotbar.lua') -- uses themes, keep it below that
dofile(modpath..'/hotbar_slots.lua') -- uses math_clamp from utility/
dofile(modpath..'/tooltips.lua')
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
    if not str then
        return nil
    end
    return minimal.remove_accented(str):lower()
end

-- messages displayed stored in "messages_occupied" to not display over an other message
local messages_occupied = {}
local message_offset = { x = -40, y = 20 }

function minimal.send_message(player, message, duration)
    if type(message) ~= "string" then
        error("minimal.send_message: got invalid type for message, got '"..type(message).."'")
    end
    -- get player's name for table
    local player_name = type(player) == "string" and player
    -- prefer player object, permit player name
    player = type(player) == "userdata" and player or
        type(player) == "string" and minetest.get_player_by_name(player)
    if not minetest.is_player(player) then return end -- logged out or wasn't valid
    player_name = player_name or player:get_player_name()

    -- check or set set duration
    duration = type(duration) == "number" and duration or 1

    local occupied = messages_occupied[player_name]
    -- convert message into table
    message = {text = message, y = message_offset.y}
    local index = 1
    -- created messages_occupied table for player
    if not occupied then
        occupied = {}
        messages_occupied[player_name] = occupied
        occupied[index] = message
    -- check for first free spot to display message
    else
        -- iterate to 1 over
        for i=1,(#occupied + 1) do
            index = i
            -- found free spot, end loop
            if not occupied[i] then
                break
            end
        end
        -- set message y coordinate
        message.y = message.y + ((index-1) * 20)
        occupied[index] = message
    end

    -- adding the message
    local hud = player:hud_add({
            hud_elem = "text",
            position = { x = 1, y = 0 },
            offset = {x = message_offset.x, y = message.y},
            text = message.text,
            number = 0xFFFFFF,
            scale = {x=50,y=20}, --not working, don't know why
            --z_index=100,
            alignment= {x = -1, y = 1}, --right align
    })
    message.hud = hud

    -- reset after a certain amount of time
    minetest.after(duration, function()
        -- player left
        if not minetest.is_player(player) then
            messages_occupied[player_name] = nil
            return
        end
        player:hud_remove(hud)
        -- if occupied exists and can find self
        if occupied and occupied[index] then
            -- remove index, remove occupied as a whole if no more messages left
            occupied[index] = nil
            if #occupied == 0 then
                messages_occupied[player_name] = nil
            end
        end
    end)

    -- return message table on success
    return message
end

function minimal.warn_message(player_name, message, duration)
    if not minetest.get_player_by_name(player_name) then return end

    minetest.sound_play("failure", {to_player = player_name})
    minimal.send_message(player_name, message, duration)
end
