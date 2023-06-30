-- Mapchunk Shepherd
-- License: GNU GPLv3
-- Copyright © Jan Wielkiewicz 2023

-- Globals
ms = mapchunk_shepherd

local mod_storage = minetest.get_mod_storage()
-- By default chunksize is 5
local blocks_per_chunk = tonumber(minetest.get_mapgen_setting("chunksize"))
local chunk_side = blocks_per_chunk * 16
-- this logic comes from Minetest source code, see src/mapgen/mapgen.cpp
local mapchunk_offset = -16 * math.floor(blocks_per_chunk / 2)
local old_chunksize = mod_storage:get_int("chunksize")

local function chunksize_changed()
    if old_chunksize == 0 then
        mod_storage:set_int("chunksize", blocks_per_chunk)
        return false
    elseif old_chunksize ~= blocks_per_chunk then
        return true
    else
        return false
    end
end

-- A global function to get hash from pos
function ms.mapchunk_hash(pos)
    local pos = vector.floor(pos)
    pos = vector.divide(pos, chunk_side)
    pos = vector.floor(pos)
    pos = vector.multiply(pos, chunk_side)
    pos = vector.add(pos, mapchunk_offset)
    return minetest.hash_node_position(pos)
end

local function neighboring_mapchunks(hash)
    local pos = minetest.get_position_from_hash(hash)
    local hashes = {}
    for z = -1, 1 do
        for y = -1, 1 do
            for x = -1, 1 do
                local v = vector.new(x, y, z)
                v = vector.multiply(v, chunk_side)
                local mapchunk_pos = vector.add(pos, v)
                table.insert(hashes, ms.mapchunk_hash(mapchunk_pos))
            end
        end
    end
    return hashes
end

local function is_tracked(hash)
    local value = mod_storage:get_int(hash)
    if value > 0 then
        return true
    else
        return false
    end
end

local function get_labels(hash)
    local encoded = mod_storage:get_int(hash)
    if encoded then
        return ms.decode_labels(encoded)
    else
        return {}
    end
end

local function add_labels(hash, new_labels)
    local labels = get_labels(hash)
    if ms.labels_valid(new_labels) then
        for _, nlabel in pairs(new_labels) do
            table.insert(labels, nlabel)
        end
        labels = ms.delete_duplicates(labels)
        mod_storage:set_int(hash, ms.encode_labels(labels))
    else
        minetest.log("error", "Mapchunk shepherd: "..label.." is not a valid label!")
    end
end

local function save_mapchunk(hash, force)
    if force then
        mod_storage:set_int(hash, ms.encode_labels({"chunk_tracked"}))
    elseif not is_tracked(hash) then
        add_labels(hash, {"chunk_tracked"})
    end
end

-- Clears labels other than "chunk_tracked"
local function reset_mapchunk(hash)
    mod_storage:set_int(hash, ms.encode_labels({"chunk_tracked"}))
end

-- Removes the hash from history
local function remove_mapchunk(hash)
    mod_storage:set_int(hash, 0)
end

local function was_scanned(hash)
    local labels = get_labels(hash)
    if ms.contains_labels(labels, {"scanned"}) then
        return true
    else
        return false
    end
end

local function remove_labels(hash, labels)
    local old_labels = get_labels(hash)
    if not is_tracked(hash) then
        minetest.log("error", "Mapchunk shepherd: "..hash.." is not tracked!")
    end
    for i, old_name in pairs(old_labels) do
        for _, name in pairs(labels) do
            if old_name == name then
                old_labels[i] = nil
            end
        end
    end
    mod_storage:set_int(hash, ms.encode_labels(old_labels))
end

-- A global function to get mapchunk borders
function ms.mapchunk_borders(hash)
    local pos_min = minetest.get_position_from_hash(hash)
    local pos_max = vector.add(pos_min, 79)
    return pos_min, pos_max
end

