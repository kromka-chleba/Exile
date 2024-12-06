-- shelter stage code

-- This stage handles differently from the others, without using triggers
--  other than enter/exit, and it calls the mapchunk shepherd to show off
--  the seasons.

zone = zone

local track = {} -- players in the stage
-- { name = { player_object, instance } }

--------------------------------------------------------------------------
-- Data

-- 3 steps:
--  rainy spring until the cave 10c
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
-- Weather

local weather = {} -- current weather state for an instance
-- { number = { name = "clear", temp_adjust = 0, zone_id = <string> }

local function create_instance_weather(instance, stage)
    local minpos = instance.offset
    local maxpos = instance.offset + stage.size
    weather[instance.number] =
        {
            name = "", zone_id =
                zone.create(
                    "cli-tmp", {
                        pos1 = minpos,
                        pos2 = maxpos,
                        ["ztrd_cli-tmp"] = {
                            ["value"] = 20,
                            ["mode"] = "absolute"
                        }
                })
        }
    print("Set up weather override at ",core.pos_to_string(minpos))
end

local function show_weather(inum, player, unshow)
    if not core.is_player(player) then return end -- disconnected?
    local new_weather = weather[inum].name
    if unshow then new_weather = "" end -- Player's leaving, stop overriding
    climate.set_weather_override(player, new_weather)
end

local shift_temp() end

local function set_weather(name, wname, temp)
    local inum = track[name].instance
    local player = track[name].player
    local zid = weather[inum].zone_id
    if wname then
        weather[inum].name = wname
        show_weather(inum, player)
    end
    if temp then
        local set = zone.get_data(zid)
        set.value = temp
        zone.set_data(zid, set)
    end
end

-- Find the player's instance, shut off weather in it
local function remove_weather(name)
    local inum = track[name].instance
    local player = track[name].player
    local zid = weather[inum].zone_id
    show_weather(inum, player, "unshow")
    zone.destroy(zid)
    weather[inum].zone_id = nil
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
    end
end

local function tracking()
    local next = next
    if next(track) == nil then return end
    for name, tab in pairs(track) do
        if not core.is_player(tab.player) then -- Disconnected
            remove_weather(name)
            track[name] = nil
            break
        end
        if minimal.get_daylight(tab.player:get_pos(), 0.5) < 11 then
            OpenTheGate(tab.player)
        end
    end
    minetest.after(1.5, tracking)
end

local function enter(stage, player, name, instance)
    track[name] = { player = player,
                    instance = instance.number,
    }

    create_instance_weather(instance, stage)
    core.after(15, tracking())
end
local function exit(stage, player, name, instance)
    remove_weather(name)
    track[name] = nil
end

return enter, exit
