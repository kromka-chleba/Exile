-- Mapchunk Shepherd: Labels
-- License: GNU GPLv3
-- Copyright © Jan Wielkiewicz 2023

-- Labels are binary flags stored in 48-bit ints.
-- This means you can register up to 48 labels.
-- Each label is identified by its name or 1-48 number
-- Changing label meaning between releases may break
-- mapchunk record on existing worlds so it is
-- not recommended.

-- Globals
ms = mapchunk_shepherd

local registered_labels = {}
local ids_by_name = {}
local names_by_id = {}

function ms.get_labels()
    return table.copy(registered_labels)
end

function ms.is_label(name)
    return ids_by_name[name]
end

function ms.register_label(name, nr)
    if nr < 1 or nr > 48 then
        minetest.log("error", "Mapchunk shepherd: Label nr needs to be 0-47 and is "..nr)
    end
    if registered_labels[nr] then
        minetest.log("error", "Mapchunk shepherd: Label with number "..nr.." already exists!")
        return
    end
    for _, label in pairs(registered_labels) do
        if name == label.name then
            minetest.log("error", "Mapchunk shepherd: Label with name \""..name.."\" already exists!")
            return
        end
    end
    local id = 2^(nr - 1)
    registered_labels[nr] = {name = name, id = id}
    ids_by_name[name] = id
    names_by_id[id] = name
end

function ms.encode_labels(label_names)
    local encoded = 0
    local ids = {}
    for _, label in pairs(label_names) do
        local id = ids_by_name[label]
        -- this makes sure each id is added only once
        ids[label] = id
    end
    for _, id in pairs(ids) do
        encoded = encoded + id
    end
    return encoded
end

function ms.decode_labels(encoded)
    local encoded = encoded
    local decoded_ids = {}
    for i = 47, 0, -1 do
        local id = 2^i
        if encoded - id >= 0 then
            table.insert(decoded_ids, names_by_id[id])
            encoded = encoded - id
        end
    end
    return decoded_ids
end

function ms.labels_valid(labels)
    for _, label in pairs(labels) do
        if not ms.is_label(label) then

            return false
        end
    end
    return true
end

-- Checks if table labels1 contains all labels from labels2
function ms.contains_labels(labels1, labels2)
    if #labels2 == 0 then
        return false
    end
    for _, label2 in pairs(labels2) do
        local pass = false
        for _, label1 in pairs(labels1) do
            if label1 == label2 then
                pass = true
                break
            end
        end
        if not pass then
            return false
        end
    end
    return true
end

ms.register_label("chunk_tracked", 1)
