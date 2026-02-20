----------------------------------------------------------------
-- Complex domain-specific workers using the mapchunk shepherd

mapchunk_shepherd = mapchunk_shepherd
local ms = mapchunk_shepherd
nodes_nature = nodes_nature
local nn = nodes_nature
local climate = climate

local placeholder_id_pairs = ms.placeholder_id_pairs()
local ignore_id = minetest.get_content_id("ignore")

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
    return function(pos_min, pos_max, vm_data, chance_in)
        local chunk_side = pos_max.x - pos_min.x + 1
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
                local z = math.floor((i - 1) / chunk_side^2)
                local y = math.floor((i - 1 - z * chunk_side^2) / chunk_side)
                local x = (i - 1) % chunk_side

                -- need to handle them edges in moisture_spread.lua
                -- too lazy for that today
                if not (x == 0 or x == chunk_side - 1 or
                        z == 0 or z == chunk_side - 1 or
                        y == 0 or y == chunk_side - 1) then

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
                        local light = data_light[i + chunk_side] or 0
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

    -- The actual worker function
    return function(pos_min, pos_max, vm_data, chance)
        local chunk_side = pos_max.x - pos_min.x + 1
        --local t1 = minetest.get_us_time()
        local hash = ms.mapchunk_hash(pos_min)
        nn.moisture_orphans[hash] = {}
        local found = false
        local data = vm_data.nodes

        local function x_index(index)
            return index + 1
        end

        local function z_index(index)
            return index + chunk_side^2
        end

        local function y_index(index)
            return index - chunk_side
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
        local finish = chunk_side - 1

        local z_start = math.random(0, 1)
        local z_finish = finish - 2 - z_start
        local x_start = math.random(0, 1)
        local x_finish = finish - 2 - x_start
        local y_start = math.random(1, 2)
        local y_finish = finish

        local function z_step()
            local index_function = z_index
            for z = z_start, z_finish, 2 do
                local z_base = z * chunk_side^2
                for y = start, y_finish do
                    local y_base = y * chunk_side
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
                local z_base = z * chunk_side^2
                for y = start, y_finish do
                    local y_base = y * chunk_side
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
                local z_base = z * chunk_side^2
                for y = y_start, y_finish, 2 do
                    local y_base = y * chunk_side
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

        local function soak_out(i)

            local air_table = {}
            local wet_nr = 1

            local function add_wet(index)
                if wet_to_dry_ids[data[index]] then
                    wet_nr = wet_nr + 1
                end
            end

            local function add_both(index)
                if wet_to_dry_ids[data[index]] then
                    wet_nr = wet_nr + 1
                elseif buildable_to_liquid_ids[data[index]] then
                    -- checking what's below
                    if buildable_to_liquid_ids[data[index - chunk_side]] then
                        -- needs to have air below to soak out
                        table.insert(air_table, index - chunk_side)
                    elseif wet_to_dry_ids[data[index]] then
                        wet_nr = wet_nr + 1
                    end
                end
            end

            local function check_wet(index)
                add_wet(index)
                add_wet(index - 1)
                add_wet(index + 1)
                add_wet(index - chunk_side^2)
                add_wet(index + chunk_side^2)
            end

            -- checks on the level and below
            local function check_both(index)
                add_both(index - 1)
                add_both(index + 1)
                add_both(index - chunk_side^2)
                add_both(index + chunk_side^2)
            end

            local above_index = i + chunk_side
            check_both(i)
            check_wet(above_index)

            if #air_table > 0 and wet_nr >= 8 then
                local air_index = air_table[math.random(1, #air_table)]
                data[i] = wet_to_dry_ids[data[i]]
                data[air_index] = buildable_to_liquid_ids[data[air_index]]
            end
        end

        for i, _ in pairs(unmoved) do
            local z = math.floor((i - 1) / chunk_side^2)
            local y = math.floor((i - 1 - z * chunk_side^2) / chunk_side)
            local x = (i - 1) % chunk_side
            if not (x == 0 or x == chunk_side - 1 or
                    z == 0 or z == chunk_side - 1 or
                    y == 0 or y == chunk_side - 1) then
                soak_out(i)
            else
                local node_pos = vector.new(x, y, z)
                table.insert(nn.moisture_orphans[hash],
                             vector.add(pos_min, node_pos))
            end
        end

        found = true

        if found then
            --minetest.log("error", string.format("elapsed time: %g ms", (minetest.get_us_time() - t1) / 1000))
            return labels_to_add, labels_to_remove
        else
            return not_found
        end
    end
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
    return function(pos_min, pos_max, vm_data, chance)
        local chunk_side = pos_max.x - pos_min.x + 1
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
                    local y = math.floor((i - 1 - z
                                          * chunk_side^2) / chunk_side)
                    local x = (i - 1) % chunk_side
                    local dry_below = dry_to_wet_ids[data[i - chunk_side]]
                    local seawater_below = seawater_ids[data[i - chunk_side]]
                    if x == 0 or x == chunk_side - 1 or
                        z == 0 or z == chunk_side - 1 or
                        y == 0 or y == chunk_side - 1 then
                        -- borders here
                        if last then
                            table.insert(orphans, i)
                        end
                    elseif dry_below then
                        -- Soak in
                        data[i] = replacement
                        data[i - chunk_side] = dry_below
                    elseif seawater_below then
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
                local air_x = (orphan - 1) % chunk_side
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
