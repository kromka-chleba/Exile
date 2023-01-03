---------------------------------------------------------
-- Seasonal changes for Exile
-- 

-- Internationalization
local S = nodes_nature.S

---------------------------------------

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

local season_names = {
    "spring_early",
    "spring_late",
    "summer_early",
    "summer_late",
    "fall_early",
    "fall_late",
    "winter_early",
    "winter_late",
}

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

local function update_plant(pos, node, season_name)
    local nodedef = minetest.registered_nodes[node.name]
    local new_name = nodedef["_"..season_name]
    local next_nodedef = minetest.registered_nodes[new_name]
    if new_name and new_name ~= node.name then
        local timer = minetest.get_node_timer(pos)
        if timer:is_started() then
            return
        end
        minetest.set_node(pos, {name = new_name,
                                param2 = next_nodedef.place_param2})
    end
end

local function change_seasonal_lbm(season_name)
    local lbm_name = "nodes_nature:season_changer"
    override_lbm({
            label = "Season changer",
            name = lbm_name,
            nodenames = {"group:seasonal"},
            run_at_every_load = true,
            action = function(pos, node, dtime_s)
                update_plant(pos, node, season_name)
            end,
    })
end

local function activate_seasonal_abm(season_name)
    local abm_name = "nodes_nature:"..season_name
    override_abm({
            label = "Season changer: "..season_name,
            name = abm_name,
            interval = 2,
            chance = 1,
            catch_up = false,
            min_y = -30,
            max_y = 500,
            nodenames = {"group:seasonal"},
            action = function(pos, node, dtime_s)
                update_plant(pos, node, season_name)
            end,
    })
end

local function change_seasonal_abm(season_name)
    for i = 1, #season_names do
        if season_name ~= season_names[i] then
            local abm_name = "nodes_nature:"..season_names[i]
            override_abm({
                    label = "Season changer: "..season_names[i],
                    name = abm_name,
                    nodenames = {"group:seasonal"},
                    interval = 10,
                    chance = 1,
                    catch_up = false,
                    min_y = -30,
                    max_y = 500,
                    action = function(pos, node, dtime_s)
                        -- nothing here
                    end,
            })
        end
    end
    activate_seasonal_abm(season_name)
end

local function inactivate_abm(abm_spec)
    local abm_spec = table.copy(abm_spec)
    abm_spec.action = function(pos, node, dtime_s)
        -- nothing here
    end
    override_abm(abm_spec)
end

local function inactivate_lbm(lbm_spec)
    local lbm_spec = table.copy(lbm_spec)
    lbm_spec.action = function(pos, node, dtime_s)
        -- nothing here
    end
    override_lbm(lbm_spec)
end

local function soil_to_winter(pos, node)
    local nodedef = minetest.registered_nodes[node.name]
    local new_name = nodedef._winter_name
    minetest.set_node(pos, {name = new_name})
end

local function soil_to_non_winter(pos, node)
    local nodedef = minetest.registered_nodes[node.name]
    local new_name = nodedef._non_winter_name
    minetest.set_node(pos, {name = new_name})
end

local winter_soil_lbm = {
    label = "Changes soils to winter soils.",
    name = "nodes_nature:winter_soil_lbm",
    nodenames = {"group:spreading"},
    run_at_every_load = true,
    action = function(pos, node, dtime_s)
        local season_name = seasons.get_season_name()
        minetest.log("error", "winter soil lbm!")
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
    run_at_every_load = false,
    action = function(pos, node, dtime_s)
        local season_name = seasons.get_season_name()
        if not (season_name == "winter_early" or
                season_name == "winter_late") then
            minetest.log("error", "non-winter soil lbm!")
            soil_to_non_winter(pos, node)
        end
    end,
}

local winter_soil_abm = {
    label = "Changes soils to winter forms.",
    name = "nodes_nature:winter_soil_abm",
    interval = 15,
    chance = 1,
    catch_up = false,
    min_y = -30,
    max_y = 500,
    nodenames = {"group:spreading"},
    action = function(pos, node, dtime_s)
        minetest.log("error", "winter abm!")
        soil_to_winter(pos, node)
    end,
}

local non_winter_soil_abm = {
    label = "Changes soils to non-winter forms.",
    name = "nodes_nature:non_winter_soil_abm",
    interval = 15,
    chance = 1,
    catch_up = false,
    min_y = -30,
    max_y = 500,
    nodenames = {"group:winter_soil"},
    action = function(pos, node, dtime_s)
        minetest.log("error", "not winter abm!")
        soil_to_non_winter(pos, node)
    end,
}

local function change_soil(season_name)
    if season_name == "winter_early" or
        season_name == "winter_late" then
        --override_abm(winter_soil_abm)
        --inactivate_abm(non_winter_soil_abm)
        minetest.log("error", "change soil")
    else
        --override_abm(non_winter_soil_abm)
        --inactivate_abm(winter_soil_abm)
    end
end

seasons = {}

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

local nr = 0

local function season_loop()
    local season_name = seasons.get_season_name()
    --local season_name = season_names[nr % 8 + 1]
    change_seasonal_lbm(season_name)
    change_seasonal_abm(season_name)
    change_soil(season_name)
    minetest.after(15, season_loop)
    minetest.log("error", season_name)
    nr = nr + 1
    --minetest.after(1200, season_loop)
end

-- register placeholder
local function register_placeholder_lbm()
    minetest.register_lbm({
            label = "Season changer",
            name = "nodes_nature:season_changer",
            nodenames = {"group:seasonal"},
            run_at_every_load = true,
            action = function(pos, node, dtime_s)
                -- nothing here
            end,
    })
    minetest.register_lbm(winter_soil_lbm)
    minetest.register_lbm(non_winter_soil_lbm)
end

-- register placeholder
local function register_placeholder_abms()
    for i = 1, #season_names do
        minetest.register_abm({
                label = "Season changer: "..season_names[i],
                name = "nodes_nature:"..season_names[i],
                interval = 5,
                chance = 1,
                catch_up = false,
                min_y = -30,
                max_y = 500,
                nodenames = {"group:seasonal"},
                action = function(pos, node, dtime_s)
                    -- nothing here
                end,
        })
    end
    local winter_soil_abm = table.copy(winter_soil_abm)
    winter_soil_abm.action = function(pos, node, dtime_s)
        -- nothing here
    end
    local non_winter_soil_abm = table.copy(winter_soil_abm)
    non_winter_soil_abm.action = function(pos, node, dtime_s)
        -- nothing here
    end
    -- minetest.register_abm(winter_soil_abm)
    -- minetest.register_abm(non_winter_soil_abm)
end

-- starts the loop after 2 seconds after everything (hopefully) finishes loading
-- starting this right away caused a crash because minetest.get_day_count()
-- returned nil

register_placeholder_lbm()
register_placeholder_abms()
minetest.after(2, season_loop)
