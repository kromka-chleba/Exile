-----------------------------
--ON ACTION EFFECTS
--e.g. for eating items, exhaustion from moving etc

-----------------------------
local random = math.random

sfinv = sfinv
HEALTH = HEALTH

local function modify_hp(...) -- player, hp_amt
  return HEALTH.modify_hp(...)
end
local function modify_int(...) -- player, int_name, int_value
  return HEALTH.modify_int(...)
end


-----------------------------
--On Actions
--
--Consummable items
function HEALTH.use_item(itemstack, user, f_table) -- itemstack, user, food_table
   if (type(itemstack) ~= "userdata" or not itemstack["get_name"]) or not minetest.is_player(user) or not minetest.settings:get_bool("enable_damage") then
      return
   end
  f_table = type(f_table) == "table" and f_table or HEALTH.get_food_stats(itemstack)
  if not f_table then
    return itemstack
  end
  -- numbered indexes for legacy support
  local hp_change = f_table.hp or f_table.health or f_table[1]
  local thirst_change = f_table.th or f_table.thirst or f_table[2]
  local hunger_change = f_table.hu or f_table.hun or f_table.hunger or f_table[3]
  local energy_change = f_table.en or f_table.energy or f_table[4]
  local temp_change = f_table.temp or f_table.temperature or f_table[5]
  local replace_item = f_table.replace or f_table[6]

   local meta = user:get_meta()
   -- set new values
   modify_hp(user,hp_change)
   modify_int(meta,"thirst",thirst_change)
   modify_int(meta,"hunger",hunger_change)
   modify_int(meta,"energy",energy_change)
   modify_int(meta,"temperature",temp_change)

   -- and update malus (need for setting correct physics)
   HEALTH.quick_physics(user,meta)
   --update form so can see change while looking
   sfinv.set_player_inventory_formspec(user)

   --minetest.chat_send_player(name, minetest.registered_items[item].description .." effect = Health: "..hp_change..", Thirst: "..thirst_change.. ", Hunger: "..hunger_change.. ", Energy: "..energy_change.. ", Body Temperature: "..temp_change )
   local pos = user:get_pos()
   minetest.sound_play("health_eat", {pos = pos, gain = 0.5, max_hear_distance = 2})

   --replace/take
   itemstack:take_item()
   if itemstack:get_count() == 0 then
      itemstack:add_item(replace_with_item)
   else
      local inv = user:get_inventory()
      if inv:room_for_item("main", replace_with_item) then
	 inv:add_item("main", replace_with_item)
      else
	 minetest.add_item(user:get_pos(), replace_with_item)
      end
   end

   return itemstack
end


