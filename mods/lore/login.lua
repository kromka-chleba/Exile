--login.lua
--A login screen to show to new players

tutorial = tutorial
HEALTH = HEALTH
lore = lore
region = region
local S = lore.S

local newplayer = {}

local tutorial_available = false
minetest.register_on_mods_loaded(function()
      for _, name in ipairs(minetest.get_modnames()) do
	 if name == "tutorial_exile" then
	    tutorial_available = true
	 end
      end
end)

------------------------------------------------------------------------------
-- Login formspecs
------------------------------------------------------------------------------
local logintext = S("login_text")
if string.match(logintext, "login_text") then -- Untranslated? Use default
   logintext =       ( "  You can scarcely hear the sound of them "..
		       "reading the list of your crimes over the " ..
		       "louder jeering of your kinsmen, but it's already "..
		       "too late to protest your innocence. "..
		       "\n  You are stripped of all possessions and given "..
		       "a writ describing your assorted crimes and the "..
		       "punishment that is to be given, and then you "..
		       "are pushed through a gateway to die in the "..
		       "cursed land of the Ancients, as an.." )
end

local function loginspec(player)
   local spec = ("formspec_version[3]"..
		 "size[7,7.5]"..
		 "bgcolor[;both;#bbb]"..
		 "background9[0,0;7,7.5;9slice-deep.png;false;10]"..
		 "styletype[scrollbar;bgimg=artifacts_antiquorium.png]"..
		 "hypertext[0.5,0.75;6,5;introtext;"..logintext.."]"..
		 "image[1.5,6;6,2;logo.png]" )
   local name = player:get_player_name()
   minetest.show_formspec(name, "lore:login", spec)
end

local function show_motd(player)
   -- Message of the day for servers
   local playername = player:get_player_name()
   if minetest.is_singleplayer() then return end
   local motd = minetest.settings:get("exile_motd")
   if ( not motd ) or motd == "" or motd == "\"\"" then return end
   motd = motd:gsub("\\n","\n")
   local meta = player:get_meta()
   local hash = minetest.sha1(motd)
   local oldhash = meta:get("seen_motd")
   if oldhash then
      if hash == oldhash then return end
   end
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
	 if not show_motd(player) then return end
      end
   end
   local playername = player:get_player_name()
   minetest.close_formspec(playername, "") -- forcibly close the previous fs
   minetest.after(0.1, do_it)
   -- ^ UDP: open may arrive before the close, and doing it again won't hurt
   minetest.after(0.3, do_it) -- (fails silently if a formspec's open already)
   return "wait"
end

------------------------------------------------------------------------------
-- Gateway effects
------------------------------------------------------------------------------
--effects at source
local function doGatewayFX(player)
    local pos = player:get_pos()
    minetest.sound_play( {name="lore_gateway", gain=1}, {pos=pos, max_hear_distance=100})
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
      region.spawn(player)
      minetest.after(0.1, function() doGatewayFX(player) end)
      return true
end)

function play_themesong(name)
   minetest.after(8, function()
		     minetest.sound_play({ name = "exile_theme", gain = 0.75 },
			{ to_player = name })
   end)
end

local function first_spawn(player)
   -- Guarantee they won't be penalized for reading:
   HEALTH.reset_attributes(player) -- All stats back to starting values
   local pname = player:get_player_name()
   newplayer[pname] = nil
   if minimal.mt_required_version(5,4,0) then
      minetest.dynamic_add_media({ filepath = minetest.get_modpath("lore")..
				      "/music/exile_theme.ogg",
				   to_player = pname
				 }, play_themesong )
   else
      minetest.dynamic_add_media(minetest.get_modpath("lore")..
				 "/music/exile_theme.ogg")
      play_themesong(pname)
   end
   -- Bang! new player appears in the world
   minetest.after(0.15, function()
		     region.spawn(player)
		     doGatewayFX(player)
		     player_api.set_invisible(player, false)
   end)
end

------------------------------------------------------------------------------
-- Login event queue
------------------------------------------------------------------------------

local player_queue = {} -- tracks what needs to be done for a player
local waiting = {} -- players with open formspecs

local jumpstart_queue_delay = tonumber(minetest.settings:get(
					  "exile_jumpstart_queue_delay")) or 20

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
   local name = player:get_player_name()
   if not player_queue[name] then player_queue[name] = {} end
   for _ = 1, #player_queue[name] do
      if waiting[name] then
	 waiting[name]:cancel() -- we're not waiting now, start next item
	 waiting[name] = nil -- cancel doesn't remove it
      end
      local qitem = queue_pop(name)
      local wait = qitem.func(player, qitem.name)
      if wait == "wait" then
	 -- The current task is still running.
	 -- It should call queue_start() when it's done
	 -- If not called in j_q_d seconds, assume it's busted
	 local nm = tostring(qitem.name) -- dereference
	 if nm == "tut" then return end -- no forcible restart on tutorial
	 if jumpstart_queue_delay == 0 then return end -- disabled
	 waiting[name] =
	    minetest.after(jumpstart_queue_delay, function()
			      -- don't run this if the queue has changed
			      -- (in case another wait has been started)
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

local function exit_tutorial(player) -- special handling, no formspec on exit
   queue_start(player)
end

local function do_tutorial(player) -- enter, and tell it to call exit_ when done
   tutorial.init(player, exit_tutorial)
   return "wait"
end

minetest.register_on_newplayer(function(player)
      local name = player:get_player_name()
      newplayer[name] = true
      region.prespawn(player)
      queue_push(player, show_formspec, "loginspec")
      -- set_invisible doesn't work in on_newplayer, only in on_join
      -- so it's not here
end)
-- process continues in on_joinplayer
minetest.register_on_joinplayer(function(player)
      local name = player:get_player_name()
      if newplayer[name] == true then
	 player:set_pos(vector.new(-500, 9002, -500))
	 -- hide new players until they read the intro
	 player_api.set_invisible(player, true, "set_invis")
      end
     queue_push(player, show_formspec, "motd")
     if tutorial_available then
	queue_push(player, do_tutorial, "tut")
     end
     if newplayer[name] == true then
	 queue_push(player, first_spawn, "1st")
     end
     queue_start(player)
end)


minetest.register_on_player_receive_fields(function(player, formname, fields)
      if formname == "lore:login" or formname == "lore:motd" then
	 minetest.after(0.1, function() queue_start(player) end)
      end
end)
