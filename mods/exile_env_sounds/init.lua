-------------------------------------------------------
--local modpath = minetest.get_modpath("exile_env_sounds")

--dofile(modpath .. "/flowing_water.lua")
--dofile(modpath .. "/beach_waves.lua")


local ran = math.random
local min = math.min

------------------------------------------------
local radius = 8 -- node search radius around player

-- End of parameters


----------------------------------------------
--
local function posav(npos, num)
   local pos_av = vector.new()
   for _, pos in ipairs(npos) do
      pos_av.x = pos_av.x + pos.x
      pos_av.y = pos_av.y + pos.y
      pos_av.z = pos_av.z + pos.z
   end
   pos_av = vector.divide(pos_av, num)

   return 	pos_av
end



-- Update sound for player

local function update_sound(player)
   local player_name = player:get_player_name()
   local ppos = player:get_pos()

   local areamin = vector.subtract(ppos, radius)
   local areamax = vector.add(ppos, radius)

   --flowing water
   if ran()<0.7 then
      local water_nodes = {"nodes_nature:freshwater_flowing",
                           "nodes_nature:salt_water_flowing"}
      local wpos, _ = minetest.find_nodes_in_area(areamin, areamax, water_nodes)
      local waters = #wpos

      if waters >= 2 then
         minetest.sound_play(
            "env_sounds_water",
            {
               pos = posav(wpos, waters),
               to_player = player_name,
               gain = min(0.04 + waters * 0.004, 0.4),
            }
         )
      end
   end

   --beach sounds
   if ran()<0.7 then
      if ppos.y < radius or ppos.y > -radius then

         local water_nodes = {"nodes_nature:salt_water_flowing",
                              "nodes_nature:salt_water_source"}
         local wpos, _ = minetest.find_nodes_in_area(areamin, areamax,
                                                     water_nodes)
         local waters = #wpos

         if waters >= 9 then
            local ground_nodes = {"group:crumbly", "group:cracky"}
            local gpos = minetest.find_node_near(ppos, 2, ground_nodes)

            if gpos then
               minetest.sound_play(
                  "env_sounds_waves",
                  {
                     pos = posav(wpos, waters),
                     to_player = player_name,
                     gain = min(0.06 + waters * 0.006, 1),
                  }
               )
            end
         end
      end
   end

   --lava sounds
   if ran()<0.7 then

      local lava_nodes = {"nodes_nature:lava_flowing",
                          "nodes_nature:lava_source"}
      local lpos, _ = minetest.find_nodes_in_area(areamin, areamax,lava_nodes)
      local lavas = #lpos

      if lavas >= 1 then
         minetest.sound_play(
            "env_sounds_lava",
            {
               pos = posav(lpos, lavas),
               to_player = player_name,
               gain = min(0.06 + lavas * 0.006, 1),
            }
         )
      end
   end


   --wind sounds
   if ran()<0.7 then
      if ppos.y > -15 then
         --(if a more sophisticated way of handling wind is ever added then this check should move to climate mod)
         local l = minimal.get_daylight({x=ppos.x,
                                         y=ppos.y + 1,
                                         z=ppos.z}, 0.5)
            or 0 --getting nil error?
         if l >= 12 then
            local w = climate.active_weather.name

            --strong wind
            if w == 'duststorm'
               or w == 'haze'
               or w == 'snowstorm'
               or w == 'superstorm'
               or w == 'thunderstorm'
               or w == 'overcast_heavy_rain'
               or w == 'overcast_heavy_snow' then

               local leafy_nodes = {"group:woody_plant", "group:fibrous_plant"}
               local lpos, _ = minetest.find_nodes_in_area(areamin,
                                                           areamax,
                                                           leafy_nodes)
               local leafy = #lpos
               if leafy >= 5 then

                  minetest.sound_play(
                     "env_sounds_wind_strong",
                     {
                        pos = posav(lpos, leafy),
                        to_player = player_name,
                        gain = min(0.06 + leafy * 0.006, 1),
                     }
                  )
               end

            elseif w == 'light_haze'
               or w == 'light_rain'
               or w == 'medium_cloud'
               or w == 'overcast_light_rain'
               or w == 'overcast_light_snow'
               or w == 'overcast_rain'
               or w == 'overcast_snow' then

               local leafy_nodes = {"group:woody_plant", "group:fibrous_plant"}
               local lpos, _ = minetest.find_nodes_in_area(areamin, areamax,
                                                           leafy_nodes)
               local leafy = #lpos
               if leafy >= 5 then

                  minetest.sound_play(
                     "env_sounds_wind_light",
                     {
                        pos = posav(lpos, leafy),
                        to_player = player_name,
                        gain = min(0.06 + leafy * 0.006, 1),
                     }
                  )
               end

            end
         end

      end
   end


   --undercity darkness haunting
   if ppos.y < -140 and ppos.y > -1150 then

      local r = ran(-15,15)
      local ranpos = {x = ppos.x + r, y = ppos.y + r/10, z = ppos.z + r }

      local node = minetest.get_node(ranpos).name
      if node ~= 'air' then return end

      local l = minetest.get_node_light(ranpos)
      if l < 6 then

         --disembodied voices breaking through from another dimension
         --memories of the past? Or are they trapped somewhere?
         local roll = ran()
         if roll < 0.25 then
            minetest.sound_play(
               "env_sounds_haunt",
               {
                  pos = ranpos,
                  to_player = player_name,
                  --max_hear_distance = 30,
                  gain = 1.4-math.abs(r/15),
               }
            )
         elseif roll < 0.5 then
            minetest.sound_play(
               "env_sounds_haunt2",
               {
                  pos = ranpos,
                  to_player = player_name,
                  --max_hear_distance = 30,
                  gain = 1.4-math.abs(r/15),
               }
            )

         elseif roll < 0.75 then
            minetest.sound_play(
               "env_sounds_haunt3",
               {
                  pos = ranpos,
                  to_player = player_name,
                  --max_hear_distance = 30,
                  gain = 1.4-math.abs(r/15),
               }
            )
         else
            minetest.sound_play(
               "env_sounds_haunt4",
               {
                  pos = ranpos,
                  to_player = player_name,
                  --max_hear_distance = 30,
                  gain = 1.4-math.abs(r/15),
               }
            )
         end

         minetest.add_particlespawner({
               amount = 24,
               time = 12,
               minpos = {x=ranpos.x-5, y=ranpos.y-3, z=ranpos.z-5},
               maxpos = {x=ranpos.x+5, y=ranpos.y+4, z=ranpos.z+5},
               minvel = {x = -0.3,  y = -0.3,  z = -0.3},
               maxvel = {x = 0.3, y = 0.4, z = 0.3},
               minacc = {x = -0.1, y = -0.1, z = -0.1},
               maxacc = {x = 0.1, y = 0.3, z = 0.1},
               minexptime = 0.01,
               maxexptime = 0.4,
               minsize = 0.2,
               maxsize = 0.4,
               texture = "env_sounds_haunt.png",
               glow = 7,
         })

      end

   end


end


-- Update sound 'on joinplayer'

minetest.register_on_joinplayer(function(player)
      update_sound(player)
end)


-- Cyclic sound update

local function cyclic_update()
   for _, player in pairs(minetest.get_connected_players()) do
      update_sound(player)
   end
   minetest.after(4, cyclic_update)
end

minetest.after(0, cyclic_update)
