local S = EXILE.S

function EXILE.invlists2string(lists)
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
function EXILE.string2invlists(string)
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
function EXILE.click_count_ready(name, id, pos, count, timeout)
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

function EXILE.get_pointed_thing(player,rn, obj, liq)
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

function EXILE.sanitize_string(badstring)
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
function EXILE.merge_tables(t1,...)
    if type(t1) ~= "table" then
        error("exile_game.merge_tables: invalid first parameter given, "..
              "expected table, got "..type(t1))
    end

    local arg_nb = select('#', ...)
    if arg_nb < 1 then
        error("exile_game.merge_tables: need a table to merge with")
    end
    local new_table = table.copy(t1)

    local tbl
    for i=1,arg_nb do -- table index, table
        tbl = select(i, ...)
        if type(tbl) ~= "table" then
            error("exile_game.merge_tables: invalid value given at paramter "..
                  i ..", expected table got "..type(tbl))
        end
        -- merge tables
        for key,value in pairs(tbl) do
            -- copy merged table values to prevent linking
            new_table[key] = type(value) == "table" and table.copy(value)
                or value
        end
    end
    return new_table
end

function EXILE.concat_tables(table_list)
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

function EXILE.math_clamp(num,min,max)
    -- math.clamp implementation from my function library (TPH/TubberPupperHusker)
    -- PARAMETERS: num;"number" - number to be clamped
    -- min;"number" - minimum number that 'num' can be
    -- max;"number" - maximum number that 'num' can be
    -- RETURNS: number - 'num' that is clamped (between 'min' and 'max')
    -- FUNCTION: clamps a specified number between a min & max
    ------------------------------------------------------------------------------------------------------------------
    if type(num) ~= "number" then
        error("math.clamp: no number provided to be clamped! got "..type(num))
    elseif type(min) ~= "number" then
        error("math.clamp: no minimum number provided for clamping, got "
              ..type(num))
    elseif type(max) ~= "number" then
        error("math.clamp: no maximum number provided for clamping, got "
              ..type(num))
    end

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

local function value_get_range(value)
    -- if value is a table and its index 1 and 2 are numbers then
    -- return a randomized value between them
    return type(value) == 'table' and type(value[1]) == "number"
      and type(value[2]) == "number" and
        (value[1]+math.random()*(value[2]-value[1]) ) or value
end

