-- Mapchunk Shepherd
-- License: GNU GPLv3
-- Copyright © Jan Wielkiewicz 2023

-- Globals
local ms = mapchunk_shepherd

local mod_storage = minetest.get_mod_storage()
local modpath = minetest.get_modpath('mapchunk_shepherd')
local dimensions = dofile(modpath.."/chunk_dimensions.lua")

local mapchunk_offset = dimensions.mapchunk_offset
local chunk_side = dimensions.chunk_side
local old_chunksize = dimensions.old_chunksize
local blocks_per_chunk = dimensions.blocks_per_chunk

-- Converts node coordinates to mapchunk coordinates
function ms.node_pos_to_mapchunk_pos(pos)
    pos = vector.subtract(pos, mapchunk_offset)
    pos = vector.divide(pos, chunk_side)
    pos = vector.floor(pos)
    return pos
end

-- A global function to get hash from pos
function ms.mapchunk_hash(pos)
    pos = ms.node_pos_to_mapchunk_pos(pos)
    pos = vector.multiply(pos, chunk_side)
    pos = vector.add(pos, mapchunk_offset)
    return minetest.hash_node_position(pos)
end

-- A global function to get mapchunk borders
function ms.mapchunk_borders(hash)
    local pos_min = minetest.get_position_from_hash(hash)
    local pos_max = vector.add(pos_min, chunk_side - 1)
    return pos_min, pos_max
end

function ms.chunksize_changed()
    if old_chunksize == 0 then
        mod_storage:set_int("chunksize", blocks_per_chunk)
        return false
    elseif old_chunksize ~= blocks_per_chunk then
        return true
    else
        return false
    end
end

function ms.is_tracked(hash)
    local value = mod_storage:get_int(hash)
    if value > 0 then
        return true
    else
        return false
    end
end

function ms.get_labels(hash)
    local encoded = mod_storage:get_int(hash)
    if encoded then
        return ms.decode_labels(encoded)
    else
        return {}
    end
end

function ms.add_labels(hash, new_labels)
    local labels = ms.get_labels(hash)
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

function ms.save_mapchunk(hash, force)
    if force then
        mod_storage:set_int(hash, ms.encode_labels({"chunk_tracked"}))
    elseif not ms.is_tracked(hash) then
        ms.add_labels(hash, {"chunk_tracked"})
    end
end

-- Clears labels other than "chunk_tracked"
function ms.reset_mapchunk(hash)
    mod_storage:set_int(hash, ms.encode_labels({"chunk_tracked"}))
end

-- Removes the hash from history
function ms.remove_mapchunk(hash)
    mod_storage:set_int(hash, 0)
end

function ms.was_scanned(hash)
    local labels = ms.get_labels(hash)
    if ms.contains_labels(labels, {"scanned"}) then
        return true
    else
        return false
    end
end

function ms.remove_labels(hash, labels)
    local old_labels = ms.get_labels(hash)
    if not ms.is_tracked(hash) then
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
