---------------------------------------------------------
--Plant growth for Plant API

-- Internationalization
local S = nodes_nature.S

---------------------------------------------------------

plant = plant or {}
soil_preferences = {}

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

function plant.start_growing_plant(pos, growing_time)
    local timer_min = plant_base_timer - 0.1 * plant_base_timer
    local timer_max = plant_base_timer + 0.1 * plant_base_timer
    local meta = minetest.get_meta(pos)
    meta:set_int("growth", growing_time)
    meta:set_int("last_updated", 0)
    local timer = minetest.get_node_timer(pos)
    if not timer:is_started() then
        timer:start(math.random(timer_min, timer_max))
    end
end

------------------------------
-- Seeds/seedling soil timers
-- if the soil quality changes under the seed it will slow/speed the timer
-- this procedure returns a timer
local function seed_soil_response(pos, soil_prefs)
    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
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
    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
    local node_under = minetest.get_node(pos_under)
    return minetest.get_item_group(node_under.name, "sediment") > 0
end

local function is_mushroom(pos)
    local plant_name = minetest.get_node(pos).name
    local nodedef = minetest.registered_nodes[plant_name]
    return minetest.get_item_group(plant_name, "mushroom") > 0
end

local function is_dark(pos)
    local light = minimal.get_daylight({x=pos.x, y=pos.y + 1, z=pos.z})
    return not light or light < 3
end

local function is_temperature_extreme(pos)
    local temp = climate.get_point_temp(pos)
    return temp < -30 or temp > 60
end

local function is_temperature_good(pos)
    local temp = climate.get_point_temp(pos)
    return temp > 5 and temp < 40
end

local function are_conditions_good(pos)
    --if not on sediment abort
    if not is_on_sediment(pos) then
        return false
    end
    --semi-extreme temps stop growth
    if not is_temperature_good(pos) then
        return false
    end
    --cannot grow indoors (unless a mushroom)
    if not is_mushroom(pos) and is_dark(pos) then
        return false
    end
    return true
end

-- returns growth to catch up or false if the plant has died 
local function catch_up_timer(pos, elapsed, last_updated, growing_left, growth_rate)
    local temp = climate.get_point_temp(pos)
    local mushroom = is_mushroom(pos)
    local elapsed = elapsed - last_updated
    if elapsed > plant_base_timer then
        if pos.y < -15 and temp >= 0 or temp <= 40 then
            if mushroom then
                --This is an underground shroom, assume steady temp
                return growing_left - growth_rate * ( elapsed / plant_base_timer)
            else
                -- underground plant, but we've got light so give it 50%
                return growing_left - growth_rate * ( elapsed / plant_base_timer / 2)
            end
        else
            -- change only takes rain, sun and temp into account
            local change = crop_rewind(elapsed, plant_base_timer, mushroom)
            if change == -1 then
                --Exteme heat or cold killed the plant
                minetest.remove_node(pos)
                return false -- kill the timer
            end
            -- growth_rate is comes from soil quality
            return growing_left - change - growth_rate * (elapsed / plant_base_timer / 2)
        end
    end
    return growing_left -- we weren't away actually
end

local function grow_roots(pos)
    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
    local plant_name = minetest.get_node(pos).name
    local plant_nodedef = minetest.registered_nodes[plant_name]
    local under_name = minetest.get_node(pos_under).name
    local nodedef_under = minetest.registered_nodes[under_name]
    local max_root_nr = plant_nodedef.groups.plant_with_roots
    if not nodedef_under.groups.sediment then
        return
    elseif not nodedef_under.groups.roots then
        minetest.set_node(pos_under, {name = under_name.."_roots"})
    end
    local meta = minetest.get_meta(pos_under)
    local root_name = meta:get_string("root_name")
    if root_name == "" then
        meta:set_string("root_name", plant_nodedef._root_name)
    end
    local root_nr = meta:get_int("root_nr")
    if root_nr < max_root_nr then
    local new_roots = root_nr + math.random(0, math.ceil(max_root_nr / 3))
    if new_roots > max_root_nr then
        new_roots = max_root_nr
    end
    meta:set_int("root_nr", new_roots)
    end
end

local function catch_up_life_stage(pos, growing_time, growing_left)
    while growing_left < 0 do
        local node_name = minetest.get_node(pos).name
        local nodedef = minetest.registered_nodes[node_name]
        if nodedef.groups.plant_with_roots then
            grow_roots(pos)
        end
        if nodedef._next_life_stage then
            local p2 = nodedef.place_param2
            minetest.remove_node(pos)
            minetest.place_node(pos, {name = nodedef._next_life_stage,
                                      param2 = p2})
        end
        growing_left = growing_left + growing_time
    end
    local meta = minetest.get_meta(pos)
    meta:set_int("growth", growing_left)
