----------------------------------------------------------------
-- Complex domain-specific workers using the mapchunk shepherd

local ms = mapchunk_shepherd
local nn = nodes_nature

local placeholder_id_pairs = ms.placeholder_id_pairs()
local placeholder_id_finder_pairs = ms.placeholder_id_finder_pairs()
local ignore_id = minetest.get_content_id("ignore")

local chunk_side = ms.chunk_side()

function nn.create_evaporator(args)
    local args = table.copy(args)
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
    return function(pos_min, pos_max, vm_data, chance)
        local chance = chance or 1
        --local t1 = minetest.get_us_time()
        local found = false
        local data = vm_data.nodes
        local data_light = vm_data.light
        for i = 1, #data do
            local replacement = ids[data[i]]
            if replacement then
                local has_air = false
                if neighbor_ids[data[i - 1]] or
                    neighbor_ids[data[i + 1]] or
                    -- not checking for air below
                    --neighbor_ids[data[i - chunk_side]] or
                    neighbor_ids[data[i + chunk_side]] or
                    neighbor_ids[data[i - chunk_side^2]] or
                    neighbor_ids[data[i + chunk_side^2]] then
                    has_air = true
                end
                local light = data_light[i + chunk_side] or 0
                local light_cofactor = light / 15
                local evap_chance = light_cofactor * chance
                if not has_air then
                    -- 5 times slower if plant grows on top
                    evap_chance = 1/5 * evap_chance
                end
                if evap_chance >= math.random() then
                    data[i] = replacement
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
end

function nn.create_soak_out_move_down(args)
    local args = table.copy(args)
    local wet_to_dry = args.wet_to_dry
    local air_to_liquid = args.air_to_liquid
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
    local wet_to_dry_ids = table.copy(placeholder_id_pairs)
    local dry_to_wet_ids = table.copy(placeholder_id_pairs)
    local air_to_liquid_ids = table.copy(placeholder_id_pairs)
    for wet, dry in pairs(wet_to_dry) do
        local wet_id = minetest.get_content_id(wet)
        local dry_id = minetest.get_content_id(dry)
        wet_to_dry_ids[wet_id] = dry_id
        dry_to_wet_ids[dry_id] = wet_id
    end
    for air, liquid in pairs(air_to_liquid) do
        local air_id = minetest.get_content_id(air)
        local liquid_id = minetest.get_content_id(liquid)
        air_to_liquid_ids[air_id] = liquid_id
    end
    return function(pos_min, pos_max, chance)
        --local t1 = minetest.get_us_time()
        local vm = VoxelManip()
        local emin, emax = vm:read_from_map(pos_min, pos_max)
        local found = false
        local data = vm:get_data()
        for i = 1, #data do
            local replacement = wet_to_dry_ids[data[i]]
            if replacement then
                local below_index = i - chunk_side
                local dry_below = dry_to_wet_ids[data[below_index]]
                if dry_below then
                    -- Move water downwards
                    if (i % chunk_side^2 - i % chunk_side) % 80 ~= 0 then
                        data[i] = replacement
                        data[below_index] = dry_below
                    end
                else
                    local air_table = {}
                    local dry_table = {}
                    local function add(index)
                        if air_to_liquid_ids[data[index]] then
                            table.insert(air_table, index)
                        end
                        if dry_to_wet_ids[data[index]] then
                            table.insert(dry_table, index)
                        end
                    end
                    local function check(index)
                        -- x border
                        if index % chunk_side ~= 1 then
                            add(index - 1)
                        end
                        if index % chunk_side ~= 0 then
                            add(index + 1)
                        end
                        -- z border
                        if index > chunk_side^2 then
                            add(index - chunk_side^2)
                        end
                        if index < #data - chunk_side^2 then
                            add(index + chunk_side^2)
                        end
                    end
                    check(i)
                    -- y border
                    if (i % chunk_side^2 - i % chunk_side) % 80 ~= 0 then
                        check(below_index)
                    end
                    if #dry_table >= 1 then
                        -- move sideways
                        local dry_index = dry_table[math.random(1, #dry_table)]
                        data[i] = replacement
                        data[dry_index] = dry_to_wet_ids[data[dry_index]]
                    elseif #air_table >= 1 then
                        -- soak out
                        local air_index = air_table[math.random(1, #air_table)]
                        data[i] = replacement
                        data[air_index] = air_to_liquid_ids[data[air_index]]
                    end
                end
                found = true
            elseif data[i] == ignore_id then
                return {"worker_failed"}
            end
        end
        if found then
            vm:set_data(data)
	    vm:write_to_map(false)
            --vm:update_liquids()
            --minetest.log("error", string.format("elapsed time: %g ms", (minetest.get_us_time() - t1) / 1000))
            return labels_to_add, labels_to_remove
        else
            return not_found
        end
    end
end