--fast interval (cf main update)
--Moving and digging and building
--Environmental based, bed rest ...
if minetest.settings:get_bool("enable_damage") then

	local timer = 0
	local interval = 4
	minetest.register_globalstep(function(dtime)
		timer = timer + dtime

		--run
		if timer > interval then
			for _,player in ipairs(minetest.get_connected_players()) do
				local name = player:get_player_name()
				local meta = player:get_meta()

				local health = player:get_hp()
				-- if we're dead, no more healing/etc
				if health > 0 and
				   player:get_armor_groups().immortal ~= 1 then
				local thirst = 0 -- to change by
				local hunger = 0 -- to change by
				local energy = meta:get_int("energy") -- full value
				local temperature = meta:get_int("temperature") -- full value

				----------------
				--movement/digging
				local controls = player:get_player_control()
				-- Determine if the player is active,
        --some actions more energetic
				if controls.up
				or controls.down
				or controls.left
				or controls.right
				or controls.RMB
				then
					energy = energy - 3
          --thirsty work
          if random()<0.07 then
            thirst = thirst - 1
            hunger = hunger - 2
          end
				elseif controls.LMB
				or controls.jump then
					energy = energy - 8
          --thirsty work
          if random()<0.07 then
            thirst = thirst - 2
            hunger = hunger - 4
          end
				end

				----------------
				--Environmental temperature
				local player_pos = player:get_pos()
        --local node_name = minetest.get_node(player_pos).name
        local water = minimal.in_group(player_pos,"water")
				player_pos.y = player_pos.y + 0.6 --adjust to body height (for radiant heat)
				local enviro_temp = climate.get_point_temp(player_pos)
				--being outside tolerance range will drain energy. When energy is drained will succumb.
        --[safe] comfort zone ->[low cost]->stress zone ->[high cost]-> danger zone->[damage]

        local comfort_low = meta:get_int("clothing_temp_min")
        local comfort_high = meta:get_int("clothing_temp_max") + 1
	-- comfort is rounded off in display, so you can be half a degree
	-- over and still in the white. Don't confuse players by penalizing!
        local stress_low = comfort_low - 10
        local stress_high = comfort_high + 10
        local danger_low = stress_low - 40
        local danger_high = stress_high +40
        --energy costs (extreme, danger, stress)
        local costex = 8
        local costd = 4
        local costs = 1
        --water conducts heat better
        if water then
          costex = 13
          costd = 8
          costs = 4
        end


        --burn or freeze
        if enviro_temp < danger_low or enviro_temp > danger_high then
          --tissue damaging freeze/burn
          modify_hp(player,-1)
          energy = energy - costex
        --exhaustion from temp
        elseif energy > 0 then
					--have energy to resist (and it is resistable cf extreme)
					if enviro_temp < comfort_low or enviro_temp > comfort_high then
            --outside comfort zone
						if enviro_temp < stress_low or enviro_temp > stress_high then
							energy = energy - costd
						else
							energy = energy -costs
						end
					end
        end

          --totally exhausted, heat stroke or hypothermia now sets in
        if energy <= 0
        and (enviro_temp < stress_low or enviro_temp > stress_high) then
          --heat or cool to ambient temperature
          HEALTH.set_int(meta,"temperature",(temperature*0.95) + (enviro_temp*0.05))
        end

				------------------
				local light = minetest.get_node_light(player_pos, 0.5)
				local rain = climate.get_rain(player_pos, light)
				local snow = climate.get_snow(player_pos, light)
				local dam_weather = climate.get_damage_weather(player_pos, light)

				--bed rest
				--when in bed, under shelter boost energy
				if energy < 1000 then
					if bed_rest.player[name] then
						--best rest is under shelter, in a non-extreme temperature
            local lvl = bed_rest.level[name]
						if rain
            or snow
            or dam_weather
            or enviro_temp < stress_low
            or enviro_temp > stress_high then
              --terrible sleep in the rain etc
              if random()>0.1 then
                energy = energy + (2 * lvl)
              end

            elseif enviro_temp < comfort_low
            or enviro_temp > comfort_high
            or light >= 14 then
              --okay sleep if in uncomfortable temp, exposed
              energy = energy + (4 * lvl)

            else
              --best rest is under shelter, in a non-extreme temperature
							energy = energy + (16 * lvl)
						end
					end
				end

        ------------------
				--drink a little rain
				if rain and thirst < 100 then
					--only sometimes or too easy
					if random()<0.2 then
						thirst = thirst + 1
					end
				end

        --thirsty in heat
        if random()<0.1 then
          if enviro_temp > stress_high then
            thirst = thirst - 2
          elseif enviro_temp > comfort_high then
            thirst = thirst - 1
          end
        end

				------------------
				--harmed by damaging weather,
				--exhausted by rain, snow
				if random()<0.5 then
					if dam_weather then
            modify_hp(player,-1)
						energy = energy - 15

            --dust fever
            if random() < 0.02 then
              if climate.active_weather.name == 'duststorm' then
                HEALTH.add_new_effect(player, {"Dust Fever", 1})
              end
            end
					elseif rain or snow then
						energy = energy - 2
					end
				end

        ------------------
        --Health effects

        --zoonotic and contagious diseases
        --in biome
         --in node

        -- Fungal Infection from standing on wet soil
        if random() < 0.002 then
          local posu = player_pos
          posu.y = posu.y - 1.6

          if minimal.in_group(posu, "wet_sediment") then
            HEALTH.add_new_effect(player, {"Fungal Infection", 1})
          end
        end
        ------------------
        --Final Housekeeping

        --update
        HEALTH.set_int(meta,"energy",energy)
        modify_int(meta,"hunger",hunger)
        modify_int(meta,"thirst",thirst)

				--update form so can see change while looking
				sfinv.set_player_inventory_formspec(player)

        end

			end
		end

		--reset
		if timer > interval then
			timer = 0
		end
	end)

end
