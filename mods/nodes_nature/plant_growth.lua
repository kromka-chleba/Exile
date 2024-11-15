---------------------------------------------------------
--Plant growth for Plant API

-- Internationalization
local S = nodes_nature.S

---------------------------------------------------------

nodes_nature = nodes_nature
local nn = nodes_nature

nn.plant = {}
nn.soil_preferences = {}
local soil_preferences = nn.soil_preferences
local seasons = nn.seasons

nn.plant_base_growing_time = 500
nn.plant_base_timer = 40
nn.seed_growing_time = 40

local good_time_rain_time = climate.good_time_rain_time

local base_health = 100

-- soil_preferences
-- points for "progress", should be integers (see nn.plant.soil_response for how it's used)
-- more complex soil_pref calculations expect tables with numbers in them
-- numbered indexes for specific soil group, then a correlating progress integer
function soil_preferences.new(args)
    args = args or {}
    local prefs = {} -- we only want certain things specified, produce separate table
    -- permit custom attributes to wet, wet_salty, or dry soil
    prefs.wet = type(args.wet) == "number" and args.wet or 2 -- wet_sediment == 1
    prefs.wet_salty = type(args.wet_salty) == "number" and args.wet_salty or -1000 -- wet_sediment == 2
    prefs.dry = type(args.dry) == "number" and args.dry or 0 -- dry_sediment == 1
    prefs.fertile_soil = type(args.fertile) == "number" and args.fertile or 2 -- fertile_soil
    local agri = args.agri or args.agricultural -- agricultural_soil
    agri = type(agri) == "number" and agri or 2
    prefs.agricultural_soil = agri
    -- permit gravel-specific
    prefs.gravel = type(args.gravel) == "number" and args.gravel or 0
    -- more complex soil_pref calculations
    -- rocky substrate
    local rockstrate = args.rocky_substrate
    rockstrate = type(rockstrate) == "number" and {[4]=rockstrate} or
        type(rockstrate) == "table" and rockstrate or nil
    local len = rockstrate and #rockstrate
    -- if rockstrate specified and correctly defined (got length)
    if len then
        -- iterate down from val, then up from val to fill out table
        local val = rockstrate[len]
        -- fill out len to 1 if len is greater than 1
        if len > 1 then
            for i=len,1,-1 do
                -- set empty index or set val
                if not rockstrate[i] then
                    rockstrate[i] = val
                else
                    val = rockstrate[i]
                end
            end
        end
        -- fill out len to 4 if len less than 4
        val = rockstrate[len]
        if len < 4 then
            for i=len,4 do
                -- these won't be set already, force set 'em
                rockstrate[i] = val
            end
        end
    else
        -- base preferences (grpnum of 3 is -1, of 4 is -2)
        rockstrate = {0,0,-1,-2}
    end
    -- organic substrate
    local orgstrate = args.organic_substrate
    orgstrate = type(orgstrate) == "number" and {[4]=orgstrate} or
        type(orgstrate) == "table" and orgstrate or nil
    -- reuse len
    len = orgstrate and #orgstrate
    -- if orgstrate specified and correctly defined (got length)
    if len then
        local val = orgstrate[len]
        -- fill out len to 1 if len is greater than 1
        if len > 1 then
            for i=len,1,-1 do
                -- set empty index or set val
                if not orgstrate[i] then
                    orgstrate[i] = val
                else
                    val = orgstrate[i]
                end
            end
        end
        -- fill out len to 4 if len less than 4
        val = orgstrate[len]
        if len < 4 then
            for i=len,4 do
                -- these won't be set already, force set 'em
                orgstrate[i] = val
            end
        end
    else
        orgstrate = nil
    end
    local density = args.density
    density = type(density) == "number" and {[4]=density} or
        type(density) == "table" and density or nil
    -- reuse len
    len = density and #density
    -- if density specified and correctly defined (got length)
    if len then
        local val = density[len]
        -- fill out len to 1 if len is greater than 1
        if len > 1 then
            for i=len,1,-1 do
                -- set empty index or set val
                if not density[i] then
                    density[i] = val
                else
                    val = density[i]
                end
            end
        end
        -- fill out len to 4 if len less than 4
        val = density[len]
        if len < 4 then
            for i=len,4 do
                -- these won't be set already, force set 'em
                density[i] = val
            end
        end
    else
        -- grpnum of 4 is -2 points
        density = {[3]=0,[4]=-2}
    end
    -- set complex prefs
    prefs.rocky_substrate = rockstrate
    prefs.organic_substrate = orgstrate
    prefs.density = density

    return prefs
end

-- allow mods to modify basic_prefs
soil_preferences.plant_basic_prefs = soil_preferences.new()

------------------------------
-- used in seed/seedling/(fruiting/flowering/fruitless) timers
-- if the soil quality changes under the seed, it will either increase or decrease growth progress per iteration
-- this function returns an integer "progress"
-- a progress of -5 or less will return no progress (0)
-- permits carrying of plant + soil definition
function nn.plant.soil_response(pos, pdef, sdef)
    pdef = pdef or minimal.get_nodedef(pos)
    sdef = sdef or minimal.get_nodedef(minimal.get_pos_under(pos))
    local sgroups = sdef and sdef.groups or {}
    -- not a sediment, 0!!! (could be a nil node or have no groups either)
    if not sgroups.sediment then return 0 end
    -- get and clone soil_prefs as we modify it
    local soil_prefs = pdef.plant_soil_preferences or soil_preferences.plant_basic_prefs
    soil_prefs = table.copy(soil_prefs)
    -- differently written soil_pref names (define progress here as well)
    local progress = 1 + (sgroups.wet_sediment == 1 and soil_prefs.wet or 0)
    progress = progress + (sgroups.wet_sediment == 2 and soil_prefs.wet_salty or 0)
    progress = progress + (sgroups.dry_sediment and soil_prefs.dry or 0)
    progress = progress + (sgroups.gravel and soil_prefs.gravel or 0)
    -- remove from soil pref loop check
    soil_prefs.wet = nil
    soil_prefs.wet_salty = nil
    soil_prefs.dry = nil
    -- not looking so good
    if progress < -4 then return 0 end
    -- iterate through soil_prefs
    for prefname, boost in pairs(soil_prefs) do
        if sgroups[prefname] then
            if type(boost) == "table" then
                -- get index of boost that equals sediment's group number and add it, otherwise add 0
                progress = progress + (boost[sgroups[prefname]] or 0)
            else
                progress = progress + boost
            end
        end
        -- not looking so good
        if progress < -4 then return 0 end
    end
    -- add fertility of soil
    progress = progress + (sgroups.fertility or 0)
    -- prevent from going below and ensure integer
    progress = progress < 0 and 0 or math.ceil(progress)
    -- what growth meta should go down by
    return progress
end

local function is_on_sediment(pos)
    local pos_under = minimal.get_pos_under(pos)
    return minimal.pos_group(pos_under, "sediment")
end

local function is_mushroom(pos, mdef)
    mdef = mdef or minetest.registered_nodes[minetest.get_node(pos).name]
    return mdef.groups and mdef.groups.mushroom and mdef.groups.mushroom > 0
end

function nn.plant.get_light(pos)
    local pos_above = minimal.get_pos_above(pos)
    local natural = minimal.get_daylight(pos_above) or 0
    local artificial = minetest.get_node_light(pos_above) or 0
    if artificial > natural then
        return artificial
    end
    return natural
end

local function is_light_good(pos, pdef, light)
    light = light or nn.plant.get_light(pos)
    return light <= pdef.plant_light_range.max and light >= pdef.plant_light_range.min
end

local function is_light_good_when_day(pos, pdef, light)
    local pos_above = minimal.get_pos_above(pos)
    light = light or minimal.get_daylight(pos_above, 0.5) or 0
    return is_light_good(pos, pdef, light)
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
    local current_light = nn.plant.get_light(pos) / 15
    if average_daily_light < 1 then
        return current_light
    else
        return average_daily_light
    end
end

local function is_temperature_extreme(pos, pdef)
    pdef = pdef or minimal.get_nodedef(pos)
    local temp = climate.get_point_temp(pos)
    -- -30C to 60C
    return temp < (pdef.plant_temp_range.min - 35) or temp > (pdef.plant_temp_range.max + 20)
end

local function is_temperature_good(pos, pdef)
    local temp = climate.get_point_temp(pos)
    return temp > pdef.plant_temp_range.min and temp < pdef.plant_temp_range.max
end

local function is_soil_and_temp_good(pos, pdef)
    pdef = pdef or minimal.get_nodedef(pos)
    --if not on sediment abort
    if not is_on_sediment(pos, pdef) then
        return false
    end
    --semi-extreme temps stop growth
    if not is_temperature_good(pos, pdef) then
        return false
    end
    return true
end

local function are_conditions_good(pos, pdef)
    pdef = pdef or minimal.get_nodedef(pos)
    if not is_soil_and_temp_good(pos, pdef) then
        return false
    end
    -- light level is insufficient
    -- too high or too low
    if not is_light_good(pos, pdef) then return false end
    return true
end

local function get_root_number(pos)
    local pos_under = minimal.get_pos_under(pos)
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

function nn.plant.kill(pos, natural_death, pdef, meta)
    pdef = pdef or minimal.get_nodedef(pos)
    meta = meta or minetest.get_meta(pos)
    local groups = pdef and pdef.groups or {}
    -- wasn't a plant, return!
    if not groups.flora then
        return
    end
    -- check raw groups instead of running core.get_item_group
    local fruiting_plant = groups.fruiting_plant and groups.fruiting_plant > 0
    local flowering_plant = groups.flowering_plant and groups.flowering_plant > 0
    local seedling = groups.seedling and groups.seedling > 0
    -- IF NATURAL DEATH;
    -- do seed if died as seedling
    -- do dead fruitless if flowering or do dead if such exists
    -- otherwise set as air
    -- IF INDUCED (due to player);
    -- set seedling to itself (replace with generic dead seedling in the future)
    -- set flowering plant to its dead fruitless
    -- set fruiting plant to its dead fruitless if such exists
    -- otherwise set as air
    local dead_name = natural_death and (seedling and pdef._seed_name or
        flowering_plant and pdef._dead_fruitless_name or
        pdef._dead_name or "air") or
        -- INDUCED (from player)
        seedling and pdef.name or flowering_plant and pdef._dead_fruitless_name or
        pdef._dead_name or "air"
    minimal.force_place_keep_param2(pos, dead_name)
    meta:from_table() -- clear out meta upon death
end

-- does not account for current lighting (night time) only light at day
local function was_light_here(pos, elapsed, pdef)
    -- 30 cycles without light kill a plant
    local light = minimal.get_daylight(minimal.get_pos_above(pos), 0.5) or 0
    if light < pdef.plant_light_range.min and
        elapsed > base_health * nn.plant_base_timer then
        return false
    end
    return true
end

local function kill_no_light(pos, elapsed, pdef, meta)
    pdef = pdef or minimal.get_nodedef(pos)
    if not is_mushroom(pos, pdef) and not was_light_here(pos, elapsed, pdef) then
        nn.plant.kill(pos, false, pdef, meta)
        return true
    end
end

local function kill_extreme_temp(pos, elapsed, pdef, meta)
    if is_temperature_extreme(pos, pdef) then
        nn.plant.kill(pos, false, pdef, meta)
        return true
    end
end

local function kill_climate_history(pos, elapsed)
    if climate.plant_killed(elapsed) then
        nn.plant.kill(pos, false)
        return true
    end
end

local is_winter = seasons.is_winter

local function kill_in_winter(pos, elapsed)
    if not are_conditions_good(pos) and is_winter() then
        nn.plant.kill(pos, true)
        return true
    end
end

local function step_through_life_stage(pos, growing_time, growing_left, elapsed, pdef, meta)
    pdef = pdef or minimal.get_nodedef(pos)
    meta = meta or minetest.get_meta(pos)
    while growing_left < 0 do
        if pdef._next_life_stage then
            minimal.force_place_keep_param2(pos, pdef._next_life_stage)
            pdef = pdef._next_life_stage and minetest.registered_nodes[pdef._next_life_stage] or pdef
        end
        -- #TODO: fix non-fruiting/flowering plants having no nodetimer
        -- erases metadata of plants without node timer functionality
        if not pdef.on_timer then
            meta:from_table()
            return
        end
        growing_left = growing_left + growing_time
    end
    -- meta gets refreshed by force_place_keep_param2, won't set growth if fruiting
    if not (pdef.groups and pdef.groups.fruiting_plant) then
        meta:set_int("growth", growing_left)
    end
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
    local soil = nn.plant.soil_response(pos)
    local progress = soil * (good_cycles + rain_cycles * 4)
    return progress
end

local function time_to_cycles(time)
    return time / nn.plant_base_timer
end

local function progress_surface(pos, elapsed)
    local mushroom = is_mushroom(pos)
    -- climate history is stored in 60s chunks, called "cycles" here for reasons
    -- number of cycles
    local good_time, rain_time = good_time_rain_time(elapsed, mushroom)
    local good_cycles = time_to_cycles(good_time)
    local rain_cycles = time_to_cycles(rain_time)

    local progress = calculate_growth_progress(pos, good_cycles, rain_cycles)
    if mushroom then return progress end
    local light_cofactor = get_light_cofactor(pos)

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
    if elapsed > nn.plant_base_timer then
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
    if elapsed > nn.plant_base_timer then
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

function nn.plant.set_to_wild(pos)
    add_to_param2(pos, 0)
end

function nn.plant.set_to_domesticated(pos)
    add_to_param2(pos, 64)
end

function nn.plant.set_to_half_wild(pos)
    add_to_param2(pos, 128)
end

------------------ Global functions of the API ------------------

function nn.plant.start_growing_seed(pos)
    local timer_min = nn.seed_growing_time - 0.25 * nn.seed_growing_time
    local timer_max = nn.seed_growing_time + 0.25 * nn.seed_growing_time
    local timer = minetest.get_node_timer(pos)
    timer:start(math.random(timer_min, timer_max))
end

function nn.plant.grow_seed(pos, elapsed)
    local nodedef = minimal.get_nodedef(pos)
    local good_time = good_time_rain_time(elapsed, is_mushroom(pos, nodedef))
    -- if conditions were good for germination we don't care about the present
    if elapsed > nn.seed_growing_time and good_time >= 60 then
        -- pass elapsed to seedlings so we can catch up from there
        minimal.force_place_keep_param2(pos, nodedef._next_life_stage)
        minimal.node_set_int(pos, "elapsed", elapsed)
        return false
    elseif not is_soil_and_temp_good(pos, nodedef) then
        return true -- unless dead, try again when conditions are good
    end
    minimal.force_place_keep_param2(pos, nodedef._next_life_stage)
    return false -- the seed becomes a seedling (stops the timer)
end

function nn.plant.death_chance_on_replant(pos)
    nn.plant.set_to_domesticated(pos)
    -- random chance to kill the plant when replanting
    if math.random() < 1/4 then
        local timer = minetest.get_node_timer(pos)
        timer:stop()
        minetest.after(3, function () nn.plant.kill(pos, false) end)
    end
end

function nn.plant.start_growing_plant(pos, growing_time, is_fruiting)
    local timer_min = nn.plant_base_timer - 0.1 * nn.plant_base_timer
    local timer_max = nn.plant_base_timer + 0.1 * nn.plant_base_timer
    if not is_fruiting then
        minimal.node_set_int(pos, "growth", growing_time)
    end
    local timer = minetest.get_node_timer(pos)
    timer:start(math.random(timer_min, timer_max))
end

function nn.plant.grow_plant(pos, elapsed_full, growing_time, soil_prefs)
    local param2 = minimal.get_param2(pos)
    if param2 < 63 then return end -- No reason to run on wild plants
    local meta = minetest.get_meta(pos)
    local pdef = minimal.get_nodedef(pos)
    if not pdef then return end -- how was this run???
    local elapsed = elapsed_full + seed_elapsed(meta)
    local current_progress = current_growth_progress(pos, elapsed)
    local past_progress = past_growth_progress(pos, elapsed)
    -- we had no light so exit before catch up
    if kill_no_light(pos, elapsed, pdef, meta) then
        return false
    end
    -- create health if not found
    local health = meta:get_int("health")
    if not meta:get("health") then
        health = base_health + base_health * math.random(-1, 1) * 0.1
        meta:set_int("health", health)
    end
    -- kill semi-wild in winter, set to wild
    if param2 >= 128 and is_winter() then
        nn.plant.set_to_wild(pos)
        nn.plant.kill(pos, true, pdef, meta)
        return
    end
    if health <= 0 then
        nn.plant.kill(pos, true, pdef, meta)
        return
    end
    if not are_conditions_good(pos) then
        current_progress = 0
        if is_winter() then
            meta:set_int("health", health - 3)
        else
            meta:set_int("health", health - 1)
        end
    elseif health < base_health then
        local chance = math.random()
        -- 2% chance to recover 2 points, 0.05% chance to recover 3
        health = health + (chance < 0.02 and 2 or chance < 0.0005 and 3 or 1)
        -- clamp health below base_health
        health = health > base_health and base_health or health
        meta:set_int("health", health)
    end
    local progress = past_progress + current_progress
    -- we shant keep growing when we're already fruiting!
    if not (pdef.groups and pdef.groups.fruiting_plant) then
        local growing_left = meta:get_int("growth") - progress
        -- let's play some catchup!
        if growing_left < 0 then
            step_through_life_stage(pos, growing_time, growing_left, elapsed, pdef, meta)
        -- set growth normally otherwise
        else
            meta:set_int("growth", growing_left)
        end
    end
    if kill_extreme_temp(pos, elapsed, pdef, meta) then
        return false
    end
    growing_side_effects(pos, progress)
    return true
end
