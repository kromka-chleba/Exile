minimal = minimal
local S = minimal.S

function minimal.invlists2string(lists)
    local cleantable = {}
    if not lists then return end
    for listname, list in pairs(lists) do
        cleantable[listname] = {}
        for i = 1, #list do
            cleantable[listname][i] = list[i]:to_string()
        end
    end
    return minetest.serialize(cleantable)
end
function minimal.string2invlists(string)
    local table = minetest.deserialize(string)
    if not table then return end
    local newlist = {}
    for listname, list in pairs(table) do
        newlist[listname] = {}
        for i = 1, #list do
            newlist[listname][i] = ItemStack(list[i])
        end
    end
    return newlist
end

local __click_count_ready = {}
function minimal.click_count_ready(name, id, pos, count, timeout)
    -- { playername_id = { timeout=time() + __timeout, count = __use_count } }
    local timeout = timeout or 2 -- 2 second window for timeout
    local count = count or 3 -- number of clicks
    local ready = __click_count_ready[name.."_"..id]
    if ready and ready.pos == pos then
        ready.count = ready.count + 1
        if os.time() < ready.timeout then
            if ready.count >= count then
                __click_count_ready[name.."_"..id]  = nil
                return true
            else
                return false
            end
        end
    end
    __click_count_ready[name.."_"..id] = {
        timeout = os.time() + timeout,
        count = 1,
        pos = pos,
    }
    return false
end

function minimal.get_pointed_thing(player,rn, obj, liq)
    -- Gets the pointed node or object. Player objects will return
    --  a non-standard type of "player"

    -- params: rn = custom "range" to override, return obj or liq if true

    -- get the player by name if string
    if (type(player) == "string") then
        player = minetest.get_player_by_name(player)
    end
    local range = 5 -- out to 5 nodes
    if not minetest.is_player(player) then
        error("exile_game.get_pointed_thing: Invalid player specified (or "..
              "improper name), got type "..type(player))
    elseif type(rn) == "number" then
        -- override with provided range number if a number
        range = rn
    else
        -- get range of player's wielded item and use that
        local w_itemdef = player:get_wielded_item()
        w_itemdef = w_itemdef:get_definition()
        if w_itemdef and type(w_itemdef.range) == "number" then
            range = w_itemdef.range
        end
    end
    local ppos = player:get_pos()
    local offset = player:get_eye_offset()
    local eye_height = player:get_properties().eye_height + ( offset.y / 10 )
    ppos.y = ppos.y + eye_height
    local lookdir = vector.multiply(player:get_look_dir(), range)
    local pointpos = vector.add(ppos, lookdir)
    local ray = minetest.raycast(ppos, pointpos, obj or false, liq or false)
    local point
    repeat
        point = ray:next()
    until ( not point ) -- nil
        or point.type == "node"
        or (point.type == "object"
            and point.ref ~= player) -- object + not player
    if point and point.type
        and point.type == "object" and point.ref:is_player() then
        point.type = "player" -- differentiate players from lua entities
    end
    return point
end

function minimal.sanitize_string(badstring)
    assert(type(badstring) == "string",
           "exile_game.sanitize_string: Invalid badstring given, got "..
           type(badstring))
    local disallowed = { "\\", "{", "}", "^", ";",
                         --lua magic characters
                         "%(", "%)", "%[", "%]", "%.", "%$",
                         "%^", "%%", "%+", "%-", "%*", "%?"  }
    badstring:trim():lower()
    for i in ipairs(disallowed) do
        badstring = badstring:gsub(disallowed[i],"")
    end
    return badstring
end

-- merges content of t1 and other tables into a new table
-- if t1 and the other table contain identical keys, values from
-- t1 are overwritten with values from the other table
function minimal.merge_tables(t1,...)
    assert(type(t1) ==
           "table",
           "exile_game.merge_tables: invalid first parameter given, expected table got "..type(t1))
    local mergeable = {...}
    assert(#mergeable >= 1,
           "exile_game.merge_tables: need a table to merge with")
    local new_table = table.copy(t1)
    for tind,tbl in pairs(mergeable) do -- table index, table
        assert(type(tbl) == "table",
               "exile_game.merge_tables: invalid value given at paramter "..
               tind..", expected table got "..type(tbl))
        -- merge tables
        for key,value in pairs(tbl) do
            -- copy merged table values to prevent linking
            new_table[key] = type(value) == "table" and table.copy(value)
                or value
        end
    end
    return new_table
end

function minimal.concat_tables(table_list)
    assert(type(table_list) == "table",
           "exile_game.concat_tables: Invalid table_list given, got "..
           type(table_list))
    local new_table = {}
    local index = 1
    for tabl_nr = 1, #table_list do
        local current_table = table_list[tabl_nr]
        for z = 1, #current_table do
            new_table[index] = current_table[z]
            index = index + 1
        end
    end
    return table.copy(new_table)
end

