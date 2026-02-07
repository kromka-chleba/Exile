---------------------------------------------------------
-- Seasonal Mapgen Script
-- Runs in mapgen environment to generate new chunks with correct season
--

-- This script runs in the mapgen environment
-- It has access to core.ipc_get to read the current season
-- and can modify freshly generated chunks before they're added to the world

-- Get season from IPC (set by main environment)
local function get_current_season()
    return core.ipc_get("exile:current_season") or "summer_early"
end

-- Helper to check if season is winter
local function is_winter_season(season_name)
    return season_name == "winter_early" or season_name == "winter_late"
end

-- Build content_id-based lookup tables for fast replacement
-- These are indexed by content_id for O(1) lookup during mapgen
local soil_to_winter = {}  -- content_id -> winter content_id
local winter_to_soil = {}  -- winter content_id -> spring/summer content_id
local winter_soil_ids = {}  -- Set of winter soil content_ids for quick checking

-- Plant replacements by season, indexed by content_id
local plant_replacements = {
    spring_early = {},
    spring_late = {},
    summer_early = {},
    summer_late = {},
    fall_early = {},
    fall_late = {},
    winter_early = {},
    winter_late = {},
}

-- Initialize replacement tables from registered nodes
-- Build soil replacement mappings (spring <-> winter) using content_ids
for name, nodedef in pairs(core.registered_nodes) do
    if nodedef._winter_name and nodedef._winter_name ~= "" then
        -- This is a spring/summer soil that has a winter variant
        local spring_id = minetest.get_content_id(name)
        local winter_id = minetest.get_content_id(nodedef._winter_name)
        
        soil_to_winter[spring_id] = winter_id
        winter_to_soil[winter_id] = spring_id
        winter_soil_ids[winter_id] = true
    end
end

-- Build plant replacement mappings for all seasons using content_ids
for name, nodedef in pairs(core.registered_nodes) do
    if nodedef._spring_early or nodedef._spring_late or 
       nodedef._summer_early or nodedef._summer_late or
       nodedef._fall_early or nodedef._fall_late or
       nodedef._winter_early or nodedef._winter_late then
        -- This is a seasonal plant - get its content_id
        local base_id = minetest.get_content_id(name)
        
        -- For each season, map base_id to the appropriate variant's content_id
        if nodedef._spring_early and nodedef._spring_early ~= "" then
            plant_replacements.spring_early[base_id] = minetest.get_content_id(nodedef._spring_early)
        end
        if nodedef._spring_late and nodedef._spring_late ~= "" then
            plant_replacements.spring_late[base_id] = minetest.get_content_id(nodedef._spring_late)
        end
        if nodedef._summer_early and nodedef._summer_early ~= "" then
            plant_replacements.summer_early[base_id] = minetest.get_content_id(nodedef._summer_early)
        end
        if nodedef._summer_late and nodedef._summer_late ~= "" then
            plant_replacements.summer_late[base_id] = minetest.get_content_id(nodedef._summer_late)
        end
        if nodedef._fall_early and nodedef._fall_early ~= "" then
            plant_replacements.fall_early[base_id] = minetest.get_content_id(nodedef._fall_early)
        end
        if nodedef._fall_late and nodedef._fall_late ~= "" then
            plant_replacements.fall_late[base_id] = minetest.get_content_id(nodedef._fall_late)
        end
        if nodedef._winter_early and nodedef._winter_early ~= "" then
            plant_replacements.winter_early[base_id] = minetest.get_content_id(nodedef._winter_early)
        end
        if nodedef._winter_late and nodedef._winter_late ~= "" then
            plant_replacements.winter_late[base_id] = minetest.get_content_id(nodedef._winter_late)
        end
    end
end

-- Register callback to run during mapgen
-- In mapgen environment, vm is passed as the first argument with data already loaded
minetest.register_on_generated(function(vm, minp, maxp, blockseed)
    local current_season = get_current_season()
    
    -- Skip if we're in default summer state
    if current_season == "summer_early" then
        return
    end
    
    -- Get data from the voxel manipulator (already prepared in mapgen environment)
    -- Don't call read_from_map() - the VM already has the data loaded
    local data = vm:get_data()
    
    local modified = false
    local is_winter = is_winter_season(current_season)
    
    -- Get the appropriate plant replacement table for this season
    local plant_table = plant_replacements[current_season]
    
    -- Iterate directly over the data array - much faster than nested x,y,z loops
    for i = 1, #data do
        local node_id = data[i]
        
        -- Replace seasonal soils using content_id lookup
        if is_winter then
            -- Convert spring/summer soils to winter
            local winter_id = soil_to_winter[node_id]
            if winter_id then
                data[i] = winter_id
                modified = true
            end
        else
            -- Convert winter soils back to spring/summer
            local spring_id = winter_to_soil[node_id]
            if spring_id then
                data[i] = spring_id
                modified = true
            end
        end
        
        -- Replace seasonal plants using content_id lookup
        local replacement_id = plant_table[node_id]
        if replacement_id and replacement_id ~= node_id then
            data[i] = replacement_id
            modified = true
        end
    end
    
    -- Write changes back if we modified anything
    if modified then
        vm:set_data(data)
        vm:write_to_map()
    end
end)

