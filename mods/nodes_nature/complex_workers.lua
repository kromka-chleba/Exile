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
    local buildable_to_liquid = args.buildable_to_liquid
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
    local wet_to_dry_ids = table.copy(placeholder_id_pairs)
    local dry_to_wet_ids = table.copy(placeholder_id_pairs)
    local buildable_to_liquid_ids = table.copy(placeholder_id_pairs)
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
    end
    return function(pos_min, pos_max, vm_data, chance)
        --local t1 = minetest.get_us_time()
        local found = false
        local data = vm_data.nodes

        for i = 1, #data do
            local replacement = wet_to_dry_ids[data[i]]
            if replacement then
                local below_index = i - chunk_side
                local dry_below = dry_to_wet_ids[data[below_index]]
                local z = math.floor((i - 1) / chunk_side^2) -- z is 0 to 79
                local y = math.floor((i - 1 - z * chunk_side^2) / chunk_side) -- y is 0 to 79
                if dry_below then
                    -- Move water downwards
                    if y >= 1 then
                        data[i] = replacement
                        data[below_index] = dry_below
                    end
                else
                    local air_table = {}
                    local dry_table = {}
                    
                    local function add(index)
                        if dry_to_wet_ids[data[index]] then
                            table.insert(dry_table, index)
                        end
                    end

                    local above_index = false
                    if y < 79 then
                        above_index = i + chunk_side
                    end

                    local function double_add(index)
                        if buildable_to_liquid_ids[data[index]] and
                            dry_to_wet_ids[data[above_index]] then
                            -- checking for water above to simulate hydrostatic pressure
                            table.insert(air_table, index)
                        end
                        if dry_to_wet_ids[data[index]] then
                            table.insert(dry_table, index)
                            table.insert(dry_table, index)
                        end
                    end
                    
                    local function check(index, below)
                        local add_fun = add
                        if below then
                            add_fun = double_add
                        end
                        -- x border
                        if index % chunk_side ~= 1 then
                            add_fun(index - 1)
                        end
                        if index % chunk_side ~= 0 then
                            add_fun(index + 1)
                        end
                        -- z border
                        if index > chunk_side^2 then
                            add_fun(index - chunk_side^2)
                        end
                        if index < #data - chunk_side^2 then
                            add_fun(index + chunk_side^2)
                        end
                    end

                    if y >= 1 then
                        check(below_index, true)
                    end
                    
                    check(i)

                    if #dry_table >= 1 then
                        -- move sideways
                        local dry_index = dry_table[math.random(1, #dry_table)]
                        data[i] = replacement
                        if dry_to_wet_ids[data[dry_index]] then
                            -- I don't know why but somehow this becomes wet before I do anything
                            data[dry_index] = dry_to_wet_ids[data[dry_index]]
                        end
                    elseif #air_table >= 1 then
                        -- soak out
                        local air_index = air_table[math.random(1, #air_table)]
                        data[i] = replacement
                        data[air_index] = buildable_to_liquid_ids[data[air_index]]
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
end

function nn.create_gravity_soak_in(args)
    local args = table.copy(args)
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
    local seawater = args.seawater
    local seawater_ids = {}
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
    for _, seawater in pairs(seawater) do
        local seawater_id = minetest.get_content_id(seawater)
        seawater_ids[seawater_id] = true
    end
    return function(pos_min, pos_max, vm_data, chance)
        --local t1 = minetest.get_us_time()
        local found = false
        local data = vm_data.nodes

        local function one_iteration()
            for i = 1, #data do
                local replacement = liquid_to_air_ids[data[i]]
                local z = math.floor((i - 1) / chunk_side^2) -- z is 0 to 79
                local y = math.floor((i - 1 - z * chunk_side^2) / chunk_side) -- y is 0 to 79
                if replacement then
                    local below_index = i - chunk_side
                    local dry_below = dry_to_wet_ids[data[below_index]]
                    local seawater_below = seawater_ids[data[below_index]]
                    local not_y_border = y >= 1
                    if dry_below and not_y_border then
                        -- Soak in
                        --minetest.log("error", "Soak in?")
                        data[i] = replacement
                        data[below_index] = dry_below
                    elseif seawater_below and not_y_border then
                        -- Remove if seawater below
                        data[i] = replacement
                    else
                        local air_table = {}
                        local dry_table = {}
                        local function add(index)
                            if buildable_to_liquid_ids[data[index]] then
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
                        -- y border
                        if not_y_border then
                            check(below_index)
                        end
                        check(i)
                        if #dry_table >= 1 then
                            -- soak in sideways
                            local dry_index = dry_table[math.random(1, #dry_table)]
                            data[i] = replacement
                            data[dry_index] = dry_to_wet_ids[data[dry_index]]
                        elseif #air_table >= 1 then
                            -- move water source
                            local index = math.ceil(math.random(1, #air_table) / 2)
                            local air_index = air_table[index]
                            data[i] = replacement
                            data[air_index] = buildable_to_liquid_ids[data[air_index]]
                        end
                    end
                    found = true
                elseif data[i] == ignore_id then
                    return {"worker_failed"}
                end
            end
        end

        -- this speeds up things a little
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
end
