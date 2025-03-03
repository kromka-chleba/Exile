-- shelter stage code

-- This stage handles differently from the others, without using triggers
--  other than enter/exit, and it calls the mapchunk shepherd to show off
--  the seasons.

minimal = minimal
climate = climate
zone = zone

--------------------------------------------------------------------------
-- Data


local track = {} -- players in the stage
-- { name = instance_number }

local function get_player_from_instance(inum)
    for name, instance in pairs(track) do
        if inum == instance then
            return name, core.get_player_by_name(name)
        end
    end
end

-- Weather steps:
--  start in rainy spring until the cave 10c
--  heatwave summer until first house 33c
--  snowy winter until second house -8c
--  clear and sunny by the end 22c

-- 10 seconds ramp-up? or maybe 1 degree c per second

-- Don't change weather until temp range is reached?

local w_steps = {
    { wn = "overcast_light_rain", temp = 10 },
    { wn = "light_haze", temp = 33 },
    { wn = "snowstorm", temp = -8 },
    { wn = "clear", temp = 22 },
}


--------------------------------------------------------------------------
-- Weather & Temperature

local weather = {} -- current weather state for an instance
-- { number = { name = "clear", temp_adjust = 0, zone_id = <string> }

local function show_weather(inum, player_out)
    local _, player = get_player_from_instance(inum)
    if not core.is_player(player) then return end -- disconnected?
    local new_weather = ""
    if not player_out and weather[inum].current_step <= #w_steps then
        new_weather = w_steps[weather[inum].current_step].name
    end
    climate.set_weather_override(nil, player, new_weather)
end


local function create_instance_weather(instance, stage)
    local minpos = instance.offset
    local maxpos = instance.offset + stage.size
    local start_temp = w_steps[1].temp
    weather[instance.number] =
        {
            name = w_steps[1].name,
            zone_id = zone.create(
                "cli-tmp", {
                    pos1 = minpos,
                    pos2 = maxpos,
                    ["ztrd_cli-tmp"] = {
                        ["value"] = start_temp,
                        ["mode"] = "absolute"
                    }
            }),
            temp_timer = 0,
            target_temp = start_temp,
            current_step = 1,
        }
    show_weather(instance.number)
    print("Set up weather override at ",core.pos_to_string(minpos))
end

-- Find the player's instance, shut off weather in it
local function remove_instance_weather(name)
    local inum = track[name]
    if not inum then return end
    local zid = weather[inum].zone_id
    print("Removing weather zone #",inum,": ",zid)
    show_weather(inum, "removed")
    print("show weather done")
    zone.destroy(zid)
    print("zone destroy done")
    weather[inum] = nil
    track[name] = nil
    print("done")
end

local function shift_temp(instance_number)
    local wtr = weather[instance_number]
    if not wtr then return end -- we closed down before this ran
    local zid = wtr.zone_id

    local def = zone.get_data(zid)
    local dat = def["ztrd_cli-tmp"]

    if dat.value == wtr.target_temp then -- finish the transition
        wtr.temp_timer = 0
        wtr.current_step = wtr.current_step + 1
        wtr.name = w_steps[wtr.current_step]
        show_weather(instance_number)
        return
    end

    dat.value = dat.value + ( wtr.target_temp - dat.value ) / 10 -- 10 steps
    wtr.temp_timer = wtr.temp_timer - 1
    zone.set_data(zid, def)
    core.after(1, shift_temp, instance_number) -- 1 step per second
end

local function queue_next_weather(player)
    local name = player:get_player_name()
    local inum = track[name]
    local wth = weather[inum]
    wth.name = "overcast" -- Transitional state
    show_weather(inum)
    wth.temp_timer = 10
    wth.target_temp = w_steps[wth.current_step + 1].temp -- next step's temp
    core.after(1, shift_temp, inum)
end

--------------------------------------------------------------------------
-- Shelter obstacles

local function OpenTheGate(player)
    local pos = player:get_pos()
    local gate = core.find_node_near(pos, 4, "tutorial_exile:iron_wall")
    if gate then
        core.remove_node(gate)
        -- #TODO: play a sound
        -- #TODO: switch to next weather stage, if any
        queue_next_weather(player)
    end
end

local function tracking()
    local next = next
    if next(track) == nil then return end
    for name, _ in pairs(track) do
        local player = core.get_player_by_name(name)
        if not core.is_player(player) then -- Disconnected
            print("Player gone, clearing instance weather")
            remove_instance_weather(name)
        else
            local daylight = minimal.get_daylight(player:get_pos(), 0.5)
            print("Checking, daylight is ",daylight)
            if daylight < 12 then
                OpenTheGate(player) ; print("Opening a gate")
            end
        end
    end
    minetest.after(1.5, tracking)
end

local function enter(stage, player, name, instance)
    track[name] = instance.number

    create_instance_weather(instance, stage)
    core.after(12, tracking) -- won't hit the next stage for a bit
end
local function exit(stage, player, name, instance)
    print("Running shelter exit")
    remove_instance_weather(name)
end

return enter, exit
