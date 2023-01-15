---------------------------------------------------------
--Plant growth for Plant API

-- Internationalization
local S = nodes_nature.S

---------------------------------------------------------

plant = plant or {}
soil_preferences = {}

local base_health = 100

function soil_preferences.new(args)
    local prefs = {
        rocky_substrate = args.rocky_substrate,
        organic_substrate = args.organic_substrate,
        density = args.density,
    }
    return prefs
end

function soil_preferences.is_sediment_good(sed_name, plant_prefs)
    local rocky_substrate = minetest.get_item_group(sed_name, "rocky_substrate")
    local organic_substrate = minetest.get_item_group(sed_name, "organic_substrate")
    local density = minetest.get_item_group(sed_name, "density")
    if not plant_prefs then return true end
    if rocky_substrate then
        if not (rocky_substrate >= plant_prefs.rocky_substrate.min
                and rocky_substrate <= plant_prefs.rocky_substrate.max) then
            return false
        end
    end
    if organic_substrate then
        if not (organic_substrate >= plant_prefs.organic_substrate.min
                and organic_substrate <= plant_prefs.organic_substrate.max) then
            return false
        end
    end
    if density then
        if not (density >= plant_prefs.density.min
                and density <= plant_prefs.density.max) then
            return false
        end
    end
    return true
end

------------------------------
-- Seeds/seedling soil timers
-- if the soil quality changes under the seed it will slow/speed the timer
-- this procedure returns a timer
local function seed_soil_response(pos, soil_prefs)
    local pos_under = minimal.get_pos_under(pos)
    local node_under = minetest.get_node(pos_under).name
    local sediment = minetest.get_item_group(node_under, "sediment")
    if sediment == 0 then
        return 0
    end
    local wetness = minetest.get_item_group(node_under, "wet_sediment")
    local progress = 1
    if wetness == 1 then
        progress = progress + 2
    elseif wetness == 2 then -- salty
        return 0
    end
    local is_soil_good = soil_preferences.is_sediment_good(node_under, soil_prefs)
    local ag_soil = minetest.get_item_group(node_under, "agricultural_soil")
    local fertile_soil = minetest.get_item_group(node_under, "fertile_soil")
    if is_soil_good then
        progress = progress + 2
    end
    -- normal and fertile agri soils can partially cancell effects of bad soil
    if fertile_soil == 1 or ag_soil == 1 then
        progress = progress + 1
    elseif not is_soil_good then
        return 0
    end
    local fertility = minetest.get_item_group(node_under, "fertility")
    if fertility > 0 then
        progress = progress + fertility
    end
    return progress
end

local function is_on_sediment(pos)
    local pos_under = minimal.get_pos_under(pos)
    return minimal.get_group(pos_under, "sediment") > 0
end

local function is_mushroom(pos)
    return minimal.get_group(pos, "mushroom") > 0
end

local function get_light(pos)
    local pos_above = minimal.get_pos_above(pos)
    local natural = minimal.get_daylight(pos_above) or 0
    local artificial = minetest.get_node_light(pos_above) or 0
    if artificial > natural then
        return artificial
    end
    return natural
end

local function is_dark(pos)
    local light = get_light(pos)
    return light < 8
end

local function is_dark_when_day(pos)
    local pos_above = minimal.get_pos_above(pos)
    local light = minimal.get_daylight(pos_above, 0.5) or 0
    return light < 8
end

local function is_temperature_extreme(pos)
    local temp = climate.get_point_temp(pos)
    return temp < -30 or temp > 60
end

local function is_temperature_good(pos)
    local temp = climate.get_point_temp(pos)
    return temp > 5 and temp < 40
end

local function is_soil_and_temp_good(pos)
    --if not on sediment abort
    if not is_on_sediment(pos) then
        return false
    end
    --semi-extreme temps stop growth
    if not is_temperature_good(pos) then
        return false
    end
    return true
end

local function are_conditions_good(pos)
    if not is_soil_and_temp_good(pos) then
        return false
    end
    --cannot grow indoors (unless a mushroom)
    if not is_mushroom(pos) and is_dark(pos) then
        return false
    end
    return true
end

local function get_root_number(pos)
    local pos_under = minimal.get_pos_under(pos)
    local nodedef_under = minimal.get_nodedef(pos_under)
    local meta = minetest.get_meta(pos_under)
    local nr = meta:get_float("root_nr")
    return nr
end

