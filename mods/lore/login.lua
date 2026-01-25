--login.lua
--A login screen to show to new players

tutorial = tutorial
HEALTH = HEALTH
lore = lore
region = region
local S = lore.S

local newplayer = {}
newplayer["AlwaysNewPlayer"] = true -- For testing purposes

local tutorial_available = false
minetest.register_on_mods_loaded(function()
        for _, name in ipairs(minetest.get_modnames()) do
            if name == "tutorial_exile" and tutorial.enable_tutorial then
                tutorial_available = true
            end
        end
end)

local queue_clear -- forward definition

------------------------------------------------------------------------------
-- Login formspecs
------------------------------------------------------------------------------

local function loginspec(player)
    local name = player:get_player_name()
    local logintext = S("login_text")
    local playerinfo = core.get_player_information(name)

    if not playerinfo then
        core.log("warning", "Player "..name.." did not provide a correct player_information table. Suspicious client")
        core.kick_player(name, "Client sent invalid data")
    end

    local lang_code = playerinfo.lang_code
    -- Untranslated? Use default
    if string.match(core.get_translated_string(lang_code, logintext),
                                                            "login_text") then

        logintext =   ( "  You can scarcely hear the sound of them "..
                        "reading the list of your crimes over the " ..
                        "louder jeering of your kinsmen, but it's already "..
                        "too late to protest your innocence. "..
                        "\n  You are stripped of all possessions and given "..
                        "a writ describing your assorted crimes and the "..
                        "punishment that is to be given, and then you "..
                        "are pushed through a gateway to die in the "..
                        "cursed land of the Ancients, as an.." )
    end

    local spec = ("formspec_version[3]"..
                  "size[7,7.5]"..
                  "bgcolor[;both;#bbb]"..
                  "background9[0,0;7,7.5;9slice-deep.png;false;10]"..
                  "styletype[scrollbar;bgimg=artifacts_antiquorium.png]"..
                  "hypertext[0.5,0.75;6,5;introtext;"..logintext.."]"..
                  "image[1.5,6;6,2;logo.png]" )

    minetest.show_formspec(name, "lore:login", spec)
end

local function get_motd()
    local motd = minetest.settings:get("exile_motd")
    if ( not motd ) or motd == "" or motd == "\"\"" then return end
    motd = motd:gsub("\\n","\n")
    local hash = minetest.sha1(motd)
    return motd, hash
end
local function show_motd(player)
    -- Message of the day for servers
    local playername = player:get_player_name()
    local motd, hash = get_motd()
    local meta = player:get_meta()
    meta:set_string("seen_motd",hash)
    local spec = "formspec_version[3]"..
        "size[7,7.5]"..
        "styletype[scrollbar;bgimg=artifacts_antiquorium.png]"..
        "hypertext[0.5,0.75;6,5;introtext; "..
        S("Message of the Day:\n\n")
        ..motd.."]"
    if newplayer[playername] then
        spec = spec.."bgcolor[;both;#bbb]"..
            "background9[0,0;7,7.5;9slice-deep.png;false;10]"
    end
    minetest.show_formspec(playername, "lore:motd", spec)
    return true
end

