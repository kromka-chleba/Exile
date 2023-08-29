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
