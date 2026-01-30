
-- Internationalization
local S = player_api.S

-- we have to do this because damage groups does not properly transfer for held items
-- with a custom hand, because yay! Engine!!!
local hand_groups = {not_in_creative_inventory = 1, nobones = 1, hand = 1}
local hand_def = core.registered_items[""]
hand_groups = minimal.merge_tables(hand_groups, table.copy(hand_def.groups))

-- callback for hand items to open a crafting formspec for simple crafting
-- task doable with pure hands
local function on_secondary_use_hand(itemstack, user, pointed_thing)
    -- must be a player not pointing at an object)
    if not core.is_player(user) or not pointed_thing
        or (pointed_thing.type ~= "nothing") then

        return
    end

    -- open `freehand crafting station`,
    -- suppress default hand tool
    local tool_node = {name = "tech:bare_hands"}
    crafting.crafting_item_on_rightclick(nil, tool_node, user, ItemStack(),
                                         pointed_thing, true)
end

-- override properties of empty hand
core.override_item("", {
                       tool_capabilities =
                           {damage_groups = {fleshy=minimal.hand_dmg}},
                       liquids_pointable = true,
                       groups = table.copy(hand_groups),
                       on_secondary_use = on_secondary_use_hand,
                       }
)

-- The hand
-- does not override core.registered_items[""]
-- use core.registered_items["player_api:hand"] instead
minetest.register_item(
    "player_api:hand", {
        description = S("Your hand"),
        type = "none",
        wield_image = "player_hand.png",
        wield_scale = {x=1,y=1,z=2.5},
        tool_capabilities = {
            full_punch_interval = minimal.hand_punch_int,
            max_drop_level = minimal.hand_max_lvl,
            groupcaps = {
                choppy = {times={[3]=minimal.hand_chop}, uses=0,
                          maxlevel=minimal.hand_max_lvl},
                crumbly = {times={[3]=minimal.hand_crum}, uses=0,
                           maxlevel=minimal.hand_max_lvl},
                snappy = {times={[3]=minimal.hand_snap}, uses=0,
                          maxlevel=minimal.hand_max_lvl},
                oddly_breakable_by_hand = {
                    times={
                        [1]=minimal.hand_crum*minimal.t_scale1,
                        [2]=minimal.hand_crum*minimal.t_scale2,
                        [3]=minimal.hand_crum}, uses=0
                },
            },
            damage_groups = {fleshy=minimal.hand_dmg}
        },
        liquids_pointable = true,
        groups = hand_groups,
        on_secondary_use = on_secondary_use_hand,
        _dig_tip = S("Dig / Punch / Stun small animals / Grab animals"),
        _use_tip = S("Split certain blocks"),
        _place_tip = S("Select a place for crafting / Drink"),
        -- despite allow_player_inventory_action Luanti 5.10 would let the hand
        -- disappear and show up later without an explicit on_drop()
        -- (fixed in 5.11, -> #TODO: remove if 5.11 becomes minimum req.)
        on_drop = function(itemstack, dropper, pos)
            return itemstack
        end
})

-- Adds a colorized hand item to the first slot of the main inventory and
-- handles existing items in that slot.
-- WARNING Calling this function before setting up textures for the player
--         will cause a crash!
function player_api.add_player_hand(player)
    -- player_api:hand is always in the first slot -> check it
    local inv = player:get_inventory()
    local stack_1 = inv:get_stack("main", 1)
    local name = stack_1:get_name()
    -- player does not yet have a hand? -> add it
    if not name:find("player_api:hand", 1, true) then
        local base_texture = player_api.load_base_texture_table(player)
        local handstring = "player_api:hand_"..base_texture["skin"]["color"]

        if inv:is_empty("main") then
            -- new player or respawn or after inventory cleared in tutorial
            inv:set_stack("main", 1, handstring)
        else
            -- must be an existing player who does not yet have a hand
            local player_name = player:get_player_name()
            core.log("info",
                     "player_api:hand for existing player: " .. player_name)
            inv:set_stack("main", 1, handstring)
            core.chat_send_player(player_name, "* * * * * *")
            core.chat_send_player(player_name, S("You were given a hand!"))
            -- try to add the replaced stack somewhere else in main
            if stack_1 and not stack_1:is_empty() then
                local leftover = inv:add_item("main", stack_1)
                if not leftover:is_empty() then
                    -- create a special inventory accessible in the clothing FS
                    inv:set_size("new_hand_backup", 1)
                    inv:set_stack("new_hand_backup", 1, leftover)
                    core.chat_send_player(player_name,
                                    S("Check your inventory!"))
                    minimal.warn_inv_full(player)
                    -- make sure the clothing FS is the current sfinv page and
                    -- that it is up to date
                    sfinv.set_page(player, "clothing:clothing")
                end
            end
            core.chat_send_player(player_name, "* * * * * *")
        end
    end
end

-- update `Clothing` FS if it is the current and if inventory "new_hand_backup"
-- is empty
local function update_clothing_formspec(player)
    local inv = player:get_inventory()
    if inv and inv:is_empty("new_hand_backup")
        and sfinv.get_page(player) == "clothing:clothing" then

        sfinv.set_player_inventory_formspec(player)
    end
end

-- Block inventory action to move/remove our hand and make special inventory
-- "new_hand_backup" inaccessible, once it gets cleared.
-- NOTE: "take" includes cases where the player tries to drop the hand or to throw it
-- out of a formspec window
core.register_allow_player_inventory_action(
function(player, action, inventory, inventory_info)
    if action == "take" then
        if inventory_info.index == 1 then
            -- prevent taking the hand out of "main"
            if inventory_info.listname == "main" then return 0 end
            -- update `Clothing` FS after "new_hand_backup" is cleared
            if inventory_info.listname == "new_hand_backup" then
                core.after(0.1, update_clothing_formspec, player)
            end
        end
        return -- no restriction
    end
    if action == "move" then
        if inventory_info.from_index == 1 then
            -- prevent moving the hand out of "main"
            if inventory_info.from_list == "main" then return 0 end
            -- update `Clothing` FS after "new_hand_backup" is cleared
            if inventory_info.from_list == "new_hand_backup" then
                core.after(0.1, update_clothing_formspec, player)
            end
        elseif inventory_info.to_list == "new_hand_backup" then
            -- to avoid confusion, block using the `pocket` forever by swapping
            return 0
        end
        return -- no restriction
    end
end)