local function set_roots(pos, nr, root_name)
    local pos_under = minimal.get_pos_under(pos)
    local nodedef_under = minimal.get_nodedef(pos_under)
    if not nodedef_under.groups.sediment or
        nodedef_under.groups.wet_sediment == 2 or
        nodedef_under.natural_slope then
        return
    elseif not nodedef_under.groups.roots then
        minetest.set_node(pos_under, {name = nodedef_under.name.."_roots"})
    end
    local meta = minetest.get_meta(pos_under)
    meta:set_string("root_name", root_name)
    meta:set_float("root_nr", nr)
end

local function add_roots(pos, nr, root_name)
    local old_nr = get_root_number(pos)
    set_roots(pos, old_nr + nr, root_name)
end

local function grow_roots(pos, progress)
    local plant_nodedef = minimal.get_nodedef(pos)
    local max_root_nr = plant_nodedef.groups.plant_with_roots
    if not max_root_nr then return end
    local current_nr = get_root_number(pos)
    --local nr = progress * math.random(0.005, 0.02)
    local nr = 0.01 * math.random(1, 10) * progress
    if nr + current_nr > max_root_nr then
        set_roots(pos, max_root_nr, plant_nodedef._root_name)
    else
        add_roots(pos, nr, plant_nodedef._root_name)
    end
end

local function deplete_soil(pos)
    local node_name = minetest.get_node(pos).name
    local nodedef = minetest.registered_nodes[node_name]
    if nodedef._depleted_name then
        minetest.swap_node(pos, {name = nodedef._depleted_name})
    end
end

local function kill_plant(pos, natural_death)
    local node = minetest.get_node(pos)
    local nodedef = minetest.registered_nodes[node.name]
    local fruiting_plant =
        minetest.get_item_group(node.name, "fruiting_plant") > 0
    local flowering_plant =
        minetest.get_item_group(node.name, "flowering_plant") > 0
    local seedling =
        minetest.get_item_group(node.name, "seedling") > 0
    local dead_names = {natural = "", induced = ""}
    if seedling then
        dead_names.natural = nodedef._seed_name
        dead_names.induced = "air"
    elseif flowering_plant and nodedef._dead_fruitless_name then
        dead_names.natural = nodedef._dead_fruitless_name
        dead_names.induced = nodedef._dead_fruitless_name
    else
        dead_names.natural = nodedef._dead_name
        dead_names.induced = nodedef._dead_name
        if fruiting_plant and nodedef._dead_fruitless_name then
            dead_names.induced = nodedef._dead_fruitless_name
        end
    end
    local dead_name = ""
    if natural_death then
        dead_name = dead_names.natural
    else
        dead_name = dead_names.induced
    end
    minetest.set_node(pos, {name = dead_name,
                            param2 = nodedef.place_param2})
    minimal.node_set_int(pos, "busted", 1)
end

local function was_light_here(pos, elapsed)
    -- 30 cycles without light kill a plant
    if is_dark(pos) and
        is_dark_when_day(pos) and
        not is_mushroom(pos) and
        elapsed > base_health * plant_base_timer then
        return false
    end
    return true
end

local function kill_no_light(pos, elapsed)
    local meta = minetest.get_meta(pos)
    if not was_light_here(pos, elapsed) then
        kill_plant(pos, false)
        return true
    end
end

local function kill_extreme_temp(pos, elapsed)
    if is_temperature_extreme(pos) then
        kill_plant(pos, false)
        return true
    end
end

local function kill_climate_history(pos, elapsed)
    if climate.plant_killed(elapsed) then
        kill_plant(pos, false)
        return true
    end
end

local function kill_in_winter(pos, elapsed)
    if not are_conditions_good(pos) then
        local season = seasons.get_season_name()
        if season == "winter_early" or
            season == "winter_late" then
            kill_plant(pos, true)
            return true
        end
        return true
    end
end

local function catch_up_life_stage(pos, growing_time, growing_left, elapsed)
    while growing_left < 0 do
        local nodedef = minimal.get_nodedef(pos)
        if nodedef._next_life_stage then
            local p2 = nodedef.place_param2
            minimal.force_place(pos, {name = nodedef._next_life_stage,
                                      param2 = p2})
        end
        growing_left = growing_left + growing_time
    end
    minimal.node_set_int(pos, "growth", growing_left)
    -- after we're done with growth we can check for season
    kill_climate_history(pos, elapsed)
end

local function growing_side_effects(pos, progress)
    local pos_under = minimal.get_pos_under(pos)
    --chance to deplete soil
    if math.random() <= 0.0001 then
        deplete_soil(pos_under)
    end
    grow_roots(pos, progress)
end

local function calculate_growth_progress(pos, good_cycles, rain_cycles)
    local good_cycles = good_cycles or 1
    local rain_cycles = rain_cycles or 0
    if rain_cycles == 0 and climate.get_rain(pos) then
        rain_cycles = 1
    end
    local soil = seed_soil_response(pos, soil_prefs)
    local progress = good_cycles * soil + rain_cycles * 4
    return progress
