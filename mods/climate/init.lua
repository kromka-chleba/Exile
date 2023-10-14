--CLIMATE

--[[
Uses a markov chain to switch between weather states.
Has seasonal and diurnal fluctations in temperature, which adjust
the probability for which switch will occur (e.g rain more likely in cold)

This is climate rather than "weather" in the sense it treats the whole map
as the same, i.e. not big enough to get regional variation.


A specific locations Temperature and more can be called elsewhere (e.g. for health)

]]



climate = {
	active_weather = {},
	active_temp = {},
	active_sea_temp = {}

}

local modpath = minetest.get_modpath("climate")
local store = minetest.get_mod_storage()


-- Adds weather to register_weathers table
--all possible weather states
climate.registered_weathers = {}
climate.weather_index = {}

-- Keeps sound handler references
local sound_handlers = {}

climate.register_weather = function(weather_obj)
   climate.registered_weathers[weather_obj.name] =
      weather_obj
   table.insert(climate.weather_index, weather_obj.name)
end

dofile(modpath .. "/particles.lua")
dofile(modpath .. "/temperature.lua")
dofile(modpath .. "/history.lua")
--weathers
dofile(modpath .. "/weathers/clear.lua")
dofile(modpath .. "/weathers/light_cloud.lua")
dofile(modpath .. "/weathers/medium_cloud.lua")
dofile(modpath .. "/weathers/sun_shower.lua")
dofile(modpath .. "/weathers/light_rain.lua")
dofile(modpath .. "/weathers/overcast_light_rain.lua")
dofile(modpath .. "/weathers/overcast.lua")
dofile(modpath .. "/weathers/overcast_rain.lua")
dofile(modpath .. "/weathers/overcast_heavy_rain.lua")
dofile(modpath .. "/weathers/thunderstorm.lua")
dofile(modpath .. "/weathers/superstorm.lua")
dofile(modpath .. "/weathers/light_haze.lua")
dofile(modpath .. "/weathers/haze.lua")
dofile(modpath .. "/weathers/duststorm.lua")
dofile(modpath .. "/weathers/snow_flurry.lua")
dofile(modpath .. "/weathers/light_snow.lua")
dofile(modpath .. "/weathers/overcast_light_snow.lua")
dofile(modpath .. "/weathers/overcast_snow.lua")
dofile(modpath .. "/weathers/overcast_heavy_snow.lua")
dofile(modpath .. "/weathers/snowstorm.lua")
dofile(modpath .. "/weathers/fog.lua")



--setting...for random intervals
local base_interval = 90
local base_int_range = 30

--temp classes for probabilities
local plvl_froz = -1
local plvl_cold = 15
local plvl_mid = 25


--what weather is on, and how long it will last, and temp
--random values that should get overriden by mod storage

