-- Mapchunk Shepherd
-- License: GNU GPLv3
-- Copyright © Jan Wielkiewicz 2023

-- Globals
ms = mapchunk_shepherd

local tracking_interval = 10
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
    local pos = vector.divide(pos, chunk_side)
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
    if value == 0 then
        return false
    else
        return value
    end
end

local function save_mapchunk(hash, force)
    if force or not is_tracked(hash) then
        mod_storage:set_int(hash, ms.encode_labels({"chunk_tracked"}))
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

local function get_labels(hash)
    local encoded = is_tracked(hash)
    if encoded then
        return ms.decode_labels(encoded)
    end
end

local function labels_valid(labels)
    for _, label in pairs(labels) do
        if not ms.is_label(label) then
            minetest.log("error", "Mapchunk shepherd: "..label.." is not a valid label!")
            return false
        end
    end
    return true
end

local function add_labels(hash, new_labels)
    local labels = get_labels(hash)
    if not labels then
        minetest.log("error", "Mapchunk shepherd: "..hash.." is not tracked!")
    end
    if labels_valid(new_labels) then
        for _, nlabel in pairs(new_labels) do
            table.insert(labels, nlabel)
        end
        mod_storage:set_int(hash, ms.encode_labels(labels))
    end
end

local function remove_labels(hash, labels)
    local old_labels = get_labels(hash)
    if not old_labels then
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

local function run_scanners(hash)
    local labels = get_labels(hash)
    local pos1, pos2 = ms.mapchunk_borders(hash)
    for name, scanner in pairs(ms.scanners) do
        --minetest.log("error", "Running scanner: "..name)
        local labels_added, labels_removed = scanner(pos1, pos2, labels)
        if labels_added then
            add_labels(hash, labels_added)
        end
        if labels_removed then
            remove_labels(hash, labels_removed)
        end
    end
end

local function run_workers(hash)
    local labels = get_labels(hash)
    for name, worker in pairs(ms.workers) do
        --minetest.log("error", "Running worker: "..name)
        local labels_added, labels_removed = worker(pos1, pos2, labels)
    end
end

-- Main loop of the shepherd
local function player_tracker()
    local players = minetest.get_connected_players()
    for _, player in ipairs(players) do
        local pos = player:get_pos()
        local hash = ms.mapchunk_hash(pos)
        local neighbors = neighboring_mapchunks(hash)
        for _, neighbor in pairs(neighbors) do
            if not is_tracked(hash) then
                save_mapchunk(neighbor, true)
                run_scanners(neighbor)
            else
                run_workers(neighbor)
            end
        end
        minetest.log("error", dump(get_labels(hash)))
    end
    minetest.after(tracking_interval, player_tracker)
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
    minetest.after(2, player_tracker)
end