local function handle_labels(hash, labels_added, labels_removed)
    if labels_added then
        add_labels(hash, labels_added)
    end
    if labels_removed then
        remove_labels(hash, labels_removed)
    end
end

---------------------------------------------------------------------
-- Main loops of the shepherd
---------------------------------------------------------------------

local scan_queue = {}
local work_queue = {}

local current_scanner = 1

local function run_scanners()
    if #scan_queue > 0 and #ms.scanners > 0 then
        minetest.log("error", "scan queue: "..#scan_queue)
        local hash = scan_queue[1]
        local labels = get_labels(hash)
        local pos1, pos2 = ms.mapchunk_borders(hash)
        local scanner = ms.scanners[current_scanner]
        if ms.contains_labels(labels, scanner.needed_labels) then
            local labels_added, labels_removed =
                scanner.scanner_function(pos1, pos2, labels)
            handle_labels(hash, labels_added, labels_removed)
        end
        current_scanner = current_scanner + 1
        if current_scanner > #ms.scanners then
            table.remove(scan_queue, 1)
            current_scanner = 1
            add_labels(hash, {"scanned"})
        end
    end
end

local current_worker = 1

local function run_workers()
    if #work_queue > 0 and #ms.workers > 0 then
        minetest.log("error", "work queue: "..#work_queue)
        local hash = work_queue[1]
        local labels = get_labels(hash)
        local pos1, pos2 = ms.mapchunk_borders(hash)
        local worker = ms.workers[current_worker]
        if ms.contains_labels(labels, worker.needed_labels) then
            local labels_added, labels_removed =
                worker.worker_function(pos1, pos2, labels)
            handle_labels(hash, labels_added, labels_removed)
        end
        current_worker = current_worker + 1
        if current_worker > #ms.workers then
            table.remove(work_queue, 1)
            current_worker = 1
        end
    end
end

-- Main loop of the shepherd
local function player_tracker()
    local players = minetest.get_connected_players()
    for _, player in pairs(players) do
        local pos = player:get_pos()
        if not pos then
            return
        end
        local hash = ms.mapchunk_hash(pos)
        local neighbors = neighboring_mapchunks(hash)
        minetest.log("error", dump(get_labels(hash)))
        for _, neighbor in pairs(neighbors) do
            if not is_tracked(neighbor) then
                save_mapchunk(neighbor)
                table.insert(scan_queue, neighbor)
            elseif not was_scanned(neighbor) then
                table.insert(scan_queue, neighbor)
                scan_queue = ms.delete_duplicates(scan_queue)
            else
                table.insert(work_queue, hash)
                work_queue = ms.delete_duplicates(work_queue)
            end
        end
    end
end

local tracker_timer = 0
local tracker_interval = 4.123
local scan_timer = 0
local scan_interval = 1.331
local work_timer = 0
local work_interval = 2.003

-- 1: track, 2: scan, 3: work
local task_index = 1

local function main_loop(dtime)
    tracker_timer = tracker_timer + dtime
    if tracker_timer > tracker_interval and task_index == 1 then
        tracker_timer = 0
        player_tracker()
        task_index = 2
    end
    scan_timer = scan_timer + dtime
    if scan_timer > scan_interval and task_index == 2 then
        scan_timer = 0
        run_scanners()
        task_index = 3
    end
    work_timer = work_timer + dtime
    if work_timer > work_interval and task_index == 3 then
        work_timer = 0
        run_workers()
        task_index = 1
    end
end

------------------------------------------------------------------
-- Here the trackers is started
------------------------------------------------------------------

-- Prevent starting Mapchunk Shepherd if chunksize changed for the world.
-- This avoids data corruption.
if chunksize_changed() then
    minetest.log("error", "Mapchunk Shepherd: chunksize changed to "..
                 blocks_per_chunk.." from "..old_chunksize..".")
    minetest.log("error", "Mapchunk Shepherd: Changing chunksize can corrupt stored data."..
                 " Refusing to start.")
else
    -- Start the tracker
    minetest.register_globalstep(main_loop)
end
