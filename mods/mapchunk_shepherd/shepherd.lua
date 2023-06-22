-- Mapchunk Shepherd
-- License: GNU GPLv3
-- Copyright © Jan Wielkiewicz 2023

local tracking_interval = 1
local visited_mapchunks = {} -- hash, labels

local function mapchunk_hash(pos)
    local pos = vector.divide(pos, 80)
    pos = vector.floor(pos)        
    return minetest.hash_node_position(pos)
end

local function is_tracked(hash)
    for saved_hash, labels in pairs(visited_mapchunks) do
        if saved_hash == hash then
            return true
        end
    end
    return false
end

local function save_mapchunk(hash)
    if not is_tracked(hash) then
        visited_mapchunks[hash] = {tracked = true}
    end
end

local function set_labels(hash, labels)
    if is_tracked(hash) then
        for label, value in pairs(labels) do
            visited_mapchunks[hash][label] = value
        end
    end
end

-- Gets mapchunk labels by their names
-- of label_names is nil, all labels are returned
local function get_labels(hash, label_names)
    if not is_tracked(hash) then
        return
    end
    if not label_names then
        return visited_mapchunks[hash]
    end
    local labels = {}
    for _, name in pairs(label_names) do
        labels[name] = visited_mapchunks[hash][name]
    end
    return labels
end

local function player_tracker()
    local players = minetest.get_connected_players()
    for _, player in ipairs(players) do
        local pos = player:get_pos()
        local hash = mapchunk_hash(pos)
        save_mapchunk(hash)
    end
    minetest.after(tracking_interval, player_tracker)
end

minetest.after(2, player_tracker)
