-- shelter stage code

-- This stage handles differently from the others, without using triggers
--  other than enter/exit, and it calls the mapchunk shepherd to show off
--  the seasons.

stage = ...
local mstore = tutorial.mstore -- mod storage

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


local save_shelter_state -- forward declaration, see "Save and restore" below

--------------------------------------------------------------------------
-- Weather & Temperature

local weather = {} -- current weather state for an instance
-- { number = { name = "clear", temp_adjust = 0, zone_id = <string> }

-- Weather steps:

local w_steps = {
--  Start in snowy winter, sheltering under a tree -8c
    { name = "snowstorm", temp = -8 },
--  A rainy spring until the cave 10c
    { name = "overcast_heavy_rain", temp = 10 },
--  Heatwave summer until the house 43c
    { name = "haze", temp = 43 },
--  clear and sunny fall at the end 22c
    { name = "clear", temp = 22 },
}

local function show_weather(inum, _player_out)
    local _, player = get_player_from_instance(inum)
    if not core.is_player(player) then return end -- disconnected?
    local new_weather = weather[inum].name
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
    mstore:set_string(name, "")
end

local function set_temp(instance_number, newtemp)
    local wtr = weather[instance_number]
    local zid = wtr.zone_id

    local def = zone.get_data(zid)
    local dat = def["ztrd_cli-tmp"]
    dat.value = newtemp
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
        wtr.name = w_steps[wtr.current_step].name
        show_weather(instance_number)
        save_shelter_state(instance_number)
        return
    end
    --local old = dat.value
    dat.value = dat.value + rate
    --print("Temperature step from ",old," to ",dat.value)
    wtr.temp_timer = wtr.temp_timer - 1
    zone.set_data(zid, def)
    core.after(1, shift_temp, instance_number, rate) -- 1 step per second
    save_shelter_state(instance_number)
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
    core.after(0.5, shift_temp, inum, shift_rate)
    save_shelter_state(inum)
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

local tracking_started = false
local function tracking()
    local next = next
    if next(track) == nil then return end
    for name, _ in pairs(track) do
        local player = core.get_player_by_name(name)
        if not core.is_player(player) then -- Disconnected
            remove_instance_weather(name)
        else
            local daylight = EXILE.get_daylight(player:get_pos(), 0.5)
            if daylight and daylight < 12 then
                OpenTheGate(player)
            end
        end
    end
    minetest.after(1.5, tracking)
end
local function begin_tracking()
    if not tracking_started then
        tracking_started = true
        tracking()
    end
end

local FireLit = {}

local function OpenFireGate(pos, player, name)
    local gate = core.find_node_near(pos, 6, "tutorial_exile:iron_wall")
    if gate then
        core.sound_play("tech_iron_chest_close",
                        { pos = gate, gain = 1, max_hear_distance = 10 })
        core.remove_node(gate)
        if player then
            queue_next_weather(player)
            core.after(5, begin_tracking)
        end
        FireLit[name] = nil
        save_shelter_state(track[name])
    end
end

local function TutorialShelterFire(pos)
    local objs = core.get_objects_inside_radius(pos, 6)
    local player
    for _, o in pairs(objs) do
        if core.is_player(o) then player = o ; break ; end
    end
    EXILE.switch_node(pos, "tech:small_wood_fire")
    local meta = core.get_meta(pos)
    meta:set_string("hot_air", "Y")
    minetest.check_for_falling(pos)

    local name = player:get_player_name()
    core.after(12, OpenFireGate, pos, player, name)

    FireLit[name] = core.pos_to_string(pos)
    save_shelter_state(track[name])
end
core.override_item("tutorial_exile:demo_fire", {
        on_ignite = TutorialShelterFire
})

--------------------------------------------------------------------------
-- Save and restore state

-- local variable set above, so above functions can access this, but
--   we can sensibly keep this code next to the loading function
function save_shelter_state(instance_number)
    local name, _ = get_player_from_instance(instance_number)

    if not track[name] then return end
    local wth = weather[instance_number]
    local saveout = {
        wname = wth.name,
        wtimer = wth.temp_timer,
        step = wth.current_step,
        litfirepos = FireLit[name]
    }
    mstore:set_string( name.."_shelter", core.serialize(saveout) )
end
local function restore_shelter_state(stage, player, name, instance)
    if stage.name ~= "Shelter" then return end
    track[name] = instance.number
    create_instance_weather(instance, stage)
    local data = core.deserialize(mstore:get_string(name.."_shelter"))
    if data then
        local wth = weather[instance.number]
        wth.name = data.wname
        wth.temp_timer = data.wtimer
        set_temp(instance.number, w_steps[data.step].temp)
        wth.current_step = data.step or 1
        if data.step > 1 then -- Tracking was already started)
            core.after(5, begin_tracking)
        end
        if data.litfirepos then -- Fire was lit, gate was not open yet
            local firepos = core.string_to_pos(data.litfirepos)
            core.after(6, OpenFireGate, firepos, player, name) -- time is halved
        end
        show_weather(instance.number)
        if data.wtimer > 0 then
            if data.step == 1 then -- Opened fire gate, would start tracking here
                core.after(5, begin_tracking)
            end
            queue_next_weather(player)
            return
        end
    end
    show_weather(instance.number)
end
table.insert(stage.handlers, restore_shelter_state)

--------------------------------------------------------------------------
-- Enter and exit functions

local function enter(stage, player, name, instance)
    HEALTH.hide_hud_elements(player, nil, "all")
    HEALTH.show_hud_elements(player, nil, "enviro_temp")
    HEALTH.show_hud_elements(player, nil, "energy")
    local inv = player:get_inventory()
    inv:add_item("main", "inferno:fire_sticks")

    track[name] = instance.number

    create_instance_weather(instance, stage)
    show_weather(instance.number)
end
local function exit(_stage, player, name, _instance)
    HEALTH.show_hud_elements(player, nil, "all")
    climate.set_weather_override(player:get_player_name(), nil, "")
    remove_instance_weather(name)
    mstore:set_string( name.."_shelter", "" )
end

return enter, exit
