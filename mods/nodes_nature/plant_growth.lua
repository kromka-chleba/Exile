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
local default_light = 8 -- What light level to assume when nodes are unloaded

-- soil_preferences
-- points for "progress", should be integers (see nn.plant.soil_response for how it's used)
-- more complex soil_pref calculations expect tables with numbers in them
-- numbered indexes for specific soil group, then a correlating progress integer
function soil_preferences.new(args)
    args = args or {}
    local prefs = {} -- we only want certain things specified, produce separate table
    -- permit custom attributes to wet, wet_salty, or dry soil
    prefs.wet = type(args.wet) == "number" and args.wet or 2 -- wet_sediment == 1
    prefs.wet_salty = type(args.wet_salty) == "number" and args.wet_salty or -50 -- wet_sediment == 2
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
        rockstrate = nil
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
        density = nil
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
    if not pdef then return 0 end

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

-- get light above plant
-- tod is timeofday used for natural light
function nn.plant.get_light(pos, tod)
    local pos_above = minimal.get_pos_above(pos)
    local natural = minimal.get_daylight(pos_above, tod) or default_light
    local artificial = minetest.get_node_light(pos_above) or default_light
    -- first is priority (return either artificial light leve or natural whichever is greatest)
    -- return natural 2nd, artificial third
    return artificial > natural and artificial or natural, natural, artificial
end

local function is_light_good(pos, pdef, light)
    light = light or nn.plant.get_light(pos)
    return light <= pdef.plant_light_range.max and light >= pdef.plant_light_range.min
end

local function is_light_good_when_day(pos, pdef, light)
    local pos_above = minimal.get_pos_above(pos)
    light = light or minimal.get_daylight(pos_above, 0.5) or default_light
    return is_light_good(pos, pdef, light)
end

local function calculate_average_light(pos)
    local pos_above = minimal.get_pos_above(pos)
    local sum = 0
    for i = 0, 20 do
        local light = minimal.get_daylight(pos_above, i / 20)
        -- Light is nil if the node above isn't loaded yet, assume it's not dark
        if not light then light = default_light end
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

local function is_temperature_extreme(pos, pdef, temp)
    pdef = pdef or minimal.get_nodedef(pos)
    if not pdef then return false end
    temp = temp or climate.get_point_temp(pos)
    -- -30C to 60C
    return temp < (pdef.plant_temp_range.min - 35) or temp > (pdef.plant_temp_range.max + 20)
end

local function is_temperature_good(pos, pdef, temp)
    temp = temp or climate.get_point_temp(pos)
    return temp >= pdef.plant_temp_range.min and temp <= pdef.plant_temp_range.max
end

local function is_soil_and_temp_good(pos, pdef, temp)
    pdef = pdef or minimal.get_nodedef(pos)
    if not pdef then return true end

    --if not on sediment abort
    if not is_on_sediment(pos, pdef) then
        return false
    end
    --semi-extreme temps stop growth
    if not is_temperature_good(pos, pdef, temp) then
        return false
    end
    return true
end

local function are_conditions_good(pos, pdef, temp)
    pdef = pdef or minimal.get_nodedef(pos)
    if not is_soil_and_temp_good(pos, pdef, temp) then
        return false
    end
    -- light level is insufficient
    -- too high or too low
    if not is_light_good(pos, pdef) then return false end
    return true
end

-- pos and meta should be the soil pos and meta
local function set_roots(pos, meta, pdef, nr)
    local sdef = minimal.get_nodedef(pos) -- soil def
    if not (sdef and sdef.groups) then return end -- can't even check groups!
    -- salty wet sediment or not a sediment at all
    if sdef.groups.wet_sediment == 2 or not sdef.groups.sediment then return end
    -- not a rooted soil (let's root it!)
    if not sdef.groups.roots then
        -- a sloped sediment
        if sdef.groups.natural_slope then
            minetest.set_node(pos, {name = sdef.drop.."_roots"})
        else
            minetest.set_node(pos, {name = sdef.name.."_roots"})
        end
    end
    -- now for meta changes
    meta:set_string("root_name", pdef._root_name)
    meta:set_float("root_nr", nr)
end

-- pos is plant's pos, spos is soil position
-- pdef is optional but helpful to provide
local function grow_roots(pos, spos, progress, pdef)
    pdef = pdef or minimal.get_nodedef(pos)
    if type(pdef._root_name) ~= "string" then return end -- shouldn't even be running this function
    local max_root_nr = pdef and pdef.groups and pdef.groups.plant_with_roots
    if not max_root_nr then return end
    local smeta = core.get_meta(spos) -- soil meta
    local nr = smeta:get_float("root_nr") -- number of roots
    -- why are we adding to the roots when at max??? return
    if nr >= max_root_nr then return end
    -- adding to number of roots by progression
    nr = nr + (0.001 * math.random(1, 10) * progress)
    -- clamp below max_root number if over
    nr = nr > max_root_nr and max_root_nr or nr
    -- set with new number
    set_roots(spos, smeta, pdef, nr)
end

local function deplete_soil(pos)
    local sdef = minimal.get_nodedef(pos)
    if sdef and sdef._depleted_name then
        minetest.swap_node(pos, {name = sdef._depleted_name})
    end
end

-- clears plant-unique meta (growth, health, and elapsed) while leaving any other fields
-- permit data argument for if to_table was already called
local function clear_meta(meta, data)
    data = data or meta:to_table()
    if not data then return end -- failed to get data
    if not data.fields then return end -- failed to get fields
    data.fields.growth = nil
    data.fields.health = nil
    data.fields.elapsed = nil
    meta:from_table(data) -- set with modified fields
end

function nn.plant.kill(pos, natural_death, pdef, meta)
    local pnode = minetest.get_node(pos)
    -- plant.kill() is also used with minetest.timer()!
    -- plant removed or replaced by different thing? -> return
    if pdef and pnode and (pdef.name ~= pnode.name) then return end
    pdef = pdef or core.registered_nodes[pnode.name]
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
    pnode.name = natural_death and (seedling and pdef._seed_name or
        flowering_plant and pdef._dead_fruitless_name or
        pdef._dead_name or "air") or
        -- INDUCED (from player)
        seedling and pdef.name or flowering_plant and pdef._dead_fruitless_name or
        pdef._dead_name or "air"
    -- reuse same node stats that we got, save meta
    minimal.switch_node(pos, pnode)
    clear_meta(meta) -- clear out plant-specific meta upon death
end

-- prefers natural light but permits artificial light at a cost
local function catchup_progress_light(pos, elapsed, progress, pdef)
    -- don't even have to catchup
    if elapsed < base_health * nn.plant_base_timer then return progress end
    -- we don't care about natural light
    if pdef.plant_light_range.min <= 0 then return progress end
    -- light will be either natural or artificial depending on whose greater - get light during noon
    local light, natural, artificial = nn.plant.get_light(pos, .5)
    -- if light BAD, we KILL
    if not is_light_good(pos, pdef, light) then return end
    -- if light is equal to natural found light (we can do a simple is equal check)
    -- or permit a greater artificial long as long as natural is alright
    if light == natural or is_light_good(pos, pdef, natural) then return progress end
    -- time to check other stuff
    if progress == 0 then return 0 end -- what, you want us to do calculations with this..?
    -- we got artificial light, hmm... let's do some calculations about how much it hurts our progress
    -- 60% of our progress only
    progress = progress * .65
    local min_prog = progress/3 -- minimum progress; as low as progress can get (third of progress)
    -- get max and min
    local max,min = pdef.plant_light_range.max,pdef.plant_light_range.min
    -- subtract max and light by min for bettered calculation
    max,light = max-min,light-min
    -- check animals.age_mechanics for a similar explanation
    -- basically clamp calculation between minimum progress (third of 65%) and 65% progress
    -- divide it by the value of max light range divided by light
    -- subtract by min
    progress = min_prog+(progress-min_prog)/(max/light)
    return progress
end

local function kill_extreme_temp(pos, elapsed, pdef, meta, temp)
    if is_temperature_extreme(pos, pdef, temp) then
        nn.plant.kill(pos, false, pdef, meta)
        return true
    end
end

local function kill_climate_history(pos, elapsed, pdef, meta)
    if climate.plant_killed(elapsed) then
        nn.plant.kill(pos, false, pdef, meta)
        return true
    end
end

local is_winter = seasons.is_winter

local function step_through_life_stage(pos, growing_left, elapsed, pdef, meta)
    local pnode = minetest.get_node(pos) -- plant node
    pdef = pdef or core.registered_nodes[pnode.name]
    meta = meta or minetest.get_meta(pos)
    local data = meta:to_table()
    if not (data and data.fields) then return end -- could not get data properly this time around
    local finished -- used to determine if we should erase metadata
    while growing_left < 0 do
        pdef = pdef._next_life_stage and core.registered_nodes[pdef._next_life_stage] or pdef
        growing_left = growing_left + pdef.plant_growing_time
        -- #TODO: fix non-fruiting/flowering plants having no nodetimer
        -- erases metadata of plants without node timer functionality
        if not pdef.on_timer then
            finished = true
            break
        end
    end
    -- set new node
    pnode.name = pdef.name -- update node name here
    -- turn semi-wild spread to wild
    pnode.param2 = finished and (pnode.param2 > 127 and (pdef.place_param2 or 0)) or pnode.param2
    minimal.switch_node(pos, pnode) -- save meta (incase custom meta is set)
    -- as mentioned above, clear meta of plants without nodetimer functionality
    if finished then return clear_meta(meta, data) end
    -- if not fruiting, set growing_left (round growing_left)
    -- otherwise do NOT set growing
    if not (pdef.groups and pdef.groups.fruiting_plant) then
        data.fields.growth = tostring(math.floor(growing_left + 0.5))
    else
        data.fields.growth = nil
    end
     -- erase catchup value (as we're done with it for now)
    data.fields.elapsed = nil
     -- save data
    meta:from_table(data)
    -- after we're done with growth we can check for season
    kill_climate_history(pos, elapsed, pdef, meta)
end

local function growing_side_effects(pos, progress, pdef)
    local pos_under = minimal.get_pos_under(pos)
    --chance to deplete soil
    if math.random() <= 0.0001 then
        deplete_soil(pos_under)
    end
    grow_roots(pos, pos_under, progress, pdef)
end

local function calculate_growth_progress(pos, pdef, good_cycles_in, rain_cycles_in)
    local good_cycles = good_cycles_in or 1
    local rain_cycles = rain_cycles_in or 0
    if rain_cycles == 0 and climate.get_rain(pos) then
        rain_cycles = 1
    end
    local soil = nn.plant.soil_response(pos, pdef)
    local progress = soil * (good_cycles + rain_cycles * 1.5)
    return progress
end

local function time_to_cycles(time)
    return time / nn.plant_base_timer
end

local function progress_surface(pos, elapsed, pdef)
    local mushroom = is_mushroom(pos)
    -- climate history is stored in 60s chunks, called "cycles" here for reasons
    -- number of cycles
    local good_time, rain_time = good_time_rain_time(elapsed, mushroom)
    local good_cycles = time_to_cycles(good_time)
    local rain_cycles = time_to_cycles(rain_time)

    local progress = calculate_growth_progress(pos, pdef, good_cycles, rain_cycles)
    if mushroom then return progress end
    local light_cofactor = get_light_cofactor(pos)

    return progress * light_cofactor
end

local function progress_underground(pos, elapsed, pdef)
    local good_cycles = time_to_cycles(elapsed)
    local progress = calculate_growth_progress(pos, pdef, good_cycles)
    if is_mushroom(pos) then
        return progress
    end
    local light_cofactor = get_light_cofactor(pos)
    return progress * light_cofactor
end

local function past_growth_progress(pos, elapsed, pdef)
    -- only check if above greatest possible time
    if elapsed > nn.plant_base_timer*1.1 then
        if pos.y < -15 then
            return progress_underground(pos, elapsed, pdef)
        else
            return progress_surface(pos, elapsed, pdef)
        end
    else
        return 0
    end
end

local function current_growth_progress(pos, elapsed, pdef)
    if is_mushroom(pos) then
        return calculate_growth_progress(pos, pdef)
    else
        local light_cofactor = get_light_cofactor(pos)
        return calculate_growth_progress(pos, pdef) * light_cofactor
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

-- optional pdef argument
local function add_to_param2(pos, nr, pdef)
    pdef = pdef or minimal.get_nodedef(pos)
    if not pdef then return end
    -- get place_param2
    local place_param2 = pdef.place_param2
    -- doesn't have a place_param2, get one from seedling
    if not place_param2 then
        local next_stage = core.registered_nodes[pdef._next_life_stage]
        place_param2 = next_stage and next_stage.place_param2
    end
    local new_param2 = (pdef.place_param2 or 0) + nr
    minetest.swap_node(pos, {name = pdef.name, param2 = new_param2})
end

function nn.plant.set_to_wild(pos, pdef)
    add_to_param2(pos, 0, pdef)
end

function nn.plant.set_to_domesticated(pos, pdef)
    add_to_param2(pos, 64, pdef)
end

function nn.plant.set_to_half_wild(pos, pdef)
    add_to_param2(pos, 128, pdef)
end

------------------ Global functions of the API ------------------

function nn.plant.start_growing_seed(pos)
    local nodetime = math.ceil(nn.seed_growing_time * math.random(75,125)/100)
    local timer = minetest.get_node_timer(pos)
    timer:start(nodetime)
end

function nn.plant.grow_seed(pos, elapsed, pdef, meta)
    local pnode = minetest.get_node(pos)
    pdef = pdef or core.registered_nodes[pnode.name]
    if not (pdef and pdef.groups) then return end -- end timer, can't even seed!
    -- if seed, get next_life_stage (become seedling)
    if pdef.groups.seed then
        pdef = core.registered_nodes[pdef._next_life_stage]
        if not (pdef and pdef.groups) then return end -- no definition, end timer
    end
    meta = meta or minetest.get_meta(pos)
    local good_time = good_time_rain_time(elapsed, is_mushroom(pos, pdef))
    -- if conditions were good for germination we don't care about the present
    if elapsed > nn.seed_growing_time and good_time >= 60 then
        -- pass elapsed to seedlings so we can catch up from there
        meta:set_int("elapsed", elapsed/nn.plant_base_timer) -- divide for proper cycle
    elseif not is_soil_and_temp_good(pos, pdef) then
        return true -- unless dead, try again when conditions are good
    end
    pnode.name = pdef.name -- becoming seedling, reuse same node data
    pnode.param2 = pnode.param2 + (pdef.place_param2 or 0) -- ensure we set the proper param2
    minimal.switch_node(pos, pnode) -- switch to seedling and save meta
    return false -- the seed becomes a seedling (stops the timer)
end

-- optional plant def argument (node definition)
function nn.plant.death_chance_on_replant(pos, pdef)
    nn.plant.set_to_domesticated(pos)
    pdef = pdef or minimal.get_nodedef(pos)
     -- do not run for seedlings to prevent autogrowth
    if not pdef
        or (pdef.groups and pdef.groups.seedling) then return end

    -- random chance to kill the plant when replanting (1 in 4, 25% chance)
    if math.random() < .25 then
        local timer = minetest.get_node_timer(pos)
        timer:stop()
        minetest.after(3, function () nn.plant.kill(pos, false, pdef) end)
    end
end

function nn.plant.start_growing_plant(pos, pdef, meta)
    pdef = pdef or minimal.get_nodedef(pos)
    if not pdef then return end -- how!
    local growingtime = pdef.plant_growing_time
    local nodetime = math.ceil(nn.plant_base_timer * math.random(90,110)/100)
    if growingtime and not (pdef.groups and pdef.groups.fruiting_plant) then
        meta = meta or core.get_meta(pos)
        meta:set_int("growth", growingtime)
    end
    local timer = minetest.get_node_timer(pos)
    timer:start(nodetime)
end

function nn.plant.grow_plant(pos, elapsed_full)
    local pnode = core.get_node(pos)
    local pdef = core.registered_nodes[pnode.name]
    if not pdef then return end -- how was this run???
    local param2 = pnode.param2
    if param2 < 63 then return end -- No reason to run on wild plants
    local meta = minetest.get_meta(pos)
    elapsed_full = elapsed_full/nn.plant_base_timer -- convert to cycle
    local elapsed = elapsed_full + seed_elapsed(meta)
    local elapsed_secs = elapsed*nn.plant_base_timer
    local current_progress = current_growth_progress(pos, elapsed_secs, pdef)
    local past_progress = past_growth_progress(pos, elapsed_secs, pdef)
    local temp = climate.get_point_temp(pos) -- temperature
    -- check what our progress should be according to light (will be normal if not artificial light dependent)
    current_progress = catchup_progress_light(pos, elapsed_secs, current_progress, pdef)
    -- oh, we ded! not enough light!
    if not current_progress then
        nn.plant.kill(pos, false, pdef, meta)
        -- set growth to prevent sudden growth on light reintroduction
        meta:set_int("growth", pdef.plant_growing_time)
        return
    end
    -- create health if not found
    local health = meta:get_int("health")
    if not meta:get("health") then
        -- 10% less or more
        health = base_health * math.random(90,110)/100
    end
    -- semi-wild growth mechanics
    if param2 >= 128 then
        -- kill semi-wild in winter, set to wild
        if is_winter() then
            nn.plant.set_to_wild(pos, pdef)
            nn.plant.kill(pos, true, pdef, meta)
            return
        -- set to wild if we're currently the same name as our type in the specific season
        elseif pdef["_"..seasons.get_season_name()] == pdef.name then
            nn.plant.set_to_wild(pos, pdef)
            return clear_meta(meta) -- clear meta
        end
    end
    -- KILL OR HURT
    if kill_extreme_temp(pos, elapsed, pdef, meta, temp) then
        return false
    end
    -- kill if we on da DEATH bed
    if health <= 0 then
        nn.plant.kill(pos, true, pdef, meta)
        return
    -- good conditions mechanics
    elseif are_conditions_good(pos, pdef, temp) then
        -- heal up if conditions are good and our health is lower than usual
        if health < base_health then
            local chance = math.random()
            -- 4% chance to recover 2 points, 0.5% chance to recover 3
            health = health + (chance < 0.04 and 2 or chance < 0.005 and 3 or 1)
            -- clamp health below base_health
            health = health > base_health and base_health or health
        end
    -- conditions bad, no progress allowed
    -- calculate damage from temperature if applicable
    else
        current_progress = 0
        local templimits = {max = pdef.plant_temp_range.max, min = pdef.plant_temp_range.min}
        -- chlorophyll degrades around 70C -- assume max + 20
        -- ceil rounds up, abs ensures positive integers
        -- higher temperatures relatively tolerable
        if temp > templimits.max then
            health = health - math.ceil(math.abs((temp - templimits.max)/10))
        -- colder temps not as tolerable
        elseif temp < templimits.min then
            health = health - math.ceil(math.abs((temp - templimits.min)/8))
        -- we just don't like these conditions, we picky
        else
            health = health - 1
        end
    end
    -- set health
    meta:set_int("health", health)
    -- figure out growth - past progress is calculated in cycles (of plant_base_timer)
    -- past_progress is set to 1 if negative or 0
    local progress = current_progress * (past_progress > 0 and past_progress or 1)
    -- we can't do any growing, return for another loop!
    if progress == 0 then
        -- stored elapsed (if greater than maximum possible cycle)
        if elapsed > 1.1 then
            -- don't store more to elapsed than need be (subtract from elapsed variable if not a significant change)
            -- i.e elapsed_full less than maximum possible cycle
            elapsed = elapsed_full > nn.plant_base_timer * 1.1 and elapsed or elapsed-elapsed_full
            meta:set_int("elapsed", elapsed)
        end
        return true
    end
    -- we shant keep growing when we're already fruiting!
    if not (pdef.groups and pdef.groups.fruiting_plant) then
        local growing_left = meta:get_int("growth") - progress
        -- let's play some catchup!
        if growing_left < 0 then
            step_through_life_stage(pos, growing_left, elapsed, pdef, meta)
        -- set growth normally otherwise
        else
            meta:set_int("growth", growing_left)
        end
    end
    growing_side_effects(pos, progress, pdef)
    return true
end
