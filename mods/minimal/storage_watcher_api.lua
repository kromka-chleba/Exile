minimal = minimal
local S = minimal.S

-- functionality for determining if a player is looking in storage
-- lets you set up proper functionality for when a player is or isn't
--   looking at something, and committing to events accordingly
-- e.g. playing sounds when a player looks into something or when they close out

local storage_watched = {} -- table for determining watchers at a position

-- get watchers
-- get a table of watchers at a position, or an empty table if there isn't
-- "create" is for creating a new watcher table to be used
--   and is assigned to storage_watched
-- shouldn't be used unless you're adding a watcher to the table;
--   used by add_watcher
function minimal.get_watchers(pos, create)
    -- pos can be a convertable position or any string of your liking
    pos = type(pos) == "string" and pos
        or type(pos) == "table" and minetest.pos_to_string(pos)
    -- create a new watcher table if it doesn't exist
    if create then
        storage_watched[pos] = storage_watched[pos] or {}
    end
    return storage_watched[pos]
        or {} -- send watcher table or create an empty one
end

-- add a watcher
-- adds a player watching storage to the provided pos
--   (or any form of "string" name technically)
function minimal.add_watcher(pos, pname)
    local wt = minimal.get_watchers(pos, true) -- watch_table
    --  (2nd boolean will create a new table to add to if there isn't one)

    pname = type(pname) == "string" and pname
        or (type(pname) == "userdata"
            or type(pname) == "table")
        and pname.get_player_name and pname:get_player_name()
    -- iterate over table for nil indexes because Lua is dysfunctional
    --   when it comes to counting
    -- iterate +1 to get a nil index at the end to add
    --   (in case there isn't a random nil index)
    for wi=1,(#wt + 1) do
        -- if we find ourselves then return false for failure
        if wt[wi] == pname then return false end
        -- if we find a nil index, add to
        if wt[wi] == nil then
            wt[wi] = pname
            return true
        end
    end
    -- due to check for self and check for nil being in the same for loop,
    --   it is possible on an off chance for a watcher to
    --   be added twice, Lua is weird!
    -- won't matter beyond getting a genuine count, as remove_watcher will
    --   iterate through the entire table to remove all instances
end

-- remove a watcher
-- removes a player watching storage from a specified pos
--   (if it exists and has more than 0 watchers)
-- deletes table if emptied
function minimal.remove_watcher(pos, pname)
    local wt = minimal.get_watchers(pos) -- watch_table
    if #wt < 1 then return end -- no watch table
    pname = type(pname) == "string" and pname
        or (type(pname) == "userdata"
            or type(pname) == "table")
        and pname.get_player_name and pname:get_player_name()
    -- iterate over table to find name and remove
    for wi=1,#wt do
        if wt[wi] == pname then
            wt[wi] = nil
            -- delete table if empty
            if #wt < 1 then storage_watched[pos] = nil end
            return true
        end
    end
end

-- sound play watcher
-- automatically finds an open or close sound and plays it at pos
-- true or empty 3rd parameter for open sound, false for close sound
-- if no nodedef is provided, will get one
function minimal.sound_play_watcher(pos, nodedef, open)
    -- playing open sound is default
    if type(open) ~= "boolean" then open = true end
    nodedef = type(nodedef) == "table"
        and minetest.registered_nodes[nodedef.name]
        or minimal.get_nodedef(pos)
    -- no nodedef or sounds, can't play
    if not nodedef or not nodedef.sounds then return end
    local sound = open and nodedef.sounds.storage_open
        or nodedef.sounds.storage_close
    -- could not get wanted sound
    if not sound then return end
    sound = table.copy(sound) -- clone for local use
    sound.pos = pos
    minimal.sound_play(sound)
end
