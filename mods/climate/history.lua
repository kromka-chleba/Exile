---------------------------------------------------------
--HISTORY
--A record of recent climatic conditions

--History is kept in a hexadecimal string for relatively compact storage
--We have to record four things: sunlight, rainfall, growing temperatures
-- and crop killing temperatures

--We only store data once every 600 ticks (60 seconds), it changes every
--60-120 seconds anyway. In-game days take 20 minutes so that's
-- 20 chunks of data per day, 140 per week 1600 bytes for a season
-- 6400 (6kb) for a year -- Maybe set that as max? Do we need two+ years?

--Also assumes sunlight between 0.3 and 0.7 timeofday; plants should check
-- whether they can have sun before calling crop_rewind
--  ^ minetest.get_natural_light(pos, [timeofday=]0.5)

local S = minetest.get_translator("climate")

local floor = math.floor
climate_history = ""
climate = climate

function climate.load_history(chist)
    --get history from storage
    climate_history = chist or ""
end

function climate.get_history()
    return climate_history
end

--record a chunk of climate history
function climate.record_history(climate)
    local ch = 0
    local dtime = minetest.get_timeofday()
    if dtime >= 0.25 and dtime <= 0.75 then
        ch = ch + 1 -- sunlight: 0001
    end
    local w = climate.active_weather.name
    if (w == 'overcast_heavy_rain'
        or w == 'overcast_rain'
        or w == 'thunderstorm'
        or w == 'superstorm') then
        ch = ch + 4 -- rain: 0100
    end
    local t = climate.active_temp
    if t < -30 or t > 60 then
        ch = ch + 8 -- kill: 1000
    elseif t >= 0 and t <= 40 then
        ch = ch + 2 -- grow: 0010
    end
    local cstring=string.format("%x", ch)
    climate_history = cstring..climate_history
end


--read out a specified chunk from the history
local function history(age)
    local chunk = {sun=false,grow=false,rain=false,kill=false}
    local len = #climate_history
    if len == 0 then
        return -- No history? Why did we get called then?
    end
    --age%len: if we run out of history, loop back and fake it from what we have
    age = age%(len)
    local x = tonumber("0x"..string.sub(climate_history, age+1, age+1))
    -- age+1, strings don't start counting at 0 in lua
    --  because someone hates programmers

    chunk.kill = bit.band(x,8) == 8
    chunk.rain = bit.band(x,4) == 4
    chunk.grow = bit.band(x,2) == 2
    chunk.sun = bit.band(x,1) == 1
    return chunk
end


------------------------------
-- returns time in seconds when conditions were good for growing
-- and time when it rained
function climate.good_time_rain_time(duration, mushroom)
    local good_chunks = 0
    local rain_chunks = 0
    local chunks = floor(duration / 60)
    for i = 0,chunks,1 do
        local conditions = history(i)
        if conditions == nil then -- we don't have any history!
            return good_chunks, rain_chunks
        end
        if (conditions.sun == true or mushroom == true)
            and conditions.grow == true then
            good_chunks = good_chunks + 1
            if conditions.rain == true then
                rain_chunks = rain_chunks + 1
            end
        end
    end
    return good_chunks * 60, rain_chunks * 60
end

-- counts number of chunks having a given property
local function number_of_chunks(property, duration)
    local chunks = floor(duration / 60)
    local total = 0
    for i = 0,chunks,1 do
        local conditions = history(i)
        if conditions[property] == true then
            total = total + 1
        end
    end
    return total
end

------------------------------
-- checks the climate record, and returns how long it rained
function climate.rain_amount(duration)
    return number_of_chunks("rain", duration)
end

-- gets time in seconds it rained
function climate.rain_time(duration)
    return number_of_chunks("rain", duration) * 60
end

-- gets time in seconds it was sunny
function climate.sun_time(duration)
    return number_of_chunks("sun", duration) * 60
end

-- gets time weather was good for growing
function climate.grow_time(duration)
    return number_of_chunks("grow", duration) * 60
end

-- returns true if plant was killed
-- duplicating the code for performance
function climate.plant_killed(duration)
    local chunks = floor(duration / 60)
    for i = 0,chunks,1 do
        local conditions = history(i)
        if conditions and conditions.kill == true then
            return true
        end
    end
    return false
end

local last_rained -- caches the gametime value of the last rain

function climate.time_since_rain(max_seek)
    if last_rained then
        local timesincelast = minetest.get_gametime() - last_rained
        if timesincelast < max_seek then
            return timesincelast
        end
    end

    local max_chunks = 0
    if max_seek then
        max_chunks = floor(max_seek / 60)
    end
    for i = 1,max_chunks,1 do
        local conditions = history(i)
        if conditions.rain == true
        then
            last_rained = minetest.get_gametime() - i*60
            return i*60
        end
    end
    return 0
end

function climate.datestring()
    local days = minetest.get_day_count()
    local time = minetest.get_timeofday()
    local year = floor((days)/80)+1
    local cdays = (days)%80 -- days into the current year
    local seasonnumber = floor((cdays)/20)+1
    local sdays = cdays%20+1 --days into the current season
    local season = S("Birth")
    if seasonnumber == 2 then
        season = S("Thirst")
    elseif seasonnumber == 3 then
        season = S("Retreat")
    elseif seasonnumber == 4 then
        season = S("Hunger")
    end
    local timestr = S("small hours")
    if time >= 0.75 then
        timestr = S("evening")
    elseif time >= 0.5 then
        timestr = S("afternoon")
    elseif time >= 0.25 then
        timestr = S("morning")
    end
    return S("It is the @1 of day @2 of the season of @3, "..
             "in the year of our exile @4", timestr, sdays, season, year)
end

local datecmd = {
    params = "",
    description = "Shows the current date and year of exile.",
    privs = {},
    func = function(name, param)
        minetest.chat_send_player(name, climate.datestring())
    end,
}
minetest.register_chatcommand("date", datecmd)
