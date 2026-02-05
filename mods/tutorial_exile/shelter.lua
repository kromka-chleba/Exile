-- shelter stage code

-- This stage handles differently from the others, without using triggers
--  other than enter/exit, and it calls the mapchunk shepherd to show off
--  the seasons.

minimal = minimal
climate = climate
zone = zone

local temp_steps = 4

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
    { name = "overcast_light_rain", temp = 10 },
    { name = "light_haze", temp = 33 },
    { name = "snowstorm", temp = -8 },
    { name = "clear", temp = 22 },
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
    local minpos = vector.new()
    local maxpos = stage.size
    local start_temp = w_steps[1].temp
    local real_base = instance.offset + stage.location
    weather[instance.number] =
        {
            name = w_steps[1].name,
            zone_id = zone.create(
                "cli-tmp", {
                    pos1 = minpos,
                    pos2 = maxpos,
                    base = real_base,
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
end

-- Find the player's instance, shut off weather in it
local function remove_instance_weather(name)
    local inum = track[name]
    if not inum then return end
    local zid = weather[inum].zone_id
    show_weather(inum, "removed")
    zone.destroy(zid)
    weather[inum] = nil
    track[name] = nil
end

local function shift_temp(instance_number, rate)
    local wtr = weather[instance_number]
    if not wtr then return end -- we closed down before this ran
    local zid = wtr.zone_id

    local def = zone.get_data(zid)
    local dat = def["ztrd_cli-tmp"]

    if wtr.temp_timer == 0 then -- finish the transition
        wtr.temp_timer = 0
        wtr.current_step = wtr.current_step + 1
        wtr.name = w_steps[wtr.current_step]
        show_weather(instance_number)
        return
    end
    local old = dat.value
    dat.value = dat.value + rate
    wtr.temp_timer = wtr.temp_timer - 1
    zone.set_data(zid, def)
    core.after(1, shift_temp, instance_number, rate) -- 1 step per second
end

local function queue_next_weather(player)
    local name = player:get_player_name()
    local inum = track[name]
    weather[inum].name = "overcast" -- Transitional state
    show_weather(inum)

    local wth = weather[inum]
    wth.temp_timer = temp_steps
    wth.target_temp = w_steps[wth.current_step + 1].temp -- next step's temp
    local shift_rate =
        (wth.target_temp - w_steps[wth.current_step].temp ) / temp_steps
    core.after(1, shift_temp, inum, shift_rate)
end

--------------------------------------------------------------------------
-- Shelter obstacles

local function OpenTheGate(player)
    local pos = player:get_pos()
    local gate = core.find_node_near(pos, 3, "tutorial_exile:iron_wall")
    if gate then
        core.sound_play("tech_iron_chest_close",
                        { pos = gate, gain = 1, max_hear_distance = 10 })
        core.remove_node(gate)
        queue_next_weather(player)
    end
end

local function tracking()
    local next = next
    if next(track) == nil then return end
    for name, _ in pairs(track) do
        local player = core.get_player_by_name(name)
        if not core.is_player(player) then -- Disconnected
            remove_instance_weather(name)
        else
            local daylight = minimal.get_daylight(player:get_pos(), 0.5)
            if daylight and daylight < 12 then
                OpenTheGate(player)
            end
        end
    end
    minetest.after(1.5, tracking)
end

local function OpenFireGate(pos, player)
    local gate = core.find_node_near(pos, 6, "tutorial_exile:iron_wall")
    if gate then
        core.sound_play("tech_iron_chest_close",
                        { pos = gate, gain = 1, max_hear_distance = 10 })
        core.remove_node(gate)
        if player then
            queue_next_weather(player)
        end
    end
end
local function TutorialShelterFire(pos)
    local objs = core.get_objects_inside_radius(pos, 6)
    local player
    for _, o in pairs(objs) do
        if core.is_player(o) then player = o ; break ; end
    end
    minimal.switch_node(pos, "tech:small_wood_fire")
    local meta = core.get_meta(pos)
    meta:set_string("hot_air", "Y")
    minetest.check_for_falling(pos)
    core.after(8, OpenFireGate, pos, player)
end
core.override_item("tutorial_exile:demo_fire", {
        on_ignite = TutorialShelterFire
})

-- Enter and exit functions

local function enter(stage, player, name, instance)
    HEALTH.hide_hud_elements(player, nil, "all")
    HEALTH.show_hud_elements(player, nil, "enviro_temp")
    HEALTH.show_hud_elements(player, nil, "energy")

    track[name] = instance.number

    create_instance_weather(instance, stage)
    core.after(12, tracking) -- won't hit the next stage for a bit
end
local function exit(stage, player, name, instance)
    HEALTH.show_hud_elements(player, nil, "all")
    remove_instance_weather(name)
end

return enter, exit
