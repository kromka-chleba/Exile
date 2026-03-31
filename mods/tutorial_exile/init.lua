--tutorial_exile
--
--If enabled, will be called by lore/login.lua, and ask new players if they
-- would like help learning the game. Clicking yes will generate a tutorial
-- zone above y = 9000, which will walk them through the basics of shelter,
-- fire, food, water, and crafting.

local settings = core.settings
local disable_tutorial = settings:get_bool("exile_notutorialprompt",false)
-- #TODO: Set this to true in minetest.conf if the tutorial is completed in
--        singleplayer?



local S = minetest.get_translator("tutorial_exile")
tutorial = {}

tutorial.enable_tutorial = not disable_tutorial

local mstore = minetest.get_mod_storage() ;  tutorial.mstore = mstore

local modpath = minetest.get_modpath("tutorial_exile")
dofile(modpath..'/nodes.lua')
dofile(modpath..'/overrides.lua')
dofile(modpath..'/entities.lua')

local stage = dofile(modpath..'/stage.lua')
local worldpath=minetest.get_worldpath()

--------------------------------------------------------------------------------
-- Start/quit from tutorial

local pstore = {} -- store status of players so we can restore it after tutorial

local quit_list = {}
function tutorial.register_on_quit(func)
    table.insert(quit_list, func)
end
local function do_quit_functions(player)
    for i = 1, #quit_list do
        quit_list[i](player)
    end
end

-- Freeze time when in the tutorial
--  Singleplayer only, would need to track tutorial users for multiplayer
local original_speed
local function store_time_speed()
    if not original_speed then
        original_speed = settings:get("time_speed") or 72
        mstore:set_string("original_time_speed", original_speed)
    end
end
local function enable_time_freeze()
    return core.is_singleplayer()
end
local function freeze_time()
    if not enable_time_freeze() then return end
    -- This won't update original_speed if the player changed their time_speed
    --  since we first saved it, but it ensures we don't overwrite it in the
    --  case of a crash and restart with the modified time_speed
    if not original_speed or not mstore:contains("original_time_speed") then
        store_time_speed()
    end
    settings:set("time_speed", 0)
end
local function thaw_time()
    if original_speed or mstore:contains("original_time_speed") then
        settings:set("time_speed", original_speed
                     or mstore:get("original_time_speed")
                     or 72 )
    end
end
local function end_time_freeze()
    thaw_time()
    mstore:set_string("original_time_speed", "")
    original_speed = nil
end

core.register_on_joinplayer(function(player)
        if player:get_meta():get_string("playtime_suspended") == "y" then
            freeze_time()
        else -- in case he logged out in the tutorial and switched to multi
            thaw_time()
        end
end)
core.register_on_shutdown(thaw_time)


local welcome = S("Welcome to Exile!")
local intro = S(
    "Exile is an original game with unique mechanics\n"..
    "that may be unfamiliar to players of other voxel\n"..
    "games. It may be difficult to learn."
)
local ask = S(
    "Would you like to enter a tutorial mode\n"..
    "to learn how to play the game?"
)

local confirmspec = "formspec_version[6]"..
    "size[8,7]"..
    "textarea[0.4,0.5;8,5;;;"..
    --"hypertext[0.375,0.5;8,5;tut_dialog;"..
    welcome.."\n\n"..intro.."\n\n"..ask.."]"..
    "button_exit[2,5.5;1,0.5;take_tut;Yes]"..
    "button_exit[5,5.5;1,0.5;refuse_tut;No]"

function tutorial.init(player)
    if disable_tutorial == true then
        do_quit_functions(player)
        return
    end
    local name = player:get_player_name()
    if pstore[name] then  -- Is the player already in?
        return
    end
    minetest.show_formspec(name, "tutorial_exile:confirm", confirmspec)
end

-- save player's state before entering the tutorial
local function store_player(player)
    local name = player:get_player_name()
    pstore[name] = {}
    local ps = pstore[name]

    ps.pos = player:get_pos()
    local meta = player:get_meta()
    ps.stats = HEALTH.get_player_stats(player, meta)
    meta:set_string("playtime_suspended", "y")
    region.disable_spawnex(name)
    freeze_time()

    local inv = player:get_inventory()
    local invlists = inv:get_lists()
    for list in pairs(invlists) do -- Clear all inventories
        for i = 1, #invlists[list] do
            invlists[list][i] = invlists[list][i]:to_string()
        end
        if list ~= "hand" then
            inv:set_list(list, {})
        end
    end
    -- keep the hand
    player_api.add_player_hand(player)
    ps.inv = invlists
    ps.privs = core.get_player_privs(name)

    if player_api.is_invisible(player) then ps.invis = true end
    player_api.set_invisible(player, false)

    mstore:set_string(name, core.serialize(ps))

    player:override_day_night_ratio(1)
end

local function restore_player(player)
    local name = player:get_player_name()

    HEALTH.show_hud_elements(player, nil, "all")
    player_api.set_invisible(player, false)
    climate.set_weather_override(player:get_player_name(), nil, "")

    local ps = pstore[name]

    if not ps then return end

    player:set_pos(ps.pos)  ;  pstore[name].pos = nil

    local meta = player:get_meta()
    HEALTH.set_player_stats(player, ps.stats, meta)
    pstore[name].stats = nil

    local inv = player:get_inventory()
    local psinv = pstore[name].inv
    for list in pairs(psinv) do
        for i = 1, #psinv[list] do
            psinv[list][i] = ItemStack(psinv[list][i])
        end
    end
    inv:set_lists(psinv)
    pstore[name].inv = nil

    core.set_player_privs(name, pstore[name].privs)
    pstore[name].privs = nil

    pstore[name].invis = nil

    end_time_freeze()
    meta:set_string("playtime_suspended", "")
    region.enable_spawnex(name)
    mstore:set_string(name, "")
    player:override_day_night_ratio(nil)