end

local function deplete_soil(pos)
    local node_name = minetest.get_node(pos).name
    local nodedef = minetest.registered_nodes[node_name]
    if nodedef._depleted_name then
        minetest.swap_node(pos, {name = nodedef._depleted_name})
    end
end

local function kill_or_stop_growing(pos)
    local node = minetest.get_node(pos)
    local nodedef = minetest.registered_nodes[node.name]
    local fruiting_plant =
        minetest.get_item_group(node.name, "fruiting_plant") > 0
    local flowering_plant =
        minetest.get_item_group(node.name, "flowering_plant") > 0
    local seedling =
        minetest.get_item_group(node.name, "seedling") > 0
    -- extreme temps will kill
    if is_temperature_extreme(pos) then
        if fruiting_plant and nodedef._dead_fruitless_name then
            minetest.set_node(pos, {name = nodedef._dead_fruitless_name,
                                    param2 = nodedef.place_param2})
        else
            minetest.set_node(pos, {name = nodedef._dead_name,
                                    param2 = nodedef.place_param2})
        end
        return true
    end
    -- stop growth if conditions not suitable
    if not are_conditions_good(pos) then
        local season = seasons.get_season_name()
        if season == "winter_early" or
            season == "winter_late" then
            if seedling then
                minetest.set_node(pos, {name = nodedef._seed_name,
                                        param2 = nodedef.place_param2})
            elseif flowering_plant and nodedef._dead_fruitless_name then
                minetest.set_node(pos, {name = nodedef._dead_fruitless_name,
                                        param2 = nodedef.place_param2})
            else
                minetest.set_node(pos, {name = nodedef._dead_name,
                                        param2 = nodedef.place_param2})
            end
            return true
        end
        return true
    end
    -- returning false allows growth
    return false
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
    local node_name = minetest.get_node(pos).name
    local nodedef = minetest.registered_nodes[node_name]
    local season = seasons.get_season_name()
    local meta = minetest.get_meta(pos)
    if meta:get_int("first_updated") == 0 then
        meta:set_int("first_updated", elapsed)
    end
    if not are_conditions_good(pos) then
        return true -- unless dead, try again when conditions are good
    end
    local first_updated = meta:get_int("first_updated")
    minetest.remove_node(pos)
    minetest.place_node(pos, {name = nodedef._next_life_stage})
    local meta = minetest.get_meta(pos)
    -- set last_updated for the new node to trigger life cycle catch up
    meta:set_int("last_updated", first_updated)
    meta:set_int("elapsed", elapsed)
    return false -- the seed becomes a seedling (stops the timer)
end

-- Grows a plant
function plant.grow_plant(pos, elapsed, growing_time, soil_prefs)
    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
    local meta = minetest.get_meta(pos)
    local growing_left = meta:get_int("growth")
    local last_updated = meta:get_int("last_updated") or elapsed
    --We've been away, let's catch up on missing growth
    local progress = seed_soil_response(pos, soil_prefs)
    -- this one is just in case the seed set elapsed to trigger catch up
    local elapsed = elapsed
    if meta:get_int("elapsed") > 0 then
        elapsed = meta:get_int("elapsed")
    end
    growing_left = catch_up_timer(pos, elapsed, last_updated, growing_left, progress)
    -- if catch_up_timer returns false it means the plant has died
    -- due to extreme weather
    if not growing_left then return false end
    -- new plant, or grow
    local plant_name = minetest.get_node(pos).name
    local plant_nodedef = minetest.registered_nodes[plant_name]
    if growing_left < 0 then
        catch_up_life_stage(pos, growing_time, growing_left)
        return false
    end
    if kill_or_stop_growing(pos) then
        return true -- the plant can't grow, waits for better times
    end
    --still growing
    --chance to deplete soil
    if math.random() <= 0.0001 then
        deplete_soil(pos_under)
    end
    if progress <= 0 then
        return true -- soil is terrible, no growing here
    end
    if plant_nodedef.groups.plant_with_roots and
        not plant_nodedef.groups.seedling then
        -- roots grow depending on conditions
        if math.random() < progress / 10 then grow_roots(pos) end
    end
    growing_left = growing_left - progress
    --grow faster in rain
    if climate.get_rain(pos) then
        growing_left = growing_left - 4
    end
    meta:set_int("growth", growing_left)
    meta:set_int("last_updated", elapsed)
    return true
end
