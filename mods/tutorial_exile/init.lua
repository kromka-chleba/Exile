--tutorial_exile
--
--If enabled, will be called by lore/login.lua, and ask new players if they
-- would like help learning the game. Clicking yes will generate a tutorial
-- zone above y = 9000, which will walk them through the basics of shelter,
-- fire, food, water, and crafting.

local disable_tutorial = minetest.settings:get("exile_notutorialprompt") or false
-- #TODO: Set this to true in minetest.conf if the tutorial is completed in
--        singleplayer?

local S = minetest.get_translator("tutorial_exile")
tutorial = {}

local modpath = minetest.get_modpath("tutorial_exile")
dofile(modpath..'/nodes.lua')
dofile(modpath..'/overrides.lua')
dofile(modpath..'/entities.lua')

local stage = dofile(modpath..'/stage.lua')
local worldpath=minetest.get_worldpath()

--------------------------------------------------------------------------------
-- Start/quit from tutorial

local mstore = minetest.get_mod_storage()

local pstore = {} -- store status of players so we can restore it after tutorial

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
    "hypertext[0.375,0.5;8,5;tut_dialog;"..
    welcome.."\n\n"..intro.."\n\n"..ask.."]"..
    "button_exit[2,5.5;1,0.5;take_tut;Yes]"..
    "button_exit[5,5.5;1,0.5;refuse_tut;No]"

function tutorial.init(player, quitfunc)
    if disable_tutorial == true then
        if quitfunc then quitfunc(player) end
        return
    end
    local name = player:get_player_name()
    if pstore[name] then stage.open(player) return end -- already in?
    pstore[name] = {}
    pstore[name].quit = quitfunc
    minetest.show_formspec(name, "tutorial_exile:confirm", confirmspec)
end

-- save player's state before entering the tutorial
local function store_player(player)
    local name = player:get_player_name()
    local ps = pstore[name]

    ps.pos = player:get_pos()
    local meta = player:get_meta()
    ps.stats = HEALTH.get_player_stats(player, meta)
    meta:set_string("playtime_suspended", "y")
    region.disable_spawnex(name)

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
    ps.inv = invlists
    ps.privs = core.get_player_privs(name)

    if player_api.is_invisible(player) then ps.invis = true end
    player_api.set_invisible(player, false)

    mstore:set_string(name, core.serialize(ps))

    player:override_day_night_ratio(1)
end

local function restore_player(player)
    local name = player:get_player_name()
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

    player_api.set_invisible(player, pstore[name].invis)
    pstore[name].invis = nil

    meta:set_string("playtime_suspended", "")
    region.enable_spawnex(name)
    mstore:set_string(name, "")
    player:override_day_night_ratio()
end

local function read_player_store(name)
        local readps = mstore:get_string(name)
        if readps then
            pstore[name] = core.deserialize(readps)
        end
end

minimal.register_on_joinplayer(function(player)
        local name = player:get_player_name()
        read_player_store(name)
        if pstore[name] then
            stage.open(player) -- restart current stage
        end
end)
--[[
core.register_on_respawnplayer(function(player)
        local name = player:get_player_name()
        if pstore[name] then
            print(name," is rejoining the tutorial")
            stage.open(player)
        end -- restart current stage
    end)
]]--

-- Tutorial's closed, call the next login function if any
local function after_tutorial(player)
    local name = player:get_player_name()
    if not pstore[name] then return end
    if pstore[name].quit then pstore[name].quit(player) end
    pstore[name] = nil
end
minetest.register_on_player_receive_fields(function(player, formname, fields)
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

__DEBUG__ = __DEBUG__
if not __DEBUG__ then return end

--------------------------------------------------------------------------------
-- Debug commands

minetest.register_chatcommand(
    "test_tut",{
        privs = "server",
        func = function(name,param)
            if core.check_player_privs(name, "server") == false then return end
            if pstore[name] then
                tutorial.exit(core.get_player_by_name(name))
            end
            local tmp = disable_tutorial
            disable_tutorial = false
            minetest.chat_send_player(name, "Starting tutorial")
            tutorial.init(minetest.get_player_by_name(name), nil)
            disable_tutorial = tmp
        end
})
minetest.register_chatcommand(
    "quit_tut",{
        privs = "server",
        func = function(name,param)
            if core.check_player_privs(name, "server") == false then return end
            minetest.chat_send_player(name, "Stopping tutorial")
            --read_player_store(name)
            tutorial.exit(minetest.get_player_by_name(name))
        end
})

if minetest.get_modpath("worldedit") then
    worldedit = worldedit
    minetest.register_chatcommand(
        "save_tutr",{
            privs = "server",
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