end

local function read_player_store(name)
        local readps = mstore:get_string(name)
        if readps ~= "" then
            pstore[name] = core.deserialize(readps)
        end
end


core.register_on_joinplayer(function(player)
        local name = player:get_player_name()
        local meta = player:get_meta()
        if meta:get_string("playtime_suspended") ~= "y"  then
            return -- Not in the tutorial, don't bother
        end
        read_player_store(name)
        if pstore[name] then
            player:override_day_night_ratio(1)
            stage.open(player) -- restart current stage
        end
    end)

-- Tutorial's closed, call the next login function if any
local function after_tutorial(player)
    do_quit_functions(player)
    local name = player:get_player_name()
    pstore[name] = nil
end
minetest.register_on_player_receive_fields(function(player, formname, fields)
        if not core.is_player(player) then return end -- logged out?
        if formname == "tutorial_exile:confirm" then
            if not fields.take_tut then -- pressed refuse, or closed the form
                after_tutorial(player)
                return
            end
            store_player(player)
            stage.open(player)
        end
end)

-- Shut down tutorial, delete regions, possibly rewrite starting area
function tutorial.exit(player)
    stage.shutdown(player)
    triggers.clear_used_triggers(player:get_player_name())
    restore_player(player)
    after_tutorial(player)
end


minetest.register_chatcommand(
    "tutorial",{
        description = "Start or restart the tutorial",
        func = function(name,param)
            if pstore[name] then
                tutorial.exit(core.get_player_by_name(name))
            end
            local tmp = disable_tutorial
            disable_tutorial = false
            minetest.chat_send_player(name, S("Starting tutorial"))
            tutorial.init(minetest.get_player_by_name(name), nil)
            disable_tutorial = tmp
        end
})
minetest.register_chatcommand(
    "quit_tutorial",{
        description = "Exit the tutorial",
        func = function(name,param)
            minetest.chat_send_player(name, S("Stopping tutorial"))
            tutorial.exit(minetest.get_player_by_name(name))
        end
})

__DEBUG__ = __DEBUG__
if not __DEBUG__ then return end

--------------------------------------------------------------------------------
-- Debug commands


if minetest.get_modpath("worldedit") then
    worldedit = worldedit
    minetest.register_chatcommand(
        "save_tutr",{
            privs = "server",
            params = "<filename>",
            description = "Save a tutorial region bounded by worledit markers",
            func = function(name,param)
                if core.check_player_privs(name, "server") == false then
                    return
                end
                local pos1 = worldedit.pos1[name]
                local pos2 = worldedit.pos2[name]
                if not vector.check(pos1) or not vector.check(pos2) then
                    return false, "Invalid positions, use worldedit //1 and //2"
                end
                minetest.chat_send_player(name, "Saving region named "..param)
                return minimal.save_region(pos1, pos2, param)
            end
    })
end

minetest.register_chatcommand(
    "load_tutr",{
        privs = "server",
        params = "<filename>",
        description = "Load a tutorial region and place it at the player",
        func = function(name,param)
            if core.check_player_privs(name, "server") == false then return end
            minetest.chat_send_player(name, "Loading region named "..param)
            local player = minetest.get_player_by_name(name)
            local pos = player:get_pos()
            local file = io.open(worldpath.."/"..param..".ex_schm","rb")
            return minimal.load_region(pos, file)
        end
})

minetest.register_chatcommand(
    "size_tutr",{
        privs = "server",
        params = "<filename>",
        description = "Show the dimensions of a saved tutorial region",
        func = function(name,param)
            if core.check_player_privs(name, "server") == false then return end
            local fname = modpath.."/schematics/"..param..".ex_schm"
            local input, err = minimal.load_region_raw(fname)
            if not input then return nil, err end
            local _, range = unpack(input)
            if not range then return false, err end
            local p1 = range.pos1
            local p2 = range.pos2
            local size = vector.subtract(p2, p1)
            local str = "Read file: "..param..".ex_schm\n"..
                "pos1: "..minetest.pos_to_string(p1).."  "..
                "pos2: "..minetest.pos_to_string(p2).."\n"..
                "size: "..minetest.pos_to_string(size)..
                ": "..(size.x * size.y * size.z).." nodes"
            minetest.log("action", str)
            return true, str
        end
})

minetest.register_chatcommand(
    "tutr_startpos",{
        privs = "server",
        func = function(name,param)
            if core.check_player_privs(name, "server") == false then return end
            local pos, err = stage.distance_to_base(name)
            if not pos then return err end
            return true, core.pos_to_string(pos)
        end
})

core.register_chatcommand(
    "get_facing",{
        privs = "server",
        func = function(name, param)
            if core.check_player_privs(name, "server") == false then return end
            local plyr = core.get_player_by_name(name)
            local facing = plyr:get_look_horizontal()
            print("Facing: ",facing)
            return true, tostring(facing)
        end
})
