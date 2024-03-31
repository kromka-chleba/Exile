local chan
local aux_fire_rate = 0.35 -- sec
local aux_held = false
local sneak_held = false

local function join()
   chan = minetest.mod_channel_join("exilecsm")
end

minetest.register_on_mods_loaded(function()
      join()
end)

minetest.register_on_modchannel_signal(function(channel_name, signal)
      if channel_name ~= "exilecsm" then return end
      if signal == 1 then -- join failed, retry
	 minetest.after(1, join)
      end
      if signal == 0 then
	 chan:send_all("ENABLE") -- Inform the server we're handling these keys
      end
end)

local player
local control
local a_limit = 0

local function use_key(dtime)
   if a_limit > 0 then a_limit = a_limit - dtime return end
   if control.aux1 then
      a_limit = aux_fire_rate
      chan:send_all(aux_held and "AUX1H"
		    or "AUX1")
   end
end

local sneak_last = 0
local sneak_count = 0
local function sneak_clear()
   sneak_last = 0
      sneak_count = 0
end

local function check_crawl(dtime) -- double tap shift to enter/exit crawl mode

   if sneak_last > 0 then -- do sneak count timeout
      sneak_last = sneak_last - dtime
      if sneak_last <=0 then sneak_clear() end
   end

   -- Only count initial presses, not holding it down
   if sneak_held and control.sneak or not control.sneak then return end

   sneak_count = sneak_count + 1
   if sneak_count == 1 then
      sneak_last = 0.35 -- timeout before sneak count clears
   end

   if sneak_count >= 2 then
      chan:send_all("CRAWL")
      sneak_clear()
   end
end

minetest.register_globalstep(function(dtime)
      player = minetest.localplayer
      if not player then return end -- don't run until the player is set up
      control = player:get_control()
      use_key(dtime)
      check_crawl(dtime)
      aux_held = control.aux1
      sneak_held = control.sneak
end)
