-- Mapchunk Shepherd: Dogs
-- License: GNU GPLv3
-- Copyright © Jan Wielkiewicz 2023

-- Globals
local ms = mapchunk_shepherd

ms.scanners = {}
ms.workers = {}
ms.scanners_by_name = {}
ms.workers_by_name = {}
ms.scanners_changed = true
ms.workers_changed = true

local placeholder_id_pairs = {}
local placeholder_id_finder_pairs = {}
local ignore_id = minetest.get_content_id("ignore")
local air_id = minetest.get_content_id("air")

local blocks_per_chunk = tonumber(minetest.get_mapgen_setting("chunksize"))
local chunk_side = blocks_per_chunk * 16

-- iterate over ids of all possible existing nodes
for i = 1, 32768 do
    placeholder_id_finder_pairs[i] = false
    placeholder_id_pairs[i] = i
end

placeholder_id_pairs[ignore_id] = false

-- fun needs to be a function fun(pos1, pos2)
-- where pos1 is minimal position in a mapchunk,
-- pos2 is maximal position in a mapchunk,
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
    local args = table.copy(args)
    local needed_labels = args.needed_labels or {}
    local has_one_of = args.has_one_of or {}
    local rescan_labels = args.rescan_labels or {}
    table.insert(needed_labels, "chunk_tracked")
    if not is_scanner_registered(args.name) then
        local scanner = {
            name = args.name,
            scanner_function = args.fun,
            needed_labels = needed_labels,
            has_one_of = has_one_of,
            scan_every = args.scan_every,
            rescan_labels = rescan_labels,
        }
        table.insert(ms.scanners, scanner)
        ms.scanners_by_name[args.name] = scanner
    end
    ms.scanners_changed = true
end

function ms.register_worker(args)
    local args = table.copy(args)
    local needed_labels = args.needed_labels or {}
    local has_one_of = args.has_one_of or {}
    local rework_labels = args.rework_labels or {}
    table.insert(needed_labels, "chunk_tracked")
    table.insert(needed_labels, "scanned")
    if not is_worker_registered(args.name) then
        local worker = {
            name = args.name,
            worker_function = args.fun,
            needed_labels = needed_labels,
            has_one_of = has_one_of,
            work_every = args.work_every,
            rework_labels = rework_labels,
        }
        table.insert(ms.workers, worker)
        ms.workers_by_name[args.name] = worker
    end
    ms.workers_changed = true
end

function ms.remove_scanner(name)
    for i = 1, #ms.scanners do
        if ms.scanners[i].name == name then
            ms.scanners_by_name[name] = nil
            table.remove(ms.scanners, i)
            ms.scanners_changed = true
        end
    end
end

function ms.remove_worker(name)
    for i = 1, #ms.workers do
        if ms.workers[i] and ms.workers[i].name == name then
            ms.workers_by_name[name] = nil
            table.remove(ms.workers, i)
            ms.workers_changed = true
        end
    end
end

function ms.create_simple_finder(args)
    local args = table.copy(args)
    local nodes_to_find = args.to_find
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "scanner_failed")
    local not_found = args.not_found_labels
    local ids = {}
    for _, name in pairs(nodes_to_find) do
        table.insert(ids, minetest.get_content_id(name))
    end
    return function(pos1, pos2)
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
    local args = table.copy(args)
    local find_replace_pairs = args.find_replace_pairs
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
    local chance = args.chance or 1
    local ids = table.copy(placeholder_id_pairs)
    for to_find, replacement in pairs(find_replace_pairs) do
        local find_id = minetest.get_content_id(to_find)
        local replacement_id = minetest.get_content_id(replacement)
        ids[find_id] = replacement_id
    end
    return function(pos1, pos2)
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
                if chance >= math.random() then
                    data[i] = replacement
                end
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
    local args = table.copy(args)
    local find_replace_pairs = args.find_replace_pairs
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
    local lower_than = args.lower_than or 257
    local higher_than = args.higher_than or -1
    local chance = args.chance or 1
    local ids = table.copy(placeholder_id_pairs)
    for to_find, replacement in pairs(find_replace_pairs) do
        local find_id = minetest.get_content_id(to_find)
        local replacement_id = minetest.get_content_id(replacement)
        ids[find_id] = replacement_id
    end
    return function(pos1, pos2)
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
                    if chance >= math.random() then
                        data[i] = replacement
                    end
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