function minimal.math_clamp(num,min,max)
    -- math.clamp implementation from my function library (TPH/TubberPupperHusker)
    -- PARAMETERS: num;"number" - number to be clamped
    -- min;"number" - minimum number that 'num' can be
    -- max;"number" - maximum number that 'num' can be
    -- RETURNS: number - 'num' that is clamped (between 'min' and 'max')
    -- FUNCTION: clamps a specified number between a min & max
    ------------------------------------------------------------------------------------------------------------------
    assert(type(num) == "number",
           "math.clamp: no number provided to be clamped! got "..type(num))
    assert(type(min) == "number",
           "math.clamp: no minimum number provided for clamping, got "..type(num))
    assert(type(max) == "number",
           "math.clamp: no maximum number provided for clamping, got "..type(num))

    -- if num, min, and max are numbers then
    if (min > max) then -- if programmer puts max number in place of minimum number... don't punish them for it
        local temp = min -- create a temporary value so that 'min' can be stored
        min = max
        max = temp -- set 'max' to the temporary value
    end

    if (num < min) then
        num = min
    elseif (num > max) then
        num = max
    end
    -- "if elseif" statement because if it's lower than minimum then it's
    -- obviously not going to be greater than maximum and vice versa
    -- (and DO NOT clamp if the number is between min and max)

    return num
end


