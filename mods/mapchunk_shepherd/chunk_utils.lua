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
    local value = mod_storage:get_string(hash)
    local labels = ms.labels.decode(value)
    return labels
end

function ms.get_labels(hash)
    local encoded = mod_storage:get_string(hash)
    if encoded == "" then
       return {}
    end
    local value = minetest.deserialize(encoded)
    if value then
       return value
    else
       minetest.log("error", "Get_labels failed for hash: "..
		    dump(hash).." / "..dump(encoded))
       return {}
    end
end

function ms.add_labels(hash, new_labels)
    local new_labels = table.copy(new_labels)
    local labels = ms.get_labels(hash)
    if ms.labels.is_valid(new_labels) then
        for _, nlabel in pairs(new_labels) do
            table.insert(labels, nlabel)
        end
        labels = ms.labels.delete_duplicates(labels)
        mod_storage:set_string(hash, ms.labels.encode(labels))
    else
        minetest.log("error", "Mapchunk shepherd: "..label.." is not a valid label!")
    end
end

function ms.save_mapchunk(hash, force)
    if force then
        mod_storage:set_string(hash, ms.labels.encode({"chunk_tracked"}))
    elseif not ms.is_tracked(hash) then
        ms.add_labels(hash, {"chunk_tracked"})
    end
end

-- Clears labels other than "chunk_tracked"
function ms.reset_mapchunk(hash)
    mod_storage:set_string(hash, ms.labels.encode({"chunk_tracked"}))
end

-- Removes the hash from history
function ms.remove_mapchunk(hash)
    mod_storage:set_string(hash, "")
end

function ms.was_scanned(hash)
    local labels = ms.get_labels(hash)
    return ms.labels.contains(labels, {"scanned"})
end

function ms.was_mapgen_scanned(hash)
    local labels = ms.get_labels(hash)
    return ms.labels.contains(labels, {"mapgen_scanned"})
end

function ms.remove_labels(hash, labels)
    -- copy to avoid modifying the table somewhere far far away
    local labels = table.copy(labels)
    local old_labels = ms.get_labels(hash)
    if not ms.is_tracked(hash) then
        minetest.log("error", "Mapchunk shepherd: "..hash.." is not tracked!")
    end
    local new_labels = {}
    for _, old_name in pairs(old_labels) do
        local removed = false
        for _, name in pairs(labels) do
            if old_name == name then
                removed = true
                break
            end
        end
        if not removed then
            table.insert(new_labels, old_name)
        end
    end
    mod_storage:set_string(hash, ms.labels.encode(new_labels))
end

function ms.handle_labels(hash, labels_added, labels_removed)
    if labels_added then
        local labels_added = table.copy(labels_added)
        ms.add_labels(hash, labels_added)
    end
    if labels_removed then
        local labels_removed = table.copy(labels_removed)
        ms.remove_labels(hash, labels_removed)
    end
end

function ms.contains_labels(hash, labels)
    local chunk_labels = ms.get_labels(hash)
    return ms.labels.contains(chunk_labels, labels)
end

function ms.has_one_of(hash, labels)
    local chunk_labels = ms.get_labels(hash)
    return ms.labels.has_one_of(chunk_labels, labels)
end
