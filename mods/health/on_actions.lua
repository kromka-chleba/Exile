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


-- for HEALTH.register_on_player_eat
local health_eat_callbacks = {}
function HEALTH.register_on_player_eat(func)
    if type(func) == "function" then
        health_eat_callbacks[#health_eat_callbacks + 1] = func
    end
end
-----------------------------
--On Actions
--
--Consummable items
function HEALTH.use_item(itemstack, user, f_table) -- itemstack, user, food_table
    if (not minetest.is_player(user)
        or not minetest.settings:get_bool("enable_damage")) then
        return
    end
    f_table = type(f_table) == "table" and f_table
        or HEALTH.get_food_stats(itemstack)
    if not f_table then
        return itemstack
    end
    f_table = type(f_table) == "table" and HEALTH.get_food_stats(f_table)
        or HEALTH.get_food_stats(itemstack)

    local meta = user:get_meta()
    -- set new values
    modify_hp(user,f_table.hp)
    modify_int(user,meta,"thirst",f_table.th)
    modify_int(user,meta,"hunger",f_table.hu)
    modify_int(user,meta,"energy",f_table.en)
    modify_int(user,meta,"temperature",f_table.temp)
    local st = player_api.get_state(user)
    if st then
        st:set_progress("thirst", f_table.th)
        st:set_progress("hunger", f_table.hu)
        st:set_progress("energy", f_table.en)
        st:set_progress("int_temp", f_table.temp)
    end


    -- and update malus (need for setting correct physics)
    HEALTH.quick_physics(user,meta)
    --update form so can see change while looking
    sfinv.set_player_inventory_formspec(user)

    --[[
        minetest.chat_send_player(
        name, minetest.registered_items[item].description ..
        " effect = Health: "..hp_change..", Thirst: "..thirst_change..
        ", Hunger: "..hunger_change.. ", Energy: "..energy_change..
        ", Body Temperature: "..temp_change )
    ]]
    if type(itemstack) == "userdata"
        and type(itemstack["take_item"]) == "function" then
        -- only play eating sound if an itemstack

        local pos = user:get_pos()
        local sound = f_table.sound
        if sound.name ~= "" then
            minetest.sound_play(sound.name, minimal.merge_tables(sound,{pos=pos}))
        end
        local replace_item = f_table.rwi
        --replace/take (non-creative)
        if not minimal.player_in_creative(user) then
            itemstack:take_item()
            if itemstack:get_count() == 0 then
                itemstack:add_item(replace_item)
            else
                local inv = user:get_inventory()
                if inv:room_for_item("main", replace_item) then
                    inv:add_item("main", replace_item)
                else
                    minetest.add_item(pos, replace_item)
                end
            end
        end
    end

    -- register_on_player_eat callbacks
    if #health_eat_callbacks > 0 then
        for _,func in pairs(health_eat_callbacks) do
            func(itemstack, user, f_table)
        end
    end

    return itemstack
end


--fast interval (cf main update)
--Moving and digging and building
--Environmental based, bed rest ...


if minetest.settings:get_bool("enable_damage") == false then return end

local timer = 0   local interval = 4

local function fast_interval(dtime)
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
                local st = player_api.get_state_by_name(name)
                local thirst = meta:get_int("thirst")
                local hunger = meta:get_int("hunger")
                local energy = meta:get_int("energy")
                local temperature = meta:get_int("temperature")

                if temperature == 37 then
                    if st:is("bodytemp") then
                        st:clear("bodytemp")
                    end
                end
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

                local water = minimal.pos_group(player_pos,"water")
                player_pos.y = player_pos.y + 0.6
                --adjust to body height (for radiant heat)

                local enviro_temp = climate.get_point_temp(player_pos, true)
                --being outside tolerance range will drain energy.
                --  When energy is drained will succumb.
                -- [safe] comfort zone ->[low cost]->
                --   stress zone ->[high cost]-> danger zone->[damage]

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
                    health = health - 1
                    energy = energy - costex
                    --exhaustion from temp
                elseif energy > 0 then
                    --have energy to resist (and it is resistable cf extreme)
                    if enviro_temp < comfort_low or enviro_temp > comfort_high then
                        --outside comfort zone
                        if enviro_temp < stress_low or enviro_temp > stress_high then
                            energy = energy - costd
                        else
                            energy = energy - costs
                        end
                    end
                end

                --totally exhausted, heat stroke or hypothermia now sets in
                if energy <= 0
                    and (enviro_temp < stress_low or enviro_temp > stress_high) then
                    --heat or cool to ambient temperature
                    temperature = (temperature*0.95) + (enviro_temp*0.05)
                    meta:set_int("temperature", temperature)
                    st:set_progress("int_temp", temperature)
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
                        st:add("resting") local sev = 2
                        --best rest is under shelter, in a non-extreme temperature
                        local lvl = bed_rest.level[name]
                        if rain
                            or snow
                            or dam_weather
                            or enviro_temp < stress_low
                            or enviro_temp > stress_high then
                            --terrible sleep in the rain etc
                            sev = 1 -- resting poorly
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
                            sev = 3 -- resting comfortably
                        end
                        if enviro_temp < comfort_low then
                            sev = 0 -- shivering
                        elseif enviro_temp > comfort_high then
                            sev = 4 -- sweating
                        end
                        st:set_severity("resting", sev)
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
                        health = health - 1
                        energy = energy - 15
                        if energy < 0 then
                            energy = 0
                        end

                        --dust fever
                        if random() < 0.02 then
                            if climate.active_weather.name == 'duststorm' then
                                HEALTH.add_new_effect(player, {"Dust Fever", 1})
                            end
                        end

                    elseif rain or snow then
                        energy = energy - 2
                        if energy < 0 then
                            energy = 0
                        end
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

                    if minimal.pos_group(posu, "wet_sediment") then
                        HEALTH.add_new_effect(player, {"Fungal Infection", 1})
                    end
                end





                ------------------
                --Final Housekeeping

                --cap energy etc
                if energy < 0 then
                    energy = 0
                elseif energy > 1000 then
                    energy = 1000
                end

                if thirst < 0 then
                    thirst = 0
                elseif thirst > 100 then
                    thirst = 100
                end

                if hunger < 0 then
                    hunger = 0
                elseif hunger > 1000 then
                    hunger = 1000
                end


                st:set_progress("energy", energy)
                st:set_progress("hunger", hunger)
                st:set_progress("thirst", thirst)

                --update
                HEALTH.set_int(player,meta,"energy",energy)
                HEALTH.set_int(player,meta,"hunger",hunger)
                HEALTH.set_int(player,meta,"thirst",thirst)
                player:set_hp(health)
                --update form so can see change while looking
                -- only in case char_tab is active (the one displaying health effect
                -- TODO proper thing to deal with thoses refreshes
                -- (lore - player_api - minimal - sfinc - crafting)

                if sfinv.get_page(player) == "lore:char_tab" then
                    sfinv.set_player_inventory_formspec(player)
                end
            end


        end
    end

    --reset
    if timer > interval then
        timer = 0
    end
end
minetest.register_globalstep(fast_interval)
