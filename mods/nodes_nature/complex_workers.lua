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

-- Moisture spread --

function nn.create_soak_out_move_down(args)
    -- Arguments and labels
    local args = table.copy(args)
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
    -- The actual worker function
    return function(pos_min, pos_max, vm_data, chance)
        --local t1 = minetest.get_us_time()
        local hash = ms.mapchunk_hash(pos_min)
        nn.moisture_orphans[hash] = {}
        local found = false
        local data = vm_data.nodes

        for i = 1, #data do
            local replacement = wet_to_dry_ids[data[i]]
            if replacement then
                local below_index = i - chunk_side
                local dry_below = dry_to_wet_ids[data[below_index]]
                -- z, y, x have values 0 - 79
                local z = math.floor((i - 1) / chunk_side^2)
                local y = math.floor((i - 1 - z * chunk_side^2) / chunk_side)
                local x = (i - 1) % 80
                local node_pos = vector.new(x, y, z)
                if dry_below and y >= 1 then
                    -- Move water downwards
                    data[i] = replacement
                    data[below_index] = dry_below
                elseif not (x == 0 or x == 79 or z == 0 or z == 79 or y == 0 or y == 79) then
                    local air_table = {}
                    local dry_table = {}
                    local wet_table = {}

                    local function add_dry(index)
                        if dry_to_wet_ids[data[index]] then
                            table.insert(dry_table, index)
                        end
                    end

                    local function add_wet(index)
                        if wet_to_dry_ids[data[index]] then
                            table.insert(wet_table, index)
                        end
                    end

                    local function add_air(index)
                        if buildable_to_liquid_ids[data[index]] and
                            buildable_to_liquid_ids[data[index + chunk_side]] then
                            -- needs to have air above too
                            table.insert(air_table, index)
                        end
                    end

                    local function check(index, add_fun)
                        add_fun(index - 1)
                        add_fun(index + 1)
                        add_fun(index - chunk_side^2)
                        add_fun(index + chunk_side^2)
                    end

                    check(below_index, add_dry)
                    check(below_index, add_air)
                    local below_dry_nr = #dry_table

                    check(i, add_dry)
                    check(i, add_wet)
                    
                    local above_index = i + chunk_side
                    check(above_index, add_wet)
                    add_wet(above_index)

                    local function move_moisture(dry_index)
                        data[i] = replacement
                        if dry_to_wet_ids[data[dry_index]] then
                            -- I don't know why but somehow this becomes wet before I do anything
                            data[dry_index] = dry_to_wet_ids[data[dry_index]]
                        end
                    end

                    if below_dry_nr > 0 then
                        move_moisture(dry_table[math.random(1, below_dry_nr)])
                    elseif #dry_table > 0 then
                        move_moisture(dry_table[math.random(below_dry_nr + 1, #dry_table)])
                    elseif #air_table > 0 and #wet_table >= 6 then
                        local air_index = air_table[math.random(1, #air_table)]
                        data[i] = replacement
                        data[air_index] = buildable_to_liquid_ids[data[air_index]]
                    end
                else
                    -- border here
                    table.insert(nn.moisture_orphans[hash], vector.add(pos_min, node_pos))
                end
                found = true
                -- "if replacement" ends here
            elseif data[i] == ignore_id then
                return {"worker_failed"}
            end
        end

        if found then
            -- minetest.log("error", string.format("elapsed time: %g ms", (minetest.get_us_time() - t1) / 1000))
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
    for _, seawater in pairs(seawater) do
        local seawater_id = minetest.get_content_id(seawater)
        seawater_ids[seawater_id] = true
    end
    return function(pos_min, pos_max, vm_data, chance)
        --local t1 = minetest.get_us_time()
        local found = false
        local data = vm_data.nodes
        local hash = ms.mapchunk_hash(pos_min)

        local orphans = {}
        nn.water_orphans[hash] = {}

        local function one_iteration(last)
            local previous_i = false
            for i = 1, #data do
                local replacement = liquid_to_air_ids[data[i]]
                if replacement and i ~= previous_i then
                    -- z, y, x have values 0 - 79
                    local z = math.floor((i - 1) / chunk_side^2)
                    local y = math.floor((i - 1 - z * chunk_side^2) / chunk_side)
                    local x = (i - 1) % 80
                    local node_pos = vector.new(x, y, z)
                    local dry_below = dry_to_wet_ids[data[i - chunk_side]]
                    local seawater_below = seawater_ids[data[i - chunk_side]]
                    if y >= 1 and (dry_below or seawater_below) then
                        if dry_below then
                            -- Soak in
                            data[i] = replacement
                            data[i - chunk_side] = dry_below
                        elseif seawater_below then
                            -- Remove if seawater below
                            data[i] = replacement
                        end
                    elseif not (x == 0 or x == 79 or z == 0 or z == 79 or y == 0 or y == 79) then
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
                            add(index - 1)
                            add(index + 1)
                            add(index - chunk_side^2)
                            add(index + chunk_side^2)
                        end
                        check(i - chunk_side) -- below
                        check(i - chunk_side) -- add twice for downwards bias
                        check(i)

                        if #dry_table >= 1 then
                            -- soak in sideways
                            local dry_index = dry_table[math.random(1, #dry_table)]
                            data[i] = replacement
                            data[dry_index] = dry_to_wet_ids[data[dry_index]]
                        elseif #air_table >= 1 then
                            -- move water source
                            local air_index = air_table[math.random(1, #air_table)]
                            data[i] = replacement
                            data[air_index] = buildable_to_liquid_ids[data[air_index]]
                            previous_i = air_index
                            if last then
                                table.insert(orphans, air_index)
                            end
                        end
                    else
                        -- borders here
                        if last then
                            table.insert(orphans, i)
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
        one_iteration(true)

        for _, orphan in pairs(orphans) do
            if liquid_to_air_ids[data[orphan]] then
                local air_z = math.floor((orphan - 1) / chunk_side^2)
                local air_y = math.floor((orphan - 1 - air_z * chunk_side^2) / chunk_side)
                local air_x = (orphan - 1) % 80
                local air_pos = vector.new(air_x, air_y, air_z)
                table.insert(nn.water_orphans[hash], vector.add(pos_min, air_pos))
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
