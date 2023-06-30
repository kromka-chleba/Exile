-- Mapchunk Shepherd: Dogs
-- License: GNU GPLv3
-- Copyright © Jan Wielkiewicz 2023

-- Globals
ms = mapchunk_shepherd

ms.scanners = {}
ms.workers = {}

-- fun needs to be a function fun(pos1, pos2, labels)
-- where pos1 is minimal position in a mapchunk,
-- pos2 is maximal position in a mapchunk,
-- labels are labels provided by the shepherd.
-- fun() needs to return two variables: labels_added,
-- labels_removed; labels to remove or add to a mapchunk

function is_scanner_registered(name)
    for i = 1, #ms.scanners do
        if ms.scanners[i].name == name then
            return true
        end
    end
    return false
end

function is_worker_registered(name)
    for i = 1, #ms.workers do
        if ms.workers[i].name == name then
            return true
        end
    end
    return false
end

function ms.register_scanner(args)
    local needed_labels = args.needed_labels or {}
    table.insert(needed_labels, "chunk_tracked")
    if not is_scanner_registered(args.name) then
        table.insert(
            ms.scanners,
            {name = args.name,
             scanner_function = args.fun,
             needed_labels = needed_labels}
        )
    end
end

function ms.register_worker(args)
    local needed_labels = args.needed_labels or {}
    table.insert(needed_labels, "chunk_tracked")
    table.insert(needed_labels, "scanned")
    if not is_worker_registered(args.name) then
        table.insert(
            ms.workers,
            {name = args.name,
             worker_function = args.fun,
             needed_labels = needed_labels}
        )
    end
end

function ms.remove_scanner(name)
    for i = 1, #ms.scanners do
        if ms.scanners[i].name == name then
            ms.scanners[i] = nil
        end
    end
end

function ms.remove_worker(name)
    for i = 1, #ms.workers do
        if ms.workers[i].name == name then
            ms.workers[i] = nil
        end
    end
end

function ms.create_simple_finder(nodes_to_find, labels_to_add, labels_to_remove)
    local ids = {}
    for _, name in pairs(nodes_to_find) do
        table.insert(ids, minetest.get_content_id(name))
    end
    return function(pos1, pos2, labels)
        local pos_min, pos_max = pos1, pos2
        local vm = VoxelManip()
        local emin, emax = vm:read_from_map(pos_min, pos_max)
        local area = VoxelArea:new{
            MinEdge = emin,
            MaxEdge = emax,
        }
        local data = vm:get_data()
        for z = pos_min.z, pos_max.z do
            for y = pos_min.y, pos_max.y do
                for x = pos_min.x, pos_max.x do
                    local index = area:index(x, y, z)
                    for _, id in pairs(ids) do
                        if data[index] == id then
                            return labels_to_add, labels_to_remove
                        end
                    end
                end
            end
        end
    end
end

function ms.create_simple_replacer(find_replace_pairs, labels_to_add, labels_to_remove)
    local ids = {}
    for to_find, replacement in pairs(find_replace_pairs) do
        local find_id = minetest.get_content_id(to_find)
        local replacement_id = minetest.get_content_id(replacement)
        ids[find_id] = replacement_id
    end
    return function(pos1, pos2, labels)
        local pos_min, pos_max = pos1, pos2
        local vm = VoxelManip()
        local emin, emax = vm:read_from_map(pos_min, pos_max)
        local area = VoxelArea:new{
            MinEdge = emin,
            MaxEdge = emax,
        }
        local found = false
        local data = vm:get_data()
        for z = pos_min.z, pos_max.z do
            for y = pos_min.y, pos_max.y do
                for x = pos_min.x, pos_max.x do
                    local index = area:index(x, y, z)
                    local replacement = ids[data[index]]
                    if replacement then
                        data[index] = replacement
                        found = true
                    end
                end
            end
        end
        vm:set_data(data)
        vm:write_to_map(true)
        if found then
            return labels_to_add, labels_to_remove
        end
    end
end