-- inspired by mobkit's "make_sound"
-- intended to play both mob sounds and custom sound files
-- target will be pos or entity
function EXILE.sound_play(target, spec)
    -- compatibility-ish
    -- switch target and spec
    if type(spec) == "table" and spec.pos then
        local old = target
        target = spec.pos
        spec = old
    end
    -- target is soundspec
    if type(target) == "table" and target.pos then
        -- target becomes pos, spec is target
        target, spec = target.pos, target
    end
    -- figure out if playing at pos or object
    local posobj = type(target) == "table" and (target.x and target.y and target.z) and "pos" or
      (type(target) == "table" and target.object or type(target) == "userdata") and "obj"
    -- no playing sounds if nil (not pos or valid entity table)
    if not posobj then return end
    -- check for sound in entity
    spec = posobj == "obj" and (type(spec) == "string" and target.sounds) and
      target.sounds[spec] or spec
    if type(spec) ~= "table" then return end -- can't play (no data)
    -- multiple sounds
    if #spec > 0 then
        local lspec = spec[math.random(1, #spec)]
        if type(lspec) ~= "table" then return end -- can't play, not a table
        -- get defaults from spec and apply to lspec
        for stat, val in pairs(spec) do
            if type(stat) ~= "number" then -- apply if not a numbered index
                if lspec[stat] == nil then -- permit overrides with boolean false
                    lspec[stat] = val
                end
            end
        end
        spec = lspec -- chosen one
    end
    if not spec.name then return end -- no name, can't play
    spec = table.copy(spec)
    -- now add pos or entity's object
    spec.pos = posobj == "pos" and target or nil
    spec.object = posobj == "obj" and (type(target) == "table" and target.object or target) or nil
    -- now to randomize each number table value (or stay the same)
    for i,v in pairs(spec) do
        if i ~= "pos" then -- not pos!
            spec[i] = value_get_range(v)
        end
    end
    -- to_player and exclude_player customization
    -- convert plural to singular
    if spec.to_players and not spec.to_player then
        spec.to_player = spec.to_players
    end
    if spec.exclude_players and not spec.exclude_player then
        spec.exclude_player = spec.exclude_players
    end
    -- provided a player, convert to string
    spec.to_player = spec.to_player and core.is_player(spec.to_player) and spec.to_player:get_player_name() or
      spec.to_player
    spec.exclude_player = spec.exclude_player and core.is_player(spec.exclude_player) and
      spec.exclude_player:get_player_name() or spec.exclude_player
    -- multi-player exclude_player, convert into to_player table
    if type(spec.exclude_player) == "table" then
        local exclude_list = {}
        for _,plr in ipairs(spec.exclude_player) do
            plr = type(plr) == "userdata" and core.is_player(plr) and plr:get_player_name() or
              plr
            -- only add to list if string
            if type(plr) == "string" then
                exclude_list[plr] = true
            end
        end
        -- iterate through connected players, if not found in exclusion list then add
        -- use to_player to emulate excluding more than 1 player
        local to_players = {}
        for _,plr in ipairs(core.get_connected_players()) do
            plr = plr:get_player_name()
            if not exclude_list[plr] then
                to_players[#to_players + 1] = plr
            end
        end
        if #to_players == 0 then return end -- can't play this to anyone, return
        -- remove exclude_player list, add to_player, will be properly handled in next if statement
        spec.to_player = to_players
        spec.exclude_player = nil
    end
    -- multi-player to_player, only if exclude_player not defined
    -- if exclude_player is table, gets converted into to_player table
    if type(spec.to_player) == "table" and not spec.exclude_player then
        -- play to each provided player
        local sounds = {}
        for _,plr in ipairs(spec.to_player) do
            -- get player name
            if type(plr) == "userdata" and core.is_player(plr) then
                plr = plr:get_player_name()
            end
            -- now to play and return handles
            if type(plr) == "string" then
                local lspec = table.copy(spec) -- local spec
                lspec.to_player = plr
                sounds[#sounds + 1] = core.sound_play(spec.name, lspec)
            end
        end
        -- 1st return is first sound handle, 2nd return is the list
        return sounds[1], sounds
    end

    return core.sound_play(spec.name, spec)
end

-- filepath_exists
-- used to determine if a specified filepath exists
-- must be a proper raw path (see minetest.get_modpath)
function EXILE.filepath_exists(path)
    assert(type(path) == "string",
        "exile.filepath_exists: got invalid path (non-string) to check, got "..type(path))
    local f = nil -- file object but nil (set prematurely to prevent error crash with io.open)
    local sucs,errmsg = pcall(function() -- success, error message
        f = io.open(path,'r') -- reading only with 'r' mode
    end)
    -- error, provide an informative message and permit runtime
    if not sucs then
        minetest.log("error",
            "EXILE.filepath_exists: got an error with io.open, did you forget to specify a "..
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
function EXILE.image_exists(name, subpath, modname)
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
  return EXILE.filepath_exists(path), path
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
function EXILE.yes_or_no(playername, question,
                           function_call, attached_data_table)
    if not playername then
        return
    end
    minetest.after( 0.1, function()
                        minetest.show_formspec(
                            playername, "EXILE:yesno_form",
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
        if formname ~= "EXILE:yesno_form" then
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

local function generic_group_finder(def_table, group_name, min, max)
    local mi = min or 1
    local mx = max or math.huge
    local definitions = {}
    for name, def in pairs(def_table) do
        local value = def.groups[group_name]
        if type(value) == "number" and
            value >= mi and
            value <= mx then
            definitions[name] = def
        end
    end
    return definitions
end

-- Returns a table of name->definition mappings for items belonging to
-- the `group_name` group.  `min` and `max` (integer) are optional
-- arguments that specify the minimal and maximal values (inclusive)
-- of numerical subgroups of the group
function minimal.get_items_from_group(group_name, min, max)
    return generic_group_finder(core.registered_items, group_name, min, max)
end

-- Returns a table of name->definition mappings for nodes belonging to
-- the `group_name` group.  `min` and `max` (integer) are optional
-- arguments that specify the minimal and maximal values (inclusive)
-- of numerical subgroups of the group
function minimal.get_nodes_from_group(group_name, min, max)
    return generic_group_finder(core.registered_nodes, group_name, min, max)
end

-- Returns a table of name->definition mappings for tools belonging to
-- the `group_name` group.  `min` and `max` (integer) are optional
-- arguments that specify the minimal and maximal values (inclusive)
-- of numerical subgroups of the group
function minimal.get_tools_from_group(group_name, min, max)
    return generic_group_finder(core.registered_tools, group_name, min, max)
end

-- Returns a table of name->definition mappings for craftitems
-- belonging to the `group_name` group.  `min` and `max` (integer) are
-- optional arguments that specify the minimal and maximal values
-- (inclusive) of numerical subgroups of the group
function minimal.get_craftitems_from_group(group_name, min, max)
    return generic_group_finder(core.registered_craftitems, group_name, min, max)
end
