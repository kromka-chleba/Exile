---------------------------------------------------------
-- Seasonal changes for Exile
-- 

-- Internationalization
local S = nodes_nature.S

---------------------------------------

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

local function override_lbm(name, lbm_spec)
    for i = 1, #minetest.registered_lbms do
        if minetest.registered_lbms[i].name == name then
            minetest.registered_lbms[i].name = ""
            minetest.registered_lbms[i] = lbm_spec
            break
        end
    end
    lbm_spec.mod_origin = "nodes_nature"
end

local function change_seasonal_lbm(season_name)
    local lbm_name = "nodes_nature:season_changer"
    override_lbm(
        lbm_name, {
            label = "Season changer",
            name = lbm_name,
            nodenames = {"group:seasonal"},
            run_at_every_load = true,
            action = function(pos, node, dtime_s)
                local nodedef = minetest.registered_nodes[node.name]
                if nodedef["_"..season_name] then
                    minetest.log("error", node.name)
                    minetest.set_node(pos, {name = nodedef["_"..season_name],
                                            param2 = nodedef.place_param2})
                end
            end,
    })
end

local function get_season_and_day()
    -- days into the current year
    local days = minetest.get_day_count() % 80
    local season_days = days % 20 + 1
    -- season_nr: Birth - 1, Thirst - 2, Retreat - 3, Hunger - 4
    local season_nr = math.floor(days/20) + 1
    return season_nr, season_days
end

local function get_season_name()
    local season, day = get_season_and_day()
    local season_name = ""
    if season == 1 then
        season_name = "spring"
    elseif season == 2 then
        season_name = "summer"
    elseif season == 3 then
        season_name = "fall"
    elseif season == 3 then
        season_name = "winter"
    end

    if day > 0 and day <= 10 then
        season_name = season_name.."_early"
    else
        season_name = season_name.."_late"
    end

    return season_name
end

local nr = 1

local function season_loop()
    --local season_name = get_season_name()
    local season_name = season_names[nr % 8 + 1]
    change_seasonal_lbm(season_name)
    minetest.after(10, season_loop)
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
                minetest.log("error", node.name)
            end,
    })
end

-- starts the loop after 2 seconds after everything (hopefully) finishes loading
-- starting this right away caused a crash because minetest.get_day_count()
-- returned nil

register_placeholder_lbm()
minetest.after(2, season_loop)