-- Set weather to something nice for start
local good_start_weathers = {
    "overcast",
    "light_rain",
    "overcast_light_rain",
    "light_haze",
    "light_snow",
    "overcast_light_snow",
    "clear",
}
local good_random = good_start_weathers[math.random(1, #good_start_weathers)]
climate.active_weather = climate.registered_weathers[good_random]
climate.active_temp = math.random(10, 20)
climate.active_sea_temp = climate.active_temp - math.random(2, 8)
local active_weather_interval = 30

--random walk, for temp
local ran_walk_range = 10
local ran_walk = math.random(-ran_walk_range,ran_walk_range)

--cache of players with weather overrides
climate.weather_override = {}

--------------------------
-- Functions
--------------------------

--------------------
--create a random interval for the weather to last
local function set_active_interval()
  local intv = base_interval + math.random(-base_int_range, base_int_range)
  return intv
end

--yearly average
local dc_mean = 13

function climate.mean_year_temp()
    return dc_mean
end

local function get_seasonal_waves()
   --get seasonal wave
   local dc = minetest.get_day_count() - 10
   --diff +/- from yearly mean (seasonal variation)
   local dc_amp = 17
   --~80 day year, 20 day seasons
   local dc_period = (2*math.pi)/80
   local dc_wav = dc_amp * math.sin(dc * dc_period) + dc_mean
   --seawater temp change has lower amplitude, behind 2 days from mass of water
   --Fudged loosely from McCombie's 1959 "Some Relations Between Air
   --  Temperatures and the Surface Temperature of Lakes", Wiley Online Library
   local sea_wav = (dc_amp-5) * math.sin((dc - 2) * dc_period) + dc_mean
   return dc_wav, sea_wav
end

--------------------
--player functions
function climate.get_player_weather(p_name)
   local ovr = climate.weather_override[p_name]
   local wth = climate.registered_weathers[ovr]
   if ovr == nil or wth == nil then
      return climate.active_weather
   end
   return wth
end

local prev_sound = {}
local function update_player_sounds(p_name, pos)
   if not pos then
      pos = minetest.get_player_by_name(p_name):get_pos()
   end
   local active_weather = climate.get_player_weather(p_name)
   local sound = sound_handlers[p_name]
   if sound and prev_sound[p_name]
      and prev_sound[p_name] ~= active_weather.name then
      minetest.sound_stop(sound)
      sound_handlers[p_name] = nil
   end
   if pos.y > -12 then -- run weather sounds
      if sound == nil and active_weather.sound_loop then
	 sound_handlers[p_name] = minetest.sound_play(
	    active_weather.sound_loop, {to_player = p_name, loop = true})
      end
   elseif pos.y < -11 and sound then
      local x = 1-(-1*pos.y-12)/5
	if x < 0 then
	   minetest.sound_stop(sound)
	   sound_handlers[p_name] = nil
	else
	   minetest.sound_fade(sound, 0.5, x)
	end
   elseif pos.y > -17 and active_weather.sound_loop and not sound then
      sound_handlers[p_name] =
	   minetest.sound_play(climate.active_weather.sound_loop,
			       {to_player = p_name, loop = true, gain = 0.1})
   end
   prev_sound[p_name] = active_weather.name
end

-- get moon's phase (returns 0 to 12)
local function get_moon_phase()
  local bounds = {x = 37, y = 37}
  local phscount = 12 -- there are 12 base phases
  
  local days = minetest.get_day_count() % 80 -- get current year's date
  
  days = days % 40 + 1 -- refresh phases every 40th day (2 times per year) (add 1 to get an accurate date)
  -- starts bright, turns dark, goes bright, ditto
  
  for i = 1, phscount, 1 do
    if (days/40 <= i/(phscount)) then
      return i, bounds, (phscount)
    end
  end
end

local function get_moon_texture(texture,spctype)
  -- spctype for setting custom moon phases
  if (type(texture) == "table") then
    texture = texture.texture
  end
  if (type(texture) ~= "string") then
    return ""
  end
  if (texture ~= "moon.png") then -- do not conflict with other provided textures
    return texture
  end
  
  local frame,bounds,phscount = get_moon_phase() -- specified frame, x & y image bounds, and total count of phases
  frame = -(bounds.y * (frame - 1))
  
  if (spctype ~= nil) then -- if a spctype is specified, then seek other specified moon textures
    frame = -(bounds.y * phscount) -- set frame to maximum
  elseif (spctype == "number") then -- manually setting the frame, hmm?
    spctype = minimal.math_clamp(spctype,0,phscount)
    frame = -(bounds.y * math.ceil(spctype))
  end
  -- yields an invisible texture (as the position beyond the 12th frame is not yet a specified texture, until someone does make it so :o)
  -- adds possibilities for "blood moon", "solar eclipse", and other possible moon modifiers IF specified and IF made in the vertical frame (add at bottom of the vertical png)
  if (spctype == "nil") then
    frame = frame - bounds.y
  end
  
  texture = "[combine:"..bounds.x.."x"..bounds.y.."..:0,"..frame.."="..texture -- using combine as a discount verticalframe to prevent conflict if more moon modifiers are added
  -- e.g. "[combine:37x37:0,1=moon.png" = phase 1 or waxing crescent of moon vertical png
  
  return texture
end

--------------------
--set the sky, for on join and when new weather set
local function set_sky_clouds(player,...)
  local args = {...} -- custom args, for example if an alternative moon phase is asked for
  
	local p_name = player:get_player_name()
	local active_weather = climate.get_player_weather(p_name)

	player:set_sky(active_weather.sky_data)
	local clouds = active_weather.cloud_data
	local pheight = player:get_pos().y
	if clouds.height < 9000 and pheight > 8999 then
	   clouds.height = clouds.height + 9000
	elseif clouds.height > 9000 and pheight < 9000 then
	   clouds.height = clouds.height - 9000
	end
	player:set_clouds(clouds)
	local wth = table.copy(active_weather)
	local actmp, _ = get_seasonal_waves()
	actmp = actmp - 15 -- move centerpoint
	wth.moon_data.scale = wth.moon_data.scale + (-actmp / 50 + 0.3)
	wth.sun_data.scale = wth.sun_data.scale + (actmp / 50 + 0.3)
  if (wth.moon_data.visible == true and wth.moon_data.texture == "moon.png") then
    wth.moon_data.texture = get_moon_texture(wth.moon_data,args[1])
  end
	player:set_moon(wth.moon_data)
	player:set_sun(wth.sun_data)
	player:set_stars(active_weather.star_data)
end

-- update sky for moon phases (accessible to climate depends)
function climate.update_sky(player,...)
  if not (minetest.is_player(player)) then
    return
  end
  
  set_sky_clouds(player,...)
end

-- updates sky boxes for all players (accessible to climate depends)
function climate.update_skies(...)
  for _,player in ipairs(minetest.get_connected_players()) do
    climate.update_sky(player,...)
  end
end

function climate.set_weather_override(p_name, p_obj, w_name)
   if p_name and not p_obj then
      p_obj = minetest.get_player_by_name(p_name)
   end
   if p_obj and not p_name then
      p_name = p_obj:get_player_name()
   end
   local p_meta = p_obj:get_meta()
   if climate.weather_override[p_name] then
      --remove old weather_override, particles first
      climate.clear_player_particle(p_name)
      climate.weather_override[p_name] = nil
   end
   local wth = climate.registered_weathers[w_name]
   if wth then
      climate.weather_override[p_name] = w_name
      climate.add_player_particle(p_name, w_name, wth)
      p_meta:set_string("weather_override", w_name)
   else
      p_meta:set_string("weather_override", "")
   end
   set_sky_clouds(p_obj)
   update_player_sounds(p_name)
end

-------------------------
--SAVE AND LOAD

local function save_weather()
    --save state so can be reloaded.
    --only actually needed on log out,... but that doesn't work
    store:set_string("weather", climate.active_weather.name)
    store:set_float("temp", climate.active_temp)
    store:set_float("sea_temp", climate.active_sea_temp)
    store:set_float("ran_walk", ran_walk)
end

-- this works, register_on_leaveplayer doesn't
minetest.register_on_shutdown(function()
        save_weather()
end)

minetest.register_on_joinplayer(
    function(player)
        local p_name = player:get_player_name()
        -- load any prior weather overrides
        local ovr = player:get_meta():get_string("weather_override")
        if ovr ~= "" then
            climate.set_weather_override(p_name, player, ovr)
        else
            update_player_sounds(p_name)
        end
        set_sky_clouds(player)
        --set weather effects for this player
        minetest.chat_send_player(p_name, exiledatestring())
end)

--get weather from storage, override random start values
local function load_saved_weather()
   local datestr = exiledatestring()
   minetest.log("action", datestr.." : Loading weather")
   local w_name = store:get_string("weather")
    if w_name ~= "" then
        --check valid
        local weather = climate.registered_weathers[w_name]
        if weather then
	    climate.active_weather = weather
	    minetest.log("action", "Loaded a valid weather: "..w_name)
            minetest.log("action", "Loaded a valid weather: "..w_name)
        else
	    minetest.log("action", "Invalid weather loaded: "..w_name)
        end
    else
        minetest.log("action", "No previous weather could be loaded")
        save_weather() -- save initial random data
    end

    --same again, but for temperature
    local temp = store:get_float("temp")
    if temp then
        climate.active_temp = temp
    end
    local stemp = store:get_float("sea_temp")
    if stemp then
        climate.active_sea_temp = stemp
    end
    --same again, but for ran_walk
    local ranw = store:get_float("ran_walk")
    if ranw then
        ran_walk = ranw
    end
    --load climate_history
    local ch = store:get_string("climate_history")
    if ch ~= nil then
        load_climate_history(ch)
    end
end

--------------------
--world functions
local function select_new_active_weather()
    --select a new active_weather from probabilities
    --it will loop through and try to change the weather
    local new_weather_name
    for n, next in pairs(climate.active_weather.chain) do
      --roll dice
      local c = math.random()
      --use temperature adjusted probability
      if climate.active_temp < plvl_froz then
	 --frozen temperature
	 if next[2] > c then
	    new_weather_name = next[1]
	 end
      elseif climate.active_temp < plvl_cold then
	 --cold temperature
	 if next[3] > c then
	    new_weather_name = next[1]
	 end
      elseif climate.active_temp < plvl_mid then
	 --mid temperature
	 if next[4] > c then
	    new_weather_name = next[1]
	 end
      else
	 --hot temperature
	 if next[5] > c then
	    new_weather_name = next[1]
	 end
      end
    end

    --did it succeed in getting a new state?
    if new_weather_name and new_weather_name ~= climate.active_weather.name then

      --we need to update the sky and set the new
       climate.active_weather = climate.registered_weathers[new_weather_name]
    end
    --do for each player
    for _,player in ipairs(minetest.get_connected_players()) do
       --set sky and clouds for new state using the new active_weather
       set_sky_clouds(player)
       update_player_sounds(player:get_player_name())
    end
end

local function set_world_temperature()
    --this is a universal temperature for the whole map
    --we treat the whole map as one coherent region, with a single climate
    --specific player temp adjusted from this (e.g. by altitude)

    --get day night wave
    local tod = minetest.get_timeofday()
    --diff between day and night is this x2
    local dn_amp = -8
    local dn_period = (2*math.pi)/1 ---match day length
    local dn_wav = dn_amp * math.cos(tod * dn_period)

    --random walk...an incremental fluctuation that is capped
    ran_walk = ran_walk + math.random(-2, 2)
    if ran_walk > ran_walk_range or ran_walk < -ran_walk_range then
       ran_walk = ran_walk/1.04
    end
    local dc_wav, sea_wav = get_seasonal_waves()
    --sum waves plus some random noise
    climate.active_temp =  dc_wav + dn_wav + ran_walk
    climate.active_sea_temp = sea_wav + ((dn_wav + ran_walk) * 0.3)
    save_weather()
end

function climate.refresh()
    set_world_temperature()
    select_new_active_weather()
end

--------------------------
-- Main step
--------------------------

local timer = 0
local timer_r = 0
local timer_s = 0

-- Overwrite random start values if the world is not brand new
minetest.register_on_mods_loaded(function()
      minetest.after(0.1, load_saved_weather)
end)

minetest.register_globalstep(function(dtime)
  timer = timer + dtime
  timer_r = timer_r + dtime
  timer_s = timer_s + dtime
  --update weather state
  if timer > active_weather_interval then
     --timer has expired, switch to a new weather state
     --reset timer and interval
     timer = 0
     active_weather_interval = set_active_interval()
     --save interval
     set_world_temperature()
     select_new_active_weather()
  end
  if timer_r >= 60 then -- it's time to record changes
     record_climate_history(climate)
     store:set_string("climate_history", get_climate_history())
     timer_r = 0
  end
  if timer_s >= 0.1 then -- update sound levels for underground transition
     for _,player in ipairs(minetest.get_connected_players()) do
	local ppos = player:get_pos()
	update_player_sounds(player:get_player_name(), ppos)
     end
     timer_s = 0
  end
end)

--------------------------------------------------------------------
--CHAT COMMANDS


minetest.register_privilege("set_temp", {
	description = "Set the Climate active temperature",
	give_to_singleplayer = false
})


minetest.register_chatcommand("set_temp", {
  params = "<temp>",
  description = "Set the Climate active temperature",
  privs = {privs=true},
  func = function(name, param)
     local newtemp = tonumber(param)
     if not newtemp then
	return false, ("Unadjusted base temp: "..climate.active_temp)
     end
     if newtemp < -100 or newtemp > 100 then
	return false, "Invalid temperature"
     end
     if minetest.check_player_privs(name, {set_temp = true}) then
	climate.active_temp = newtemp

	--only actually needed on log out,... but that doesn't work
	store:set_float("temp", climate.active_temp)

	return true, "Climate active temperature set to: "..newtemp

     else
	return false, "You need the set_temp privilege to use this command."
     end
  end,
})



-------------

minetest.register_privilege("set_weather", {
	description = "Set the Climate active weather",
	give_to_singleplayer = false
})


minetest.register_chatcommand("set_weather", {
 params = "<weather> | help",
 description = "Set the Climate active weather",
 privs = {set_weather=true},
 func = function(name, param)
    if minetest.check_player_privs(name, {set_weather = true}) then
       --check valid
       if param == "help" then
	  local wlist = "Available weather states:\n"
	  for i = 1,#climate.weather_index do
	     wlist = wlist..climate.weather_index[i].."\n"
	  end
	  return false, wlist
       end

       local weather = climate.registered_weathers[param]
       if weather then
	  climate.active_weather = weather
	  --do for each player
	  for _,player in ipairs(minetest.get_connected_players()) do
	     --set sky and clouds for new state using the new active_weather

	     set_sky_clouds(player)
	     update_player_sounds(player:get_player_name())

	  end
	  --only actually needed on log out,... but that doesn't work
	  store:set_string("weather", climate.active_weather.name)

	  return true, "Climate active weather set to: "..param
       else
	  return false, ("Current weather is "..climate.active_weather.name)
       end

    else
       return false, "You need the set_temp privilege to use this command."
    end
 end,
})

-------------

minetest.register_chatcommand("set_woverride", {
    params = "<weather name>",
    description = "Sets your weather override",
    privs = {set_weather=true},
    func = function(name, param)
       if minetest.check_player_privs(name, {set_weather = false}) then
	  return
       end
       if param == "" or param == "help" then
	  return false
       end
       if param == "none" then
	  climate.set_weather_override(name, nil, "")
	  return
       end
       local weather = climate.registered_weathers[param]
       if weather then
	  climate.set_weather_override(name, nil, param)
       else
	  return false, "argument must be a valid weather name, or none"
       end
    end
})

minetest.register_on_mods_loaded(function()
      if beerchat then -- we have beerchat installed, add a date command
	 beerchat.register_relaycommand("date", function()
                  local date = exiledatestring()
		  return date
	 end)
      end
end)


-- MOON PHASE CHECKING LOOP

local mphl_interval = (5*60) -- moon_phase_loop_interval (25% an Exile day or 8 minutes)
local function moon_phase_loop()
  --local tod = minetest.get_timeofday() or 0
  
  -- only set skies while the moon is not up (nvm lol, keeping the old code lines just in case though)
  --if not (tod < 0.23 or tod > 0.75) then
    climate.update_skies()
  --end
  
  minetest.after(mphl_interval,moon_phase_loop)
end

minetest.after(mphl_interval,moon_phase_loop) -- sky is set on player join, check again after interval
