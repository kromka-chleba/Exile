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

-- Build lookup tables for node replacements
local soil_replacements = {}
local plant_replacements = {}

-- Initialize replacement tables from registered nodes
-- Build soil replacement mappings (spring <-> winter)
for name, nodedef in pairs(core.registered_nodes) do
    if nodedef._winter_name and nodedef._winter_name ~= "" then
        -- This is a spring/summer soil that has a winter variant
        soil_replacements[name] = nodedef._winter_name
        -- Also store reverse mapping (winter -> spring)
        soil_replacements[nodedef._winter_name] = name
    end
end

-- Build plant replacement mappings for all seasons
for name, nodedef in pairs(core.registered_nodes) do
    if nodedef._spring_early or nodedef._spring_late or 
       nodedef._summer_early or nodedef._summer_late or
       nodedef._fall_early or nodedef._fall_late or
       nodedef._winter_early or nodedef._winter_late then
        -- This is a seasonal plant
        plant_replacements[name] = {
            spring_early = nodedef._spring_early or name,
            spring_late = nodedef._spring_late or name,
            summer_early = nodedef._summer_early or name,
            summer_late = nodedef._summer_late or name,
            fall_early = nodedef._fall_early or name,
            fall_late = nodedef._fall_late or name,
            winter_early = nodedef._winter_early or name,
            winter_late = nodedef._winter_late or name,
        }
    end
end

-- Register callback to run during mapgen
minetest.register_on_generated(function(minp, maxp, blockseed)
    local current_season = get_current_season()
    
    -- Skip if we're in default summer state
    if current_season == "summer_early" then
        return
    end
    
    -- Get voxel manipulator for the chunk
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    local data = vm:get_data()
    local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
    
    local modified = false
    local is_winter = is_winter_season(current_season)
    
    -- Process all nodes in the chunk
    for z = minp.z, maxp.z do
        for y = minp.y, maxp.y do
            for x = minp.x, maxp.x do
                local pos = {x=x, y=y, z=z}
                local idx = area:index(x, y, z)
                local node_id = data[idx]
                local node_name = minetest.get_name_from_content_id(node_id)
                
                -- Replace seasonal soils
                if soil_replacements[node_name] then
                    local target_name
                    if is_winter then
                        -- If current node is spring variant, replace with winter
                        target_name = soil_replacements[node_name]
                        -- Check if target is actually the winter variant
                        local target_def = core.registered_nodes[target_name]
                        if target_def and target_def._is_winter_soil then
                            data[idx] = minetest.get_content_id(target_name)
                            modified = true
                        end
                    end
                    -- For non-winter seasons, keep the spring/summer variant (default)
                end
                
                -- Replace seasonal plants
                if plant_replacements[node_name] then
                    local variants = plant_replacements[node_name]
                    local target_name = variants[current_season]
                    if target_name and target_name ~= "" and target_name ~= node_name then
                        local target_id = minetest.get_content_id(target_name)
                        if target_id ~= node_id then
                            data[idx] = target_id
                            modified = true
                        end
                    end
                end
            end
        end
    end
    
    -- Write changes back if we modified anything
    if modified then
        vm:set_data(data)
        vm:write_to_map()
    end
end)

