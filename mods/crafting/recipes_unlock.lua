-- LOCK/UNLOCK recipe per player -----------------------------------------------
--------------------------------------------------------------------------------

-- list of unlocked recipes per player_name.
-- Stored in player's meta
local unlocked_cache = {}

function crafting.get_unlocked(name)
    local player = minetest.get_player_by_name(name)
    if not player then
        minetest.log(
            "warning",
            "Crafting doesn't support getting unlocks for offline players")
        return {}
    end

    local retval = unlocked_cache[name]
    if not retval then
        retval = minetest.parse_json(
            player:get_meta():get("crafting:unlocked") or "{}")
        unlocked_cache[name] = retval
    end

    assert(retval)

    return retval
end

-- lock and unlock recipes
local function write_json_dictionary(value)
    if next(value) then
        return minetest.write_json(value)
    else
        return "{}"
    end
end

-- locks all player name's recipes and updates player's meta with that info
function crafting.lock_all(name)
    local player = minetest.get_player_by_name(name)
    if not player then
        minetest.log(
            "warning",
            "Crafting doesn't support setting unlocks for offline players")
        return {}
    end

    local unlocked = crafting.get_unlocked(name)

    for key, _ in pairs(unlocked) do
        unlocked[key] = nil
    end

    unlocked_cache[name] = unlocked

    player:get_meta():set_string("crafting:unlocked",
                                 write_json_dictionary(unlocked))
end

-- locks "output" recipe and updates player's meta with that info
function crafting.unlock(name, output)
    local player = minetest.get_player_by_name(name)
    if not player then
        minetest.log(
            "warning",
            "Crafting doesn't support setting unlocks for offline players")
        return {}
    end

    local unlocked = crafting.get_unlocked(name)

    if type(output) == "table" then
        for i=1, #output do
            unlocked[output[i]] = true
            minetest.chat_send_player(name, "You've unlocked " .. output[i])
        end
    else
        unlocked[output] = true
        minetest.chat_send_player(name, "You've unlocked " .. output)
    end

    unlocked_cache[name] = unlocked
    player:get_meta():set_string("crafting:unlocked",
                                 write_json_dictionary(unlocked))
end

if core then
    core.register_on_leaveplayer(function(player)
            unlocked_cache[player:get_player_name()] = nil
        end)
end
