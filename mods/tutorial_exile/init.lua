--tutorial_exile
--
--If enabled, will be called by lore/login.lua, and ask new players if they
-- would like help learning the game. Clicking yes will generate a tutorial
-- zone above y = 9000, which will walk them through the basics of shelter,
-- fire, food, water, and crafting.

local disable_tutorial = minetest.settings:get("exile_notutorialprompt") or true
-- #TODO: switch this to "or false" when it's debugged and ready to use
-- Set this to true in minetest.conf if the tutorial is completed in singleplayer

local S = minetest.get_translator("tutorial_exile")
tutorial = {}

local modpath = minetest.get_modpath("tutorial_exile")
dofile(modpath..'/nodes.lua')
dofile(modpath..'/overrides.lua')
dofile(modpath..'/entities.lua')

local stage = dofile(modpath..'/stage.lua')
local worldpath=minetest.get_worldpath()

--------------------------------------------------------------------------------
-- Entry/exit from tutorial

local pstore = {} -- store status of players so we can restore it after tutorial
local mstore = minetest.get_mod_storage()

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
    "button_exit[2,6;1,1;take_tut;Yes]"..
    "button_exit[5,6;1,1;refuse_tut;No]"

function tutorial.init(player, exitfunc)
    if disable_tutorial then
        if exitfunc then exitfunc(player) end
        return
    end
    local name = player:get_player_name()
    pstore[name] = {}
    pstore[name].exit = exitfunc
    minetest.show_formspec(name, "tutorial_exile:confirm", confirmspec)
end

local function store_player(player)
    local name = player:get_player_name()
    local ps = pstore[name]

    ps.pos = player:get_pos()
    local meta = player:get_meta()
    ps.stats = HEALTH.get_player_stats(player, meta)
    meta:set_string("playtime_suspended", "y")
    mstore:set_string(name, minetest.write_json(ps))
    -- #TODO: stash inventory; for people doing the tutorial later optionally
    --  Unnecessary on first login, we'll reset it all when they spawn in anyway
end

local function call_exit(player)
    local name = player:get_player_name()
    local ps = pstore[name]
    if not ps or not ps.exit then return end
    ps.exit(player)
end

local function restore_player(player)
    local name = player:get_player_name()
    local ps = pstore[name] or minetest.parse_json(mstore:get_string(name))

    if not ps then return end
    player:set_pos(ps.pos)
    local meta = player:get_meta()
    HEALTH.set_player_stats(player, ps.stats, meta)
    meta:set_string("playtime_suspended", "")
    mstore:set_string(name, "")
    pstore[name] = nil
    -- #TODO: Restore inventory
    call_exit(player)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
        if formname == "tutorial_exile:confirm" then
            if not fields.take_tut then -- pressed refuse, or closed the form
                call_exit(player)
                pstore[player:get_player_name()] = nil
                return
            end
            local tut_spos = stage.get_spawn_pos(player)
            store_player(player)
            player:set_pos(tut_spos)
        end
end)

function tutorial.exit(player)
    -- Shut down tutorial, delete regions, possibly rewrite starting area
    stage.exit(player)
    restore_player(player)
end

--------------------------------------------------------------------------------
-- Debug commands

minetest.register_chatcommand(
    "test_tut",{
        privs = "server",
        func = function(name,param)
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
            minetest.chat_send_player(name, "Stopping tutorial")
            tutorial.exit(minetest.get_player_by_name(name))
        end
})

if minetest.get_modpath("worldedit") then
    worldedit = worldedit
    minetest.register_chatcommand(
        "save_tutr",{
            privs = "server",
            func = function(name,param)
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
            local range, err = minimal.get_region_size(param)
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
