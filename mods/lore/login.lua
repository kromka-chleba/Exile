--login.lua
--A login screen to show to new players

local logintext = ( "  You can scarcely hear the sound of them "..
		       "reading the list of your crimes over the " ..
		       "louder jeering of your kinsmen, but it's already "..
		       "too late to protest your innocence. "..
		       "\n  You are stripped of all possessions and given "..
		       "a writ describing your assorted crimes and the "..
		       "punishment that is to be given, and then you "..
		       "are pushed through a gateway to die in the "..
		       "cursed land of the Ancients, as an.." )

local loginspec = ("formspec_version[3]"..
		       "size[7,7.5]"..
		   "bgcolor[;both;#bbb]"..
		   "background9[0,0;7,7.5;9slice.png;false;10]"..
		   "hypertext[0.5,0.75;6,5;introtext;"..logintext.."]"..
		   "image[1.5,6;6,2;logo.png]" )


minetest.register_on_newplayer(function(player)
      local props = player:get_properties()
      -- hide new players until they read the intro (is_visible fails?)
      props.visual_size = {x=0.0001,y=0.0001,z=0.0001}
      props.nametag = " "
      player:set_properties(props)
      minetest.show_formspec(player:get_player_name(),"lore:login",loginspec)
end)

local rspawn_available = false
for _, name in ipairs(minetest.get_modnames()) do
	if name == "rspawn" then
		rspawn_available = true
	end
end


local function safepoint_and_rspawn(player)
      --If rspawn is enabled, send new players to the safe point if enabled
      -- and later respawning players elsewhere randomly
      local safepoint = minetest.setting_get_pos("exile_safe_spawn_pos")
      local meta = player:get_meta()
      local lives = meta:get_int("lives")
      local safespawn = minetest.setting_get_pos("exile_safe_spawn_lives") or 0
      if lives <= safespawn and safepoint then
	 player:set_pos(safepoint)
	 return true -- disable regular respawn
      elseif rspawn_available then
	 rspawn:renew_player_spawn(player:get_player_name())
	 return true
      end
end

minetest.register_on_newplayer(safepoint_and_rspawn)
minetest.register_on_respawnplayer(safepoint_and_rspawn)



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


minetest.register_on_respawnplayer(function(player)
      minetest.after(0.1, function() doGatewayFX(player) end)
end)

function play_themesong(name)
   minetest.after(8, function()
		     minetest.sound_play({ name = "exile_theme", gain = 0.75 },
			{ to_player = name })
   end)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
      --maybe unnecessary, but guarantee they won't be penalized for reading
      if formname == "lore:login" then
	 reset_attributes(player) -- All stats back to starting values
	 doGatewayFX(player)
	 local pname = player:get_player_name()
	 minetest.dynamic_add_media({ filepath = minetest.get_modpath("lore")..
					 "/music/exile_theme.ogg",
				      to_player = pname
				    }, play_themesong )
	 local props = player:get_properties()
	 props.nametag = "" -- An empty tag defaults to player's name
	 props.is_visible = true -- Bang! new player appears in the world
	 props.visual_size = {x=1,y=1,z=1}
	 minetest.after(0.25, function()
			   player:set_properties(props)
	 end)
      end
end)
