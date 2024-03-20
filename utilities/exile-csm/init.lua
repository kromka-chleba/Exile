local chan

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
	 chan:send_all("ENABLE")
      end
end)

local player
local control

local debounce = 0

local function use_key(dtime)
      if debounce > 0 then
	 debounce = debounce - dtime
	 return
      end
      if control.aux1 then
	 debounce = 1
	 chan:send_all("AUX1")
      end
end

local sneak_last = 0
local sneak_prev

local function check_crawl(dtime) -- double tap shift to enter/exit crawl mode
   if sneak_last > 0 then
      sneak_last = sneak_last - dtime
      if sneak_last <=0 then
	 sneak_last = 0
    end
   end
   if sneak_prev == true and control.sneak == false then -- just released
      if sneak_last == 0 then
	 sneak_last = 1 -- 1 second timeout
      else
	 chan:send_all("CRAWL")
      end
   end
   sneak_prev = control.sneak
end

minetest.register_globalstep(function(dtime)
      player = minetest.localplayer
      if not player then return end -- don't run until the player is set up
      control = player:get_control()
      use_key(dtime)
      check_crawl(dtime)
end)
