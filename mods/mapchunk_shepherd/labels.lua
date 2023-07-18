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
local ms = mapchunk_shepherd
ms.labels = {}

local registered_labels = {}

function ms.labels.get_registered()
    return table.copy(registered_labels)
end

function ms.labels.is_label(name)
    if registered_labels[name] then
        return true
    end
    return false
end

function ms.labels.register(name)
    if registered_labels[name] then
        minetest.log("error", "Mapchunk shepherd: Label with name \""..name.."\" already exists!")
        return
    else
        registered_labels[name] = {name = name}
    end
end

function ms.labels.is_valid(labels)
    for _, label in pairs(labels) do
        if not ms.labels.is_label(label) then
            return false
        end
    end
    return true
end

function ms.labels.encode(label_names)
    local to_encode = {}
    for _, label in pairs(label_names) do
        -- Only uses valid labels
        if ms.labels.is_valid({label}) then
            table.insert(to_encode, label)
        else
            minetest.log("error", "Mapchunk shepherd: Label \""..label.."\" is not a valid label!")
        end
    end
    return minetest.serialize(to_encode)
end

function ms.labels.decode(encoded)
    return minetest.deserialize(encoded)
end

-- Checks if table labels1 contains all labels from labels2
function ms.labels.contains(labels1, labels2)
    if #labels2 == 0 then
        return true
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

function ms.labels.has_one_of(labels1, labels2)
    if #labels2 == 0 then
        return true
    end
    for _, label2 in pairs(labels2) do
        for _, label1 in pairs(labels1) do
            if label1 == label2 then
                return true
            end
        end
    end
    return false
end

-- Don't change this
-- I'm using this for the queue also,
-- not only labels.
function ms.labels.delete_duplicates(labels)
    local paired = {}
    for _, label in pairs(labels) do
        paired[label] = label
    end
    local clean = {}
    for _, label in pairs(paired) do
        table.insert(clean, label)
    end
    return clean
end

ms.labels.register("chunk_tracked")
ms.labels.register("scanned")
ms.labels.register("scanner_failed")
ms.labels.register("worker_failed")
ms.labels.register("mapgen_scanned")
