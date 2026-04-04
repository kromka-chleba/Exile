local modpath=minetest.get_modpath('exile_game').."/interface"

-- color of tooltips in description and display in HUD
EXILE.TOOLTIP_COLOR = "#ccccff"
-- #TODO make it be a player setting, as some player find it hardly visible
-- in a general way, a dedicated color tab in player settings could be great.

dofile(modpath..'/item_names.lua') -- display in HUD
dofile(modpath..'/infotext.lua')
dofile(modpath..'/themes.lua')
dofile(modpath..'/hotbar.lua') -- uses themes, keep it below that
dofile(modpath..'/hotbar_slots.lua') -- uses math_clamp from utility/
dofile(modpath..'/tooltips.lua')
dofile(modpath..'/playersettings.lua')

-- remove accented characters from strings
-- return an other string
-- https://stackoverflow.com/questions/50459102/replace-accented-characters-in-string-to-standard-with-lua
function EXILE.remove_accented (str)
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
function EXILE.make_search_string(str)
    if not str then
        return nil
    end
    return EXILE.remove_accented(str):lower()
end

-- sorts player and player_name for send_messages functionality (maybe make into a proper EXILE function?)
-- returns back as player, player_name or nil on failure
local function sort_player_and_name(player, player_name)
    if minetest.is_player(player_name) then
        -- switch player and player_name
        if type(player) == "string" then
            -- we're replacing player with player_name, creating a temporary value to set player_name
            local temp = player
            player = player_name
            player_name = temp
        -- switch player to player_name, get player's name for player_name
        else
            player = player_name
            player_name = player:get_player_name()
        end
    elseif type(player) == "string" then
        -- switch player_name and player
        if minetest.is_player(player_name) then
            -- we're replacing player_name with player, creating a temporary value to set player
            local temp = player_name
            player_name = player
            player = temp
        -- switch player_name to player, get player obj from player_name
        else
            player_name = player
            player = minetest.get_player_by_name(player)
        end
    -- ascertain values if one is nil
    -- get player_name from player or get player from player_name
    else
        player = minetest.is_player(player) and player
        player_name = type(player_name) == "string" and player_name
        -- don't overwrite if already fine, otherwise try to seek proper values
        player = player or player_name and minetest.get_player_by_name(player_name)
        player_name = player_name or player and player:get_player_name()
    end
    -- only return results on success
    if minetest.is_player(player) and type(player_name) == "string" then
        return player, player_name
    end
end

-- messages displayed stored in "messages_occupied" to not display over an other message
local messages_occupied = {}
local message_offset = { x = -40, y = 20 }

function EXILE.send_message(player, player_name, message, duration)
    player, player_name = sort_player_and_name(player, player_name)
    -- player might've left, let's not error
    if not player then return end
    if type(message) ~= "string" then
        error("EXILE.send_message: got invalid type for message, got '"..type(message).."'")
    end

    -- check or set set duration
    -- if duration not specified, assumes a 20 char string to last a second
    -- then calculates duration by dividing message length by 20 (e.g. 35/20 = 1.75sec)
    duration = type(duration) == "number" and duration or #message/20

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
        -- player still online
        if minetest.is_player(player) then
            player:hud_remove(hud)
        -- player left
        else
            messages_occupied[player_name] = nil
            return
        end
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

-- produces error noise if successfully sends message
function EXILE.warn_message(player, player_name, ...)
    player, player_name = sort_player_and_name(player, player_name)
    -- player might've signed off, don't error
    if not player then return end
    -- only play sound on success
    if EXILE.send_message(player, player_name, ...) then
        minetest.sound_play("failure", {to_player = player_name})
    end
end
