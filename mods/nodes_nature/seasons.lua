---------------------------------------------------------
-- Seasonal changes for Exile
-- 

-- Internationalization
local S = nodes_nature.S

---------------------------------------

nsl = naturalslopeslib

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
            return true, S("Date chagned!")
        end,
})

local function override_lbm(lbm_spec)
    for i = 1, #minetest.registered_lbms do
        if minetest.registered_lbms[i].name == lbm_spec.name then
            minetest.registered_lbms[i].name = ""
            minetest.registered_lbms[i] = lbm_spec
            break
        end
    end
    lbm_spec.mod_origin = "nodes_nature"
end

local function override_abm(abm_spec)
    for i = 1, #minetest.registered_abms do
        if minetest.registered_abms[i].name == abm_spec.name then
            minetest.registered_abms[i].name = ""
            minetest.registered_abms[i] = abm_spec
            break
        end
    end
    abm_spec.mod_origin = "nodes_nature"
end

local function update_plant(pos, node)
    local season_name = seasons.get_season_name()
    local nodedef = minetest.registered_nodes[node.name]
    local new_name = nodedef["_"..season_name]
    local next_nodedef = minetest.registered_nodes[new_name]
    if new_name and new_name ~= node.name then
        local timer = minetest.get_node_timer(pos)
        local busted = minimal.node_get_int(pos, "busted")
        if timer:is_started() or busted then
            return
        end
        minetest.set_node(pos, {name = new_name,
                                param2 = next_nodedef.place_param2})
    end
end

local function inactivate_abm(abm_spec)
    local abm_spec = table.copy(abm_spec)
    abm_spec.action = function(pos, node, dtime_s)
        -- nothing here
    end
    override_abm(abm_spec)
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

local winter_soil_lbm = {
    label = "Changes soils to winter soils.",
    name = "nodes_nature:winter_soil_lbm",
    nodenames = {"group:spreading"},
    run_at_every_load = true,
    action = function(pos, node, dtime_s)
        local season_name = seasons.get_season_name()
        if season_name == "winter_early" or
            season_name == "winter_late" then
            soil_to_winter(pos, node)
        end
    end,
}

local non_winter_soil_lbm = {
    label = "Changes winter soils to soils.",
    name = "nodes_nature:non_winter_soil_lbm",
    nodenames = {"group:winter_soil"},
    run_at_every_load = true,
    action = function(pos, node, dtime_s)
        local season_name = seasons.get_season_name()
        if not (season_name == "winter_early" or
                season_name == "winter_late") then
            soil_to_non_winter(pos, node)
        end
    end,
}

local winter_soil_abm = {
    label = "Changes soils to winter forms.",
    name = "nodes_nature:winter_soil_abm",
    interval = 50,
    chance = 1,
    catch_up = false,
    min_y = -30,
    max_y = 300,
    nodenames = {"group:spreading"},
    action = function(pos, node, dtime_s)
        soil_to_winter(pos, node)
    end,
}

local non_winter_soil_abm = {
    label = "Changes soils to non-winter forms.",
    name = "nodes_nature:non_winter_soil_abm",
    interval = 50,
    chance = 1,
    catch_up = false,
    min_y = -30,
    max_y = 300,
    nodenames = {"group:winter_soil"},
    action = function(pos, node, dtime_s)
        soil_to_non_winter(pos, node)
    end,
}

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

local last_season = ""

local function change_soil(season_name)
    if last_season ~= season_name then
        last_season = season_name
        if season_name == "winter_early" or
            season_name == "winter_late" then
            override_abm(winter_soil_abm)
            inactivate_abm(non_winter_soil_abm)
        else
            override_abm(non_winter_soil_abm)
            inactivate_abm(winter_soil_abm)
        end
    end
end

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

local function season_loop()
    local season_name = seasons.get_season_name()
    change_soil(season_name)
    minetest.after(1200, season_loop)
end

-- register placeholder
local function register_placeholder_abms()
    local winter_soil_abm = table.copy(winter_soil_abm)
    winter_soil_abm.action = function(pos, node, dtime_s)
        -- nothing here
    end
    local non_winter_soil_abm = table.copy(non_winter_soil_abm)
    non_winter_soil_abm.action = function(pos, node, dtime_s)
        -- nothing here
    end
    minetest.register_abm(winter_soil_abm)
    minetest.register_abm(non_winter_soil_abm)
end

-- starts the loop after 2 seconds after everything (hopefully) finishes loading
-- starting this right away caused a crash because minetest.get_day_count()
-- returned nil

register_placeholder_abms()
minetest.register_lbm(winter_soil_lbm)
minetest.register_lbm(non_winter_soil_lbm)
minetest.register_abm(seasonal_plant_abm)
minetest.after(2, season_loop)