function ms.create_light_aware_replacer(args)
    local args = table.copy(args)
    local find_replace_pairs = args.find_replace_pairs
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
    local lower_than = args.lower_than or 16
    local higher_than = args.higher_than or -1
    local chance = args.chance or 1
    local ids = table.copy(placeholder_id_pairs)
    for to_find, replacement in pairs(find_replace_pairs) do
        local find_id = minetest.get_content_id(to_find)
        local replacement_id = minetest.get_content_id(replacement)
        ids[find_id] = replacement_id
    end
    return function(pos1, pos2)
        local pos_min, pos_max = pos1, pos2
        local vm = VoxelManip()
        local emin, emax = vm:read_from_map(pos_min, pos_max)
        local area = VoxelArea:new{
            MinEdge = emin,
            MaxEdge = emax,
        }
        local found = false
        local data = vm:get_data()
        local data_light = vm:get_light_data()
        for i = 1, #data do
            local replacement = ids[data[i]]
            if replacement then
                local above = area:position(i)
                above.y = above.y + 1
                local above_index = area:indexp(above)
                local random_pick = false
                if not data_light[above_index] then
                    above_index = i
                    random_pick = true
                    -- we can't read pos above at the top boundary
                    -- that's why we're picking randomly lol
                end
                if data_light[above_index] > higher_than and
                    data_light[above_index] < lower_than or random_pick
                then
                    if chance >= math.random() then
                        data[i] = replacement
                    end
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

-- Places nodes on top of a node if light above the node is good
function ms.create_light_aware_top_placer(args)
    local args = table.copy(args)
    -- Labels
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    table.insert(labels_to_remove, "worker_failed")
    local not_found = args.not_found_labels
    -- Node properties
    local lower_than = args.lower_than or 16
    local higher_than = args.higher_than or -1
    local chance = args.chance or 1
    -- Find ids
    local nodes_to_find = args.to_find
    local find_ids = table.copy(placeholder_id_finder_pairs)
    for _, name in pairs(nodes_to_find) do
        table.insert(find_ids, minetest.get_content_id(name))
        local f_id = minetest.get_content_id(name)
        find_ids[f_id] = f_id
    end
    -- Replace ids
    local find_replace_pairs = args.find_replace_pairs
    local replace_ids = table.copy(placeholder_id_pairs)
    for to_find, replacement in pairs(find_replace_pairs) do
        local find_id = minetest.get_content_id(to_find)
        local replacement_id = minetest.get_content_id(replacement)
        replace_ids[find_id] = replacement_id
    end
    return function(pos1, pos2)
        local pos_min, pos_max = pos1, pos2
        local vm = VoxelManip()
        local emin, emax = vm:read_from_map(pos_min, pos_max)
        local area = VoxelArea:new{
            MinEdge = emin,
            MaxEdge = emax,
        }
        local found = false
        local data = vm:get_data()
        local data_light = vm:get_light_data()
        for i = 1, #data do
            local find_id = find_ids[data[i]]
            if find_id then
                if data[i] == find_id then
                    local above = area:position(i)
                    above.y = above.y + 1
                    local above_index = area:indexp(above)
                    local replacement = replace_ids[data[above_index]]
                    if data_light[above_index] and
                        data_light[above_index] > higher_than and
                        data_light[above_index] < lower_than
                    then
                        if chance >= math.random() and replacement then
                            data[above_index] = replacement
                            found = true
                        end
                    end
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

function ms.create_deco_finder(args)
    local args = table.copy(args)
    local deco_list = args.deco_list
    local labels_to_add = args.add_labels or {}
    local labels_to_remove = args.remove_labels or {}
    for _, deco in pairs(deco_list) do
        local id = minetest.get_decoration_id(deco.name)
        minetest.set_gen_notify({decoration = true}, {id})
        minetest.register_on_generated(
            function(minp, maxp, blockseed)
                local gennotify = minetest.get_mapgen_object("gennotify")
                local pos_list = gennotify["decoration#"..id] or {}
                if #pos_list > 0 then
                    local hash = ms.mapchunk_hash(minp)
                    if not ms.contains_labels(hash, labels_to_add) then
                        ms.save_mapchunk(hash)
                        ms.handle_labels(hash, labels_to_add, labels_to_remove)
                        ms.add_labels(hash, {"scanned"})
                    end
                end
            end
        )
    end
end