end

local function time_to_cycles(time)
    return time / plant_base_timer
end

local function progress_surface(pos, elapsed)
    -- number of cycles
    local good_time, rain_time = good_time_rain_time(elapsed, is_mushroom(pos))
    local good_cycles = time_to_cycles(good_time)
    local rain_cycles = time_to_cycles(rain_time)
    -- climate history is stored in 60s chunks
    -- prevent calculating progress for just one chunk when elapsed is lower than that
    if good_time == 60 then
        good_cycles = time_to_cycles(elapsed)
        if rain_time == 60 then
            rain_cycles = time_to_cycles(elapsed)
        end
    end
    local progress = calculate_growth_progress(pos, good_cycles, rain_cycles)
    return progress
end

local function progress_underground(pos, elapsed)
    local good_cycles = time_to_cycles(elapsed)
    local base_progress = calculate_growth_progress(pos, good_cycles)
    if is_mushroom(pos) then
        return base_progress
    end
    local dark_day = is_dark_when_day(pos)
    local dark_now = is_dark(pos)
    if (dark_day and not dark_now) or
        (not dark_day and not dark_now) then
        return base_progress
    elseif not dark_day and dark_now then
        return base_progress / 2
    end
    return 0
end

local function past_growth_progress(pos, elapsed)
    if elapsed > plant_base_timer then
        if pos.y < -15 then
            return progress_underground(pos, elapsed)
        else
            return progress_surface(pos, elapsed)
        end
    else
        return 0
    end
end

local function current_growth_progress(pos, elapsed)
    return calculate_growth_progress(pos)
end

local function seed_elapsed(meta)
    local seed_elapsed = meta:get_int("elapsed")
    if seed_elapsed > plant_base_timer then
        meta:set_int("elapsed", 0)
        return seed_elapsed
    end
    return 0
end

------------------ Global functions of the API ------------------

function plant.start_growing_seed(pos)
    local timer_min = seed_growing_time - 0.25 * seed_growing_time
    local timer_max = seed_growing_time + 0.25 * seed_growing_time
    local timer = minetest.get_node_timer(pos)
    if not timer:is_started() then
        timer:start(math.random(timer_min, timer_max))
    end
end

function plant.grow_seed(pos, elapsed)
    local nodedef = minimal.get_nodedef(pos)
    local good_time = good_time_rain_time(elapsed, is_mushroom(pos))
    -- if conditions were good for germination we don't care about the present
    if elapsed > seed_growing_time and good_time >= 60 then
        -- pass elapsed to seedlings so we can catch up from there
        minimal.force_place(pos, {name = nodedef._next_life_stage})
        minimal.node_set_int(pos, "elapsed", elapsed)
        return false
    elseif not is_soil_and_temp_good(pos) then
        return true -- unless dead, try again when conditions are good
    end
    minimal.force_place(pos, {name = nodedef._next_life_stage})
    return false -- the seed becomes a seedling (stops the timer)
end

function plant.start_growing_plant(pos, growing_time)
    local timer_min = plant_base_timer - 0.1 * plant_base_timer
    local timer_max = plant_base_timer + 0.1 * plant_base_timer
    minimal.node_set_int(pos, "growth", growing_time)
    minimal.node_set_int(pos, "health", base_health)
    minimal.node_set_int(pos, "growing_time", growing_time)
    local timer = minetest.get_node_timer(pos)
    if not timer:is_started() then
        timer:start(math.random(timer_min, timer_max))
    end
end

function plant.grow_plant(pos, elapsed, growing_time, soil_prefs)
    local meta = minetest.get_meta(pos)
    local elapsed = elapsed + seed_elapsed(meta)
    local current_progress = current_growth_progress(pos, elapsed)
    local past_progress = past_growth_progress(pos, elapsed)
    local health = meta:get_int("health")
    if kill_no_light(pos, elapsed) then
        -- we had no light so exit before catch up
        return false
    end
    if health <= 0 then
        kill_plant(pos, true)
    end
    if not are_conditions_good(pos) then
        current_progress = 0
        meta:set_int("health", health - 1)
    elseif health < base_health then
        meta:set_int("health", health + 1)
    end
    local progress = past_progress + current_progress
    local growing_left = meta:get_int("growth") - progress
    meta:set_int("growth", growing_left)
    if growing_left < 0 then
        catch_up_life_stage(pos, growing_time, growing_left, elapsed)
    end
    if kill_extreme_temp(pos, elapsed) then
        return false
    end
    growing_side_effects(pos, progress)
    return true
end