local function show_formspec(player, qname)
    local function do_it()
        if qname == "loginspec" then
            loginspec(player)
        elseif qname == "motd" then
             show_motd(player)
        end
    end
    local playername = player:get_player_name()
    minetest.close_formspec(playername, "") -- forcibly close the previous fs
    minetest.after(0.1, do_it)
    -- ^ UDP: open may arrive before the close, and doing it again won't hurt
    minetest.after(0.3, do_it) -- (fails silently if a formspec's open already)
    return "wait"
end

local function check_motd(player)
    if minetest.is_singleplayer() then return end
    local _, hash = get_motd()
    local meta = player:get_meta()
    local oldhash = meta:get("seen_motd")
    if oldhash then
        if hash == oldhash then return end
    end
    return show_formspec(player, "motd")
end

------------------------------------------------------------------------------
-- Gateway effects
------------------------------------------------------------------------------
--effects at source
local function doGatewayFX(player)
    local pos = player:get_pos()
    if not pos then return end
    minetest.sound_play( {name="lore_gateway", gain=0.75},
        {pos=pos, max_hear_distance=100})
    minetest.add_particlespawner({
            amount = 10,
            time = 1,
            minpos = {x=pos.x-1, y=pos.y, z=pos.z-1},
            maxpos = {x=pos.x+1, y=pos.y+1, z=pos.z+1},
            minvel = {x = -2,  y = 0,  z = -2},
            maxvel = {x = 2, y = 0, z = 2},
            minacc = {x = -4, y = 0, z = -4},
            maxacc = {x = 4, y = 0.5, z = 4},
            minexptime = 0.5,
            maxexptime = 2,
            minsize = 1,
            maxsize = 10,
            texture = "gateway_sparks.png",
            glow = 15,
    })
end

------------------------------------------------------------------------------
-- Spawning and Respawning
------------------------------------------------------------------------------

minetest.register_on_respawnplayer(function(player)
        local meta = player:get_meta()
        if meta:get("playtime_suspended") then return end
        region.spawn(player)
        minetest.after(0.1, function() doGatewayFX(player) end)
        return true
end)

local songs_playing = {}

local function play_themesong(name, meta)
    minetest.after(8, function()
        local plr = core.get_player_by_name(name)
        if not core.is_player(plr) then
            return -- Player left during the 8 second delay timer
        end
        if not meta then meta = plr:get_meta() end
        if meta:get_string("disable_music") == "true" then
            return -- Player turned off music during the delay
        end
        songs_playing[name] = minetest.sound_play({
               name = "exile_theme", gain = 0.75 },
           { to_player = name })
    end)
end

function lore.stopmusic(name)
    local handle = songs_playing[name]
    if handle then
        minetest.sound_stop(handle)
    end
    songs_playing[name] = nil
end

local function add_media(pname, meta)
    if meta:get_string("disable_music") == "true" then
        -- Don't send media to players who've shut it off
        -- Prevents wasting bandwidth if "exile_always_play_music" is on
        return
    end
    if minetest.features.dynamic_add_media_table then
        minetest.dynamic_add_media({ filepath = minetest.get_modpath("lore")..
                                         "/music/exile_theme.ogg",
                                     to_player = pname
                                   }, play_themesong )
    else
        minetest.dynamic_add_media(minetest.get_modpath("lore")..
                                   "/music/exile_theme.ogg")
        play_themesong(pname, meta)
    end
end


-- stop music if setting changes
minimal.register_on_player_setting_change(function(player, setting, value, meta)
    if setting ~= "disable_music" or value ~= true then return end
    lore.stopmusic(player:get_player_name())
end)

local function first_spawn(player)
    local meta = player:get_meta() -- we use this
    -- Guarantee they won't be penalized for reading:
    HEALTH.reset_attributes(player, meta) -- All stats back to starting values
    local pname = player:get_player_name()
    newplayer[pname] = nil
    climate.set_weather_override(pname, player, "")
    player:override_day_night_ratio()
    add_media(pname, meta)
    -- Bang! new player appears in the world
    minetest.after(0.15, function()
                       -- #TODO: check if this .after() still serves a purpose
                       if not minetest.is_player(player) then return end
                       region.spawn(player)
                       doGatewayFX(player)
                       player_api.set_invisible(player, false)
                       meta:set_string("spawning", "")
    end)
end

local function annoy_ihirc(player, name, meta)
    if not minetest.settings:get_bool("exile_always_play_theme") then
        return
    end
    add_media(name, meta)
end


------------------------------------------------------------------------------
-- Login event queue
------------------------------------------------------------------------------

local player_queue = {} -- tracks what needs to be done for a player
local waiting = {} -- players with open formspecs

local jumpstart_queue_delay = tonumber(minetest.settings:get(
                                           "exile_jumpstart_queue_delay")) or 20

function queue_clear(playername) -- actually local, defined above
    player_queue[playername] = {}
    if waiting[playername] then waiting[playername]:cancel() end
end

local function queue_push(player, func_to_run, qname)
    -- Add a thing to run on a player, fifo, formspecs require a delay
    local name = player:get_player_name()
    if not player_queue[name] then player_queue[name] = {} end
    local count = #player_queue[name]
    player_queue[name][count+1] = { name = qname, func = func_to_run }
end
local function queue_pop(name) -- Run the first queued action, remove from list
    local qitem = player_queue[name][1]
    table.remove(player_queue[name], 1)
    return qitem
end
local function queue_start(player)
    if not minetest.is_player(player) then
        return
    end
    local name = player:get_player_name()
    if not player_queue[name] then player_queue[name] = {} end
    local todo = ""
    for i = 1, #player_queue[name] do
        todo = todo .. (player_queue[name][i].name) .. ", "
    end
    if waiting[name] then
        waiting[name]:cancel() -- we're not waiting now, start next item
        waiting[name] = nil -- cancel doesn't remove it
    end
    for _ = 1, #player_queue[name] do
        local qitem = queue_pop(name)
        local wait = qitem.func(player, qitem.name)
        --print("Ran item ",qitem.name," - ",qitem.func,"  Result: ",wait)
        if wait == "wait" then
            -- The current task is still running.
            -- It should call queue_start() when it's done
            -- If not called in j_q_d seconds, assume it's busted
            local nm = tostring(qitem.name) -- dereference
            if nm == "tut" then return end -- no forcible restart on tutorial
            if jumpstart_queue_delay == 0 then return end -- disabled
            --print("Will restart in ",jumpstart_queue_delay," seconds")
            waiting[name] =
                minetest.after(jumpstart_queue_delay, function()
                                   minetest.log("action",
                                                "forcibly restarted queue for "..
                                                name)
                                   queue_start(player)
                end)
            return
        end
    end
end

------------------------------------------------------------------------------
-- Queue up the actual events
------------------------------------------------------------------------------

tutorial.register_on_quit(queue_start)

local function do_tutorial(player) -- enter, and tell it to call exit_ when done
    --local meta = player:get_meta()
    --if meta:get_string("playtime_suspended") ~= "y" then
        tutorial.init(player)
    --end
    return "wait"
end

minetest.register_on_newplayer(function(player)
        player:set_pos(vector.new(-500, 9002, -500))
        local name = player:get_player_name()
        climate.set_weather_override(name, player, "clear")
        player:override_day_night_ratio(0) -- night sky until spawned
        newplayer[name] = true
        region.prespawn(player)
        queue_push(player, show_formspec, "loginspec")
        -- set_invisible doesn't work in on_newplayer, only in on_join
        -- so it's not here
end)
-- process continues in on_joinplayer
minetest.register_on_joinplayer(function(player)
        local name = player:get_player_name()
        local meta = player:get_meta()
        if newplayer[name] == true and not meta:contains("spawning") then
            meta:set_string("spawning",
                            minetest.pos_to_string(player:get_pos()))
            -- hide new players until they read the intro
            player_api.set_invisible(player, true, "set_invis")
        end
        if not newplayer[name] and meta:contains("spawning") then
            newplayer[name] = true -- Restart a player who quit before spawning
        end
        queue_push(player, check_motd, "motd")
        if newplayer[name] == true then
            if tutorial_available then
            --    and meta:get_string("playtime_suspended") ~= "y" then
                    queue_push(player, do_tutorial, "tut")
            end
            queue_push(player, first_spawn, "1st")
        end
        if not newplayer[name] then
            annoy_ihirc(player, name, meta)
        end
        -- Pretty print a list of queue items and their function addresses
        --[[
        local todo = ""
        for i = 1, #player_queue[name] do
            print(player_queue[name][i].name , ": ",
                  (player_queue[name][i].func)       )
        end
        print("Queue is: ",todo)
        ]]--

        queue_start(player)
end)


minetest.register_on_player_receive_fields(function(player, formname, fields)
        if formname == "lore:login" or formname == "lore:motd" then
            minetest.after(0.1, function() queue_start(player) end)
        end
end)


minetest.register_chatcommand(
    "motd",{
        description = S("This command shows the current message of the day."),
        func = function(name, param)
            show_motd(minetest.get_player_by_name(name))
        end
})


__DEBUG__ = __DEBUG__
if not __DEBUG__ then return end

minetest.register_chatcommand(
    "dumpqueue",{
        description = S("This command prints the login queue for all players."),
        privs = "server",
        func = function(name,param)
            if core.check_player_privs(name, "server") == false then return end
            print("Queue: ",dump(player_queue))
            print("Waiting: ",dump(waiting))
        end
})
