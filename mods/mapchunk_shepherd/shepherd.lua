-- Mapchunk Shepherd
-- License: GNU GPLv3
-- Copyright © Jan Wielkiewicz 2023

-- Globals
local ms = mapchunk_shepherd

local modpath = minetest.get_modpath('mapchunk_shepherd')
local dimensions = dofile(modpath.."/chunk_dimensions.lua")

local mapchunk_offset = dimensions.mapchunk_offset
local chunk_side = dimensions.chunk_side
local old_chunksize = dimensions.old_chunksize
local blocks_per_chunk = dimensions.blocks_per_chunk

local function neighboring_mapchunks(hash)
    local pos = minetest.get_position_from_hash(hash)
    local hashes = {}
    local diameter = tonumber(minetest.settings:get("viewing_range")) * 2
    local nr = math.ceil(diameter / chunk_side)
    local y_min = 0
    local y_max = 0
    if pos.y == mapchunk_offset then
        y_min = 0
        y_max = 3
    elseif pos.y == mapchunk_offset + chunk_side then
        y_min = -1
        y_max = 2
    else
        y_min = -2
        y_max = 1
    end
    for z = -nr, nr do
        for y = y_min, y_max do
            for x = -nr, nr do
                local v = vector.new(x, y, z)
                v = vector.multiply(v, chunk_side)
                local mapchunk_pos = vector.add(pos, v)
                table.insert(hashes, ms.mapchunk_hash(mapchunk_pos))
            end
        end
    end
    return hashes
end

local function filter_underground_mapchunks(hashes)
    local clean = {}
    for _, hash in pairs(hashes) do
        local pos_min, pos_max = ms.mapchunk_borders(hash)
        if pos_max.y >= -15 then
            table.insert(clean, hash)
        end
    end
    return clean
end

---------------------------------------------------------------------
-- Main loops of the shepherd
---------------------------------------------------------------------

local scan_queue = {}
local work_queue = {}

local current_scanner = 1

local scanners = {}

local longer_break = 2 -- two seconds
local previous_failure = false
local scanner_break = 0.005

