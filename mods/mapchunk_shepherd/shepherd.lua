-- Mapchunk Shepherd
-- License: GNU GPLv3
-- Copyright © Jan Wielkiewicz 2023

-- Globals
ms = mapchunk_shepherd

local tracking_interval = 2
local mod_storage = minetest.get_mod_storage()

local function mapchunk_hash(pos)
    local pos = vector.divide(pos, 80)
    pos = vector.floor(pos)
    pos = vector.multiply(pos, 80)
    return minetest.hash_node_position(pos)
end

local function neighboring_mapchunks(hash)
    local pos = minetest.get_position_from_hash(hash)
    local hashes = {}
    for z = -1, 1 do
        for y = -1, 1 do
            for x = -1, 1 do
                local v = vector.new(x, y, z)
                v = vector.multiply(v, 80)
                local mapchunk_pos = vector.add(pos, v)
                table.insert(hashes, mapchunk_hash(mapchunk_pos))
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

local function save_mapchunk(hash)
    if not is_tracked(hash) then
        mod_storage:set_int(hash, ms.encode_labels({"chunk_tracked"}))
    end
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

local function mapchunk_borders(hash)
    local pos_min = minetest.get_position_from_hash(hash)
    local pos_max = vector.add(pos_min, 79)
    return pos_min, pos_max
end

local function player_tracker()
    local players = minetest.get_connected_players()
    for _, player in ipairs(players) do
        local pos = player:get_pos()
        local hash = mapchunk_hash(pos)
        save_mapchunk(hash)
        minetest.log("error", dump(get_labels(hash)))
    end
    minetest.after(tracking_interval, player_tracker)
end

minetest.after(2, player_tracker)