-- inspired by mobkit's "make_sound"
-- intended to play both mob sounds and custom sound files
function minimal.make_sound(params_table,sound_name)
    if type(params_table) == "string" and type(sound_name) == "table" then
        -- do a switcheroo for this function
        -- allows one to use this function like minetest.sound_play()
        local temp = sound_name
        sound_name = params_table
        params_table = temp
    end
    local sound_spec
    if type(params_table) == "string" then
        sound_spec = {name = params_table, gain = 0.5}
        return minetest.sound_play(sound_spec.name,sound_spec)
    elseif type(params_table) ~= "table" then
        -- not viable
        return
    end
    local function get_range(value)
        -- if value is a table and its index 1 and 2 are numbers then
        --   return a randomized value between them
        return type(value) == 'table' and type(value[1]) == "number"
            and type(value[2]) == "number" and

            (value[1]+math.random()*(value[2]-value[1]) ) or value
    end
    if type(sound_name) == "string" then
        -- assume it's a mob's sounds
        local look_through = params_table.sound or params_table.sounds
        if type(look_through) == "table" then
            sound_spec = params_table[sound_name]
        elseif not params_table.name then
            -- do not assume it's a mob's sounds
            sound_spec = minimal.merge_tables({name = sound_name}, params_table)
        end
    else
        sound_spec = params_table
    end
    if type(sound_spec) ~= "table" then
        return
    end
    if #sound_spec > 0 then
        sound_spec = sound_spec[math.random(#sound_spec)]
        if type(sound_spec) ~= "table" then
            -- if indexes are malformed - e.g. t[1] = value, t[2] = value, t[5] = value - math.random will index from 1-5, but 3 and 4 will be nil - then return nil
            return
        end
    end
    if not sound_spec.name then
        return
    end
    if not sound_spec.pos and not sound_spec.object then
        sound_spec.object = params_table.object
    end
    -- ensure no accidental overwrite
    sound_spec = table.copy(sound_spec)
    sound_spec.gain = get_range(sound_spec.gain)
    sound_spec.fade = get_range(sound_spec.fade)
    sound_spec.pitch = get_range(sound_spec.pitch)
    sound_spec.max_hear_distance = get_range(sound_spec.max_hear_distance)
    sound_spec.start_time = get_range(sound_spec.start_time)

    if sound_spec.to_players and not sound_spec.to_player then
        -- convert plural to singular
        sound_spec.to_player = sound_spec.to_players
    end
    if sound_spec.exclude_players and not sound_spec.exclude_player then
        -- ditto plural
        sound_spec.exclude_player = sound_spec.exclude_players
    end
    if minetest.is_player(sound_spec.to_player) then
        -- provided a player, convert to string
        sound_spec.to_player = sound_spec.to_player:get_player_name()
    end
    if minetest.is_player(sound_spec.exclude_player) then
        -- ditto conversion
        sound_spec.exclude_player = sound_spec.exclude_player:get_player_name()
    end
    if type(sound_spec.to_player) == "table"
        and not sound_spec.exclude_player then

        -- play to each provided player
        local sounds = {}
        for _,player_name in pairs(sound_spec.to_player) do
            local player = player_name
            if minetest.is_player(player) then
                -- get player name from player obj
                player = player:get_player_name()
            end
            if type(player) == "string" then
                local spec = table.copy(sound_spec) -- copy to play for each
                spec.to_player = player
                sounds[#sounds + 1] = minetest.sound_play(spec.name,spec)
            end
        end
        return sounds[1],sounds -- return first played sound, rest of sounds
    elseif type(sound_spec.exclude_player) == "table" then
        -- exclude these provided folk
        local to_players = {}
        -- use to_player to emulate excluding more than 1 player
        for _,player in pairs(minetest.get_connected_players()) do
            local including = true -- whether or not to add to to_players
            local player_name = player:get_player_name()
            for _,exclude in pairs(sound_spec.exclude_player) do
                local exclude_name = exclude
                if minetest.is_player(exclude) then
                    exclude_name = exclude:get_player_by_name()
                end
                if player_name == exclude_name then
                    including = false
                    break
                end
            end
            if including then
                -- finished loop, add if including
                to_players[#to_players + 1] = player_name
            end
        end
        sound_spec.exclude_player = nil -- no longer necessary to specify
        local sounds = {}
        for _,player in pairs(to_players) do
            local spec = table.copy(sound_spec)
            spec.to_player = player
            sounds[#sounds + 1] = minetest.sound_play(spec.name,spec)
        end
        return sounds[1],sounds -- return first played sound, rest of sounds
    end

    return minetest.sound_play(sound_spec.name,sound_spec)
end
function minimal.sound_play(...)
    return minimal.make_sound(...)
end

-- filepath_exists
-- used to determine if a specified filepath exists
-- must be a proper raw path (see minetest.get_modpath)
function minimal.filepath_exists(path)
    assert(type(path) == "string",
        "exile.filepath_exists: got invalid path (non-string) to check, got "..type(path))
    local f = nil -- file object but nil (set prematurely to prevent error crash with io.open)
    local sucs,errmsg = pcall(function() -- success, error message
        f = io.open(path,'r') -- reading only with 'r' mode
    end)
    -- error, provide an informative message and permit runtime
    if not sucs then
        minetest.log("error",
            "minimal.filepath_exists: got an error with io.open, did you forget to specify a "..
            "proper path with minetest.get_modpath()? See error here below: ")
        minetest.log("error",errmsg)
    end
    -- check if file object exists
    if f then
        -- have to close it after opening
        f:close()
        return true
    end
    return false
end

-- image_exists
-- uses filepath_exists to determine if an image exists
-- will not get images with modifiers "^"
-- OPTIONAL: subpath parameter for checking a subpath within /textures/
-- OPTIONAL: modname parameter for checking within a specific mod instead of what calls function
function minimal.image_exists(name, subpath, modname)
  assert(type(name) == "string",
      "exile.image_exists: got invalid name (non-string) to check for, got "..type(name))
  assert(name:match("%."),
      "exile.image_exists: got no image extension (no delimiter (no dot)), cannot try to find image")
  modname = type(modname) == "string" and modname or minetest.get_current_modname() -- confirm or get mod name
  if not modname then return false end -- couldn't get modname
  local path = minetest.get_modpath(modname)
  if not path then return false end -- couldn't get modpath
  -- purify custom subpath
  subpath = type(subpath) == "string" and subpath or nil
  -- add slash to end of subpath
  subpath = subpath and subpath:sub(#subpath) ~= "/" and subpath.."/" or subpath
  -- delete slash at beginning of subpath if one or if subpath is nil, make it as an empty string
  subpath = subpath and subpath:sub(1) == "/" and subpath:sub(2,#subpath) or subpath or ""
  -- complete path string
  path = path.."/textures/"..subpath..name
  -- return boolean, path
  return minimal.filepath_exists(path), path
end

-- get name without the mods: before it
function minimal.get_short_name(reg_name)
    startindex, endindex = string.find(reg_name, ":")
    return string.sub(reg_name, endindex + 1)
end

-- Yes or no dialog
--
-- "question" will be displayed to the player
-- "function_call" will be executed when the player clicks
-- "attached_data_table" will be passed through to function_call
--
-- format for the function:
-- local function name(clicked_yes, data_table, player, playername)
--
-- be careful with what you feed into data_table, if it contains an
-- inv that players can alter, it might cause  item duplication glitches

local open_yesno = {}
function minimal.yes_or_no(playername, question,
                           function_call, attached_data_table)
    if not playername then
        return
    end
    minetest.after( 0.1, function()
                        minetest.show_formspec(
                            playername, "minimal:yesno_form",
                            "formspec_version[3]"..
                            "size[7,4.5]"..
                            "hypertext[0.5,0.75;6,2;introtext;"..
                            question.."]"..
                            "button_exit[1,3;2,1;Yes;"..S("Yes").."]"..
                            "button_exit[4,3;2,1;No;"..S("No").."]"
                        )
    end)
    open_yesno[playername] = { fcall = function_call,
                               data = attached_data_table }
end

minetest.register_on_player_receive_fields(function(player,
                                                    formname,fields)
        if formname ~= "minimal:yesno_form" then
            return
        end
        local playername = player:get_player_name()
        local stored = open_yesno[playername]
        if not stored then
            minetest.log("error", "Couldn't find an open yesno dialog"..
                         " for "..playername)
            return
        end
        if fields.Yes then
            stored.fcall(true, stored.data, player, playername)
        end
        if fields.No then
            stored.fcall(false, stored.data, player, playername)
        end
        open_yesno[playername] = nil
end)
