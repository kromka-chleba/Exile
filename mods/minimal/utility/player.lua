minimal = minimal
local hud_type = minimal.hud_type

-- check if a provided player is in creative mode
local creative_mode_cache = minetest.settings:get_bool("creative_mode")
function minimal.player_in_creative(plyr)
  -- get the player by name if string
  if (type(plyr) == "string") then
    plyr = minetest.get_player_by_name(plyr)
  end
  -- if player is a player...
  if (minetest.is_player(plyr)) then
    if (minetest.check_player_privs(plyr,"creative") or creative_mode_cache == true) then
      return true
    end
  end
  return false
end 
 
 -- ping functionality scope
 do
  local clear_ping_delay = tonumber(minetest.settings:get(
               "exile_clear_ping_delay")) or 20
  local waypoints = {}

  if minetest.settings:get_bool("unlimited_player_transfer_distance", true) then
     return -- don't need a ping command if everyone can be seen anyway
  end

  local function add_waypoint(name, viewername, viewer, pos)
     local id = viewer:hud_add({
     [hud_type] = "waypoint",
     number = 0xFFFFFF,
     name = name,
     text = "m",
     world_pos = pos
     })
     if not waypoints[name] then -- initialize
        waypoints[name] = { }
     end
     waypoints[name][viewername] = { handle = id , obj = viewer }
  end

  local function clear_waypoint(name)
     if not waypoints[name] then return end
     for _, data in pairs(waypoints[name]) do
        if minetest.is_player(data.obj) and data.handle then
     data.obj:hud_remove(data.handle)
        end
     end
     waypoints[name] = {}
  end

  local timestamp = {}

  minetest.register_chatcommand("ping",{
    privs = "shout",
    func = function(myname,param)
       local nowtime = minetest.get_gametime()
       if timestamp[myname] and ( timestamp[myname] +20 ) > nowtime then
          return false, "You can't use this command "..
       " more than once per 20 seconds."
       end
       local pos = minetest.get_player_by_name(myname):get_pos()
       local targets
       local isplayer = minetest.get_player_by_name(param)
       if param and param ~= "" and not isplayer then
          return false, "Player "..param.." not found!"
       end
       if isplayer then -- single target
          targets = { [param] = minetest.get_player_by_name(param) }
       end
       for _, player in pairs(targets or
            minetest.get_connected_players()) do
          local theirname = player:get_player_name()
          if myname ~= theirname then
       add_waypoint(myname, theirname, player, pos)
       timestamp[myname] = nowtime
       minetest.after(clear_ping_delay, clear_waypoint, myname)
          end
       end
    end
  })
end
