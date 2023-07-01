---------------------------------------------------------
-- Seasonal changes for Exile
-- 

-- Internationalization
local S = nodes_nature.S

---------------------------------------

nsl = naturalslopeslib
ms = mapchunk_shepherd

seasons = {}

seasons.season_names = {
    "spring_early",
    "spring_late",
    "summer_early",
    "summer_late",
    "fall_early",
    "fall_late",
    "winter_early",
    "winter_late",
}

local season_names = seasons.season_names

minetest.register_chatcommand(
    "set_day", {
        params = S("<day>"),
        description = S("Sets date."),
        privs = {settime = true},
        func = function(name, param)
            if param == "" or not tonumber(param) then
                return false, S("Wrong argument, needs a number!")
            end
            local old_time = minetest.get_timeofday()
            local day = math.floor(param)
            local current_day = minetest.get_day_count() % 80 + 1
            local days_to_skip
            if day > current_day then
                days_to_skip = day - current_day
            elseif day < current_day then
                days_to_skip = 80 - current_day + day
            else
                return true, S("Nothing to change, the date stays as is.")
            end
            -- life is a tragedy but sometimes also a comedy
            -- there's no /set_date command in minetest so we wrote one
            local function loop()
                if days_to_skip > 0 then
                    days_to_skip = days_to_skip - 1
                    minetest.set_timeofday(1)
                    minetest.after(0.05, loop)
                else
                    minetest.after(0.05, function () minetest.set_timeofday(old_time) end)
                    minetest.after(0.5, climate.refresh)
                end
            end
            loop()
            local new_current_day = minetest.get_day_count() % 80 + 1
            return true, S("Date changed!")
        end,
})

local function update_plant(pos, node)
    if node.param2 < 64 or node.param2 >= 128 and seasons.is_winter() then
        local season_name = seasons.get_season_name()
        local nodedef = minetest.registered_nodes[node.name]
        local new_name = nodedef["_"..season_name]
        local next_nodedef = minetest.registered_nodes[new_name]
        if new_name and new_name ~= node.name then
            minetest.remove_node(pos)
            minetest.swap_node(pos, {name = new_name,
                                    param2 = next_nodedef.place_param2})
        end
    end
end

local function soil_to_winter(pos, node)
    local nodedef = minetest.registered_nodes[node.name]
    local new_name = nodedef._winter_name
    local id = nodedef.groups.natural_slope
    if id then -- We're a slope, preserve that
        new_name = nsl.get_all_slopes(new_name)[id]
    end
    minetest.set_node(pos, {name = new_name, param2 = node.param2})
end

local function soil_to_non_winter(pos, node)
    local nodedef = minetest.registered_nodes[node.name]
    local new_name = nodedef._non_winter_name
    local id = nodedef.groups.natural_slope
    if id then -- We're a slope, preserve that
        new_name = nsl.get_all_slopes(new_name)[id]
    end
    minetest.set_node(pos, {name = new_name, param2 = node.param2})
end

local seasonal_plant_abm = {
    label = "Seasonal plant changer",
    name = "nodes_nature:seasonal_plant_abm",
    name = abm_name,
    interval = 15,
    chance = 1,
    catch_up = false,
    min_y = -30,
    max_y = 300,
    nodenames = {"group:seasonal"},
    action = function(pos, node, dtime_s)
        update_plant(pos, node)
    end,
}

local leaf_drop_abm = {
    label = "Removes leaves in winter.",
    name = "nodes_nature:remove_leaves",
    interval = 10,
    chance = 0.1,
    catch_up = false,
    min_y = -30,
    max_y = 300,
    nodenames = {"group:drops_leaves"},
    action = function(pos, node, dtime_s)
       if seasons.is_winter() then
	  minetest.remove_node(pos)
       end
    end,
}

function seasons.get_season_and_day()
    -- days into the current year
    local days = minetest.get_day_count() % 80
    local season_days = days % 20 + 1
    -- season_nr: Birth - 1, Thirst - 2, Retreat - 3, Hunger - 4
    local season_nr = math.floor(days/20) + 1
    return season_nr, season_days
