---------------------------------------------------------
--Plant growth for Plant API

-- Internationalization
local S = nodes_nature.S

---------------------------------------------------------

plant = {}
soil_preferences = {}
seasons = seasons

plant_base_growing_time = 500
plant_base_timer = 40
seed_growing_time = 40

local good_time_rain_time = climate.good_time_rain_time

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
    local rocky_substrate = minetest.get_item_group(sed_name,
                                                    "rocky_substrate")
    local organic_substrate = minetest.get_item_group(sed_name,
                                                      "organic_substrate")
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
    local is_soil_good = soil_preferences.is_sediment_good(node_under,
                                                           soil_prefs)
    local ag_soil = minetest.get_item_group(node_under, "agricultural_soil")
    local fertile_soil = minetest.get_item_group(node_under, "fertile_soil")
    if is_soil_good then
        progress = progress + 2
    end
    -- normal and fertile agri soils can partially cancell effects of bad soil
    if fertile_soil == 1 then
        -- this is a hack because fertility doesn't work right now
        progress = progress + 2
    end
    if ag_soil == 1 then
        progress = progress + 2
    end
    if not is_soil_good then
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
    return minimal.in_group(pos_under, "sediment")
end

local function is_mushroom(pos)
    return minimal.in_group(pos, "mushroom")
end

function plant.get_light(pos)
    local pos_above = minimal.get_pos_above(pos)
    local natural = minimal.get_daylight(pos_above) or 0
    local artificial = minetest.get_node_light(pos_above) or 0
    if artificial > natural then
        return artificial
    end
    return natural
end

local function is_dark(pos)
    local light = plant.get_light(pos)
    return light < 4
end

local function calculate_average_light(pos)
    local pos_above = minimal.get_pos_above(pos)
    local sum = 0
    for i = 0, 20 do
        local light = minimal.get_daylight(pos_above, i / 20)
        -- Light can be also nil for some weird reason...
        if not light then light = 0 end
        sum = sum + light
    end
    return sum / 20
end

local function get_light_cofactor(pos)
    local average_daily_light = calculate_average_light(pos) / 9.25
    local current_light = plant.get_light(pos) / 15
    if average_daily_light < 1 then
        return current_light
    else
        return average_daily_light
    end
end

local function is_dark_when_day(pos)
    local pos_above = minimal.get_pos_above(pos)
    local light = minimal.get_daylight(pos_above, 0.5) or 0
    return light < 4
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
        nodedef_under.groups.wet_sediment == 2 then
        return
    elseif not nodedef_under.groups.roots then
        if nodedef_under.groups.natural_slope then
            minetest.set_node(pos_under, {name = nodedef_under.drop.."_roots"})
        else
            minetest.set_node(pos_under, {name = nodedef_under.name.."_roots"})
        end
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
    local nr = 0.001 * math.random(1, 10) * progress
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

function plant.kill(pos, natural_death)
    local node = minetest.get_node(pos)
    local nodedef = minetest.registered_nodes[node.name]
    if minetest.get_item_group(node.name, "flora") == 0 then
        return
    end
    local fruiting_plant =
        minetest.get_item_group(node.name, "fruiting_plant") > 0
    local flowering_plant =
        minetest.get_item_group(node.name, "flowering_plant") > 0
    local seedling =
        minetest.get_item_group(node.name, "seedling") > 0
    local dead_names = {natural = "", induced = ""}
    if seedling then
        dead_names.natural = nodedef._seed_name
        -- to be replaced with a generic dead seedling
        dead_names.induced = node.name
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
        dead_name = dead_names.natural or "air"
    else
        dead_name = dead_names.induced or "air"
    end
    minimal.force_place_keep_param2(pos, dead_name)
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
    if not was_light_here(pos, elapsed) then
        plant.kill(pos, false)
        return true
    end
end

local function kill_extreme_temp(pos, elapsed)
    if is_temperature_extreme(pos) then
        plant.kill(pos, false)
        return true
    end
end

local function kill_climate_history(pos, elapsed)
    if climate.plant_killed(elapsed) then
        plant.kill(pos, false)
        return true
    end
end

local is_winter = seasons.is_winter

local function kill_in_winter(pos, elapsed)
    if not are_conditions_good(pos) and is_winter() then
        plant.kill(pos, true)
        return true
    end
end

local function step_through_life_stage(pos, growing_time, growing_left, elapsed)
    while growing_left < 0 do
        local nodedef = minimal.get_nodedef(pos)
        if nodedef._next_life_stage then
            local meta = minetest.get_meta(pos)
            local health
            if not meta:get("health") then
                health = base_health + base_health * math.random(-1, 1) * 0.1
            else
                health = meta:get_int("health")
            end
            minimal.force_place_keep_param2(pos, nodedef._next_life_stage)
            meta:set_int("health", health)
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

local function calculate_growth_progress(pos, good_cycles_in, rain_cycles_in)
    local good_cycles = good_cycles_in or 1
    local rain_cycles = rain_cycles_in or 0
    if rain_cycles == 0 and climate.get_rain(pos) then
        rain_cycles = 1
    end
    local soil = seed_soil_response(pos, soil_prefs)
    local progress = soil * (good_cycles + rain_cycles * 4)
    return progress
end

local function time_to_cycles(time)
    return time / plant_base_timer
end

