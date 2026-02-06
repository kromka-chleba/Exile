----------------------------------------------------------------
-- Complex domain-specific workers using the mapchunk shepherd

mapchunk_shepherd = mapchunk_shepherd
local ms = mapchunk_shepherd
local bn = ms.block_neighborhood
nodes_nature = nodes_nature
local nn = nodes_nature
local climate = climate

local placeholder_id_pairs = ms.placeholder_id_pairs()
local ignore_id = minetest.get_content_id("ignore")

local block_side = ms.block_side()

function nn.create_evaporator(args_in)
    local args = table.copy(args_in)
    local find_replace_pairs = args.find_replace_pairs
    local neighbors = args.neighbors
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
    local ids = table.copy(placeholder_id_pairs)
    for to_find, replacement in pairs(find_replace_pairs) do
        local find_id = minetest.get_content_id(to_find)
        local replacement_id = minetest.get_content_id(replacement)
        ids[find_id] = replacement_id
    end
    local neighbor_ids = {}
    for _, neighbor in pairs(neighbors) do
        local id = minetest.get_content_id(neighbor)
        neighbor_ids[id] = true
    end
    local water_ids = {}
    for _, water in pairs(args.water_names) do
        local id = minetest.get_content_id(water)
        water_ids[id] = true
    end
    
    local function worker_fn(pos_min, pos_max, vm_data, chance_in, neighborhood)
        local chance = chance_in or 1/35
        --local t1 = minetest.get_us_time()
        local found = false
        local data = vm_data.nodes
        local data_light = vm_data.light

        -- I made up this equation
        -- below 0 there should be no evaporation but that's fake
        --  (irl there's still evap)
        -- for mean = 13 it gets values:
        -- 5 °C:  0.73
        -- 10°C:  1.93
        -- 20°C:  5.09
        -- 30°C:  8.99
        -- 40°C: 13.46
        -- 50°C: 18.39
        -- So input chance = 1/35 sounds reasonable (can simulate air humidity)
        -- this gives 0.52 chance for 50°C, 0.257 for 30°C, 0.05 for 10°C
        local temperature_cofactor =
            climate.active_temp^1.4 / climate.mean_year_temp()
        if temperature_cofactor <= 0 then
            temperature_cofactor = 0.5
        end

        for i = 1, #data do
            local replacement = ids[data[i]]
            if replacement then
                local z = math.floor((i - 1) / block_side^2)
                local y = math.floor((i - 1 - z * block_side^2) / block_side)
                local x = (i - 1) % block_side
                
                local world_pos = vector.add(pos_min, vector.new(x, y, z))

                local has_air = false
                
                -- Check all 6 neighbors, using neighborhood API for cross-block access
                local adjacent = neighborhood:get_adjacent_positions(world_pos)
                for _, adj_pos in ipairs(adjacent) do
                    local adj_node = neighborhood:read_node(adj_pos)
                    if adj_node and neighbor_ids[adj_node] then
                        has_air = true
                        break
                    end
                end

                local evap_chance

                if water_ids[data[i]] and has_air then
                    local light = data_light[i] or 0
                    local light_cofactor = light / 15
                    evap_chance = temperature_cofactor * light_cofactor
                        * chance * 1/15
                    if evap_chance >= math.random() then
                        data[i] = replacement
                    end
                else
                    -- is sediment
                    local light = data_light[i + block_side] or 0
                    local light_cofactor = light / 15
                    evap_chance = temperature_cofactor * light_cofactor
                        * chance
                    if not has_air then
                        -- 5 times slower if plant grows on top
                        evap_chance = 1/5 * evap_chance
                    end
                    if evap_chance >= math.random() then
                        data[i] = replacement
                    end
                end
                
                found = true
            elseif data[i] == ignore_id then
                return {"worker_failed"}
            end
        end
        if found then
            --minetest.log("error", string.format("elapsed time: %g ms", (minetest.get_us_time() - t1) / 1000))
            return labels_to_add, labels_to_remove
        else
            return not_found
        end
    end
    
    return bn.wrap_worker_function(worker_fn, true)
end

-- Moisture spread --

function nn.create_soak_out_move_down(args_in)
    -- Arguments and labels
    local args = table.copy(args_in)
    local wet_to_dry = args.wet_to_dry
    local buildable_to_liquid = args.buildable_to_liquid
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
    -- Preparing node IDs
    local wet_to_dry_ids = table.copy(placeholder_id_pairs)
    local dry_to_wet_ids = table.copy(placeholder_id_pairs)
    local buildable_to_liquid_ids = table.copy(placeholder_id_pairs)
    for wet, dry in pairs(wet_to_dry) do
        local wet_id = minetest.get_content_id(wet)
        local dry_id = minetest.get_content_id(dry)
        wet_to_dry_ids[wet_id] = dry_id
        dry_to_wet_ids[dry_id] = wet_id
    end
    for air, liquid in pairs(buildable_to_liquid) do
        local buildable_id = minetest.get_content_id(air)
        local liquid_id = minetest.get_content_id(liquid)
        buildable_to_liquid_ids[buildable_id] = liquid_id
    end

    -- The actual worker function with neighborhood support
    local function worker_fn(pos_min, pos_max, vm_data, chance, neighborhood)
        --local t1 = minetest.get_us_time()
        local found = false
        local data = vm_data.nodes

        local function x_index(index)
            return index + 1
        end

        local function z_index(index)
            return index + block_side^2
        end

        local function y_index(index)
            return index - block_side
        end

        local unmoved = {}

        local function z_x_cursor(i1, i2)
            local node_1 = data[i1]
            local node_2 = data[i2]
            if wet_to_dry_ids[node_1] and
                dry_to_wet_ids[node_2] then
                -- first wet, second dry
                if math.random() < 0.15 then
                    return
                end
                data[i1] = wet_to_dry_ids[node_1]
                data[i2] = dry_to_wet_ids[node_2]
                unmoved[i1] = nil
            elseif wet_to_dry_ids[node_2] and
                dry_to_wet_ids[node_1] then
                -- first dry, second wet
                if math.random() < 0.15 then
                    return
                end
                data[i1] = dry_to_wet_ids[node_1]
                data[i2] = wet_to_dry_ids[node_2]
                unmoved[i2] = nil
            else
                -- can't move
                if wet_to_dry_ids[node_1] then
                    unmoved[i1] = true
                end
                if wet_to_dry_ids[node_2] then
                    unmoved[i2] = true
                end
            end
        end

        local function y_cursor(i1, i2)
            local node_1 = data[i1]
            local node_2 = data[i2]
            if wet_to_dry_ids[node_1] and
                dry_to_wet_ids[node_2] then
                -- first wet, second dry
                data[i1] = wet_to_dry_ids[node_1]
                data[i2] = dry_to_wet_ids[node_2]
                unmoved[i1] = nil
            else
                -- can't move
                if wet_to_dry_ids[node_1] then
                    unmoved[i1] = true
                end
                if wet_to_dry_ids[node_2] then
                    unmoved[i2] = true
                end
            end
        end

        local start = 0
        local finish = block_side - 1

        local z_start = math.random(0, 1)
        local z_finish = finish - 2 - z_start
        local x_start = math.random(0, 1)
        local x_finish = finish - 2 - x_start
        local y_start = math.random(1, 2)
        local y_finish = finish

        local function z_step()
            local index_function = z_index
            for z = z_start, z_finish, 2 do
                local z_base = z * block_side^2
                for y = start, y_finish do
                    local y_base = y * block_side
                    for x = start, finish do
                        local i1 = z_base + y_base + x + 1
                        local i2 = index_function(i1)
                        z_x_cursor(i1, i2)
                    end
                end
            end
        end

        local function x_step()
            local index_function = x_index
            for z = start, finish do
                local z_base = z * block_side^2
                for y = start, y_finish do
                    local y_base = y * block_side
                    for x = x_start, x_finish, 2 do
                        local i1 = z_base + y_base + x + 1
                        local i2 = index_function(i1)
                        z_x_cursor(i1, i2)
                    end
                end
            end
        end

        local function y_step()
            local index_function = y_index
            for z = start, finish do
                local z_base = z * block_side^2
                for y = y_start, y_finish, 2 do
                    local y_base = y * block_side
                    for x = start, finish do
                        local i1 = z_base + y_base + x + 1
                        local i2 = index_function(i1)
                        y_cursor(i1, i2)
                    end
                end
            end
        end

        z_step()
        x_step()
        y_step()

        local function soak_out(world_pos)
            local air_table = {}
            local wet_nr = 1

            local function count_wet(check_pos)
                local node_id = neighborhood:read_node(check_pos)
                if node_id and wet_to_dry_ids[node_id] then
                    wet_nr = wet_nr + 1
                end
            end

            local function check_air_below(check_pos)
                local node_id = neighborhood:read_node(check_pos)
                if node_id then
                    if wet_to_dry_ids[node_id] then
                        wet_nr = wet_nr + 1
                    elseif buildable_to_liquid_ids[node_id] then
                        -- check what's below
                        local below_pos = vector.add(check_pos, vector.new(0, -1, 0))
                        local below_id = neighborhood:read_node(below_pos)
                        if below_id and buildable_to_liquid_ids[below_id] then
                            -- needs to have air below to soak out
                            table.insert(air_table, check_pos)
                        elseif below_id and wet_to_dry_ids[below_id] then
                            wet_nr = wet_nr + 1
                        end
                    end
                end
            end

            -- Check neighbors using neighborhood API
            local adjacent = neighborhood:get_adjacent_positions(world_pos)
            for _, adj_pos in ipairs(adjacent) do
                -- Don't check below for now
                if adj_pos.y >= world_pos.y then
                    check_air_below(adj_pos)
                else
                    count_wet(adj_pos)
                end
            end
            
            -- Check above
            local above_pos = vector.add(world_pos, vector.new(0, 1, 0))
            count_wet(above_pos)

            if #air_table > 0 and wet_nr >= 8 then
                local selected_pos = air_table[math.random(1, #air_table)]
                -- Dry the current position and add water to selected position
                neighborhood:write_node(world_pos, wet_to_dry_ids[neighborhood:read_node(world_pos)])
                neighborhood:write_node(selected_pos, buildable_to_liquid_ids[neighborhood:read_node(selected_pos)])
            end
        end

        -- Process unmoved wet nodes using neighborhood API
        for i, _ in pairs(unmoved) do
            local z = math.floor((i - 1) / block_side^2)
            local y = math.floor((i - 1 - z * block_side^2) / block_side)
            local x = (i - 1) % block_side
            local world_pos = vector.add(pos_min, vector.new(x, y, z))
            soak_out(world_pos)
        end

        found = true

        if found then
            --minetest.log("error", string.format("elapsed time: %g ms", (minetest.get_us_time() - t1) / 1000))
            return labels_to_add, labels_to_remove
        else
            return not_found
        end
    end
    
    return bn.wrap_worker_function(worker_fn, true)
end

function nn.create_gravity_soak_in(args_in)
    local args = table.copy(args_in)
    local wet_to_dry = args.wet_to_dry
    local buildable_to_liquid = args.buildable_to_liquid
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
    local wet_to_dry_ids = table.copy(placeholder_id_pairs)
    local dry_to_wet_ids = table.copy(placeholder_id_pairs)
    local buildable_to_liquid_ids = table.copy(placeholder_id_pairs)
    local liquid_to_air_ids = table.copy(placeholder_id_pairs)
    local seawater_list = args.seawater
    local seawater_ids = table.copy(placeholder_id_pairs)
    local air_id = minetest.get_content_id(args.air)
    for wet, dry in pairs(wet_to_dry) do
        local wet_id = minetest.get_content_id(wet)
        local dry_id = minetest.get_content_id(dry)
        wet_to_dry_ids[wet_id] = dry_id
        dry_to_wet_ids[dry_id] = wet_id
    end
    for air, liquid in pairs(buildable_to_liquid) do
        local buildable_id = minetest.get_content_id(air)
        local liquid_id = minetest.get_content_id(liquid)
        buildable_to_liquid_ids[buildable_id] = liquid_id
        liquid_to_air_ids[liquid_id] = air_id
    end
    for _, seawater in pairs(seawater_list) do
        local seawater_id = minetest.get_content_id(seawater)
        seawater_ids[seawater_id] = true
    end
    
    local function worker_fn(pos_min, pos_max, vm_data, chance, neighborhood)
        --local t1 = minetest.get_us_time()
        local found = false
        local data = vm_data.nodes

        local function one_iteration()
            local previous_i = false
            for i = 1, #data do
                local replacement = liquid_to_air_ids[data[i]]
                if replacement and i ~= previous_i then
                    local z = math.floor((i - 1) / block_side^2)
                    local y = math.floor((i - 1 - z * block_side^2) / block_side)
                    local x = (i - 1) % block_side
                    local world_pos = vector.add(pos_min, vector.new(x, y, z))
                    
                    -- Check below using neighborhood
                    local below_pos = vector.add(world_pos, vector.new(0, -1, 0))
                    local below_node = neighborhood:read_node(below_pos)
                    local dry_below = below_node and dry_to_wet_ids[below_node]
                    local seawater_below = below_node and seawater_ids[below_node]
                    
                    if dry_below then
                        -- Soak in
                        data[i] = replacement
                        neighborhood:write_node(below_pos, dry_below)
                    elseif seawater_below then
                        -- Remove if seawater below
                        data[i] = replacement
                    else
                        local air_positions = {}
                        local dry_positions = {}
                        
                        local function check_adjacent(check_pos)
                            local check_node = neighborhood:read_node(check_pos)
                            if check_node then
                                if buildable_to_liquid_ids[check_node] then
                                    table.insert(air_positions, check_pos)
                                end
                                if dry_to_wet_ids[check_node] then
                                    table.insert(dry_positions, check_pos)
                                end
                            end
                        end
                        
                        -- Check positions below and sideways
                        local adjacent = neighborhood:get_adjacent_positions(world_pos)
                        for _, adj_pos in ipairs(adjacent) do
                            if adj_pos.y <= world_pos.y then
                                check_adjacent(adj_pos)
                                -- Check twice for positions below to add downward bias
                                if adj_pos.y < world_pos.y then
                                    check_adjacent(adj_pos)
                                end
                            end
                        end

                        if #dry_positions >= 1 then
                            -- soak in sideways
                            local selected_pos = dry_positions[math.random(1, #dry_positions)]
                            data[i] = replacement
                            local dry_node = neighborhood:read_node(selected_pos)
                            neighborhood:write_node(selected_pos, dry_to_wet_ids[dry_node])
                        elseif #air_positions >= 1 then
                            -- move water source
                            local selected_pos = air_positions[math.random(1, #air_positions)]
                            data[i] = replacement
                            local air_node = neighborhood:read_node(selected_pos)
                            neighborhood:write_node(selected_pos, buildable_to_liquid_ids[air_node])
                            
                            -- Update previous_i if we moved within the same block
                            local block_offset_x = selected_pos.x - pos_min.x
                            local block_offset_y = selected_pos.y - pos_min.y
                            local block_offset_z = selected_pos.z - pos_min.z
                            if block_offset_x >= 0 and block_offset_x < block_side and
                               block_offset_y >= 0 and block_offset_y < block_side and
                               block_offset_z >= 0 and block_offset_z < block_side then
                                previous_i = 1 + block_offset_z * block_side^2 + 
                                           block_offset_y * block_side + block_offset_x
                            end
                        end
                    end
                    found = true
                elseif data[i] == ignore_id then
                    return {"worker_failed"}
                end
            end
        end

        -- Run multiple iterations to speed up water movement
        one_iteration()
        one_iteration()
        one_iteration()
        one_iteration()
        one_iteration()

        if found then
            --minetest.log("error", string.format("elapsed time: %g ms", (minetest.get_us_time() - t1) / 1000))
            return labels_to_add, labels_to_remove
        else
            return not_found
        end
    end
    
    return bn.wrap_worker_function(worker_fn, true)
end