end

function seasons.get_season_name()
    local season, day = seasons.get_season_and_day()
    local season_name = ""
    if season == 1 then
        season_name = "spring"
    elseif season == 2 then
        season_name = "summer"
    elseif season == 3 then
        season_name = "fall"
    elseif season == 4 then
        season_name = "winter"
    end

    if day > 0 and day <= 10 then
        season_name = season_name.."_early"
    else
        season_name = season_name.."_late"
    end

    return season_name
end

function seasons.is_winter()
    local season = seasons.get_season_name()
    if season == "winter_early" or
        season == "winter_late" then
        return true
    end
    return false
end

local function get_spreading_soil_names(include_slopes)
    local soil_names = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "spreading") > 0 then
            local slope = minetest.get_item_group(name, "natural_slope")
            if slope == 0 then
                table.insert(soil_names, name)
            end
            if include_slopes and slope > 0 then
                table.insert(soil_names, name)
            end
        end
    end
    return soil_names
end

local function spring_to_winter_pairs(include_slopes)
    local soil_pairs = {}
    local spring_soils = get_spreading_soil_names(include_slopes)
    for _, name in pairs(spring_soils) do
        local nodedef = minetest.registered_nodes[name]
        if not nodedef then
            minetest.log("error", name)
        end
        local winter_name = nodedef._winter_name
        local slope = minetest.get_item_group(name, "natural_slope")
        if slope > 0 then
            winter_name = nsl.get_all_slopes(winter_name)[slope]
        end
        soil_pairs[name] = winter_name
    end
    return soil_pairs
end

local function get_winter_soil_names(include_slopes)
    local spring_to_winter = spring_to_winter_pairs(include_slopes)
    local names = {}
    for _, winter in pairs(spring_to_winter) do
        table.insert(names, winter)
    end
    return names
end

local function winter_to_spring_pairs(include_slopes)
    local soil_pairs = {}
    local spring_to_winter = spring_to_winter_pairs(include_slopes)
    for spring, winter in pairs(spring_to_winter) do
        soil_pairs[winter] = spring
    end
    return soil_pairs
end

local spring_soils = get_spreading_soil_names()
local winter_soils = get_winter_soil_names()
local spring_to_winter = spring_to_winter_pairs(true)
local winter_to_spring = winter_to_spring_pairs(true)

ms.register_label("winter_soil", 3)
ms.register_label("spring_soil", 4)

local spring_soil_finder =
    ms.create_simple_finder(
        spring_soils,
        {"spring_soil"}
    )

local winter_soil_finder =
    ms.create_simple_finder(
        winter_soils,
        {"winter_soil"}
    )

local spring_soil_replacer =
    ms.create_simple_replacer(
        spring_to_winter,
        {"winter_soil"},
        {"spring_soil"}
    )

local winter_soil_replacer =
    ms.create_simple_replacer(
        winter_to_spring,
        {"spring_soil"},
        {"winter_soil"}
    )


local function swap_soils()
    if seasons.is_winter() then
        ms.remove_worker("winter_soil_replacer")
        ms.register_worker({name = "spring_soil_replacer",
                            fun = spring_soil_replacer,
                            needed_labels = {"spring_soil"}})
    else
        ms.remove_worker("spring_soil_replacer")
        ms.register_worker({name = "winter_soil_replacer",
                            fun = winter_soil_replacer,
                            needed_labels = {"winter_soil"}})
    end
end

local function season_loop()
    swap_soils()
    minetest.after(4, season_loop)
end

-- starts the loop after 2 seconds after everything (hopefully) finishes loading
-- starting this right away caused a crash because minetest.get_day_count()
-- returned nil

minetest.register_abm(seasonal_plant_abm)
minetest.register_abm(leaf_drop_abm)
minetest.after(2, season_loop)

ms.register_scanner({name = "spring_soil_finder",
                     fun = spring_soil_finder})
