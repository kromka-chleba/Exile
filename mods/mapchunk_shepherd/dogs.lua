-- Mapchunk Shepherd: Dogs
-- License: GNU GPLv3
-- Copyright © Jan Wielkiewicz 2023

-- Globals
local ms = mapchunk_shepherd

ms.scanners = {}
ms.workers = {}
ms.scanners_changed = true
ms.workers_changed = true

local ignore_id = minetest.get_content_id("ignore")

local blocks_per_chunk = tonumber(minetest.get_mapgen_setting("chunksize"))
local chunk_side = blocks_per_chunk * 16

-- fun needs to be a function fun(pos1, pos2, labels)
-- where pos1 is minimal position in a mapchunk,
-- pos2 is maximal position in a mapchunk,
-- labels are labels provided by the shepherd.
-- fun() needs to return two variables: labels_added,
-- labels_removed; labels to remove or add to a mapchunk

local function is_scanner_registered(name)
    for i = 1, #ms.scanners do
        if ms.scanners[i].name == name then
            return true
        end
    end
    return false
end

local function is_worker_registered(name)
    for i = 1, #ms.workers do
        if ms.workers[i] and ms.workers[i].name == name then
            return true
        end
    end
    return false
end

function ms.register_scanner(args)
    local needed_labels = args.needed_labels or {}
    local has_one_of = args.has_one_of or {}
    table.insert(needed_labels, "chunk_tracked")
    if not is_scanner_registered(args.name) then
        table.insert(
            ms.scanners,
            {name = args.name,
             scanner_function = args.fun,
             needed_labels = needed_labels,
             has_one_of = has_one_of
            }
        )
    end
    ms.scanners_changed = true
end

function ms.register_worker(args)
    local needed_labels = args.needed_labels or {}
    local has_one_of = args.has_one_of or {}
    table.insert(needed_labels, "chunk_tracked")
    table.insert(needed_labels, "scanned")
    if not is_worker_registered(args.name) then
        table.insert(
            ms.workers,
            {name = args.name,
             worker_function = args.fun,
             needed_labels = needed_labels,
             has_one_of = has_one_of,
            }
        )
    end
    ms.workers_changed = true
end

function ms.remove_scanner(name)
    for i = 1, #ms.scanners do
        if ms.scanners[i].name == name then
            table.remove(ms.scanners, i)
            ms.scanners_changed = true
        end
    end
end

function ms.remove_worker(name)
    for i = 1, #ms.workers do
        if ms.workers[i] and ms.workers[i].name == name then
            table.remove(ms.workers, i)
            ms.workers_changed = true
        end
    end
end

function ms.create_simple_finder(args)
    local nodes_to_find = args.to_find
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "scanner_failed")
    local not_found = args.not_found_labels
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
        for i = 1, #data do
            for _, id in pairs(ids) do
                if data[i] == id then
                    return labels_to_add, labels_to_remove
                elseif data[i] == ignore_id then
                    return {"scanner_failed"}, {"scanned"}
                end
            end
        end
        return not_found
    end
end

function ms.create_simple_replacer(args)
    local find_replace_pairs = args.find_replace_pairs
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
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
        for i = 1, #data do
            local replacement = ids[data[i]]
            if replacement then
                data[i] = replacement
                found = true
            elseif data[i] == ignore_id then
                return {"worker_failed"}
            end
        end
        if found then
            vm:set_data(data)
            vm:write_to_map(false)
            return labels_to_add, labels_to_remove
        else
            return not_found
        end
    end
end

function ms.create_param2_aware_replacer(args)
    local find_replace_pairs = args.find_replace_pairs
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
    local lower_than = args.lower_than or 257
    local higher_than = args.higher_than or -1
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
        local data_param2 = vm:get_param2_data()
        for i = 1, #data do
            local replacement = ids[data[i]]
            if replacement then
                if data_param2[i] > higher_than and
                    data_param2[i] < lower_than then
                    data[i] = replacement
                    found = true
                elseif data[i] == ignore_id then
                    return {"worker_failed"}
                end
            end
        end
        if found then
            vm:set_data(data)
            vm:write_to_map(false)
            return labels_to_add, labels_to_remove
        else
            return not_found
        end
    end
end