local function run_scanners()
    if ms.scanners_changed then
        scanners = table.copy(ms.scanners)
        ms.scanners_changed = false
        current_scanner = 1
        scan_queue = {}
        minetest.after(longer_break, run_scanners)
    end
    local hash = scan_queue[1]
    if not hash then
        minetest.after(scanner_break, run_scanners)
        return
    end
    local pos1, pos2 = ms.mapchunk_borders(hash)
    local failed = ms.contains_labels(hash, {"scanner_failed"})
    if not minetest.compare_block_status(pos1, "loaded") or
        ms.was_scanned(hash) and not failed then
        table.remove(scan_queue, 1)
        current_scanner = 1
        minetest.after(scanner_break, run_scanners)
        return
    end
    if #scanners > 0 then
        --minetest.log("warning", "scan queue: "..#scan_queue)
        if failed then
            current_scanner = 1
            if previous_failure == hash and math.random() < 0.5 then
                -- 50% chance to remove recurrent failure
                table.remove(scan_queue, 1)
                minetest.after(scanner_break, run_scanners)
                return
            else
                previous_failure = hash
            end
        end
        local scanner = scanners[current_scanner]
        if ms.contains_labels(hash, scanner.needed_labels) and
            ms.has_one_of(hash, scanner.has_one_of) then
            local labels_added, labels_removed =
                scanner.scanner_function(pos1, pos2)
            ms.handle_labels(hash, labels_added, labels_removed)
        end
        current_scanner = current_scanner + 1
        if current_scanner > #scanners then
            table.remove(scan_queue, 1)
            current_scanner = 1
            if minetest.compare_block_status(pos1, "loaded") then
                ms.add_labels(hash, {"scanned"})
            end
        end
        minetest.after(scanner_break, run_scanners)
        return
    end
    minetest.after(longer_break, run_scanners)
    return
end

local current_worker = 1

local workers = {}
local worker_break = 0.005

local function run_workers()
    if ms.workers_changed then
        workers = table.copy(ms.workers)
        ms.workers_changed = false
        current_worker = 1
        work_queue = {}
        minetest.after(longer_break, run_workers)
        return
    end
    local hash = work_queue[1]
    if not hash then
        minetest.after(worker_break, run_workers)
        return
    end
    local pos1, pos2 = ms.mapchunk_borders(hash)
    if not minetest.compare_block_status(pos1, "loaded") then
        table.remove(work_queue, 1)
        current_worker = 1
        minetest.after(worker_break, run_workers)
        return
    end
    if #workers > 0 then
        --minetest.log("warning", "work queue: "..#work_queue)
        local worker = workers[current_worker]
        if ms.contains_labels(hash, worker.needed_labels) and
            ms.has_one_of(hash, worker.has_one_of) then
            local labels_added, labels_removed =
                worker.worker_function(pos1, pos2)
            ms.handle_labels(hash, labels_added, labels_removed)
        end
        current_worker = current_worker + 1
        if current_worker > #workers then
            table.remove(work_queue, 1)
            current_worker = 1
        end
        minetest.after(worker_break, run_workers)
        return
    end
    minetest.after(longer_break, run_workers)
    return
end

local function add_to_scan_queue(hash)
    local scan = true
    for _, chunk in pairs(scan_queue) do
        if chunk == hash then
            scan = false
        end
    end
    if scan then
        table.insert(scan_queue, hash)
    end
end

local function add_to_work_queue(hash)
    local work = true
    for _, chunk in pairs(work_queue) do
        if chunk == hash then
            scan = false
        end
    end
    if work then
        table.insert(work_queue, hash)
    end
end

-- Part of the tracker
local function save_scan_work(hash)
    local labels = ms.get_labels(hash)

    if not ms.is_tracked(hash) then
        ms.save_mapchunk(hash)
        table.insert(scan_queue, hash)
        return
    end

    if not ms.was_scanned(hash) then
        add_to_scan_queue(hash)
    elseif ms.contains_labels(hash, {"scanner_failed"}) then
        if math.random() < 0.2 then
            -- 20% chance of rescanning on failure
            add_to_scan_queue(hash)
        end
    end

    for _, worker in pairs(workers) do
        if ms.contains_labels(hash, worker.needed_labels) and
            ms.has_one_of(hash, worker.has_one_of) or
            ms.contains_labels(hash, worker.needed_labels) and
            ms.has_one_of(hash, worker.has_one_of) and
            ms.contains_labels(hash, {"worker_failed"})
        then
            add_to_work_queue(hash)
        end
    end
end

-- Player tracker - responsible for saving mapchunks
-- and adding chunks into scan and work queues.
local function player_tracker()
    local players = minetest.get_connected_players()
    for _, player in pairs(players) do
        local pos = player:get_pos()
        if not pos then
            return
        end
        local hash = ms.mapchunk_hash(pos)
        local neighbors = neighboring_mapchunks(hash)
        neighbors = filter_underground_mapchunks(neighbors)
        --minetest.log("error", dump(ms.get_labels(hash)))
        for _, neighbor in pairs(neighbors) do
            local pos_min, pos_max = ms.mapchunk_borders(neighbor)
            if minetest.compare_block_status(pos_min, "loaded") then
                save_scan_work(neighbor)
            end
        end
    end
end

local tracker_timer = 0
local tracker_interval = 10

local function player_tracker_loop(dtime)
    tracker_timer = tracker_timer + dtime
    if tracker_timer > tracker_interval then
        tracker_timer = 0
        player_tracker()
    end
end

------------------------------------------------------------------
-- Here the trackers is started
------------------------------------------------------------------

-- Prevent starting Mapchunk Shepherd if chunksize changed for the world.
-- This avoids data corruption.
if ms.chunksize_changed() then
    minetest.log("error", "Mapchunk Shepherd: chunksize changed to "..
                 blocks_per_chunk.." from "..old_chunksize..".")
    minetest.log("error", "Mapchunk Shepherd: Changing chunksize can corrupt stored data."..
                 " Refusing to start.")
else
    -- Start the tracker
    minetest.register_globalstep(player_tracker_loop)
    minetest.after(5, run_scanners)
    minetest.after(5, run_workers)
end

minetest.register_chatcommand(
    "shepherd_status", {
        description = S("Prints status of the Mapchunk Shepherd."),
        privs = {},
        func = function(name, param)
            local nr_of_chunks = ms.tracked_chunk_counter()
            local tracked_chunks_status = S("Tracked chunks: ")..nr_of_chunks
            local scan_queue_status = S("Scan queue: ")..#scan_queue
            local work_queue_status = S("Work queue: ")..#work_queue
            return true, tracked_chunks_status.."\n"..scan_queue_status.."\n"..work_queue_status
        end,
})