local function progress_surface(pos, elapsed)
    local mushroom = is_mushroom(pos)
    -- climate history is stored in 60s chunks, called "cycles" here for reasons
    -- number of cycles
    local good_time, rain_time = good_time_rain_time(elapsed, mushroom)
    local good_cycles = time_to_cycles(good_time)
    local rain_cycles = time_to_cycles(rain_time)


    local light_cofactor = get_light_cofactor(pos)
    if mushroom then
        light_cofactor = 1
    end
    local progress = calculate_growth_progress(pos, good_cycles, rain_cycles)
    return progress * light_cofactor
end

local function progress_underground(pos, elapsed)
    local good_cycles = time_to_cycles(elapsed)
    local progress = calculate_growth_progress(pos, good_cycles)
    if is_mushroom(pos) then
        return progress
    end
    local light_cofactor = get_light_cofactor(pos)
    return progress * light_cofactor
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
    if is_mushroom(pos) then
        return calculate_growth_progress(pos)
    else
        local light_cofactor = get_light_cofactor(pos)
        return calculate_growth_progress(pos) * light_cofactor
    end
end

local function seed_elapsed(meta)
    local elapsed = meta:get_int("elapsed")
    if elapsed > plant_base_timer then
        meta:set_int("elapsed", 0)
        return elapsed
    end
    return 0
end

local function add_to_param2(pos, nr)
    local nodedef = minimal.get_nodedef(pos)
    local name = nodedef.name
    -- is a seed, doesn't have place_param2
    if not nodedef.place_param2 and nodedef._next_life_stage then
        local seedling_name = nodedef._next_life_stage
        nodedef = minetest.registered_nodes[seedling_name]
    end
    local new_param2 = (nodedef.place_param2 or 0) + nr
    minetest.swap_node(pos, {name = name, param2 = new_param2})
end

function plant.set_to_wild(pos)
    add_to_param2(pos, 0)
end

function plant.set_to_domesticated(pos)
    add_to_param2(pos, 64)
end

function plant.set_to_half_wild(pos)
    add_to_param2(pos, 128)
end

------------------ Global functions of the API ------------------

function plant.start_growing_seed(pos)
    local timer_min = seed_growing_time - 0.25 * seed_growing_time
    local timer_max = seed_growing_time + 0.25 * seed_growing_time
    local timer = minetest.get_node_timer(pos)
    timer:start(math.random(timer_min, timer_max))
end

function plant.grow_seed(pos, elapsed)
    local nodedef = minimal.get_nodedef(pos)
    local good_time = good_time_rain_time(elapsed, is_mushroom(pos))
    -- if conditions were good for germination we don't care about the present
    if elapsed > seed_growing_time and good_time >= 60 then
        -- pass elapsed to seedlings so we can catch up from there
        minimal.force_place_keep_param2(pos, nodedef._next_life_stage)
        minimal.node_set_int(pos, "elapsed", elapsed)
        return false
    elseif not is_soil_and_temp_good(pos) then
        return true -- unless dead, try again when conditions are good
    end
    minimal.force_place_keep_param2(pos, nodedef._next_life_stage)
    return false -- the seed becomes a seedling (stops the timer)
end

function plant.death_chance_on_replant(pos)
    plant.set_to_domesticated(pos)
    -- random chance to kill the plant when replanting
    if math.random() < 1/4 then
        local timer = minetest.get_node_timer(pos)
        timer:stop()
        minetest.after(3, function () plant.kill(pos, false) end)
    end
end

function plant.start_growing_plant(pos, growing_time)
    local timer_min = plant_base_timer - 0.1 * plant_base_timer
    local timer_max = plant_base_timer + 0.1 * plant_base_timer
    minimal.node_set_int(pos, "growth", growing_time)
    local timer = minetest.get_node_timer(pos)
    timer:start(math.random(timer_min, timer_max))
end

function plant.grow_plant(pos, elapsed_full, growing_time, soil_prefs)
    local param2 = minimal.get_param2(pos)
    if param2 < 63 then return end -- No reason to run on wild plants
    local meta = minetest.get_meta(pos)
    local elapsed = elapsed_full + seed_elapsed(meta)
    local current_progress = current_growth_progress(pos, elapsed)
    local past_progress = past_growth_progress(pos, elapsed)
    local health = meta:get_int("health")
    if not meta:get("health") then
        health = base_health + base_health * math.random(-1, 1) * 0.1
        meta:set_int("health", health)
    end
    if kill_no_light(pos, elapsed) then
        -- we had no light so exit before catch up
        return false
    end
    if param2 >= 128 and is_winter() then
        plant.set_to_wild(pos)
        plant.kill(pos, true)
    end
    if health <= 0 then
        plant.kill(pos, true)
    end
    if not are_conditions_good(pos) then
        current_progress = 0
        if is_winter() then
            meta:set_int("health", health - 3)
        else
            meta:set_int("health", health - 1)
        end
    elseif health < base_health then
        meta:set_int("health", health + 1)
    end
    local progress = past_progress + current_progress
    local growing_left = meta:get_int("growth") - progress
    meta:set_int("growth", growing_left)
    if growing_left < 0 then
        step_through_life_stage(pos, growing_time, growing_left, elapsed)
    end
    if kill_extreme_temp(pos, elapsed) then
        return false
    end
    growing_side_effects(pos, progress)
    return true
end
