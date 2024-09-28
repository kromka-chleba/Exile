--restart.lua
--A chat command to allow users to start over

--Local table to store pending confirmations.
local timestamp = {}
region = region
lore = lore
local S = lore.S

local __stash_timeout = 60*60*24*14 -- keep for 2 weeks
local function stash_inventory(player, stash, list)
    local timeout = os.time() - __stash_timeout
    local pmeta = player:get_meta()
    local stash_table = {}
    -- Purge expired entries from the list
    if pmeta:contains(stash) then
        stash_table=minetest.deserialize(pmeta:get_string(stash))
        for i, stack in ipairs(stash_table) do
            if stack.epoch < timeout then
                stash_table[i] = nil -- expire old entries
            end
        end
    end
    -- Append new entries to the list
    for _, stack in ipairs(list) do
        table.insert(stash_table, stack)
    end
    -- save the stash to player meta
    pmeta:set_string(stash, minetest.serialize(stash_table))
end

local function dump_stash(player)
    local pos = vector.add(player:get_pos(), vector.new(0,1,0))
    local pmeta = player:get_meta()
    if not pmeta:contains("restart_list") then return false end
    local stash_table=minetest.deserialize(pmeta:get_string("restart_list"))
    for i, entry in ipairs(stash_table) do
        local object = ItemStack(entry.stack)
        object:get_meta():from_table(minetest.deserialize(entry.meta))
        minetest.add_item(pos, object)
    end
end

local function killplayer(name)
    local player = minetest.get_player_by_name(name)
    if not player then
        -- exit if the player left or we somehow got garbage
        return
    end
    player:set_hp(1) -- for players who hit the death formspec bug
    -- See Minetest issues, #11523
    if not minimal.player_in_creative(player) then
        -- Don't remove inventory from creative mode players, just kill 'em
        player:set_hp(0)
        return
    end
    local player_inv = player:get_inventory()
    -- get inv lists we want to empty
    local inv_names = player_api.get_inv_names()
    table.insert(inv_names, 'main')
    table.insert(inv_names, 'craft')
    local epoch=os.time()
    local restart_list = {}
    -- empty them
    for _, list_name in ipairs(inv_names) do
        if not player_inv:is_empty(list_name) then
            for _, stack in ipairs(player_inv:get_list(list_name)) do
                if stack:get_name() ~= "" then
                    local meta=minetest.serialize(stack:get_meta():to_table())
                    table.insert(restart_list, {
                                     epoch=epoch,
                                     stack=stack:to_string(),
                                     meta=meta
                    })
                end
            end
            player_inv:set_list(list_name,{}) -- delete the inventory.
        end
    end
    stash_inventory(player,'restart_list',restart_list)
    -- reset effects of clothes to defaults now that we are naked
    player_api.reset_equipment_effects(player)
    player:set_hp(0)
end

local function restart_confirm (confirmed, _, player, name)
    if confirmed == true then
        region.prespawn(player)
        minetest.log("action", S("@1 gave up the ghost.", name))
        timestamp[name] = minetest.get_gametime()
        local remaining = 20
        local function loop()
            if not minetest.is_player(player) then return end
            if remaining <= 0 then
                minimal.send_message(name, S("POP!"))
                killplayer(name)
            else
                minimal.send_message(name, S("Restart in: @1 seconds.",
                                                  remaining))
                remaining = remaining - 5
                minetest.after(5, loop)
            end
        end
        loop()
    else
        minetest.chat_send_player(name,S("You've come to your senses and "..
                                         "decided to keep trying"))
    end
end

local function killthemagain(player)
    -- Players who manage to close the death formspec can get stuck half-dead
    player:set_hp(1) -- so make them alive again
    minetest.after(2, function() player:set_hp(0) end) -- then try once more
end


local function restart (name, param)
    local nowtime = minetest.get_gametime()
    if timestamp[name] and  ( timestamp[name] +3 ) > nowtime then
        return -- 3 second ratelimit: Don't run killthemagain() until it finishes
    end

    local plyr = minetest.get_player_by_name(name)
    if plyr and plyr:get_hp() == 0 then -- they're stuck in an invalid state
        killthemagain(plyr) -- so we shouldn't make them wait
        return -- signed, comment doggerel gang
    end
    if timestamp[name] and ( timestamp[name] +300 ) > nowtime then
        minetest.chat_send_player(name, S("You can't use this command more "..
                                          "than once per 5 minutes."))
        return
    else
        timestamp[name] = nil
        minimal.yes_or_no(name, S("Restarting does not leave bones!")
                          .."\n "..
                          S("Your inventory will be deleted.").."\n"..
                          S("Are you sure?"), restart_confirm)
    end
end

minetest.register_chatcommand(
    "restart",{
        privs = {
            interact = true,
        },
        description =
            S("Give up on your current character without leaving a "..
              "trace. Everything you hold will be lost. Have a new Exile "..
              "appear in this world in their stead and try your hand at "..
              "survival again."),
        func = restart
})

minetest.register_chatcommand(
    "respawn",{
        privs = {
            interact = true,
        },
        description = S("This command is an alias for /restart. See there for "..
                        "further information."),
        func = restart
})

minetest.register_chatcommand(
    "recover_inv",{
        params = "<playername>",
        privs = {
            server = true,
        },
        description = "This command allows admins to recover a player's "..
            "inventory after they have restarted.\n"..
            "Items will be dropped at their feet.",
        func = function(name, param)
            local ply = minetest.get_player_by_name(param)
            if not ply then return "Could not find player "..tostring(param) end
            if dump_stash(ply) then
                return "Dumped all stashed inventory for "..param
            else
                return "Failed to dump stashed inventory for "..param
            end
        end
})
